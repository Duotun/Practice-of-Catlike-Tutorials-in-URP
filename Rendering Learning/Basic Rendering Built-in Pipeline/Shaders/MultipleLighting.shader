Shader "Custom/MultipleLighting"
{
   //properties are the same level of Subshader
   Properties {
			_Tint("Tint", Color) = (1, 1, 1, 1)
			//_SpecularTint("Specular", Color) = (0.5, 0.5, 0.5)    //non-use, PBR from Unity inner functions is used now
			[Gamma]_MainTex("Albedo", 2D) = "white" {}   //add a Gamma tag for auto gamma correction
			_Metallic("Metallic", Range(0, 1)) = 0
			_Smoothness ("Smoothness", Range(0, 1)) = 0.5
	    }		

	SubShader{  
		Pass {

			Tags{
			   "LightMode" = "ForwardBase"     //used for obtain the main light in the scene
			}

			// target 4.5 is used for indicating the unity pbs
		    CGPROGRAM
			#pragma target 4.5    
			#pragma vertex MyVertexProgram
			#pragma fragment MyFragmentProgram
			#if !defined(MY_LIGHTING_INCLUDED)
			#include "MyLighting.cginc"
			#endif
			ENDCG
		}

		Pass {
			Tags {
				"LightMode" = "ForwardAdd"
			}

			Blend One One
			ZWrite Off  // writing depth the second time for the opaque objects are meaningless, so we disable it in this pass
			CGPROGRAM

			#pragma multi_compile DIRECTIONAL POINT SPOT
			#pragma target 3.0
			#pragma vertex MyVertexProgram
			#pragma fragment MyFragmentProgram

			//indicate point light in this pass
			//#define POINT   
			#include "MyLighting.cginc"

			ENDCG
		}
	}
}
