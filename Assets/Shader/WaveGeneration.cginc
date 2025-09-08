
#ifdef WAVE_BROWNIAN
    #include "Rand.cginc"
#endif

#if !defined(WAVE_BROWNIAN)  // If no other type of wave generation is defined define the static version
#define WAVE_STATIC
#endif 

float WaveFunctionSine(float ampli, float2 p, float2 waveDir, float freq, float phase){
    float frontProj = p.x * waveDir.x + p.y * waveDir.y;
    return ampli * sin(frontProj * freq + phase * _Time.y);
}
float2 WaveFunctionSineDer(float ampli, float2 p, float2 waveDir, float freq, float phase){
    float frontProj = p.x * waveDir.x + p.y * waveDir.y;
    float wfd = ampli * freq * cos(frontProj * freq + phase * _Time.y);
    return wfd * waveDir;
}

float WaveFunctionExpSine(float ampli, float2 p, float2 waveDir, float freq, float phase){
    float frontProj = p.x * waveDir.x + p.y * waveDir.y;
    return ampli * exp( sin(frontProj * freq + phase * _Time.y) - 1);
}
float2 WaveFunctionExpSineDer(float ampli, float2 p, float2 waveDir, float freq, float phase){
    float frontProj = p.x * waveDir.x + p.y * waveDir.y;
    float wfd = exp(sin(frontProj * freq + phase * _Time.y) - 1) * ampli * freq * cos(frontProj * freq + phase * _Time.y);
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

    #define AMPLI_F 0.78
    #define FREQ_F 1.15
    
    WaveInfo GetWave(int s, int i, float maxF, float maxA, float maxP){
        WaveInfo w;
        w.dir = float2(0,0);
        int state = generate(s);
        w.dir.x = state /4294967296.0;
        state = generate(s);
        w.dir.y = state /4294967296.0;
        w.dir = normalize(w.dir);
        w.phase = maxP;
        w.freq =  maxF * pow(FREQ_F, i);
        w.ampli = maxA * pow(AMPLI_F, i) * (1-(AMPLI_F * 0.99));
        w.state = state;
        return w;
    }
#endif 