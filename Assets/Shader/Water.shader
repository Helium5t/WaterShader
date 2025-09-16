Shader "Custom/Water"
{
    Properties
    {
        // Shading Parameters
        _MainTex ("Texture", 2D) = "white" {}
        _BaseColor ("Color", Color) = (1,1,1,1)
        _SpecularColor ("Specular Color", Color) = (1,1,1,1)
        _SpecularSharpness ("Reflection Sharpness", Float) = 2
        _SpecularStrength ("Specular Strength", Float) = 1
        _AmbientColor ("Ambient Color", Color) = (0.5,0.5,0.5,0.5)
        _FoamBaseColor ("Foam Base Color", Color ) = (1,1,1,1)
        _FoamFactorHeight("Height Based Foam Amount", Range(0,1) ) = 1
        _FoamSharpnessHeight("Height BasedFoam Sharpness", Float) = 1
        _FoamFactorAngle("Angle Based Foam Amount", Range(0,1) ) = 1
        _FoamSharpnessAngle("Angle Based Foam Sharpness", Float) = 1
        _FoamSpecularFactor ("Foam Specular Multiplier", Float) = 1
        _NormalContrast("Normal Contrast", Float) = 1
        _MinHeightRemap("Height Remapping Minimum", Range(0,1)) = 0
        _MaxHeightRemap("Height Remapping Maximum", Range(0,1)) = 1
        [NoScaleOffset] _CubemapTex ("Reflection Cubemap", Cube) = "grey" {}
        // Generation Parameters
        _WaveSize ("Wave Size", Float) = 1
        _DisplacementScale ("Displacement Scale", Float) = 1
        _WaveNumber("Wave Number", Integer) = 1
        // FBM Generation Parameters
        _BaseAmplitude("Starting Amplitude", Float) = 1
        _BasePhase ("Starting Phase", Float) = 1
        _BaseFrequency ("Starting Frequency", Float) = 1
        _PhaseRampMultiplier("Phase Ramp Multiplier", Float) = 1
        _AmplitudeRampMultiplier("Amplitude Ramp Multiplier", Float) = 1
        _FrequencyRampMultiplier("Frequency Ramp Multiplier", Float) = 1
        _BrownianLacunarity("Lacunarity", Integer) = 1
        // ExpSine specific parameters
        _MaxExpMultiplier("Max Exponential Multiplier", Float) = 1
        _ExpOffset("Exponential Negative Offset", Float) = 1
        // Debug Parameters 
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

        #pragma shader_feature _ DIFFUSE_TEXTURE
        #pragma shader_feature _ SPECULAR_CUBEMAP
        #pragma shader_feature _ DEBUG_MODE

        #pragma shader_feature _ DYNAMIC_WAVE_NUM


        #ifdef DEBUG_MODE
            float2 _DebugTime;
        #endif


        #if defined(SUM_OF_SINES)
            #define ComputeDisplacement(a,p,w,f,ph) WaveFunctionExpSine(a,p,w,f,ph, _MaxExpMultiplier, _ExpOffset)
            #define ComputeDerivative(a,p,w,f,ph) WaveFunctionExpSineDer(a,p,w,f,ph, _MaxExpMultiplier, _ExpOffset)
        #endif

        #include "UnityPBSLighting.cginc"
        #include "AutoLight.cginc"
        #include "LightingModels.cginc"
        #include "HeliumUtils.cginc" 
        #include "WaveGeneration.cginc"

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
            float4 _BaseColor, _FoamBaseColor;
            float4 _MainTex_ST;
            float   _SpecularSharpness,
                    _WaveSize,
                    _NormalContrast, 
                    _BaseAmplitude, 
                    _DisplacementScale, 
                    _FoamFactorHeight,
                    _FoamFactorAngle, 
                    _FoamSharpnessAngle,
                    _FoamSharpnessHeight,
                    _FoamSpecularFactor,
                    _SpecularStrength,
                    _BasePhase,
                    _BaseFrequency,
                    _PhaseRampMultiplier,
                    _AmplitudeRampMultiplier,
                    _FrequencyRampMultiplier,
                    _MaxExpMultiplier,
                    _ExpOffset,
                    _MinHeightRemap,
                    _MaxHeightRemap;
            float3 _SpecularColor, _AmbientColor;

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


                float rotT = 80 * (PI / 180);
                float bigWaveFreq = 0.07;
                float bigWavePhase =0.7;
                float2 bigWaveDir1 = normalize(float2(sin(rotT ),cos(rotT)));
                float fp = dot(bigWaveDir1, p.xz);
                float fx = bigWaveFreq * fp + bigWavePhase * _Time.y ;
                rotT += PI*7.1/2;
                float2 bigWaveDir2 = normalize(float2(sin(rotT),cos(rotT)));
                fp = dot(bigWaveDir2, p.xz);
                float fy = bigWaveFreq * fp + bigWavePhase * 1.7 * _Time.y ;
                float mult = clamp((sin(fx) + sin(fy) + 2)*0.5,0,1);
                float2 multDer =   cos(fx) * fp + fp * cos(fy);
                for (int i = 0 ; i < WAVE_ITER; i++){
                    #if defined(WAVE_BROWNIAN)

                    float ampli = _BaseAmplitude;
                    WaveInfo w = GetWave(x, i, _BaseFrequency, ampli, _BasePhase, _BrownianLacunarity, _AmplitudeRampMultiplier, _FrequencyRampMultiplier, _PhaseRampMultiplier);
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
                    float displ = ComputeDisplacement(w.ampli, p.xz + der, d, w.freq, w.phase);
                    p.y += displ;
                    // p.y +=  * displ;
                    der = ComputeDerivative(w.ampli, p.xz + der, d,  w.freq, w.phase);
                    // der = mult * der + multDer + displ;
                    #else
                    p.y += ComputeDisplacement(w.ampli, p.xz, d, w.freq, w.phase);
                    #endif


                }
                mult = step(0.0001, abs(mult)) * mult + (1-step(0.0001, abs(mult))) * 0.0001;
                p.y /= ampliSum;
                p.y *= mult;
                o.h = p.y ;
                p.y -= 0.5;
                p.y *= _DisplacementScale ;
                
                v.vertex.y =  p.y;
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
                    float ampli = _BaseAmplitude;
                    WaveInfo w = GetWave(x, idx, _BaseFrequency, ampli, _BasePhase, _BrownianLacunarity, _AmplitudeRampMultiplier, _FrequencyRampMultiplier, _PhaseRampMultiplier);
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
                // Foam Computation
                // Create Foam on tallest waves
                float height =saturate(i.h/ampliSum);
                height =  (height-_MinHeightRemap)/(_MaxHeightRemap-_MinHeightRemap);
                height = saturate((height - 1 + _FoamFactorHeight) / _FoamFactorHeight);
                height = pow(height, _FoamSharpnessHeight);
                // Create foam at sharp angles
                float foamAngle = DotClamped(float3(0,1,0), n);
                foamAngle = saturate((foamAngle -1 + _FoamFactorAngle) / _FoamFactorAngle);
                foamAngle = lerp(height,pow(foamAngle, _FoamSharpnessAngle), height);
                height = max(height, foamAngle);
                
                #ifdef DIFFUSE_TEXTURE
                    float4 diffuseCol = tex2D(_MainTex, i.uv) + lerp(0, _FoamBaseColor, height);
                #else
                    float4 diffuseCol = _BaseColor + lerp(0, _FoamBaseColor, height);
                #endif

                float3 lDir =  _WorldSpaceLightPos0.xyz;
                float4 lColor = _LightColor0;
                float3 diffuse = BlinnPhongDiffuse(i.wPos, n, diffuseCol, lDir, 0, lColor.xyz, 0);
                float3 lookDir = normalize(-i.wPos + _WorldSpaceCameraPos);
                float schlickFresnel = pow(1 - DotClamped(lookDir, n), 5);
                float3 ambientColor =  _AmbientColor;
                #ifdef SPECULAR_CUBEMAP
                    float3 spec = schlickFresnel * _SpecularStrength * BlinnPhongSpecularFromCubemap(i.wPos, n, lDir, 0, lColor.xyz, 1, _SpecularSharpness, _CubemapTex, _SpecularColor);
                #else 
                    float3 spec = schlickFresnel * _SpecularStrength * BlinnPhongSpecular(i.wPos, n, lDir, 0, lColor.xyz, 1, _SpecularSharpness, _SpecularColor);
                #endif

                float4 finalColor = float4(saturate(ambientColor+ diffuse + spec),1.0);
                UNITY_APPLY_FOG(i.fogCoord, finalColor);
                return finalColor;
            }
            ENDCG
        }
    }
    CustomEditor "WaterShaderGUI"
}
