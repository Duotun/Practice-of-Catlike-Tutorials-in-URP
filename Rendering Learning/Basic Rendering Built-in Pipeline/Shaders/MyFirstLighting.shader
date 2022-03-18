
Shader "Custom/MyFirstLighting"
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

			float _Metallic;
			float _Smoothness;
			//float4 _SpecularTint;
			float4 _Tint;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			//#include "UnityCG.cginc"
			//#include "UnityStandardBRDF.cginc"   
			//#include "UnityStandardUtils.cginc"
			#include "UnityPBSLighting.cginc"
			// "UnityStandardBRDF" already includes UnityCG.cginc
			
			struct VertexData{
				float4 position: POSITION;
				float3 normal: NORMAL;
				float2 uv: TEXCOORD0;

			};

			struct Interpolators{
				float4 position: SV_POSITION;
				float3 normal: TEXCOORD1;
				float3 localposition: TEXCOORD2; //SEMANTICS ARE THE SAME is fine
				float2 uv: TEXCOORD0; 
				float3 worldPos: TEXCOORD3;   //used for specular lighting

			};

			//Pass-in object space vertex
			Interpolators MyVertexProgram (VertexData v
			)  {
				Interpolators i;
				i.uv = TRANSFORM_TEX(v.uv, _MainTex);
				i.localposition = v.position.xyz;
				i.position = UnityObjectToClipPos(v.position);
				//i.normal = v.normal;  //object space
				//i.normal = normalize(mul(transpose(unity_ObjectToWorld), float4(v.normal, 0)));  //normal in world space
				i.normal = UnityObjectToWorldNormal(v.normal);
				i.worldPos = mul(unity_ObjectToWorld, v.position);
				return i;
			}


			float4 MyFragmentProgram (Interpolators i ): SV_TARGET{    // SV_TARGET Stands for the frame buffer
				
				i.normal = normalize(i.normal);  //reduce the interpolation error for the wolrd normal

				//obtain the light information
				float3 lightDir = _WorldSpaceLightPos0.xyz;
				float3 lightColor = _LightColor0.rgb;

				//calculate the direction for the specular Lighting
				float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
				//float3 reflectionDir = reflect(-lightDir, i.normal);   // pay attention to the negating
				float3 halfVector = normalize(lightDir + viewDir);   //blinn-phong

				//declare lights for pbr lighting
				UnityLight light;
				light.color = lightColor;
				light.dir = lightDir;
				light.ndotl = DotClamped(i.normal, lightDir);  //diffuse term
				UnityIndirect indirectLight;
				indirectLight.diffuse = 0;
				indirectLight.specular = 0;

				//add the albedo maintex
				float3 albedo = tex2D(_MainTex, i.uv).rgb * _Tint.rgb;  

				//energy consideration
				float3 specularTint;
				float oneMinusReflectivity;  //the multiplier for energy monochrone
				albedo = DiffuseAndSpecularFromMetallic(
					albedo, _Metallic, specularTint, oneMinusReflectivity
				);   //obtain specularTint from albedo and _Metallic
				//albedo =  EnergyConservationBetweenDiffuseAndSpecular(albedo, _SpecularTint.rgb, oneMinusReflectivity);
				//albedo *= 1- max(_SpecularTint.r, max(_SpecularTint.g, _SpecularTint.b));    //need to consider the energy conservation and monochrome (diffuse + specular)
				
				float3 diffuse = albedo * lightColor * DotClamped(lightDir, i.normal);
				float3 specular = specularTint * lightColor * pow(DotClamped(halfVector, i.normal),
						_Smoothness * 10);

				return UNITY_BRDF_PBS(
				 albedo, specularTint,
				 oneMinusReflectivity, _Smoothness,
				 i.normal, viewDir,
				 light, indirectLight
				);
				//return float4(specular + diffuse, 1);
				//return pow(DotClamped(halfVector, i.normal), _Smoothness * 10);   //specular light only
				//return float4(diffuse, 1);
				//return DotClamped(lightDir, i.normal);
				//return saturate(dot(float3(0, 1, 0), i.normal));   //simulate diffuse shading
				//return float4(i.normal * 0.5 + 0.5, 1.0);
				//return tex2D(_MainTex, i.uv) *_Tint;
			}

			ENDCG
		}
	}
}
