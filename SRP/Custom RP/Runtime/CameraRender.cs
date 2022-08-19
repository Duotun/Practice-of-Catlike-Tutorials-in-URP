using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
public partial class CameraRender 
{

    ScriptableRenderContext context;
    Camera camera;

    const string bufferName = "Render Camera";
    CommandBuffer buffer = new CommandBuffer
    {
        name = bufferName
    };

    CullingResults cullingResults;
    static ShaderTagId unlitshaderTagId = new ShaderTagId("SRPDefaultUnlit");   //tag pass
    static ShaderTagId litShaderTagId = new ShaderTagId("CustomLit");
    Lighting lighting = new Lighting();


    public void Render(ScriptableRenderContext context, Camera camera,
        bool useDynamicBatching, bool useGPUInstancing)
    {
        this.context = context;
        this.camera = camera;

        PrepareBuffer();  // for multiple camera's command buffer preparing
        //for ui elements in the scene view even before any culling
        PrepareForSceneWindow();

        if (!Cull()) return;  // if culling parameters are not retrieved, return 

        Setup();
        lighting.Setup(context, cullingResults);   //setup light before thedrawing objects

        DrawVisibleGeometry(useDynamicBatching, useGPUInstancing);
        DrawUnsupportedShaders();
        DrawGizmos();
        Submit();
    }

    void Setup()
    {
        context.SetupCameraProperties(camera);  //set up the camera for this rendering
        var flags = camera.clearFlags;
        buffer.ClearRenderTarget(
            flags<=CameraClearFlags.Depth, //only clear depth, previous results will be preserved as background
            flags == CameraClearFlags.Color,
            flags == CameraClearFlags.Color? camera.backgroundColor.linear: Color.clear);  //clear both depth and color
        buffer.BeginSample(SampleName);
        ExecuteBuffer();
    }
    void DrawVisibleGeometry(bool useDynamicBatching = false, bool useGPUInstancing = false)
    {

        var sortSettings = new SortingSettings(camera)
        {
            criteria = SortingCriteria.CommonOpaque   //set the rendering sorting order
        };  //orthographic or distance
        var drawingSettings = new DrawingSettings(unlitshaderTagId, sortSettings)
        {
            enableDynamicBatching = useDynamicBatching,
            enableInstancing = useGPUInstancing
        };

        drawingSettings.SetShaderPassName(1, litShaderTagId);

        var filteringSettings = new FilteringSettings(RenderQueueRange.opaque);

        context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSettings);
        context.DrawSkybox(camera);  //draw skybox first

        //render transparent objects after skybox
        sortSettings.criteria = SortingCriteria.CommonTransparent;
        drawingSettings.sortingSettings = sortSettings;
        filteringSettings.renderQueueRange = RenderQueueRange.transparent;
        context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSettings);
        context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSettings);

    }

    void Submit()
    {
        buffer.EndSample(SampleName);
        ExecuteBuffer();
        context.Submit();
    }

    void ExecuteBuffer()
    {
        context.ExecuteCommandBuffer(buffer);
        buffer.Clear();
    }

   bool Cull()
    {
        if(camera.TryGetCullingParameters(out ScriptableCullingParameters p))
        {
            cullingResults = context.Cull(ref p);
            return true;
        }
        return false;
    }

   
}

/*
 //a custom script used to take care of rendering of each camera
    ScriptableRenderContext context;
    CullingResults cullingResults;
    Camera camera;

    //indicate which kind of shader passes are allowed
    static ShaderTagId unlitshaderTagId = new ShaderTagId("SRPDefaultUnlit");   //tag pass
    
    const string bufferName = "Render Camera";
    CommandBuffer buffer = new CommandBuffer
    {
        name = bufferName   //name for the command buffer (could be found in the profile)
    };

    public void Render(ScriptableRenderContext context, Camera camera)
    {
        this.context = context;
        this.camera = camera;

        PrepareBuffer();    // each camera gets its own scope
        PrepareForSceneWindow();  // do this before the culling
        if(!Cull())  //if false no need to render
        {
            return;
        }

        SetUp();
        DrawVisibleGeometry();
        DrawUnsupportedShaders();
        DrawGizmos();  //draw this lastly
        Submit();

    }

    // draw all the visible stuff starting from the skybox
    void DrawVisibleGeometry () {
		var sortingSettings = new SortingSettings(camera) {
			criteria = SortingCriteria.CommonOpaque
		};
		var drawingSettings = new DrawingSettings(
			unlitshaderTagId, sortingSettings
		);
		var filteringSettings = new FilteringSettings(RenderQueueRange.opaque);

		context.DrawRenderers(
			cullingResults, ref drawingSettings, ref filteringSettings
		);

		context.DrawSkybox(camera);

		sortingSettings.criteria = SortingCriteria.CommonTransparent;
		drawingSettings.sortingSettings = sortingSettings;
		filteringSettings.renderQueueRange = RenderQueueRange.transparent;

		context.DrawRenderers(
			cullingResults, ref drawingSettings, ref filteringSettings
		);
	}

    void Submit()
    {
        buffer.EndSample(SampleName);   //this buffer is used to inject profile samplers and clear render target
        ExecuteBuffer();
        context.Submit();  //submit the command buffer to render things 
    }
    
    //setup the camera's properties like view-projection matrix
    void SetUp()
    {
        context.SetupCameraProperties(camera);  //setup this before clear render target
        CameraClearFlags flags = camera.clearFlags;
        //if clear flags is Color may need to specify the linear color sapce 
        buffer.ClearRenderTarget(flags <= CameraClearFlags.Depth, flags == CameraClearFlags.Color, flags == CameraClearFlags.Color?
            camera.backgroundColor.linear: Color.clear);  //whether to clear depth and color (background clear color) 
        buffer.BeginSample(SampleName);   // We can use command buffers to inject profiler samples,
        // which will show up both in the profiler and the frame debugger.
        ExecuteBuffer();   //make sure it could be seen by the profile in the sample
        
    }

    void ExecuteBuffer()
    {
        context.ExecuteCommandBuffer(buffer);
        buffer.Clear();  //clear the buffer after executing it
    }

    bool Cull()
    {
        // instead filling by themselves, we could try this method
        if (camera.TryGetCullingParameters(out ScriptableCullingParameters p))
        {
            cullingResults = context.Cull(ref p);   //ref is an optimization here (prevent memory allocation)
            return true;
        }
        return false;
    }

*/ 