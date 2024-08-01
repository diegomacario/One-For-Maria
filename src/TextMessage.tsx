import { SpeechBubble } from "./SpeechBubble.tsx";
import { Heart } from "./Heart.tsx";
import { Text } from "@react-three/drei";
import { useEffect, useRef } from "react";
import * as THREE from "three";

export function TextMessage() {
  const groupRef = useRef<THREE.Group>(null);
  const portraitOffset = 0.25;
  const aspectLimit = 0.75;

  useEffect(() => {
    const width = window.innerWidth;
    const height = window.innerHeight;
    const aspect = width / height;

    if (groupRef.current) {
      if (aspect < aspectLimit) {
        // Taller than wide
        groupRef.current.position.set(portraitOffset, 0, 0);
      } else {
        // Wider than tall
        groupRef.current.position.set(0, 0, 0);
      }
    }
  }, []);

  useEffect(() => {
    const handleResize = () => {
      const width = window.innerWidth;
      const height = window.innerHeight;
      const aspect = width / height;

      if (groupRef.current) {
        if (aspect < aspectLimit) {
          // Taller than wide
          groupRef.current.position.set(portraitOffset, 0, 0);
        } else {
          // Wider than tall
          groupRef.current.position.set(0, 0, 0);
        }
      }
    };

    window.addEventListener("resize", handleResize);

    // Cleanup event listener on component unmount
    return () => {
      window.removeEventListener("resize", handleResize);
    };
  }, []);

  return (
    <group ref={groupRef} scale={0.75}>
      <SpeechBubble
        position={[-0.75, 0, 0]}
        rotation={[0, Math.PI, 0]}
      ></SpeechBubble>
      <Text
        renderOrder={3}
        position={[-0.675, 0.25, -0.01]}
        rotation={[0, Math.PI, 0]}
        font={"./fonts/Caveat-Bold.ttf"}
        fontSize={0.08}
      >
        {"Happy birthday Maria!"}
        <meshBasicMaterial
          color={"#000000"}
          transparent
          depthTest={false}
        ></meshBasicMaterial>
      </Text>
      <Heart
        position={[-1.085, 0.25, -0.01]}
        rotation={[0, Math.PI, Math.PI * -0.025]}
        scale={0.125}
      ></Heart>
    </group>
  );
}
