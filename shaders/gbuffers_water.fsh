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

void main() {
    vec4 baseColor = texture2D(texture, texcoord) * glcolor;
    if (baseColor.a < 0.1) discard;

    vec3 lm = texture2D(lightmap, lightLevels.st).rgb;
    vec3 n = normalize(worldNormal);
    vec3 viewDir = normalize(cameraPosition - vWorldPos);

    vec3 waterBase = mix(vec3(0.0, 0.4, 0.5), vAmbCol * 0.8, 0.5);
    
    vec3 reflection = getWaterReflection(n, viewDir, vSunCol, vAmbCol, vTimeFactors.y);
    
    float specular = pow(max(0.0, dot(n, normalize(sunDir))), 64.0) * vTimeFactors.x;
    
    vec3 finalRGB = (baseColor.rgb * waterBase * lm) + reflection + (vSunCol * specular);

    finalRGB = 1.0 - exp(-finalRGB * 1.15);

    finalRGB = applySSREFog(finalRGB, vWorldPos, viewDist, rainStrength, fogColor, vTimeFactors, 32.0, 24.0);

    gl_FragData[0] = vec4(finalRGB, 0.7);
}
