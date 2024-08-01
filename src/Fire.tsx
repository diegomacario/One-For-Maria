import { useMemo } from "react";
import { useFrame } from "@react-three/fiber";
import * as THREE from "three";

import { generatePerlin } from "./noise.js";

import fragmentShader from "./shaders/fire/fragment.glsl";
import vertexShader from "./shaders/fire/vertex.glsl";

const size = 32;
const width = size;
const height = size;
const depth = size;
const scale1 = 6;
const scale2 = 8;

export function Fire() {
  const texture = useMemo(() => {
    const data = new Float32Array(width * height * depth);
    generatePerlin(data, width, height, depth, scale1);
    const texture = new THREE.Data3DTexture(data, width, height, depth);
    texture.format = THREE.RedFormat;
    texture.type = THREE.FloatType;
    texture.minFilter = THREE.LinearFilter;
    texture.magFilter = THREE.LinearFilter;
    texture.unpackAlignment = 1;
    texture.needsUpdate = true;
    return texture;
  }, []);

  const noiseTexture = useMemo(() => {
    const noiseData = new Float32Array(width * height * depth);
    generatePerlin(noiseData, width, height, depth, scale2);
    const noiseTexture = new THREE.Data3DTexture(
      noiseData,
      width,
      height,
      depth
    );
    noiseTexture.format = THREE.RedFormat;
    noiseTexture.type = THREE.FloatType;
    noiseTexture.minFilter = THREE.LinearFilter;
    noiseTexture.magFilter = THREE.LinearFilter;
    noiseTexture.unpackAlignment = 1;
    noiseTexture.needsUpdate = true;
    return noiseTexture;
  }, []);

  const mat = useMemo(() => {
    return new THREE.ShaderMaterial({
      uniforms: {
        map: { value: texture },
        noise: { value: noiseTexture },
        time: { value: 0.0 },
      },
      transparent: true,
      vertexShader,
      fragmentShader,
      side: THREE.BackSide,
      blending: THREE.CustomBlending,
      blendEquation: THREE.MaxEquation,
    });
  }, [texture, noiseTexture]);

  useFrame((state, delta) => {
    mat.uniforms.time.value = state.clock.elapsedTime;
  });

  return (
    <>
      <group position={[0, 0.075, 0]} scale={1}>
        <mesh scale={[1, 2, 1]}>
          <cylinderGeometry args={[0.5, 0.5, 1, 36, 1]}></cylinderGeometry>
          <primitive object={mat} attach="material" />
        </mesh>
      </group>
    </>
  );
}
