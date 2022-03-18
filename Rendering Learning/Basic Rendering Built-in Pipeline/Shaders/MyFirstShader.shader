// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/MyFirstShader"
{
	//properties are the same level of Subshader
   Properties {
				_Tint("Tint", Color) = (1, 1, 1, 1)
				_MainTex("Texture", 2D) = "white" {}

	    }
		
	SubShader{  

		Pass {
		    CGPROGRAM

			#pragma vertex MyVertexProgram
			#pragma fragment MyFragmentProgram
  
			float4 _Tint;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			#include "UnityCG.cginc"

			struct VertexData{
				float4 position: POSITION;
				float2 uv: TEXCOORD0;

			};

			struct Interpolators{
				float4 position: SV_POSITION;
				float3 localposition: TEXCOORD2; //SEMANTICS ARE THE SAME is fine
				float2 uv: TEXCOORD0; 
			};

			//Pass-in object space vertex
			Interpolators MyVertexProgram (VertexData v
			)  {
				Interpolators i;
				i.uv = TRANSFORM_TEX(v.uv, _MainTex);
				i.localposition = v.position.xyz;
				i.position = UnityObjectToClipPos(v.position);
				return i;
			}

			float4 MyFragmentProgram (Interpolators i ): SV_TARGET{    // SV_TARGET Stands for the frame buffer
				
				return tex2D(_MainTex, i.uv) *_Tint;
			}

			ENDCG
		}
	}
}
