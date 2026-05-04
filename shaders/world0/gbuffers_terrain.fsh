#version 120

#define HALF_LAMBERT
#define CLOUD_SHADOWS

#include "/lib/ssre_math.glsl"
#include "/lib/ssre_atmos.glsl"

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
uniform float frameTimeCounter;
uniform vec3 cameraPosition;

void main() {
    vec4 baseColor = texture2D(texture, texcoord) * glcolor;
    if (baseColor.a < 0.1) discard;

    baseColor.rgb *= (1.0 - rainStrength * 0.15);
    vec3 lm = texture2D(lightmap, lightLevels.st).rgb;
    vec3 n = normalize(worldNormal);
    vec3 l = normalize(sunDir);
    if (n.y > 0.8) {
        float nNoise = noise(vWorldPos.xz * 12.0) - 0.5;
        n = normalize(n + vec3(nNoise * 0.06, 0.0, nNoise * 0.06));
    }

    float lightmapAO = clamp(max(lm.r, lm.g) * 1.2, 0.2, 1.0);

    float diffuseL;
#ifdef HALF_LAMBERT
    float wrap = 0.4 + (rainStrength * 0.25);
    diffuseL = max(0.0, (dot(n, l) + wrap) / (1.0 + wrap));
#else
    diffuseL = max(0.0, dot(n, l));
#endif

    float sss = pow(max(dot(l, -n), 0.0), 3.0) * 0.25 * vTimeFactors.x;
   
    float cloudDensity = 0.0;
#ifdef CLOUD_SHADOWS
    cloudDensity = getCloudCoverage(vWorldPos.xz * 0.005, frameTimeCounter);
    cloudDensity *= smoothstep(0.6, 0.9, lightLevels.y);
#endif

    float shadowMult = mix(1.0, 0.35, cloudDensity * vTimeFactors.x);
    float shadow = ((diffuseL + sss) * 0.8 + 0.2) * lightmapAO * shadowMult;
    float goldenHour = vTimeFactors.y * 1.3;
    vec3 groundColor = vAmbCol * 0.25;
    float skyWeight = n.y * 0.5 + 0.5;
    vec3 hemiAmbient = mix(groundColor, vAmbCol, skyWeight);

    vec3 moonlight = vec3(0.35, 0.45, 0.65) * vTimeFactors.z;
    vec3 environmentLight = (shadow * vSunCol * (vTimeFactors.x + goldenHour));
    environmentLight += (hemiAmbient * 0.5);
    environmentLight += (moonlight * skyWeight * lightmapAO);

    float blockLight = clamp(lightLevels.x, 0.0, 1.0);
    float torchInfluence = clamp(blockLight * 4.0, 0.0, 1.0);
    float desatAmount = vTimeFactors.z * 0.45 * (1.0 - torchInfluence);
    float luminance = dot(baseColor.rgb, vec3(0.299, 0.587, 0.114));
    vec3 finalBase = mix(baseColor.rgb, vec3(luminance), desatAmount);
    vec3 finalRGB = finalBase * environmentLight * lm;

    vec3 torchColor = vec3(1.0, 0.55, 0.12);
    float torchGlow = pow(blockLight, 2.2) * 2.8;
    finalRGB += finalBase * torchColor * torchGlow;

    float b2 = blockLight * blockLight;
    float b4 = b2 * b2;
    float sourceEmission = b4 * b4 * b2;
    vec3 glowingTexture = baseColor.rgb * vec3(1.2, 1.1, 0.9);
    finalRGB = mix(finalRGB, glowingTexture, sourceEmission);

    if (rainStrength > 0.0) {
        vec3 viewDir = normalize(cameraPosition - vWorldPos);
        float fresnel = 1.17 - max(0.0, dot(n, viewDir));
        float specular = pow(max(0.0, dot(n, l)), 52.0);
        vec3 specGlow = vSunCol * shadowMult; 
        
        finalRGB += specGlow * specular * rainStrength * 0.5;
        finalRGB += specGlow * pow(fresnel, 1.17) * rainStrength * 0.75;
    }

    finalRGB = 1.0 - exp(-finalRGB * 1.15);
    
    finalRGB = applySSREFog(finalRGB, vWorldPos, viewDist, rainStrength, fogColor, vTimeFactors, 20.0, 14.0);
    
    gl_FragData[0] = vec4(finalRGB, baseColor.a);
}
