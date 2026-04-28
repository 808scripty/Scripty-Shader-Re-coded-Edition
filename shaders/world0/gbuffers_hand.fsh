#version 120

#define HALF_LAMBERT
#define CLOUD_SHADOWS

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

float hash(vec2 p) { 
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise(vec2 x) {
    vec2 p = floor(x); vec2 f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(p), hash(p + vec2(1.0, 0.0)), f.x), mix(hash(p + vec2(0.0, 1.0)), hash(p + vec2(1.0, 1.0)), f.x), f.y);
}

float getCloudCoverage(vec2 pos, float time) {
    pos += time * vec2(0.015, 0.01);
    float n = noise(pos) * 0.6 + noise(pos * 2.0) * 0.4;
    return smoothstep(0.45, 0.75, n);
}

void main() {
    vec4 baseColor = texture2D(texture, texcoord) * glcolor;
    if (baseColor.a < 0.1) discard;
    
    baseColor.rgb *= (1.0 - rainStrength * 0.35); 

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
    
    vec3 moonlight = vec3(0.15, 0.2, 0.35) * vTimeFactors.z;
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

    finalRGB = 1.0 - exp(-finalRGB * 1.15);
    
    float currentFogDensity = mix(0.004, 0.015, rainStrength); 
    float effectiveDist = max(viewDist - 22.0, 0.0); 
    float distVisibility = exp(-effectiveDist * currentFogDensity);
    
    float heightMistVisibility = clamp((vWorldPos.y - 45.0) * 0.04, 0.65, 1.0); 
    float mistDistanceMask = clamp((viewDist - 14.0) * 0.02, 0.0, 1.0);
    heightMistVisibility = mix(1.0, heightMistVisibility, mistDistanceMask);
    
    float visibility = distVisibility * mix(heightMistVisibility, 1.0, rainStrength);
    
    vec3 mistyFogColorDay = vec3(0.5, 0.55, 0.6);
    vec3 mistyFogColorNight = vec3(0.02, 0.03, 0.05);
    vec3 mistyFogColor = mix(mistyFogColorNight, mistyFogColorDay, vTimeFactors.x + vTimeFactors.y * 0.5);
    
    vec3 dynamicFog = mix(fogColor, mistyFogColor, rainStrength);
    
    finalRGB = mix(dynamicFog, finalRGB, clamp(visibility, 0.0, 1.0));
    
    gl_FragData[0] = vec4(finalRGB, baseColor.a);
}
