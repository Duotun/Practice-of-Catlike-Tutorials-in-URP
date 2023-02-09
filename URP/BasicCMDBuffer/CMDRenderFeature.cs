using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class CMDRenderFeature: ScriptableRendererFeature
{

    //For the external configurations
    [System.Serializable]
    public class Settings
    {
        public RenderPassEvent passEvent;
        public Mesh mesh;
        public Material material;

        public Settings(Settings in_Settings)
        {
            passEvent = in_Settings.passEvent;
            mesh = in_Settings.mesh;
            material = in_Settings.material;
        }
    }

    public Settings g_settings;
    SimpleDrawRenderPass m_ScriptablePass;
    class SimpleDrawRenderPass : ScriptableRenderPass
    {
        public Settings m_settings;
        // This method is called before executing the render pass.
        // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
        // When empty this render pass will render to the active camera render target.
        // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
        // The render pipeline will ensure target setup and clearing happens in a performant manner.
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {

        }

        // Here you can implement the rendering logic.
        // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
        // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
        // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (renderingData.cameraData.isPreviewCamera) return;
            if (m_settings.mesh == null || m_settings.material == null) return;

            var cmd = CommandBufferPool.Get("CommandBufferTutorial");  //Obtain the free cmd related to the rendering pass
            cmd.DrawMesh(m_settings.mesh, Matrix4x4.identity, m_settings.material); 
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);  //release the cmd
        }

        // Cleanup any allocated resources that were created during the execution of this render pass.
        public override void OnCameraCleanup(CommandBuffer cmd)
        {

        }

        public SimpleDrawRenderPass()
        {

        }
    }


    /// <inheritdoc/>
    public override void Create()    //create passes during the creation of render feature
    {
        m_ScriptablePass = new SimpleDrawRenderPass();
        m_ScriptablePass.m_settings = g_settings;
        // Configures where the render pass should be injected. (put into the settings for the external configuration)
        //m_ScriptablePass.renderPassEvent = RenderPassEvent.AfterRenderingOpaques;
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        
        renderer.EnqueuePass(m_ScriptablePass);
    }
}


