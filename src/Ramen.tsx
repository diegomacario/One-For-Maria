import { Float, useGLTF } from "@react-three/drei";
import * as THREE from "three";
import type { GLTF } from "three-stdlib";

useGLTF.preload("/models/ramen.glb");

type GLTFResult = GLTF & {
  nodes: {
    Ramen: THREE.Mesh;
    Cylinder021: THREE.Mesh;
    Cylinder021_1: THREE.Mesh;
    Vegetables: THREE.Mesh;
    Vegetables001: THREE.Mesh;
    Vegetables002: THREE.Mesh;
    Vegetables003: THREE.Mesh;
  };
  materials: {
    Atlas: THREE.MeshStandardMaterial;
    Grey: THREE.MeshStandardMaterial;
    DarkBrown: THREE.MeshStandardMaterial;
    ["Atlas.001"]: THREE.MeshStandardMaterial;
  };
};

const speed = 5;
const rotationIntensity = 0.1;
const floatingRange: [number, number] = [-0.005, 0.005];

export function Ramen(props: JSX.IntrinsicElements["group"]) {
  const { nodes, materials } = useGLTF("/models/ramen.glb") as GLTFResult;

  return (
    <group {...props} dispose={null}>
      <mesh
        geometry={nodes.Ramen.geometry}
        material={materials.Atlas}
        position={[0, -0.403, 0]}
        scale={1.886}
      />
      <Float
        speed={speed}
        rotationIntensity={rotationIntensity}
        floatingRange={floatingRange}
      >
        <mesh
          geometry={nodes.Vegetables.geometry}
          material={materials["Atlas.001"]}
          position={[0, -0.403, 0]}
          scale={1.886}
        />
      </Float>
      <Float
        speed={speed}
        rotationIntensity={rotationIntensity}
        floatingRange={floatingRange}
      >
        <mesh
          geometry={nodes.Vegetables001.geometry}
          material={materials["Atlas.001"]}
          position={[0, -0.403, 0]}
          scale={1.886}
        />
      </Float>
      <Float
        speed={speed}
        rotationIntensity={rotationIntensity}
        floatingRange={floatingRange}
      >
        <mesh
          geometry={nodes.Vegetables002.geometry}
          material={materials["Atlas.001"]}
          position={[0, -0.403, 0]}
          scale={1.886}
        />
      </Float>
      <Float
        speed={speed}
        rotationIntensity={rotationIntensity}
        floatingRange={floatingRange}
      >
        <mesh
          geometry={nodes.Vegetables003.geometry}
          material={materials["Atlas.001"]}
          position={[0, -0.403, 0]}
          scale={1.886}
        />
      </Float>
      <mesh geometry={nodes.Cylinder021.geometry} material={materials.Grey} />
      <mesh
        geometry={nodes.Cylinder021_1.geometry}
        material={materials.DarkBrown}
      />
    </group>
  );
}
