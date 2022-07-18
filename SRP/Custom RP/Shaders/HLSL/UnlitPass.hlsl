#ifndef CUSTOM_UNLIT_PASS_INCLUDED
#define CUSTOM_UNLIT_PASS_INCLUDED 
//avoid duplicate contents

//incllude hlsl from Unity defines
#include "../ShaderLibrary/Common.hlsl"

//sampler textures
TEXTURE2D(_BaseMap);
SAMPLER(sampler_BaseMap);

//inside the UnityPerMaterial Buffer
UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
	UNITY_DEFINE_INSTANCED_PROP(float4, _BaseMap_ST)  //OFFSET AND SCALING
	UNITY_DEFINE_INSTANCED_PROP(float4, _BaseColor)  //define the per instance property
	UNITY_DEFINE_INSTANCED_PROP(float, _Cutoff)
UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

struct Attributes{
	float3 positionOS: POSITION;
	float2 baseUV: TEXCOORD0;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings{
	float4 positionCS: SV_POSITION;
	float2 baseUV: TEXCOORD0;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

Varyings UnlitPassVertex(Attributes input)
{	
	Varyings output;
	float4 baseST = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseMap_ST);
	output.baseUV = input.baseUV * baseST.xy + baseST.zw;
	UNITY_SETUP_INSTANCE_ID(input);  //extacts the index from the input
	UNITY_TRANSFER_INSTANCE_ID(input, output);  //transfor instance to the fragment
	float3 positionWS = TransformObjectToWorld(input.positionOS);
	output.positionCS = TransformWorldToHClip(positionWS);
	return output;
}

float4 UnlitPassFragment(Varyings input): SV_TARGET   //semantics indicate for output target
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
	return base;
}

#endif