#ifndef SSRE_WATER_INCLUDED
#define SSRE_WATER_INCLUDED

#define WAVETYPE 1 // [0 1]

// --- GLOBAL WAVE FUNCTIONS ---

// WAVETYPE 0: Calm, performance-friendly 2D sine waves
mediump float getWaveHeight0(vec3 worldPos, float time) {
    mediump vec2 p = worldPos.xz;
    mediump float t = time * 1.2;
    
    // Two overlapping sine waves with different frequencies and directions
    mediump float wave  = sin(p.x * 0.8 + p.y * 0.4 + t);
                  wave += sin(p.x * 0.3 - p.y * 0.9 + t * 0.8);
    
    return wave * 0.03; // Low amplitude for calm water
}

// Derivative of WAVETYPE 0 for perfect normals
vec3 getWaterNormal0(vec3 worldPos, float time) {
    mediump vec2 p = worldPos.xz;
    mediump float t = time * 1.2;
    
    mediump float dx = 0.8 * cos(p.x * 0.8 + p.y * 0.4 + t) + 
                       0.3 * cos(p.x * 0.3 - p.y * 0.9 + t * 0.8);
                       
    mediump float dz = 0.4 * cos(p.x * 0.8 + p.y * 0.4 + t) - 
                       0.9 * cos(p.x * 0.3 - p.y * 0.9 + t * 0.8);
                       
    return normalize(vec3(-dx * 0.03, 1.0, -dz * 0.03));
}

// WAVETYPE 1: Performance-heavy, multi-octave exponential waves (BSL style)
mediump float getWaveHeight1(vec3 worldPos, float time) {
    mediump vec2 p = worldPos.xz;
    mediump float h = 0.0;
    mediump float amp = 0.08;
    mediump float freq = 0.6;
    mediump float speed = time * 1.5;
    
    mediump vec2 dir = normalize(vec2(1.0, 0.7));
    
    // 4-Octave loop for detailed, sharp-crested waves
    for(int i = 0; i < 2; i++) {
        mediump float wave = sin(dot(p, dir) * freq + speed);
        h += exp(wave - 1.0) * amp; // exp() creates sharper peaks
        
        // Rotate direction and scale freq/amp for the next octave
        dir = vec2(dir.x * 0.737 - dir.y * 0.675, dir.x * 0.675 + dir.y * 0.737);
        freq *= 1.8;
        amp *= 0.45;
        speed *= 1.3;
    }
    return h;
}

// Derivative of WAVETYPE 1 loop for perfect normals
vec3 getWaterNormal1(vec3 worldPos, float time) {
    mediump vec2 p = worldPos.xz;
    mediump float dx = 0.0;
    mediump float dz = 0.0;
    mediump float amp = 0.08;
    mediump float freq = 0.6;
    mediump float speed = time * 1.5;
    
    mediump vec2 dir = normalize(vec2(1.0, 0.7));
    
    for(int i = 0; i < 4; i++) {
        mediump float phase = dot(p, dir) * freq + speed;
        mediump float wave = sin(phase);
        mediump float dWave = cos(phase) * exp(wave - 1.0); // Chain rule of exp(sin(x)-1)
        
        dx += dWave * dir.x * freq * amp;
        dz += dWave * dir.y * freq * amp;
        
        dir = vec2(dir.x * 0.737 - dir.y * 0.675, dir.x * 0.675 + dir.y * 0.737);
        freq *= 1.8;
        amp *= 0.45;
        speed *= 1.3;
    }
    return normalize(vec3(-dx, 1.0, -dz));
}


// --- MAIN FUNCTIONS ---

vec3 getWaterWaves(vec3 worldPos, float time) {
    mediump float h = 0.0;
    
    #if WAVETYPE == 0
        h = getWaveHeight0(worldPos, time);
    #elif WAVETYPE == 1
        h = getWaveHeight1(worldPos, time);
    #endif

    // Return as a displacement vector
    return vec3(0.0, h, 0.0); 
}

vec3 getWaterNormal(vec3 worldPos, float time) {
    #if WAVETYPE == 0
        return getWaterNormal0(worldPos, time);
    #elif WAVETYPE == 1
        return getWaterNormal1(worldPos, time);
    #else
        return vec3(0.0, 1.0, 0.0);
    #endif
}

vec3 getWaterReflection(vec3 normal, vec3 viewDir, vec3 sunCol, vec3 ambCol, float sunsetFactor) {
    mediump float fRange = 1.0 - max(dot(normal, viewDir), 0.0);
    mediump float f2 = fRange * fRange;
    mediump float fresnel = f2 * f2 * fRange; 
    mediump vec3 skyReflect = mix(ambCol * 0.9, sunCol * 1.2, sunsetFactor);
    return skyReflect * mix(0.05, 1.0, fresnel);
}

#endif
