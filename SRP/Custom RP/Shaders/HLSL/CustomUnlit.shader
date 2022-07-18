Shader "Custom/CustomUnlit"
{
    Properties
    {
        [MainTexture]_BaseMap ("Texture", 2D) = "white" {}
        _BaseColor("Color", Color) = (1.0, 1.0, 1.0, 1.0)
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend", Float) = 1.0
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend", Float) = 0.0
        [Enum(Off, 0, On, 1)] _ZWrite("Z Write", Float) = 1.0
        [Toggle(_CLIPPING)] _Cutoff("Alpha Cutoff", Float) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        
        Pass
        {
            Blend [_SrcBlend][_DstBlend]
            ZWrite [_ZWrite]
            HLSLPROGRAM
            
            #pragma multi_compile_instancing
            #pragma shader_feature _CLIPPING
            #pragma vertex UnlitPassVertex
            #pragma fragment UnlitPassFragment

            //insert the entire contents of the file of the include directive
            #include "UnlitPass.hlsl" 
            
            ENDHLSL
        }
    }
}
