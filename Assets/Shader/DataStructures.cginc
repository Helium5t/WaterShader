#ifndef H_STRUCTS
#define H_STRUCTS

struct v2f
{
    float2 uv : TEXCOORD0;
    float3 n : NORMAL;
    UNITY_FOG_COORDS(4)
    float4 vertex : SV_POSITION;
    float h : TEXCOORD1;
    float4 wPos : TEXCOORD2;
    float3 wavePoint : TEXCOORD3;
};

struct TessellatedV2f{
    float2 uv : TEXCOORD0;
    float3 n : NORMAL;
    float4 vertex: INTERNALTESSPOS;
    float h : TEXCOORD1;
    float4 wPos : TEXCOORD2;
    float3 wavePoint : TEXCOORD3;
};

struct tFactors{
    float edge[3]: SV_TessFactor; // SV_TESSFACTOR
    float inner : SV_InsideTessFactor; // SV_INSIDETESSFACTOR 
};


struct appdata
{
    float4 vertex : POSITION;
    float2 texcoord : TEXCOORD0;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;
    float4 texcoord1 : TEXCOORD1;
    float3 wavePoint : TEXCOORD2;
};


struct Input{
    float3 worldPos;
    float2 uv_MainTex;
    float4 waveInfo;
    // float4 uv2;
    // float3 worldNormal;
    // float3 viewDir;
    // float3 wavePoint;
    // float3 vertex;
    // float h;
};

#endif