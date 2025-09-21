#ifndef H_UTILS
#define H_UTILS



#define PI 3.14159265358979323846

float3 ComputeH(float3 cameraPos, float3 wPosFragment, float3 lightDir){
    float3 v = normalize(cameraPos - wPosFragment);
    float3 l = normalize(lightDir); // For now just directional
    return normalize(v + l);
}

#define PLANE_TEST(pt, pl, bias) dot(pt##0, pl) + bias < 0 && dot(pt##1, pl) + bias < 0 && dot(pt##2, pl) + bias < 0 

#define BARYCENTRIC_INTERP(p, bc, var, field) var.field = p[0].field * bc.x + p[1].field * bc.y + p[2].field * bc.z;


bool frustumCulling(float3 p0,float3 p1,float3 p2){
    float4 wp0 = mul(unity_ObjectToWorld, float4(p0,1));
    float4 wp1 = mul(unity_ObjectToWorld, float4(p1,1));
    float4 wp2 = mul(unity_ObjectToWorld, float4(p2,1));
    float b = -1000;

    return  PLANE_TEST(wp,unity_CameraWorldClipPlanes[0], b) &&
            PLANE_TEST(wp,unity_CameraWorldClipPlanes[1], b) &&
            PLANE_TEST(wp,unity_CameraWorldClipPlanes[2], b) &&
            PLANE_TEST(wp,unity_CameraWorldClipPlanes[3], b) &&
            PLANE_TEST(wp,unity_CameraWorldClipPlanes[4], b) &&
            PLANE_TEST(wp,unity_CameraWorldClipPlanes[5], b) ;
}


#endif