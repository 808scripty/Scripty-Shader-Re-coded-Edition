#ifndef SSRE_WATER_INCLUDED
#define SSRE_WATER_INCLUDED

#define WAVETYPE 0

vec3 getWaterWaves(vec3 worldPos, float time) {
   
#if WAVETYPE == 0
    mediump float waveSpeed = time * 0.4; 
    mediump vec2 pos = worldPos.xz * 0.5;

    mediump vec4 wA = vec4(0.8, 0.6, 0.15, 1.5);
    mediump vec4 wB = vec4(-0.5, 0.7, 0.10, 3.0);

    mediump vec2 freqs = vec2(wA.w, wB.w);
    mediump vec2 phases = vec2(dot(wA.xy, pos) - waveSpeed, dot(wB.xy, pos) - waveSpeed * 1.2);
    
    mediump vec2 waves = sin(phases * freqs);
    mediump float w = dot(vec2(wA.z, wB.z), waves);

    return vec3(0.0, w * 0.1, 0.0);
    #elif WAVETYPE == 1
    #elif WAVETYPE == 1
    mediump float waveSpeed = time * 0.2;
    mediump vec2 pos = worldPos.xz * 0.35;

    float wave1 = sin(pos.x * 0.8 + pos.y * 0.5 + waveSpeed);
    float wave2 = sin(pos.x * -0.6 + pos.y * 1.2 - waveSpeed * 1.4);
    float wave3 = sin(pos.y * 2.5 + waveSpeed * 2.1);

    float w = (wave1 * 0.5) + (wave2 * 0.3) + (wave3 * 0.2);

    return vec3(0.0, w * 0.06, 0.0); 
    
    #else
    return vec3(0.0);
#endif
}

vec3 getWaterNormal(vec3 worldPos, float time) {
#if WAVETYPE == 0
    mediump float waveSpeed = time * 0.4;
    mediump vec2 pos = worldPos.xz * 0.5;

    mediump vec4 wA = vec4(0.8, 0.6, 0.15, 1.5);
    mediump vec4 wB = vec4(-0.5, 0.7, 0.10, 3.0);

    mediump vec2 freqs = vec2(wA.w, wB.w);
    mediump vec2 phases = vec2(dot(wA.xy, pos) - waveSpeed, dot(wB.xy, pos) - waveSpeed * 1.2);
    
    mediump vec2 cosines = cos(phases * freqs);
    mediump vec2 amps = vec2(wA.z, wB.z) * freqs * cosines;
    
    mediump float dx = wA.x * amps.x + wB.x * amps.y;
    mediump float dz = wA.y * amps.x + wB.y * amps.y;

    mediump float normalStrength = 0.25; 
    return normalize(vec3(-dx * normalStrength, 1.0, -dz * normalStrength));
 #elif WAVETYPE == 1
    mediump float waveSpeed = time * 0.2;
    mediump vec2 pos = worldPos.xz * 0.35;

    float d1 = cos(pos.x * 0.8 + pos.y * 0.5 + waveSpeed);
    float d2 = cos(pos.x * -0.6 + pos.y * 1.2 - waveSpeed * 1.4);
    float d3 = cos(pos.y * 2.5 + waveSpeed * 2.1);

    float dx = (d1 * 0.8 * 0.5) + (d2 * -0.6 * 0.3);
    float dz = (d1 * 0.5 * 0.5) + (d2 * 1.2 * 0.3) + (d3 * 2.5 * 0.2);

    mediump float normalStrength = 0.12; 
    return normalize(vec3(-dx * normalStrength, 1.0, -dz * normalStrength));    
    #else
    return vec3(0.0);
#endif
}

vec3 getWaterReflection(vec3 normal, vec3 viewDir, vec3 sunCol, vec3 ambCol, float sunsetFactor) {
    mediump float fRange = 1.0 - max(dot(normal, viewDir), 0.0);
    
    mediump float f2 = fRange * fRange;
    mediump float fresnel = f2 * f2 * fRange; 
    
    mediump float metallicFresnel = mix(0.05, 1.0, fresnel);
    mediump float reflectionStrength = 1.5;
    mediump vec3 skyReflect = mix(ambCol * 0.9, sunCol * 1.2, sunsetFactor) * reflectionStrength;
    
    return skyReflect * metallicFresnel;
}

#endif
