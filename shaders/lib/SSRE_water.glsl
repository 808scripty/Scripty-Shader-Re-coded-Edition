#ifndef SSRE_WATER_INCLUDED
#define SSRE_WATER_INCLUDED

#define WAVETYPE 0 // [0 1]

vec3 getWaterWaves(vec3 worldPos, float time) {

#if WAVETYPE == 0
    mediump float waveSpeed = time * 1.2;

    mediump float w1 = sin(worldPos.x * 0.5 + waveSpeed) * 0.08;
    mediump float w2 = cos(worldPos.z * 0.4 + waveSpeed * 0.8) * 0.08;
    mediump float w3 = sin((worldPos.x - worldPos.z) * 0.3 + waveSpeed * 1.1) * 0.05;

    return vec3(0.0, w1 + w2 + w3, 0.0);
#elif WAVETYPE 1
    mediump float waveSpeed = time * 0.8;
    mediump vec2 pos = worldPos.xz;
    mediump vec4 g1 = vec4(0.8, 0.6, 0.4, 1.2);
    mediump vec4 g2 = vec4(-0.5, 0.7, 0.3, 2.5);
    mediump vec4 g3 = vec4(0.2, -0.9, 0.2, 4.0);

    mediump float w = 0.0;
    
    mediump float f1 = (2.0 * 3.14159 / g1.w) * (dot(g1.xy, pos) - waveSpeed);
    w += g1.z * sin(f1);
    
    mediump float f2 = (2.0 * 3.14159 / g2.w) * (dot(g2.xy, pos) - waveSpeed * 1.3);
    w += g2.z * sin(f2);
    
    mediump float f3 = (2.0 * 3.14159 / g3.w) * (dot(g3.xy, pos) - waveSpeed * 1.8);
    w += g3.z * sin(f3);

    return vec3(0.0, w * 0.2, 0.0);

#else
    return vec3(0.0);
#endif
}



vec3 getWaterNormal(vec3 worldPos, float time) {

#if WAVETYPE == 0
    mediump float waveSpeed = time * 1.2;

    mediump float dWdx =
        cos(worldPos.x * 0.5 + waveSpeed) * 0.04 +
        cos((worldPos.x - worldPos.z) * 0.3 + waveSpeed * 1.1) * 0.015;

    mediump float dWdz =
        -sin(worldPos.z * 0.4 + waveSpeed * 0.8) * 0.032 -
        cos((worldPos.x - worldPos.z) * 0.3 + waveSpeed * 1.1) * 0.015;

    return normalize(vec3(-dWdx, 1.0, -dWdz));

#elif WAVETYPE 1
    mediump float waveSpeed = time * 0.8;
    mediump vec2 pos = worldPos.xz;

    mediump vec4 g1 = vec4(0.8, 0.6, 0.4, 1.2);
    mediump vec4 g2 = vec4(-0.5, 0.7, 0.3, 2.5);
    mediump vec4 g3 = vec4(0.2, -0.9, 0.2, 4.0);

    mediump float dx = 0.0;
    mediump float dz = 0.0;
    mediump float k1 = 2.0 * 3.14159 / g1.w;
    mediump float f1 = k1 * (dot(g1.xy, pos) - waveSpeed);
    mediump float amp1 = g1.z * k1 * cos(f1);
    dx += g1.x * amp1;
    dz += g1.y * amp1;
    mediump float k2 = 2.0 * 3.14159 / g2.w;
    mediump float f2 = k2 * (dot(g2.xy, pos) - waveSpeed * 1.3);
    mediump float amp2 = g2.z * k2 * cos(f2);
    dx += g2.x * amp2;
    dz += g2.y * amp2;
    mediump float k3 = 2.0 * 3.14159 / g3.w;
    mediump float f3 = k3 * (dot(g3.xy, pos) - waveSpeed * 1.8);
    mediump float amp3 = g3.z * k3 * cos(f3);
    dx += g3.x * amp3;
    dz += g3.y * amp3;
    mediump float normalStrength = 0.6;
    return normalize(vec3(-dx * normalStrength, 1.0, -dz * normalStrength));

#endif
}



vec3 getWaterReflection(vec3 normal, vec3 viewDir, vec3 sunCol, vec3 ambCol, float sunsetFactor) {
    mediump float fRange = 1.0 - max(dot(normal, viewDir), 0.0);
    mediump float fresnel = pow(fRange, 5.0); 
    mediump float metallicFresnel = mix(0.02, 1.0, fresnel); 
    mediump vec3 skyReflect = mix(ambCol * 0.8, sunCol * 1.5, sunsetFactor);

    return skyReflect * metallicFresnel;
}

#endif