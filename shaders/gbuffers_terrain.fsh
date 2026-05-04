#version 120

#define FOGTYPE 1 //[0 1 2]
#define CHUNK_FADE
#define HALF_LAMBERT
#define CLOUD_SHADOWS
#define SUN_SSS

#include "/lib/ssre_math.glsl"
#include "/lib/ssre_atmos.glsl"
#include "/lib/ssre_color.glsl"

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
uniform float far; 
uniform vec3 cameraPosition;

void main() {
    vec4 baseColor = texture2D(texture, texcoord) * glcolor;
    if (baseColor.a < 0.1) discard;

    baseColor.rgb *= (1.0 - rainStrength * 0.15);
    vec3 lm = texture2D(lightmap, lightLevels.st).rgb;
    vec3 n = normalize(worldNormal);
    vec3 l = normalize(sunDir);
    
    float lightmapAO = clamp(max(lm.r, lm.g) * 1.2, 0.2, 1.0);
    float diffuseL;

#ifdef HALF_LAMBERT
    float wrap = 0.4 + (rainStrength * 0.25);
    diffuseL = max(0.0, (dot(n, l) + wrap) / (1.0 + wrap));
#else
    diffuseL = max(0.0, dot(n, l));
#endif

    float sss = 0.0;
    vec3 viewDir = normalize(cameraPosition - vWorldPos);

#ifdef SUN_SSS
    float viewDotSun = max(0.0, dot(-viewDir, l)); 
    float rimLight = 1.0 - max(0.0, dot(n, viewDir));
    rimLight = fastPow4(rimLight); 
    float shimmer = fastPow14(viewDotSun) * 3.5 * rimLight; 
    float sssWrap = max(0.0, dot(l, -n) * 0.6 + 0.4); 
    sss = (fastPow3(max(dot(l, -n), 0.0)) * 0.25 + (shimmer * sssWrap)) * (vTimeFactors.x + vTimeFactors.y * 1.2);
#endif
   
    float cloudDensity = 0.0;
#ifdef CLOUD_SHADOWS
    cloudDensity = getCloudCoverage(vWorldPos.xz * 0.005, frameTimeCounter);
    cloudDensity *= smoothstep(0.6, 0.9, lightLevels.y);
#endif

    float shadowMult = mix(1.0, 0.35, cloudDensity * vTimeFactors.x);
    float shadow = ((diffuseL + sss) * 0.8 + 0.2) * lightmapAO * shadowMult;
    float goldenHour = vTimeFactors.y * 1.3;
    
    vec3 groundBase = vec3(0.25, 0.40, 0.15); 
    vec3 bounceGround = groundBase * (vSunCol * vTimeFactors.x + vAmbCol);
    vec3 bounceSky = vAmbCol * 1.5; 
    vec3 bounceSide = mix(bounceGround, vAmbCol, 0.5);

    float faceUp   = max(n.y, 0.0);
    float faceDown = max(-n.y, 0.0);
    float faceSide = 1.0 - abs(n.y);

    vec3 fakeGI = (faceUp * bounceSky * 0.4) + 
                  (faceDown * bounceGround * 0.5) + 
                  (faceSide * bounceSide * 0.3);

    float giStrength = mix(0.7, 0.2, vTimeFactors.z); 
    float giMask = smoothstep(0.0, 0.9, lightLevels.y) * giStrength;

    vec3 groundColor = vAmbCol * 0.25;
    float skyWeight = n.y * 0.5 + 0.5;
    vec3 hemiAmbient = mix(groundColor, vAmbCol, skyWeight);

    hemiAmbient += (fakeGI * giMask);

    vec3 fogDay = vec3(0.50, 0.65, 0.85); 
    vec3 fogSunset = vec3(0.29, 0.25, 0.40); 
    vec3 fogNight  = vec3(0.02, 0.04, 0.01); 

    vec3 dynamicFog = (fogDay    * vTimeFactors.x) + 
                      (fogSunset * vTimeFactors.y) + 
                      (fogNight  * vTimeFactors.z);

    dynamicFog = mix(dynamicFog, vec3(0.2, 0.2, 0.25), rainStrength);

    vec3 moonlight = vec3(0.35, 0.45, 0.65) * vTimeFactors.z;
    vec3 environmentLight = (shadow * vSunCol * (vTimeFactors.x + goldenHour));
    
    environmentLight += hemiAmbient * 0.5; 
    environmentLight += (moonlight * skyWeight * lightmapAO);
    
    float blockLight = clamp(lightLevels.x, 0.0, 1.0);
    float torchInfluence = clamp(blockLight * 4.0, 0.0, 1.0);
    float desatAmount = vTimeFactors.z * 0.45 * (1.0 - torchInfluence);
    float luminance = dot(baseColor.rgb, vec3(0.299, 0.587, 0.114));
    vec3 finalBase = mix(baseColor.rgb, vec3(luminance), desatAmount);

    vec3 finalRGB = finalBase * environmentLight * lm;
    
    vec3 torchColor = vec3(1.0, 0.55, 0.12);
    float torchGlow = (blockLight * blockLight) * 2.8; 
    finalRGB += finalBase * torchColor * torchGlow;

    float b2 = blockLight * blockLight;
    float b4 = b2 * b2;
    float sourceEmission = b4 * b4 * b2;
    vec3 glowingTexture = baseColor.rgb * vec3(1.2, 1.1, 0.9);
    finalRGB = mix(finalRGB, glowingTexture, sourceEmission);

    if (rainStrength > 0.0) {
        float fresnel = 1.17 - max(0.0, dot(n, viewDir));  
        float specular = fastPow52(max(0.0, dot(n, l)));
        vec3 specGlow = vSunCol * shadowMult; 
        finalRGB += specGlow * specular * rainStrength * 0.5;
        finalRGB += specGlow * (fresnel * fresnel) * rainStrength * 0.75;
    }

    finalRGB = colorGrading(finalRGB, mix(0.8, 0.8, vTimeFactors.z), mix(0.96, 0.7, vTimeFactors.z));
    
#if FOGTYPE > 0
    float distFalloff = smoothstep(160.0, 45.0, viewDist);
    finalRGB *= mix(0.3, 1.0, distFalloff); 

    float fogDensity = 22.0 - (rainStrength * 12.0);
    float distanceFactor = clamp(viewDist / 128.0, 0.0, 1.0);
    vec3 blueShift = vec3(0.05, 0.1, 0.25) * distanceFactor * vTimeFactors.x;
    vec3 finalFogColor = mix(dynamicFog, dynamicFog + blueShift, distanceFactor);

    #if FOGTYPE == 1
        float simpleFog = clamp(viewDist / 180.0, 0.0, 1.0) * clamp(1.0 - (vWorldPos.y - cameraPosition.y + 5.0) * 0.05, 0.3, 0.9);
        finalRGB = mix(finalRGB, finalFogColor, simpleFog);
    #elif FOGTYPE == 2
        finalRGB = applySSREFog(finalRGB, vWorldPos, viewDist, rainStrength, finalFogColor, vTimeFactors, fogDensity, 12.0);
    #endif
#endif

    float finalAlpha = baseColor.a;
    #ifdef CHUNK_FADE
        float chunkFade = clamp((viewDist - far * 0.7) / (far * 0.25), 0.0, 1.0);
        finalAlpha *= (1.0 - chunkFade);
        if (finalAlpha < 0.05) discard;
    #endif
    
    finalRGB = ACESFilm(finalRGB);
    
    gl_FragData[0] = vec4(finalRGB, finalAlpha);
}
