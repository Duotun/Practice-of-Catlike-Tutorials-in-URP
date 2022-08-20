
#if !defined(MY_LIGHTING_INCLUDED)
#define MY_LIGHTING_INCLUDED
//use define to avoid code duplication
// define the global parameters
float _Metallic;
float _Smoothness;
float4 _Tint;

sampler2D _MainTex, _DetailTex;
float4 _MainTex_ST, _DetailTex_ST;

sampler2D _NormalMap, _DetailNormalMap;
float _BumpScale, _DetailBumpScale; 

//used for the light attenuation
#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"    
			
struct VertexData
{
    float4 vertex : POSITION;   //name as vertex for using built-in Unity method
    float3 normal : NORMAL;
    float2 uv : TEXCOORD0;
    float4 tangent: TANGENT; 

};

struct Interpolators
{
    float4 pos : SV_POSITION;  //for using built-in methods
    float3 normal : TEXCOORD1;
    #if defined(BINORMAL_PER_FRAGMENT)
        float4 tangent : TEXCOORD2; 
    #else
        float3 tangent: TEXCOORD2;
        float3 binormal: TEXCOORD3;
    #endif 

    float4 uv : TEXCOORD0;   //packed diffuse and detail texture uv together
    float3 worldPos : TEXCOORD4; //used for specular lighting
    
    //#if defined(SHADOWS_SCREEN)
    //    float4 shadowCoordinates: TEXCOORD5;  // for screen-space texture coordinates
    //#endif 
    //same things as above 
    SHADOW_COORDS(5)

    #if defined(VERTEXLIGHT_ON)
    float3 vertexLightColor: TEXCOORD6;
    #endif

};

void ComputeVertexLightColor(inout Interpolators i)
{
    #if defined(VERTEXLIGHT_ON)
        /*float3 lightPos = float3(
            unity_4LightPosX0.x, unity_4LightPosY0.x, unity_4LightPosZ0.x
        );
        float3 lightVec = lightPos - i.worldPos;
        float3 lightDir = normalize(lightVec);
        float ndotl = DotClamped(i.normal, lightDir);
        float attenuation = 1 / (1+dot(lightVec, lightVec) * unity_4LightAtten0.x);
        i.vertexLightColor = unity_LightColor[0].rgb * ndotl * attenuation;
        */
        //change to support up to 4 vertex lights in the forward base
        i.vertexLightColor = Shade4PointLights(
            unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
            unity_LightColor[0].rgb, unity_LightColor[1].rgb,
            unity_LightColor[2].rgb, unity_LightColor[2].rgb,
            unity_4LightAtten0, i.worldPos, i.normal);
    #endif
}

float3 CreateBinormal(float3 normal, float3 tangent, float binormalSign)
{
    return cross(normal, tangent.xyz) * (binormalSign * unity_WorldTransformParams.w);

}

Interpolators MyVertexProgram(VertexData v)
{
    Interpolators i;
    i.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
    i.uv.zw = TRANSFORM_TEX(v.uv, _DetailTex);
    i.pos = UnityObjectToClipPos(v.vertex);
    i.normal = UnityObjectToWorldNormal(v.normal);
    #if defined(BINORMAL_PER_FRAGMENT)
        i.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);   //to world space tangent
    #else
        i.tangent = UnityObjectToWorldDir(v.tangent.xyz);
        i.binormal = CreateBinormal(i.normal, i.tangent, v.tangent.w);
    #endif 

    //#if defined(SHADOWS_SCREEN)  
        //d3d11 ->y downwards
        //i.shadowCoordinates.xy = (float2(i.pos.x, -i.pos.y)+i.pos.w)*0.5;  //to scren-space coordinates
        //i.shadowCoordinates.zw = i.pos.zw;
        //or just utilize unity built in function
    // i.shadowCoordinates = ComputeScreenPos(i.pos);  
    //#endif 
    //use Unity built-in macros perform the same things for shadow coordinates
    TRANSFER_SHADOW(i);
    i.worldPos = mul(unity_ObjectToWorld, v.vertex);
    ComputeVertexLightColor(i);   //compute vertex light in the vertex stage
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
    //#if defined(SHADOWS_SCREEN)  
    //for shadow generation with lighting
    //perform the division after interpolation
        //float attenuation = tex2D(_ShadowMapTexture, i.shadowCoordinates.xy/i.position.w);  //sample the shadows
        //float attenuation = SHADOW_ATTENUATION(i);  
    //#else
        //UNITY_LIGHT_ATTENUATION(attenuation, 0, i.worldPos); //or put the i in the below
    //#endif 
    UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldPos);  //include the SHDOW_ATTENUATION COMPUTING as well

    light.color = _LightColor0.rgb * attenuation;
    light.ndotl = DotClamped(i.normal, light.dir);  //diffuse term, lambert
    return light;
}

float3 BoxProjection (float3 direction, float3 position,
float4 cubemapPosition, float3 boxMin, float3 boxMax
){
    
    //w component controlls the box projection used or not actually
    // sepcify the branch explicityly rather than only conditional case in the compiled code
 #if UNITY_SPECCUBE_BOX_PROJECTION
    UNITY_BRANCH
    if (cubemapPosition.w > 0) {
        // adjust the bounds relative to the surface position 
        boxMin -= position;
        boxMax -= position;
        float3 factors = (direction >0 ? boxMax : boxMin) / direction;
        float scalar = min(min(factors.x, factors.y), factors.z);  //find the nearest interection point on the reflection box size
        // then find the projected reflection vector for the cube map
        return direction * scalar + position - cubemapPosition;
    }
  #endif

    return direction;   //no box projection used
}

