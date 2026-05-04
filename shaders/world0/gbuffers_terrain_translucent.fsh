#version 120

#include "/lib/ssre_math.glsl"
#include "/lib/ssre_atmos.glsl"
#include "/lib/ssre_water.glsl"

varying vec2 texcoord;
varying vec4 glcolor;
varying vec3 worldNormal;
varying vec3 sunDir;
varying float viewDist;
varying vec4 lightLevels;
varying vec3 vTimeFactors;
varying vec3 vSunCol;
varying vec3 vAmbCol;
varying vec3 vWorldPos; 

uniform sampler2D texture;
uniform sampler2D lightmap;
uniform vec3 fogColor;
uniform float rainStrength;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;

void main() {
    vec4 baseColor = texture2D(texture, texcoord) * glcolor;
    if (baseColor.a < 0.1) discard;

    vec3 lm = texture2D(lightmap, lightLevels.st).rgb;
    vec3 n = normalize(worldNormal);
    
    if (n.y > 0.8) {
        n = getWaterNormal(vWorldPos, frameTimeCounter);
    }

    vec3 viewDir = normalize(cameraPosition - vWorldPos);
    
    vec3 waterDeep = vec3(0.08, 0.16, 0.26); 
    vec3 waterShallow = vec3(0.18, 0.35, 0.38); 
    
    float viewAngle = max(dot(n, viewDir), 0.0);
    
    float colorMix = sqrt(viewAngle); 
    
    vec3 waterBase = mix(waterDeep, waterShallow, colorMix) * (vAmbCol * 1.5);
    vec3 reflection = getWaterReflection(n, viewDir, vSunCol, vAmbCol, vTimeFactors.y);
    
    float specBase = max(0.0, dot(n, normalize(sunDir)));
    specBase *= specBase; 
    specBase *= specBase; 
    specBase *= specBase; 
    float specular = specBase * specBase * specBase * specBase * vTimeFactors.x * 3.5; 

    vec3 finalRGB = (baseColor.rgb * 0.1 + waterBase * lm) + reflection + (vSunCol * specular);
    finalRGB = 1.0 - exp(-finalRGB * 1.15);

    finalRGB = applySSREFog(finalRGB, vWorldPos, viewDist, rainStrength, fogColor, vTimeFactors, 32.0, 24.0);
    
    float finalAlpha = (worldNormal.y > 0.8) ? mix(0.9, 0.35, viewAngle) : 0.7;
    
    gl_FragData[0] = vec4(finalRGB, finalAlpha);
}
