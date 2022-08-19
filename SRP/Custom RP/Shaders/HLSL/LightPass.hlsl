#ifndef CUSTOM_LIT_PASS_INCLUDED
#define CUSTOM_LIT_PASS_INCLUDED 
//avoid duplicate contents

//include hlsl from Unity defines, pay attention to the include sequence -> 
#include "../ShaderLibrary/Common.hlsl"
#include "../ShaderLibrary/Surface.hlsl"
#include "../ShaderLibrary/Light.hlsl" 
#include "../ShaderLibrary/BRDF.hlsl" 
#include "../ShaderLibrary/Lighting.hlsl" 

//sampler textures
TEXTURE2D(_BaseMap);
SAMPLER(sampler_BaseMap);

//inside the UnityPerMaterial Buffer -> GPU Instance
UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
	UNITY_DEFINE_INSTANCED_PROP(float4, _BaseMap_ST)  //OFFSET AND SCALING
	UNITY_DEFINE_INSTANCED_PROP(float4, _BaseColor)  //define the per instance property
	UNITY_DEFINE_INSTANCED_PROP(float, _Cutoff)
	UNITY_DEFINE_INSTANCED_PROP(float, _Metallic)
	UNITY_DEFINE_INSTANCED_PROP(float, _Smoothness)
UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

struct Attributes{
	float3 positionOS: POSITION;
	float3 normalOS: NORMAL;
	float2 baseUV: TEXCOORD0;
	UNITY_VERTEX_INPUT_INSTANCE_ID   //for GPU Instance
};

struct Varyings{
	float4 positionCS: SV_POSITION;
	float3 positionWS: VAR_POSITION;
	float3 normalWS: VAR_NORMAL;
	float2 baseUV: VAR_BASE_UV;   // Just attach some meanings to this uv, not necessary to use TEXCOORD0
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

Varyings LitPassVertex(Attributes input)
{	
	Varyings output;
	float4 baseST = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseMap_ST);
	output.baseUV = input.baseUV * baseST.xy + baseST.zw;
	UNITY_SETUP_INSTANCE_ID(input);  //extacts the index from the input
	UNITY_TRANSFER_INSTANCE_ID(input, output);  //transfor instance to the fragment
	output.positionWS = TransformObjectToWorld(input.positionOS);
	output.positionCS = TransformWorldToHClip(output.positionWS);
	output.normalWS = TransformObjectToWorldNormal(input.normalOS);

	return output;
}

float4 LitPassFragment(Varyings input): SV_TARGET   //semantics indicate for output target
{
	UNITY_SETUP_INSTANCE_ID(input);
	//access the variable through instance buffer
	float4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.baseUV);
	float4 baseColor = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseColor); 
	float4 base = baseMap * baseColor;
	float cutoffval = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Cutoff);
	//cutoffval = 0.3f;
	#if defined(_CLIPPING)
		clip(base.a - cutoffval);
	#endif	

	Surface surface;
	surface.normal = normalize(input.normalWS);
	surface.viewDirection = normalize(_WorldSpaceCameraPos - input.positionWS);
	surface.scolor = base.rgb;
	surface.alpha = base.a;
	surface.metallic = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Metallic);
	surface.smoothness =  UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Smoothness);

	BRDF brdf = GetBRDF(surface);
	float3 fcolor = GetLighting(surface, brdf);
	return float4(fcolor, surface.alpha);
}

#endif