#version 120

varying vec2 texcoord;
varying vec4 glcolor;
varying float viewDist;
varying vec3 vTimeFactors; 

uniform sampler2D texture;
uniform float rainStrength;
uniform vec3 fogColor;

void main() {
    vec4 baseColor = texture2D(texture, texcoord) * glcolor;
    if (baseColor.a < 0.1) discard;

    float luminance = dot(baseColor.rgb, vec3(0.299, 0.587, 0.114));
    

    float timeBrightness = vTimeFactors.x + vTimeFactors.y * 0.5;
    float rainDarkness = clamp(timeBrightness + 0.05, 0.0, 1.0); 
    vec3 grayRain = vec3(luminance) * 0.8 * rainDarkness; 

    float currentFogDensity = mix(0.012, 0.05, rainStrength);
    float fog = exp(-viewDist * currentFogDensity);
    
    vec3 mistyFogColorDay = vec3(0.4, 0.45, 0.5);
    vec3 mistyFogColorNight = vec3(0.02, 0.03, 0.05);
    vec3 mistyFogColor = mix(mistyFogColorNight, mistyFogColorDay, timeBrightness);

    vec3 dynamicFog = mix(fogColor, mistyFogColor, rainStrength);
    
    vec3 finalRGB = mix(dynamicFog, grayRain, clamp(fog, 0.0, 1.0));
    gl_FragData[0] = vec4(finalRGB, baseColor.a);
}
