Shader "Custom/Water"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BaseColor ("Color", Color) = (1,1,1,1)
        _SpecularColor ("Specular Color", Color) = (1,1,1,1)
        _SpecularSharpness ("Reflection Sharpness", Float) = 2
        _NormalContrast("Normal Contrast", Float) = 1
        _WaveSize ("Wave Size", Float) = 1
        _DisplacementScale ("Displacement Scale", Float) = 1
        _StartingAmplitude("Starting Amplitude", Float) = 1
        _BrownianLacunarity("Lacunarity", Integer) = 1
        _WaveNumber("Wave Number", Integer) = 1
        [NoScaleOffset] _CubemapTex ("Cubemap   (HDR)", Cube) = "grey" {}
        _DebugTime("Time Debug", Vector) = (1,1,1,1)
    }
    SubShader
    {
        Tags { 
            "RenderType"="Opaque"
             "LightMode" = "ForwardBase"
        }
        
        CGINCLUDE 
        #pragma target 3.0 
        #pragma vertex vert
        #pragma fragment frag
        // make fog work
        #pragma multi_compile_fog

        #define WAVE_BROWNIAN
        #define BROWNIAN_DOMAIN_WARPING
        #define SUM_OF_SINES
        #define DIR_LIGHT
        #define RAND_SEED 2147483647
        
        #pragma multi_compile DIRECTIONAL POINT

        #pragma shader_feature _ DEBUG_MODE

        #pragma shader_feature _ DYNAMIC_WAVE_NUM


        #ifdef DEBUG_MODE
            float2 _DebugTime;
        #endif

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
        #endif

        #ifdef DYNAMIC_WAVE_NUM
            int _WaveNumber;
            #define WAVE_ITER _WaveNumber
        #else
            #define WAVE_ITER 32
        #endif

        
        ENDCG

        Pass
        {
            CGPROGRAM


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
                UNITY_FOG_COORDS(4)
                float4 vertex : SV_POSITION;
                float h : TEXCOORD1;
                float4 wPos : TEXCOORD2;
                float3 wavePoint : TEXCOORD3;
            };

            sampler2D _MainTex;
            samplerCUBE _CubemapTex;
            float4 _BaseColor;
            float4 _MainTex_ST;
            float _SpecularSharpness,_WaveSize, _NormalContrast, _StartingAmplitude, _DisplacementScale;
            float3 _SpecularColor, _DiffuseColor;
            int _BrownianLacunarity;

            v2f vert (appdata v)
            {
                v2f o;
                float4 p = mul(unity_ObjectToWorld, v.vertex) * _WaveSize;
                float2 d = normalize(float2(1,1));


                o.h = 0;
                float2 der = 0;
                int x = RAND_SEED;
                float ampliSum;
                for (int i = 0 ; i < WAVE_ITER; i++){
                    #if defined(WAVE_BROWNIAN)

                    float ampli = _StartingAmplitude;
                    WaveInfo w = GetWave(x, i, freq, ampli, phase, _BrownianLacunarity);
                    x = w.state;
                    ampliSum += w.ampli;
                    #else
                    if(i>2) break;
                    WaveInfo w = GetWave(i);
                    #endif
                    #ifdef DEBUG_MODE
                    #endif

                    d = w.dir;
                    d = normalize(d);
                    #if defined(WAVE_BROWNIAN) && defined(BROWNIAN_DOMAIN_WARPING)
                    p.y += ComputeDisplacement(w.ampli, p.xz + der, d, w.freq, w.phase);
                    der = ComputeDerivative(w.ampli, p.xz + der, d,  w.freq, w.phase);
                    #else
                    p.y += ComputeDisplacement(w.ampli, p.xz, d, w.freq, w.phase);
                    #endif
                }
                p.y /= ampliSum;
                p.y -= 0.5;
                p.y *= _DisplacementScale;

                v.vertex.y =  p.y;
                o.h = p.y;
                o.n = v.n;
                o.wPos = mul(unity_ObjectToWorld, v.vertex);
                o.uv = v.uv;
                o.vertex = UnityObjectToClipPos(v.vertex.xyz);
                o.wavePoint = p;
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {

                int x = RAND_SEED;
                float3 p = i.wavePoint;
                float3 n = float3(0,1,0);
                float2 d = normalize(float2(1,1));
                float2 der = float2(0,0);
                float ampliSum;
                
                for (int idx = 0 ; idx < WAVE_ITER; idx++){
                    #if defined(WAVE_BROWNIAN)
                    float ampli = _StartingAmplitude;
                    WaveInfo w = GetWave(x, idx, freq, ampli, phase, _BrownianLacunarity);
                    ampliSum += w.ampli;
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
                n/= ampliSum;
                n = normalize(float3(-n.x, 1/_NormalContrast, -n.z ));

                fixed4 diffuseCol = tex2D(_MainTex, i.uv) * _BaseColor;
                float3 lDir =  _WorldSpaceLightPos0.xyz;
                float4 lColor = _LightColor0;
                float3 diffuse = BlinnPhongDiffuse(i.wPos, n, diffuseCol, lDir, 0, lColor.xyz, 0);
                float3 lookDir = normalize(-i.wPos + _WorldSpaceCameraPos);
                float3 aDir = normalize(reflect(lookDir, n));
                // aDir.y = step(0, aDir.y) * aDir.y;
                float3 ambientColor =  texCUBE(_CubemapTex, n).xyz * 0;
                float3 spec = BlinnPhongSpecularFromCubemap(i.wPos, n, lDir, 0, lColor.xyz, 1, _SpecularSharpness, _CubemapTex);
                // return float4(diffuse,1);
                // return float4(spec,1);
                // return float4(ambientColor,1) * step(0,n.y);
                // return float4(diffuse,1);
                // return UNITY_LIGHTMODEL_AMBIENT;
                float4 finalColor = float4(saturate(ambientColor+ diffuse + spec),1.0);
                UNITY_APPLY_FOG(i.fogCoord, finalColor);
                return finalColor;
            }
            ENDCG
        }
    }
    CustomEditor "WaterShaderGUI"
}
