Shader "Custom/Customlit"
{
    Properties
    {
        [MainTexture]_BaseMap ("Texture", 2D) = "white" {}
        _BaseColor("Color", Color) = (1.0, 1.0, 1.0, 1.0)
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend", Float) = 1.0
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend", Float) = 0.0
        [Enum(Off, 0, On, 1)] _ZWrite("Z Write", Float) = 1.0
        [Toggle(_CLIPPING)] _Cutoff("Alpha Cutoff", Float) = 0.1
        _Metallic ("Metallic", Range(0, 1)) = 0
        _Smoothness ("Smoothness", Range(0, 1)) = 0.5 
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        
        Pass
        {
            Tags {
                "LightMode" = "CustomLit"
            }

            Blend [_SrcBlend][_DstBlend]
            ZWrite [_ZWrite]
            HLSLPROGRAM
            #pragma target 3.5 

            #pragma multi_compile_instancing
            #pragma shader_feature _CLIPPING
            #pragma vertex LitPassVertex
            #pragma fragment LitPassFragment

            //insert the entire contents of the file of the include directive
            #include "LightPass.hlsl" 
            
            ENDHLSL
        }
    }
}
