import ReactDOM from "react-dom/client";
import "./style.css";
import { Canvas } from "@react-three/fiber";
import * as THREE from "three";
import { Fire } from "./Fire.tsx";
import { Environment, Float, OrbitControls, Text } from "@react-three/drei";
import { PostProcessingEffects } from "./PostProcessingEffects.tsx";
import { TrackingEyeballs } from "./TrackingEyeballs.tsx";
import { Mouth } from "./Mouth.tsx";
import { Ramen } from "./Ramen.tsx";
import { SpeechBubble } from "./SpeechBubble.tsx";
import { Heart } from "./Heart.tsx";

const root = ReactDOM.createRoot(
  document.querySelector("#root") as HTMLElement
);

const camera = new THREE.PerspectiveCamera(45, 1, 0.1, 50);
camera.position.set(...new THREE.Vector3(0, 0.5, -3.5).toArray());
camera.lookAt(0.0, -0.2, 0);

root.render(
  <>
    <Canvas
      dpr={[1, 2]}
      camera={camera}
      gl={{ powerPreference: "high-performance", antialias: true }}
      shadows={true}
    >
      <color attach="background" args={["black"]} />

      <Environment
        files={"/environment_maps/kiara_1_dawn_1k.hdr"}
        environmentRotation={[0, Math.PI, 0]}
      ></Environment>

      <PostProcessingEffects></PostProcessingEffects>

      <OrbitControls
        target={[0.0, -0.2, 0.0]}
        enablePan={true}
        enableRotate={true}
        enableZoom={true}
        minDistance={2}
        maxDistance={5}
        minPolarAngle={0}
        maxPolarAngle={Math.PI * 0.575}
        makeDefault
      />

      <Fire></Fire>

      <Float speed={5} rotationIntensity={0.5} floatingRange={[-0.05, 0.05]}>
        <group position={[0, 0.25 + 0.075, 0]} scale={1.45}>
          <TrackingEyeballs
            position={[0, -0.625, 0]}
            rotation={[0, Math.PI, 0]}
            scale={0.1}
          ></TrackingEyeballs>
          <Mouth
            position={[0, -0.75, 0.01]}
            rotation={[0, Math.PI, 0]}
            scale={0.3}
          ></Mouth>
        </group>
      </Float>

      <Ramen
        position={[0, -1.15, 0]}
        rotation={[0, Math.PI * -0.25, 0]}
        scale={0.85}
      ></Ramen>

      <Float speed={3} rotationIntensity={0.5} floatingRange={[-0.05, 0.05]}>
        <group position={[0, 0, 0]} scale={0.75}>
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
      </Float>
    </Canvas>
  </>
);
