Shader "Custom/Reflection"
{
   //properties are the same level of Subshader
   Properties {
			_Tint("Tint", Color) = (1, 1, 1, 1)
			[NoScaleOffset] _NormalMap("Normals", 2D) = "bump"{}
			_BumpScale("Bump Scale", Float) = 1
			[Gamma]_MainTex("Albedo", 2D) = "white" {}   //add a Gamma tag for auto gamma correction
			_Metallic("Metallic", Range(0, 1)) = 0
			_Smoothness ("Smoothness", Range(0, 1)) = 0.5
			_DetailTex ("Detail Texture", 2D) = "gray"{}
			[NoScaleOffset] _DetailNormalMap("Detail Normals", 2D) = "bump"{}
			_DetailBumpScale("Detail Bump Scale", Float) = 1
	    }		

	//define CG Program including for all subshader and passes
	CGINCLUDE
	 //#define BINORMAL_PER_FRAGMENT
	ENDCG

	SubShader{  
		Pass {

			Tags{
			   "LightMode" = "ForwardBase"     //used for obtain the main light in the scene
			}

			// target 4.5 is used for indicating the unity pbs
		    CGPROGRAM
			#pragma target 4.5   
			//for shadow of the main light
			#pragma multi_compile _ SHADOWS_SCREEN  
			//only cares about the base light using the vertex light
			#pragma multi_compile _ VERTEXLIGHT_ON 
			#define FORWARD_BASE_PASS
			#pragma vertex MyVertexProgram
		    #pragma fragment MyFragmentProgram
			#if !defined(MY_LIGHTING_INCLUDED)
			#include "MyOwnLighting.cginc"
			#endif
			ENDCG
		}

		Pass {
			Tags {
				"LightMode" = "ForwardAdd"
			}

			Blend One One   //for adding another light color influence
			ZWrite Off  // writing depth the second time for the opaque objects are meaningless, so we disable it in this pass
			CGPROGRAM
  
			//equal to the below's multi_compile, add multiple shdows support
			#pragma multi_compile_fwdadd_fullshadows   
			//#pragma multi_compile DIRECTIONAL DIRECTIONAL_COOKIE POINT POINT_COOKIE SPOT
			#pragma target 4.5
			#pragma vertex MyVertexProgram
			#pragma fragment MyFragmentProgram

			//indicate point light in this pass
			//#define POINT   
			#if !defined(MY_LIGHTING_INCLUDED)
			#include "MyOwnLighting.cginc"
			#endif

			ENDCG
		}

		Pass
		{
			Tags{
			"LightMode" = "ShadowCaster"
			}

			CGPROGRAM
			#pragma target 3.0

			//add the multi-support for point light shadow
			#pragma multi_compile_shadowcaster
			
			#pragma vertex  MyShadowVertexProgram
			#pragma fragment MyShadowFragmentProgram
			#include "MyShadows.cginc"

			ENDCG

		}
	}

}
