import { Bloom, EffectComposer } from "@react-three/postprocessing";
import { BlendFunction, KernelSize } from "postprocessing";

export function PostProcessingEffects() {
  return (
    <>
      <ambientLight color="#ffffff" intensity={0.007} />

      <EffectComposer stencilBuffer={false} multisampling={0}>
        <Bloom
          luminanceThreshold={0.3}
          luminanceSmoothing={1}
          intensity={2.33}
          kernelSize={KernelSize.VERY_SMALL}
          mipmapBlur={true}
          radius={0.7}
          blendFunction={BlendFunction.SCREEN}
          levels={8}
        />
      </EffectComposer>
    </>
  );
}
