Shader "Custom/TessellatedWater"
{
    Properties
    {
        // Shading Parameters
        _MainTex ("Texture", 2D) = "white" {}
        _BaseColor ("Color", Color) = (1,1,1,1)
        _SpecularColor ("Specular Color", Color) = (1,1,1,1)
        _SpecularSharpness ("Specular Sharpness", Float) = 2
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
        _Seed("Seed", Integer) = 2147483647
        _Subdivs("Tessellation Subdivisions",Float) = 1
        _TargetEdgeLen ("Tessellation Target Edge Length", Float) = 1
        _MaxDistTessellation ("Tessellation Maximum Distance", Float) = 0
        _MinDistTessellation ("Tessellation Minimum Distance", Float) = 0
        _MinEdgeTesselation ("Tessellation at Edge Minimum", Float) = 1
        _MaxEdgeTesselation ("Tessellation at Edge Maximum", Float) = 1
        _PhongTesselationFactor ("Phong Tesselation Factor", Float) = 1
    }
    SubShader
    {
        Tags { 
            "RenderType"="Opaque"
             "LightMode" = "ForwardBase"
        }
        CGPROGRAM

        // #pragma target 4.6

        #define WAVE_BROWNIAN
        #define BROWNIAN_DOMAIN_WARPING
        #define SUM_OF_SINES
        #define DIR_LIGHT

        #pragma shader_feature _ DIFFUSE_TEXTURE
        #pragma shader_feature _ SPECULAR_CUBEMAP
        #pragma shader_feature _ DEBUG_MODE
        #pragma shader_feature _ DYNAMIC_SEED

        #pragma shader_feature _ DYNAMIC_WAVE_NUM

        #pragma shader_feature _ EDGE_BASED_TESSELLATION DISTANCE_BASED_TESSELLATION HEIGHT_FUNCTION_BASED_TESSELATION

        #pragma surface surf Lambert fullforwardshadows tessellate:tess vertex:vert  //tessphong:_PhongTesselationFactor 

        #ifdef DEBUG_MODE
            float2 _DebugTime;
        #endif

        #ifdef DYNAMIC_SEED
            int _Seed;
            #define RAND_SEED _Seed
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
        #include "DataStructures.cginc"
        #include "Tessellation.cginc"

        #ifdef DYNAMIC_WAVE_NUM
            int _WaveNumber;
            #define WAVE_ITER _WaveNumber
        #else
            #define WAVE_ITER 32
        #endif


        sampler2D _MainTex;
        samplerCUBE _CubemapTex;
        float4 _BaseColor, _FoamBaseColor;
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
                _MaxHeightRemap,
                _TargetEdgeLen,
                _MinDistTessellation,
                _MaxDistTessellation,
                _PhongTesselationFactor, 
                _Subdivs,
                _MinEdgeTesselation,
                _MaxEdgeTesselation;
        float3 _SpecularColor, _AmbientColor;

        int _BrownianLacunarity;
        void vert (inout appdata_full v)
        {
            float4 p = mul(unity_ObjectToWorld, v.vertex) / _WaveSize;
            float h = 0;
            float2 der = 0;
            int x = RAND_SEED;
            float ampliSum;
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

                float2 d = w.dir;
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
            h = p.y;
            p.y *= _DisplacementScale;

            v.vertex.y = p.y;
        }

        float GetHeightFunTess(float3 wp0, float3 wp1){
            #ifdef WAVE_BROWNIAN
                WaveInfo w = GetWave(0, 1, _BaseFrequency, _BaseAmplitude, _BasePhase,  _BrownianLacunarity, _AmplitudeRampMultiplier, _FrequencyRampMultiplier, _PhaseRampMultiplier);
            #else
                WaveInfo w = GetWave(2);
            #endif
            float freq = w.freq;
            float3 pm = (wp0 + wp1) / 2;
            wp0 /= _WaveSize;
            wp1 /= _WaveSize; 
            float3 viewDir = _WorldSpaceCameraPos.xyz - pm;
            float sf = clamp(pow(1-dot(float3(0,1,0), normalize(viewDir)),5), _MinEdgeTesselation, _MaxEdgeTesselation);
            float df = 1 - clamp( (length(viewDir) - _MinDistTessellation)/(_MaxDistTessellation - _MinDistTessellation),0,0.9999);
            float samples = 2 * freq * length(wp0-wp1);
            samples *= sf;
            samples *= df;
            samples *= _Subdivs;
            return samples;
        }
        
        float4 tess(
            appdata_full vi1,
            appdata_full vi2,
            appdata_full vi3){

            float maxDispl =  _BaseAmplitude * (1/(1-_AmplitudeRampMultiplier)) * _DisplacementScale;
            #ifdef EDGE_BASED_TESSELLATION
            return UnityEdgeLengthBasedTessCull(vi1.vertex, vi2.vertex, vi3.vertex, _TargetEdgeLen,maxDispl);
            #elif DISTANCE_BASED_TESSELLATION
            return UnityDistanceBasedTess(vi1.vertex, vi2.vertex, vi3.vertex,_MinDistTessellation, _MaxDistTessellation, _TargetEdgeLen);
            #elif HEIGHT_FUNCTION_BASED_TESSELATION
            float3 pos1 = mul(unity_ObjectToWorld, vi1.vertex);
            float3 pos2 = mul(unity_ObjectToWorld, vi2.vertex);
            float3 pos3 = mul(unity_ObjectToWorld, vi3.vertex);
            if (UnityWorldViewFrustumCull(pos1, pos2, pos3, maxDispl))
            {
                return 0.0f;
            }
            float f1 = GetHeightFunTess(pos2,pos3);
            float f2 = GetHeightFunTess(pos3,pos1);
            float f3 = GetHeightFunTess(pos1,pos2);
            return float4(f1,f2,f3, (f1 + f2 + f3) * 0.2);
            #else
            return float4(_Subdivs*0.6,_Subdivs*0.6,_Subdivs*0.6,_Subdivs);
            #endif
        }


        void surf (Input i, inout SurfaceOutput o) 
        {
            
            int x = RAND_SEED;
            float3 p = i.worldPos / _WaveSize;
            float3 n = float3(0,1,0);
            float2 d = normalize(float2(1,1));
            float2 der = float2(0,0);
            float ampliSum;
            float h;
            
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
                h += ComputeDisplacement(w.ampli, p.xz + der, d, w.freq, w.phase);
                der = ComputeDerivative(w.ampli, p.xz + der, d,  w.freq, w.phase);
                #else
                h += ComputeDisplacement(w.ampli, p.xz, d, w.freq, w.phase);
                der = ComputeDerivative(w.ampli, p.xz, d,  w.freq, w.phase);
                #endif
                n.x += der.x;
                n.z += der.y;
            }
            n/= ampliSum;
            n = normalize(float3(-n.x, 1/_NormalContrast, -n.z ));
            // Foam Computation
            // Create Foam on tallest waves
            float height =saturate(h/ampliSum);
            height =  (height-_MinHeightRemap)/(_MaxHeightRemap-_MinHeightRemap);
            height = saturate((height - 1 + _FoamFactorHeight) / _FoamFactorHeight);
            height = pow(height, _FoamSharpnessHeight);
            // Create foam at sharp angles
            float foamAngle = DotClamped(float3(0,1,0), n);
            foamAngle = saturate((foamAngle -1 + _FoamFactorAngle) / _FoamFactorAngle);
            foamAngle = lerp(height,pow(foamAngle, _FoamSharpnessAngle), height);
            height = max(height, foamAngle);
            
            #ifdef DIFFUSE_TEXTURE
                float4 diffuseCol = tex2D(_MainTex, i.uv_MainTex) + lerp(0, _FoamBaseColor, height);
            #else
                float4 diffuseCol = _BaseColor + lerp(0, _FoamBaseColor, height);
            #endif

            float3 lDir =  _WorldSpaceLightPos0.xyz;
            float4 lColor = _LightColor0;
            float3 diffuse = BlinnPhongDiffuse(i.worldPos, n, diffuseCol, lDir, 0, lColor.xyz, 0);
            float3 lookDir = normalize(-i.worldPos + _WorldSpaceCameraPos);
            float schlickFresnel = pow(1 - DotClamped(lookDir, n), 5);
            float3 ambientColor =  _AmbientColor;
            #ifdef SPECULAR_CUBEMAP
                float3 spec = schlickFresnel * _SpecularStrength * BlinnPhongSpecularFromCubemap(i.worldPos, n, lDir, 0, lColor.xyz, 1, _SpecularSharpness, _CubemapTex, _SpecularColor);
            #else 
                float3 spec = schlickFresnel * _SpecularStrength * BlinnPhongSpecular(i.worldPos, n, lDir, 0, lColor.xyz, 1, _SpecularSharpness, _SpecularColor);
            #endif
            float3x3 tsMat = float3x3(float3(1,0,0), float3(0,0,1), float3(0,1,0));
            tsMat = transpose(tsMat);
            o.Normal = normalize(mul(tsMat, n));
            o.Albedo = diffuse + spec;// Use ALbedo only to pass the cubemap reflection properly
        }
        ENDCG
    }
    CustomEditor "TessellatedWaterShaderGUI"
}
