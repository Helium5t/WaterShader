
#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"

/*
wPos    - fragment position in world space
wNormal - normal in world space
lDir    - direction from fragment to light
diffuseColor  - Diffuse Color
lightWorldPos - Light Position (Can use 0 if directional), 
lightColor    - Light Color
lightIntensity - Light intensity
*/
float3 BlinnPhongDiffuse(float3 wPos, float3 wNormal, float3 diffuseColor, float3 lDir, float3 lightWorldPos, float3 lightColor, float lightIntensity){
    lDir = normalize(lDir);
    wNormal = normalize(wNormal);
    float diffuseStrength = DotClamped(wNormal, lDir);
	#ifdef POINT
        float3 diffuse = diffuseStrength * diffuseColor * lightColor * (lightIntensity / len(lightWorldPos - wPos));
	#elif defined(DIRECTIONAL)
        float3 diffuse = diffuseStrength * diffuseColor * lightColor;
    #else
        return float3(1,0,1);
	#endif
    return diffuse;
}

/*
wPos    - fragment position in world space
wNormal - normal in world space
lDir    - direction from fragment to light
diffuseColor  - Diffuse Color
lightWorldPos - Light Position (Can use 0 if directional), 
lightColor    - Light Color
lightIntensity - Light intensity
specularSharpness - Sharpness of the falloff of the specular intensity
specularColor - Specular Color
*/ 
float3 BlinnPhongSpecular(float3 wPos, float3 wNormal, float3 lDir, float3 lightWorldPos, float3 lightColor, float lightIntensity, float specularSharpness, float3 specularColor){
    float3 worldViewDir = normalize(_WorldSpaceCameraPos - wPos.xyz);
    wNormal = normalize(wNormal);
    lDir = normalize(lDir);
    float3 halfwayVector = normalize(lDir + worldViewDir); // Bisects the two vectors
	float NdH = DotClamped(wNormal, halfwayVector);
    float NdL = DotClamped(wNormal, lDir);
	float specularStrength = pow(NdH, specularSharpness ) * NdL;
	#if defined(POINT) 
		float3 specular = specularStrength * specularColor * lightColor * lightIntensity / len(lightWorldPos - wPos);
	#elif defined(DIRECTIONAL)
		float3 specular = specularStrength * specularColor * lightColor;
    #else
        return float3(1,0,1); // Not supported
	#endif 
    return specular;
}

/*
wPos    - fragment position in world space
wNormal - normal in world space
lDir    - direction from fragment to light
diffuseColor  - Diffuse Color
lightWorldPos - Light Position (Can use 0 if directional), 
lightColor    - Light Color
lightIntensity - Light intensity
specularSharpness - Sharpness of the falloff of the specular intensity
cubemap - Cubemap to sample the specular from
*/ 
float3 BlinnPhongSpecularFromCubemap(float3 wPos, float3 wNormal, float3 lDir, float3 lightWorldPos, float3 lightColor, float lightIntensity, float specularSharpness, samplerCUBE cubemap, float3 specularTint){
    float3 worldViewDir = normalize(_WorldSpaceCameraPos - wPos.xyz);
    wNormal = normalize(wNormal);
    lDir = normalize(lDir);
    float3 halfwayVector = normalize(lDir + worldViewDir); // Bisects the two vectors
	float NdH = DotClamped(wNormal, halfwayVector);
    float NdL = DotClamped(wNormal, lDir);
	float specularStrength = pow(NdH, specularSharpness ) * NdL;
    float3 r = normalize(reflect(-worldViewDir, wNormal));
    r.y = abs(r.y);
    float3 specularColor = specularTint * texCUBE(cubemap,r );
	#if defined(POINT) 
		float3 specular = 10 * specularStrength * specularColor * lightColor * lightIntensity / len(lightWorldPos - wPos);
	#elif defined(DIRECTIONAL)
		float3 specular = 10 * specularStrength * specularColor * lightColor;
    #else
        return float3(1,0,1);
	#endif 
    return specular;
}