import { useMemo } from "react";
import { useFrame } from "@react-three/fiber";
import * as THREE from "three";

import fragmentShader from "./shaders/heart/fragment.glsl";
import vertexShader from "./shaders/heart/vertex.glsl";

type Props = JSX.IntrinsicElements["group"];

export function Heart({ ...props }: Props) {
  const shaderMaterial = useMemo(() => {
    return new THREE.ShaderMaterial({
      uniforms: {
        time: { value: 0.0 },
      },
      vertexShader: vertexShader,
      fragmentShader: fragmentShader,
      transparent: true,
      depthTest: false,
    });
  }, []);

  useFrame((state, delta) => {
    shaderMaterial.uniforms.time.value = state.clock.elapsedTime;
  });

  return (
    <group {...props}>
      <mesh renderOrder={3}>
        <planeGeometry args={[1, 1]}></planeGeometry>
        <primitive object={shaderMaterial} attach="material" />
      </mesh>
    </group>
  );
}
