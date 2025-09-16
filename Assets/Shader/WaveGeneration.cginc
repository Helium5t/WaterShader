
#ifdef WAVE_BROWNIAN
    #include "Rand.cginc"
#endif

#if !defined(WAVE_BROWNIAN)  // If no other type of wave generation is defined define the static version
#define WAVE_STATIC
#endif 

#ifdef DEBUG_MODE
    #define H_TIME _DebugTime //(100000 * _DebugTime)
#else
    #define H_TIME _Time
#endif

float WaveFunctionSine(float ampli, float2 p, float2 waveDir, float freq, float phase){
    float frontProj = p.x * waveDir.x + p.y * waveDir.y;
    return ampli * sin(frontProj * freq + phase * H_TIME.y);
}
float2 WaveFunctionSineDer(float ampli, float2 p, float2 waveDir, float freq, float phase){
    float frontProj = p.x * waveDir.x + p.y * waveDir.y;
    float wfd = ampli * freq * cos(frontProj * freq + phase * H_TIME.y);
    return wfd * waveDir;
}

float WaveFunctionExpSine(float ampli, float2 p, float2 waveDir, float freq, float phase, float maxValue, float offset){
    float frontProj = dot(p,waveDir);
    return ampli * exp( (maxValue * sin(frontProj * freq + phase * H_TIME.y)) - offset) ;
}
float2 WaveFunctionExpSineDer(float ampli, float2 p, float2 waveDir, float freq, float phase, float maxValue, float offset){
    float frontProj = dot(p,waveDir);
    float2 wfd = ampli * exp((maxValue * sin(frontProj * freq + phase * H_TIME.y)) - offset) * maxValue * cos(frontProj * freq + phase * H_TIME.y) * freq;
    wfd *= waveDir;
    return waveDir * wfd;
}

struct WaveInfo{
    float2 dir;
    float phase;
    float freq;
    float ampli;
    #ifdef WAVE_BROWNIAN
    int state;
    #endif
};

#ifdef WAVE_STATIC
    static const float2 dirs[3] = {
        float2(1,1),
        float2(1,1.5),
        float2(3,2),
    };
    static const float phases[3] = {
        1,
        0.63,
        0.2,
    };
    static const float freqs[3] = {
        0.1,
        0.5,
        0.7,
    };
    static const float amplis[3] = {
        3.4,
        1,
        0.5,
    };
    
    WaveInfo GetWave(int i){
        WaveInfo w;
        w.dir = dirs[i];
        w.phase = phases[i];
        w.freq = freqs[i];
        w.ampli = amplis[i];
        return w;
    }
#elif defined(WAVE_BROWNIAN)

    #ifndef AMPLI_F
    #define AMPLI_F 0.95
    #endif
    #ifndef FREQ_F
    #define FREQ_F 1.025
    #endif
    
    WaveInfo GetWave(int s, int i, float maxF, float maxA, float maxP, int lacunarity, float aRamp, float fRamp, float pRamp){
        WaveInfo w;
        w.dir = float2(0,0);
        int state = generate(s);
        w.dir.x = state /4294967296.0;
        state = generate(s);
        w.dir.y = state /4294967296.0;
        w.dir = normalize(w.dir);
        w.phase = maxP * pow(pRamp, i * lacunarity);
        w.freq =  maxF * pow(fRamp, i * lacunarity);
        w.ampli = maxA * pow(aRamp,i * lacunarity);
        if (i == 33){
            w.ampli = 0;
        }
        w.state = state;
        return w;
    }
#endif 