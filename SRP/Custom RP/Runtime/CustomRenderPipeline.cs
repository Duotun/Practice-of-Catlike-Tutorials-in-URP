using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

//do the rendering work according to the configuration of pipelineAssets
public class CustomRenderPipeline : RenderPipeline
{
    CameraRender cameraRender = new CameraRender();
    bool useDynamicBatching, useGPUInstancing;  //keep track of these options in the render pipeline
    protected override void Render(ScriptableRenderContext context, Camera[] cameras)
    {
        //throw new System.NotImplementedException();
        foreach(var cam in cameras)
        {
            cameraRender.Render(context, cam, useDynamicBatching, useGPUInstancing);
        }
    }

    public CustomRenderPipeline(bool useDynamicBatching, bool useGPUInstancing,
        bool useSRPBatcher)
    {
        this.useDynamicBatching = useDynamicBatching;
        this.useGPUInstancing = useGPUInstancing;
        GraphicsSettings.useScriptableRenderPipelineBatching = useSRPBatcher;
        GraphicsSettings.lightsUseLinearIntensity = true;   // light color -> linear Space
    }
}
