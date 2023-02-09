using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class CMDBufferTutorial : MonoBehaviour
{
    public Material mat;
    public Mesh CubeMesh;
    public Mesh CustomMesh;

    private void OnEnable()
    {
        //if (mat != null)
        //    RenderPipelineManager.endCameraRendering += m_PostProcessRender_Cube;
    }

    private void OnDisable()
    {
        //RenderPipelineManager.endCameraRendering -= m_PostProcessRender_Cube;
    }

    private void m_PostProcessRender_Tri(ScriptableRenderContext context, Camera cam)
    {
        mat.SetPass(0);
        //Change with Matrix (Stack way)
        GL.PushMatrix();
        //GL.LoadIdentity();
        GL.MultMatrix(transform.localToWorldMatrix);
        GL.Begin(GL.TRIANGLE_STRIP);    // GL.LINES / GL.TRIANGLES  /GL.TRIANGLE_STRIP (Edge neighbors)
        GL.Vertex3(-1, 0, 0);
        GL.Vertex3(1, 0, 0);
        GL.Vertex3(0, 2, 0);
        GL.End();
        GL.PopMatrix();
    }

    private void m_PostProcessRender_Cube(ScriptableRenderContext context, Camera cam)
    {
        mat.SetPass(0);
        //Change with Matrix (Stack way)
        GL.PushMatrix();
        //GL.LoadIdentity();
        GL.MultMatrix(transform.localToWorldMatrix);
        GL.Begin(GL.TRIANGLE_STRIP);    // GL.LINES / GL.TRIANGLES  /GL.TRIANGLE_STRIP (Edge neighbors)
        foreach(var v in CubeMesh.vertices)
        {
            GL.Vertex(v);
        }
        GL.End();
        GL.Begin(GL.TRIANGLE_STRIP);
        foreach (var v in CubeMesh.vertices)
        {
            GL.Vertex(v + new Vector3(2.0f, 0.0f, 0.0f));
        }
        GL.End();
        GL.PopMatrix();
     }

    Matrix4x4[] poses;
    public int instanceCount = 100;
    //For Random Draw Meshes
    public void PrepareSpheres()
    {
        poses = new Matrix4x4[instanceCount];
        for (int i=0; i<instanceCount; i++)
        {
            var pos = Random.insideUnitSphere * 10;
            var q = Quaternion.identity;
            var scale = Vector3.one;

            poses[i] = Matrix4x4.TRS(pos, q.normalized,scale);
        }

    }

    public void DrawMultipleMeshes()
    {
        Graphics.DrawMesh(CubeMesh, Matrix4x4.identity, mat, 0);
        Graphics.DrawMeshInstanced(CustomMesh, 0, mat, poses);
    }
    // Start is called before the first frame update
    void Start()
    {
        //PrepareSpheres();
    }

    // Update is called once per frame
    void Update()
    {
        //DrawMultipleMeshes();
    }
}
