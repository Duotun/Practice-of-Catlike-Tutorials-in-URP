// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

#if !defined(MY_SHADOWS_INCLUDED)

#define MY_SHADOWS_INCLUDED
#include "UnityCG.cginc"
// generate shadow map -> another pass rendering is fine with proper shadow bias

struct VertexData{
	float4 position: POSITION;
	float3 normal: NORMAL;
}; 

	#if defined(SHADOWS_CUBE)
	//for the point Light
	struct Interpolators{
		float4 position: SV_POSITION;
		float3 lightVec: TEXCOORD0;
	};

	Interpolators MyShadowVertexProgram(VertexData v)
	{
		Interpolators i;
		i.position = UnityObjectToClipPos(v.position);
		i.lightVec = mul(unity_ObjectToWorld, v.position.xyz) - _LightPositionRange.xyz;
		return i;
	}

	float4 MyShadowFragmentProgram(Interpolators i): SV_TARGET{
		//depth is from the lighting range actually
		float depth = length(i.lightVec) + unity_LightShadowBias.x;
		depth *= _LightPositionRange.w;   //make it in range[0, 1]
		return UnityEncodeCubeShadowDepth(depth);
	}

	#else 
// GPU will record depth for us for shadow mapping generation
	float4 MyShadowVertexProgram (VertexData v): SV_POSITION
	{
		//consider normal bias
		float4 position = UnityClipSpaceShadowCasterPos(v.position.xyz, v.normal);
		return UnityApplyLinearShadowBias(position);   //extrude the depth bias 
	
	}

	half4 MyShadowFragmentProgram(): SV_TARGET{
		return 0;
	}

	#endif 
#endif 