#ifndef SSRE_LIGHTING_INCLUDED
 #define SSRE_LIGHTING_INCLUDED

void applyTorchAndEmission(inout vec3 finalRGB, vec3 baseColor, float blockLight) {
    vec3 torchColor = vec3(1.0, 0.55, 0.12);
    float torchGlow = pow(blockLight, 2.2) * 2.8;
    finalRGB += baseColor * torchColor * torchGlow;

    float b2 = blockLight * blockLight;
    float b4 = b2 * b2;
    float sourceEmission = b4 * b4 * b2; 
    
    vec3 glowingTexture = baseColor * vec3(1.2, 1.1, 0.9);
    finalRGB = mix(finalRGB, glowingTexture, sourceEmission);
}


vec3 getTimeFactors(float sunHeight) {
    float dayFactor = clamp(sunHeight * 8.0 + 0.1, 0.0, 1.0);
    float sunsetFactor = clamp(1.0 - abs(sunHeight * 5.0), 0.0, 1.0);
    float nightFactor = clamp(-sunHeight * 8.0 - 0.5, 0.0, 1.0);
    return vec3(dayFactor, sunsetFactor, nightFactor);
}

#endif
