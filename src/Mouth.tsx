import { useMemo } from "react";
import { useFrame } from "@react-three/fiber";
import * as THREE from "three";

import fragmentShader from "./shaders/mouth/fragment.glsl";
import vertexShader from "./shaders/mouth/vertex.glsl";

type Props = JSX.IntrinsicElements["group"];

export function Mouth({ ...props }: Props) {
  const shaderMaterial = useMemo(() => {
    return new THREE.ShaderMaterial({
      uniforms: {
        time: { value: 0.0 },
      },
      vertexShader: vertexShader,
      fragmentShader: fragmentShader,
      transparent: true,
    });
  }, []);

  useFrame((state, delta) => {
    shaderMaterial.uniforms.time.value = state.clock.elapsedTime;
  });

  return (
    <group {...props}>
      <mesh renderOrder={1}>
        <planeGeometry args={[1, 1]}></planeGeometry>
        <primitive object={shaderMaterial} attach="material" />
      </mesh>
    </group>
  );
}
