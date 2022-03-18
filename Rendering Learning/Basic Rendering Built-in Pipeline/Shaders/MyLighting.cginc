
#define MY_LIGHTING_INCLUDED   
//use define to avoid code duplication
// define the global parameters
float _Metallic;
float _Smoothness;
float4 _Tint;
sampler2D _MainTex;
float4 _MainTex_ST;

//used for the light attenuation
#include "AutoLight.cginc"    
#include "UnityPBSLighting.cginc"
			
struct VertexData
{
    float4 position : POSITION;
    float3 normal : NORMAL;
    float2 uv : TEXCOORD0;

};

struct Interpolators
{
    float4 position : SV_POSITION;
    float3 normal : TEXCOORD1;
    float3 localposition : TEXCOORD2; //SEMANTICS ARE THE SAME is fine
    float2 uv : TEXCOORD0;
    float3 worldPos : TEXCOORD3; //used for specular lighting

};

//Pass-in object space vertex
Interpolators MyVertexProgram(VertexData v)
{
    Interpolators i;
    i.uv = TRANSFORM_TEX(v.uv, _MainTex);
    i.localposition = v.position.xyz;
    i.position = UnityObjectToClipPos(v.position);
    i.normal = UnityObjectToWorldNormal(v.normal);
    i.worldPos = mul(unity_ObjectToWorld, v.position);
    return i;
}


UnityLight CreateLight (Interpolators i)
{
    UnityLight light;
    float3 lightvec = _WorldSpaceLightPos0.xyz - i.worldPos;
    #if defined(POINT) || defined(SPOT)
    light.dir = normalize(lightvec);   //obtin light information and calculate the light direction
    #else 
    light.dir = _WorldSpaceLightPos0.xyz;   // otherwise, dir comes from the directional light 
    #endif

    //float attenuation = 1.0 / (1.0 + dot(lightvec, lightvec));   //+1 to avoid wierd brightness when close to the surface
    UNITY_LIGHT_ATTENUATION(attenuation, 0, i.worldPos);
    light.color = _LightColor0.rgb * attenuation;
    light.ndotl = DotClamped(i.normal, light.dir);  //diffuse term
    return light;
}

float4 MyFragmentProgram(Interpolators i) : SV_TARGET
{ // SV_TARGET Stands for the frame buffer
				
    i.normal = normalize(i.normal); //reduce the interpolation error for the wolrd normal

				//calculate the direction for the specular Lighting
    float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
	//float3 reflectionDir = reflect(-lightDir, i.normal);   // pay attention to the negating
    //float3 halfVector = normalize(lightDir + viewDir); //blinn-phong, NO USE

	//declare lights for pbr lighting, I put this to the CreateLight Function
    //UnityLight light;
    //light.color = lightColor;
    //light.dir = lightDir;
    //light.ndotl = DotClamped(i.normal, lightDir); //diffuse term

    UnityIndirect indirectLight;
    indirectLight.diffuse = 0;
    indirectLight.specular = 0;

				//add the albedo maintex
    float3 albedo = tex2D(_MainTex, i.uv).rgb * _Tint.rgb;

	//energy consideration
    float3 specularTint;
    float oneMinusReflectivity; //the multiplier for energy monochrone
    albedo = DiffuseAndSpecularFromMetallic(
					albedo, _Metallic, specularTint, oneMinusReflectivity
				); 
    // energy consevation, monochrome manual way, no use
    //float3 diffuse = albedo * lightColor * DotClamped(lightDir, i.normal);
    //float3 specular = specularTint * lightColor * pow(DotClamped(halfVector, i.normal), _Smoothness * 10);

    return UNITY_BRDF_PBS(
				 albedo, specularTint,
				 oneMinusReflectivity, _Smoothness,
				 i.normal, viewDir,
				 CreateLight(i), indirectLight
				);
				
}