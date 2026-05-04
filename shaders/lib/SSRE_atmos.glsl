#ifndef SSRE_ATMOS_INCLUDED
 #define SSRE_ATMOS_INCLUDED

#include "/lib/ssre_math.glsl"

float getCloudCoverage(vec2 pos, float time) {
    pos += time * vec2(0.015, 0.01);
    float n = noise(pos) * 0.6 + noise(pos * 2.0) * 0.4;
    return smoothstep(0.45, 0.75, n);
}

vec3 applySSREFog(vec3 finalRGB, vec3 vWorldPos, float viewDist, float rainStrength, vec3 fogColor, vec3 vTimeFactors, float deadzone, float mistDist) {
    float currentFogDensity = mix(0.004, 0.015, rainStrength); 
    float effectiveDist = max(viewDist - deadzone, 0.0); 
    float distVisibility = exp(-effectiveDist * currentFogDensity);
    
    float heightMistVisibility = clamp((vWorldPos.y - 45.0) * 0.04, 0.65, 1.0); 
    float mistDistanceMask = clamp((viewDist - mistDist) * 0.02, 0.0, 1.0); 
    heightMistVisibility = mix(1.0, heightMistVisibility, mistDistanceMask);
    
    float visibility = distVisibility * mix(heightMistVisibility, 1.0, rainStrength);
    
    return mix(fogColor, finalRGB, clamp(visibility, 0.0, 1.0));
}

#endif
