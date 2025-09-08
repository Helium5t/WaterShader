Shader "Custom/Water"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BaseColor ("Color", Color) = (1,1,1,1)
        _AmbientColor ("Ambient Color", Color) = (0.5,0.5,0.5,0.5)
        _SpecularColor ("Specular Color", Color) = (1,1,1,1)
        _SpecularSharpness ("Reflection Sharpness", Float) = 2
        _DiffuseReflectance ("Diffuse Reflection Tint", Color) = (1,1,1,1)
        _WaveSize ("Wave Size", Float) = 1
    }
    SubShader
    {
        Tags { 
            "RenderType"="Opaque"
             "LightMode" = "ForwardBase"
        }
        
        CGINCLUDE 

        #define WATER_ITER 32
        #define WAVE_BROWNIAN
        #define BROWNIAN_DOMAIN_WARPING
        #define SUM_OF_SINES
        #define DIR_LIGHT
        #define RAND_SEED 2147483647
        
        #pragma multi_compile DIRECTIONAL POINT

        #include "UnityPBSLighting.cginc"
        #include "AutoLight.cginc"
        #include "LightingModels.cginc"
        #include "HeliumUtils.cginc"
        #include "WaveGeneration.cginc"
        

        #if defined(SUM_OF_SINES)
            #define ComputeDisplacement WaveFunctionExpSine
            #define ComputeDerivative WaveFunctionExpSineDer
        #endif

        #if defined(WAVE_BROWNIAN)
                static const float phase = 1.7;
                static const float freq = 0.7;
                static const float ampli = 5.5;
        #endif


        ENDCG
        Pass
        {
            CGPROGRAM
            #pragma target 3.0 
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog


            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 n : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 n : NORMAL;
                float4 vertex : SV_POSITION;
                float h : TEXCOORD1;
                float4 wPos : TEXCOORD2;
                float3 wavePoint : TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _BaseColor;
            float4 _MainTex_ST;
            float _SpecularSharpness;
            float3 _DiffuseReflectance;
            float3 _AmbientColor, _SpecularColor, _DiffuseColor;

            v2f vert (appdata v)
            {
                v2f o;
                float4 p = v.vertex;
                float2 d = normalize(float2(1,1));


                o.h = 0;
                float2 der = 0;
                int x = RAND_SEED;
                for (int i = 0 ; i < WATER_ITER; i++){
                    #if defined(WAVE_BROWNIAN)
                    WaveInfo w = GetWave(x, i, freq, ampli, phase);
                    x = w.state;
                    #else
                    if(i>2) break;
                    WaveInfo w = GetWave(i);
                    #endif
                    d = w.dir;
                    d = normalize(d);
                    #if defined(WAVE_BROWNIAN) && defined(BROWNIAN_DOMAIN_WARPING)
                    der = ComputeDerivative(w.ampli, p.xz + der, d,  w.freq, w.phase);
                    p.y += ComputeDisplacement(w.ampli, p.xz + der, d, w.freq, w.phase);
                    #else
                    p.y += ComputeDisplacement(w.ampli, p.xz, d, w.freq, w.phase);
                    #endif
                    // p.y = v.vertex.y * 10;
                }
                // p.y *= _WaveSize;
                o.h = p.y;
                o.n = v.n;
                o.wPos = mul(unity_ObjectToWorld, p);
                o.uv = v.uv;
                o.vertex = UnityObjectToClipPos(p.xyz);
                o.wavePoint = v.vertex;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {

                int x = RAND_SEED;
                float3 p = i.wavePoint;
                float3 n = float3(0,1,0);
                float2 d = normalize(float2(1,1));
                float2 der = float2(0,0);

                for (int idx = 0 ; idx < WATER_ITER; idx++){
                    #if defined(WAVE_BROWNIAN)
                    WaveInfo w = GetWave(x, idx, freq, ampli, phase);
                    x = w.state;
                    #else
                    if(idx>2) break;
                    WaveInfo w = GetWave(idx);
                    #endif
                    d = w.dir;

                    #if defined(WAVE_BROWNIAN) && defined(BROWNIAN_DOMAIN_WARPING)
                    der = ComputeDerivative(w.ampli, p.xz + der, d,  w.freq, w.phase);
                    #else
                    der = ComputeDerivative(w.ampli, p.xz, d,  w.freq, w.phase);
                    #endif
                    n.x += der.x;
                    n.z += der.y;
                }
                n = normalize(float3(-n.x, 1, -n.z));

                fixed4 diffuseCol = tex2D(_MainTex, i.uv) * _BaseColor;
                float3 lDir = _WorldSpaceLightPos0.xyz;
                float4 lColor = _LightColor0;

                float3 diffuse = BlinnPhongDiffuse(i.wPos, n, diffuseCol, lDir, 0, lColor.xyz, 0);
                diffuse *= unity_IndirectSpecColor;
                float3 spec = BlinnPhongSpecular(i.wPos, n, lDir, 0, lColor.xyz, 1, _SpecularSharpness, _SpecularColor);
                    
                return float4( diffuse + spec,1.0);
            }
            ENDCG
        }
    }
}
