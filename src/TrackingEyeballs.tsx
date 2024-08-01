import { useMemo, useRef } from "react";
import { useFrame } from "@react-three/fiber";
import * as THREE from "three";

import fragmentShader from "./shaders/tracking_eyeball/fragment.glsl";
import vertexShader from "./shaders/tracking_eyeball/vertex.glsl";
import { Track, Interpolation, Frame } from "./animationUtils";

function composeBlinkAnimation(): Track {
  const track = new Track();
  const frames = [
    { mTime: 0.0, mValue: 0.0, mInSlope: 0.0, mOutSlope: 0.0 },
    { mTime: 0.08, mValue: 0.1, mInSlope: 0.0, mOutSlope: 0.0 },
    { mTime: 0.16, mValue: 1.0, mInSlope: 0.0, mOutSlope: 0.0 },
    { mTime: 0.24, mValue: 1.0, mInSlope: 0.0, mOutSlope: 0.0 },
    { mTime: 0.32, mValue: 0.8, mInSlope: 0.0, mOutSlope: 0.0 },
    { mTime: 0.4, mValue: -0.1, mInSlope: 0.0, mOutSlope: 0.0 },
    { mTime: 0.48, mValue: 0.0, mInSlope: 0.0, mOutSlope: 0.0 },
  ];

  track.setNumberOfFrames(frames.length);
  track.setInterpolation(Interpolation.Cubic);

  frames.forEach((frameData, index) => {
    const frame = new Frame();
    frame.mTime = frameData.mTime;
    frame.mValue = frameData.mValue;
    frame.mInSlope = frameData.mInSlope;
    frame.mOutSlope = frameData.mOutSlope;
    track.setFrame(index, frame);
  });

  return track;
}

type Props = JSX.IntrinsicElements["group"];

const pupilRadius = 0.2;
const scleraRadius = 0.45;

export function TrackingEyeballs({ ...props }: Props) {
  const nextBlinkTimeRef = useRef(Math.random() * 3 + 1);

  const blinkAnimation = useMemo(() => {
    return composeBlinkAnimation();
  }, []);

  const shaderMaterial = useMemo(() => {
    return new THREE.ShaderMaterial({
      uniforms: {
        eyelidBlink: { value: 0.0 },
        pupilCenter: { value: new THREE.Vector2(0.5, 0.5) },
        time: { value: 0.0 },
      },
      vertexShader: vertexShader,
      fragmentShader: fragmentShader,
      transparent: true,
    });
  }, []);

  const eyeballsGroupRef = useRef<THREE.Group>(null);

  const cameraWorldPositionRef = useRef(new THREE.Vector3());
  const eyeballWorldPositionRef = useRef(new THREE.Vector3());
  const directionToCameraRef = useRef(new THREE.Vector3());
  const planeNormalRef = useRef(new THREE.Vector3(0, 0, -1));
  const projectionOntoUVPlaneRef = useRef(new THREE.Vector3());
  const pupilMovementDirectionInUVSpaceRef = useRef(new THREE.Vector2());
  const closestPointOnIrisToEdgeRef = useRef(new THREE.Vector2(0.5, 0.5));
  const targetPupilCenterRef = useRef(new THREE.Vector2(0.5, 0.5));
  const eyeballCenterRef = useRef(new THREE.Vector2(0.5, 0.5));
  const tempVector2Ref = useRef(new THREE.Vector2());
  const tempVector3Ref = useRef(new THREE.Vector3());

  useFrame((state, delta) => {
    const elapsedTime = state.clock.getElapsedTime();

    shaderMaterial.uniforms.time.value = elapsedTime;

    // Handle blink animation
    if (elapsedTime >= nextBlinkTimeRef.current) {
      const eyelidBlink = blinkAnimation.sample(
        elapsedTime - nextBlinkTimeRef.current,
        false
      );
      shaderMaterial.uniforms.eyelidBlink.value = eyelidBlink;
      if (
        elapsedTime - nextBlinkTimeRef.current >=
        blinkAnimation.getEndTime()
      ) {
        nextBlinkTimeRef.current = elapsedTime + Math.random() * 3 + 1;
      }
    }

    if (eyeballsGroupRef.current) {
      // Get the world positions of the camera and the eyeball
      state.camera.getWorldPosition(cameraWorldPositionRef.current);
      eyeballsGroupRef.current.getWorldPosition(
        eyeballWorldPositionRef.current
      );

      // Calculate the direction from the eyeball to the camera
      directionToCameraRef.current
        .subVectors(
          cameraWorldPositionRef.current,
          eyeballWorldPositionRef.current
        )
        .normalize();

      // Project the direction onto the UV plane
      projectionOntoUVPlaneRef.current
        .copy(directionToCameraRef.current)
        .sub(
          tempVector3Ref.current
            .copy(planeNormalRef.current)
            .multiplyScalar(
              directionToCameraRef.current.dot(planeNormalRef.current)
            )
        )
        .normalize();

      // Calculate the movement direction in UV space
      pupilMovementDirectionInUVSpaceRef.current
        .set(
          -projectionOntoUVPlaneRef.current.x,
          projectionOntoUVPlaneRef.current.y
        )
        .normalize();

      // Calculate the distance the pupil should move
      closestPointOnIrisToEdgeRef.current
        .set(0.5, 0.5)
        .add(
          tempVector2Ref.current
            .copy(pupilMovementDirectionInUVSpaceRef.current)
            .multiplyScalar(pupilRadius)
        );
      const maxPupilMovementDistance =
        scleraRadius -
        closestPointOnIrisToEdgeRef.current.distanceTo(
          eyeballCenterRef.current
        ) +
        pupilRadius * 0.25;
      const angleBetweenDecalToPlayerAndItsProjection =
        Math.acos(
          directionToCameraRef.current.dot(projectionOntoUVPlaneRef.current)
        ) *
        (180 / Math.PI);
      const pupilMovementDistance =
        (1.0 - angleBetweenDecalToPlayerAndItsProjection / 90.0) *
        maxPupilMovementDistance;

      // Calculate the target pupil center in UV space
      targetPupilCenterRef.current
        .set(0.5, 0.5)
        .add(
          pupilMovementDirectionInUVSpaceRef.current.multiplyScalar(
            pupilMovementDistance
          )
        );

      shaderMaterial.uniforms.pupilCenter.value = targetPupilCenterRef.current;
    }
  });

  return (
    <group {...props} ref={eyeballsGroupRef}>
      {/* Left eye */}
      <mesh position-x={1.25} renderOrder={1}>
        <planeGeometry args={[1, 1]}></planeGeometry>
        <primitive object={shaderMaterial} attach="material" />
      </mesh>
      {/* Right eye */}
      <mesh position-x={-1.25} renderOrder={1}>
        <planeGeometry args={[1, 1]}></planeGeometry>
        <primitive object={shaderMaterial} attach="material" />
      </mesh>
    </group>
  );
}
