#ifndef CUSTOM_LIGHT_INCLUDED
#define CUSTOM_LIGHT_INCLUDED


// 4 directional lights support 
#define MAX_DIRECTIONAL_LIGHT_COUNT 4

// CBuffer, for lighting color associated with materials 
CBUFFER_START(_CustomLight)
	int _DirectionalLightCount;
	float4 _DirectionalLightColors[MAX_DIRECTIONAL_LIGHT_COUNT];
	float4 _DirectionalLightDirections[MAX_DIRECTIONAL_LIGHT_COUNT];
CBUFFER_END

struct Light{
	float3 lcolor;
	float3 direction;
};

int GetDirectionalLightCount()
{
	return _DirectionalLightCount;
}


Light GetDirectionalLight(int index)
{
	Light light;
	light.lcolor = _DirectionalLightColors[index].rgb;
	light.direction = _DirectionalLightDirections[index].xyz;
	return light;
}


#endif 