UnityIndirect CreateIndirectLight(Interpolators i, float3 viewDir)
{
    //self-define the indirect light
    UnityIndirect indirectLight;
    indirectLight.diffuse = 0;   //for environmental reflection as metal and smoothness
    indirectLight.specular = 0;

    #if defined(VERTEXLIGHT_ON)   
        //add vertex light to the indirect light diffuse term
        indirectLight.diffuse = i.vertexLightColor;
        
    #endif 

    //add spherical harmonics
    #if defined(FORWARD_BASE_PASS)
        indirectLight.diffuse += max(0.0, ShadeSH9(float4(i.normal, 1.0)));
        float3 reflectionDir = reflect(-viewDir, i.normal);
        float roughness = 1 - _Smoothness;
        roughness *= 1.7 - 0.7*roughness;
        // sample color -> 4
        //float4 envSample = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflectionDir, roughness * UNITY_SPECCUBE_LOD_STEPS
        //);  //sample the reflection / skybox with glossy considered
        //indirectLight.specular = DecodeHDR(envSample, unity_SpecCube0_HDR);

        //or use Unity_GlossyEnvironment to take care of the roughness and skybox
        Unity_GlossyEnvironmentData envData;
        envData.roughness = 1 - _Smoothness;
        
        envData.reflUVW =  BoxProjection(reflectionDir, i.worldPos,
        unity_SpecCube0_ProbePosition, unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax);    //consider the box projection
        //sample the reflection with the built-in method "Unity_GlossyEnvironment"
        //perform the probes blending
        float3 probe0 = Unity_GlossyEnvironment(UNITY_PASS_TEXCUBE(unity_SpecCube0), unity_SpecCube0_HDR, envData);
        
        //add a unity_branch as well to determine the blending to work
        float interpolator = unity_SpecCube0_BoxMin.w;
        // use this macro by considering multiple target platform capabailities
        #if UNITY_SPECCUBE_BLENDING 
            UNITY_BRANCH
            if(interpolator < 0.999999)
            {
        
            envData.reflUVW = BoxProjection(
               reflectionDir, i.worldPos,
               unity_SpecCube1_ProbePosition, unity_SpecCube1_BoxMin, unity_SpecCube1_BoxMax);
                //sampler with the unity_SpecCube0
                float3 probe1 = Unity_GlossyEnvironment(UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1, unity_SpecCube0), unity_SpecCube1_HDR, envData);
                //from 1 to 0 
                indirectLight.specular = lerp(probe1, probe0, interpolator);  //interpolated factors coming from .w
            }
            else 
            {
                indirectLight.specular = probe0;
            }
        #else
            indirectLight.specular = probe0;
        #endif 

    #endif 
    return indirectLight;
}

// unpacknormal -> DXT5nm
void InitializeFragmentNormal(inout Interpolators i)
{
    float3 mainNormal = UnpackScaleNormal(tex2D(_NormalMap, i.uv.xy), _BumpScale);
    float3 detailNormal = UnpackScaleNormal(tex2D(_DetailNormalMap, i.uv.zw), _DetailBumpScale);

    //that's the normals from the tangent space
    float3 tangentSpaceNormal = BlendNormals(mainNormal, detailNormal);
    //equals whiteout normals
    //i.normal = float3(mainNormal.xy+detailNormal.xy, mainNormal.z * detailNormal.z);  //unity-style channels
    
    #if defined(BINORMAL_PER_FRAGMENT)
        float3 binormal = cross(i.normal, i.tangent.xyz) * (i.tangent.w * unity_WorldTransformParams.w);  //in case negative scale
    #else 
        float3 binormal = i.binormal;
    #endif 
    // to the final world space normal combined with the normal map
    i.normal = tangentSpaceNormal.x * i.tangent.xyz 
    + tangentSpaceNormal.y * binormal+ tangentSpaceNormal.z * i.normal;   //flip y, z directly here
   
    i.normal = normalize(i.normal);
}


float4 MyFragmentProgram(Interpolators i) : SV_TARGET
{ 
    // SV_TARGET Stands for the frame buffer
    InitializeFragmentNormal(i);

	//calculate the direction for the specular Lighting
    float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
	//float3 reflectionDir = reflect(-lightDir, i.normal);   // pay attention to the negating
    //float3 halfVector = normalize(lightDir + viewDir); //blinn-phong, NO USE

	//declare lights for pbr lighting, I put this to the CreateLight Function
    //UnityLight light;
    //light.color = lightColor;
    //light.dir = lightDir;
    //light.ndotl = DotClamped(i.normal, lightDir); //diffuse term


				//add the albedo maintex
    float3 albedo = tex2D(_MainTex, i.uv.xy).rgb * _Tint.rgb;
    albedo *= tex2D(_DetailTex, i.uv.zw) * unity_ColorSpaceDouble;  //stop from color darker
	//energy consideration
    float3 specularTint;
    float oneMinusReflectivity; //the multiplier for energy monochrone
    albedo = DiffuseAndSpecularFromMetallic(
					albedo, _Metallic, specularTint, oneMinusReflectivity
				); 
    // energy consevation, monochrome manual way, no use
    //float3 diffuse = albedo * lightColor * DotClamped(lightDir, i.normal);
    //float3 specular = specularTint * lightColor * pow(DotClamped(halfVector, i.normal), _Smoothness * 10);
    
    //ShadeSH9 used for the ambient lights
    //float3 shColor = ShadeSH9(float4(i.normal, 1));
    //return float4(shColor, 1.0);
    
    return UNITY_BRDF_PBS(
				 albedo, specularTint,
				 oneMinusReflectivity, _Smoothness,
				 i.normal, viewDir,
				 CreateLight(i), CreateIndirectLight(i, viewDir)
				);
				
}

#endif