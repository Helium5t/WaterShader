
#define PI 3.14159265358979323846

float3 ComputeH(float3 cameraPos, float3 wPosFragment, float3 lightDir){
    float3 v = normalize(cameraPos - wPosFragment);
    float3 l = normalize(lightDir); // For now just directional
    return normalize(v + l);
}