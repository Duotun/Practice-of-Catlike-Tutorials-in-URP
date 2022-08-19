#ifndef CUSTOM_BRDF_INCLUDED
#define CUSTOM_BRDF_INCLUDED
#define MIN_REFLECTIVITY 0.04

struct BRDF{
	float3 diffuse;
	float3 specular;
	float roughness;
};


float oneMinusReflectivity(float metallic)
{
	float range = 1.0 - MIN_REFLECTIVITY;
	return range - metallic * range;
}

float Square (float v){
	return v*v;
}

float SpecularStength (Surface surface, BRDF brdf, Light light)
{
	float3 h = SafeNormalize(light.direction + surface.viewDirection);
	float nh2 = Square(saturate(dot(surface.normal, h)));
	float lh2 = Square(saturate(dot(light.direction, h)));
	float r2 = Square(brdf.roughness);
	float d2 = Square(nh2* (r2-1.0)+1.00001);
	float normalization = brdf.roughness * 4.0 + 2.0;
	return r2/(d2*max(0.1, lh2)*normalization);
}

float3 DirectBRDF(Surface surface, BRDF brdf, Light light)
{
	return SpecularStength(surface, brdf, light) * brdf.specular + brdf.diffuse;
}

BRDF GetBRDF (Surface surface)
{
	float oneMinusReflectivityval = oneMinusReflectivity(surface.metallic);
	BRDF brdf;
	brdf.diffuse = surface.scolor * oneMinusReflectivityval;
	brdf.specular = lerp(oneMinusReflectivityval, surface.scolor, surface.metallic);   //follow the energe conservation
	
	float perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(surface.smoothness);   // roughness = 1- smoothness
	brdf.roughness = PerceptualRoughnessToRoughness(perceptualRoughness);
	return brdf;
}

#endif 