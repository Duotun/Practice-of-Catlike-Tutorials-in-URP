#ifndef CUSTOM_UNITY_INPUT_INCLUDED
#define CUSTOM_UNITY_INPUT_INCLUDED


CBUFFER_START(UnityPerDraw)
	float4x4 unity_ObjectToWorld;   //we want these variables for later SRP Batch
	float4x4 unity_WorldToObject;   
	float4 unity_WorldTransformParams;
	float4 unity_LODFade;  // just for group values of LOD
CBUFFER_END

float4x4 unity_prev_ObjectToWorld;
float4x4 unity_prev_WorldToObject;

float4x4 unity_MatrixVP;
float4x4 unity_MatrixV;
float4x4 glstate_matrix_projection;
float3 _WorldSpaceCameraPos; // world camera pos 



#endif 