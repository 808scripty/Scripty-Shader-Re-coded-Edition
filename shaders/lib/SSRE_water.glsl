#ifndef SSRE_WATER_INCLUDED
 #define SSRE_WATER_INCLUDED

vec3 getWaterWaves(vec3 worldPos, float time) {
    float waveSpeed = time * 2.5;
    float w1 = sin(worldPos.x * 1.5 + waveSpeed) * 0.06;
    float w2 = cos(worldPos.z * 1.2 + waveSpeed * 0.8) * 0.05;
    float w3 = sin((worldPos.x + worldPos.z) * 0.7 + waveSpeed * 1.2) * 0.03;
    
    return vec3(0.0, w1 + w2 + w3, 0.0);
}

vec3 getWaterReflection(vec3 normal, vec3 viewDir, vec3 sunCol, vec3 ambCol, float sunsetFactor) {
    float fresnel = pow(1.0 - max(dot(normal, viewDir), 0.0), 4.0);
    vec3 skyReflect = mix(ambCol * 2.0, sunCol * 1.5, sunsetFactor);
    return skyReflect * fresnel;
}

#endif
