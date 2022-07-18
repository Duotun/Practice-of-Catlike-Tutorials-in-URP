using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Profiling;
using UnityEditor;

public partial class CameraRender  //this part for the editor methods in the camera renderer
{
    partial void PrepareBuffer();  //each camera obtain get its own scope in the debug profile
    partial void DrawGizmos();
    partial void DrawUnsupportedShaders();

    partial void PrepareForSceneWindow();

#if UNITY_EDITOR

    string SampleName { get; set; }
    static ShaderTagId[] legacyShaderTagIds =
    {
        new ShaderTagId("Always"),
        new ShaderTagId("ForwardBase"),
        new ShaderTagId("PrepassBase"),
        new ShaderTagId("Vertex"),
        new ShaderTagId("VertexLMRGBM"),
        new ShaderTagId("VertexLM")
    };
    static Material errorMaterial;
    partial void DrawUnsupportedShaders()
    {
        if (errorMaterial == null)
        {
            errorMaterial = new Material(Shader.Find("Hidden/InternalErrorShader"));
        }

        //similarly, we need to setup drawing settings and filter settings
        var drawingSettings = new DrawingSettings(legacyShaderTagIds[0], new SortingSettings(camera))
        {
            overrideMaterial = errorMaterial
        };
        for (int i = 1; i < legacyShaderTagIds.Length; i++)
        {
            drawingSettings.SetShaderPassName(i, legacyShaderTagIds[i]);  //use default shaders
        }
        var filterSettings = FilteringSettings.defaultValue;
        context.DrawRenderers(
            cullingResults, ref drawingSettings, ref filterSettings
            );

    }

    partial void DrawGizmos()
    {
        if(Handles.ShouldRenderGizmos())
        {
            context.DrawGizmos(camera, GizmoSubset.PreImageEffects);
            context.DrawGizmos(camera, GizmoSubset.PostImageEffects);  //invoke both before and after image effects
        }
    }

    partial void PrepareForSceneWindow()
    {
        //draw UI elements in the scene view
        if(camera.cameraType == CameraType.SceneView)
        {
            ScriptableRenderContext.EmitWorldGeometryForSceneView(camera);
        }
    }

    partial void PrepareBuffer()
    {
        Profiler.BeginSample("Editor Only");
        //prepareBuffer with Samplenames
        buffer.name = SampleName = camera.name;  //command buffer is named with camera's name
        Profiler.EndSample();
    }
#else 
    const stirng SampleName = bufferName;   //else just point to the bufferName as "Render Camera"
#endif

}


/*
 
 partial void PrepareBuffer();
    partial void PrepareForSceneWindow();   //for UI shown in Scene Editor
    partial void DrawGizmos();
    partial void DrawUnsupportedShaders();   //make the method partial as well to avoid repeating containing

    // we only care about the unsupported rendering for the editor here
#if UNITY_EDITOR
    static ShaderTagId[] legacyShaderTagIds =
    {
        new ShaderTagId("Always"),
        new ShaderTagId("ForwardBase"),
        new ShaderTagId("PrepassBase"),
        new ShaderTagId("Vertex"),
        new ShaderTagId("VertexLMRGBM"),
        new ShaderTagId("VertexLM")
    };
    static Material errorMaterial;
    partial void DrawUnsupportedShaders()
    {
        if (errorMaterial == null)
        {
            errorMaterial = new Material(Shader.Find("Hidden/InternalErrorShader"));
        }

        //similarly, we need to setup drawing settings and filter settings
        var drawingSettings = new DrawingSettings(legacyShaderTagIds[0], new SortingSettings(camera))
        {
            overrideMaterial = errorMaterial
        };
        for (int i = 1; i < legacyShaderTagIds.Length; i++)
        {
            drawingSettings.SetShaderPassName(i, legacyShaderTagIds[i]);  //use default shaders
        }
        var filterSettings = FilteringSettings.defaultValue;
        context.DrawRenderers(
            cullingResults, ref drawingSettings, ref filterSettings
            );

    }
    partial void DrawGizmos()
    {
        if (Handles.ShouldRenderGizmos())
        {
            // need camra contexts as parameters
            context.DrawGizmos(camera, GizmoSubset.PreImageEffects);   //both stages included
            context.DrawGizmos(camera, GizmoSubset.PostImageEffects);
        }
    }

    partial void PrepareForSceneWindow()
    {
        if (camera.cameraType == CameraType.SceneView)  //scene editor only
        {
            ScriptableRenderContext.EmitWorldGeometryForSceneView(camera);
        }
    }

    string SampleName { get; set; }
    partial void PrepareBuffer()
    {
        buffer.name = SampleName = camera.name;
    }
#else 
    const string SampleName => bufferName;
#endif
*/