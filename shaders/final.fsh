#version 120

#include "/lib/ssre_math.glsl"
#include "/lib/ssre_color.glsl"

varying vec2 texcoord;

uniform sampler2D colortex0;
uniform sampler2D depthtex0; 
uniform float frameTimeCounter;

uniform float viewWidth;  
uniform float viewHeight;

uniform vec3 sunPosition;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;

#define GRAIN 
#define GRAIN_STRENGTH 0.025 // [0.000 0.050]

#define BLOOM // Toggle for Pseudo-Bloom
#define BLOOM_THRESHOLD 0.65 // [0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define BLOOM_STRENGTH 0.20  // [0.10 0.20 0.30 0.40 0.50]
#define BLOOM_RADIUS 5.0     // [0.1 0.2 0.3 0.4 0.5]
#define DITHERING

#define SUNGLOW 
#define SUNGLOW_STRENGTH 2.5 

vec3 getBloom(vec2 uv) {
    vec2 texel = vec2(1.0 / viewWidth, 1.0 / viewHeight) * BLOOM_RADIUS;
    vec3 bloom = vec3(0.0);

    vec2 offsets[5] = vec2[](
        vec2(0.0, 0.0),
        vec2(1.5, 1.5), vec2(-1.5, -1.5),
        vec2(1.5, -1.5), vec2(-1.5, 1.5)
    );
    float weights[5] = float[](0.35, 0.1625, 0.1625, 0.1625, 0.1625);
    for(int i = 0; i < 5; i++) {
        vec3 color = texture2D(colortex0, uv + offsets[i] * texel).rgb;
        float luma = dot(color, vec3(0.299, 0.587, 0.114));
        float mask = smoothstep(BLOOM_THRESHOLD - 0.1, BLOOM_THRESHOLD + 0.1, luma);
        bloom += (color * mask) * weights[i];
    }
    return bloom;
}

#ifdef SUNGLOW
float getMiePhase(float cosTheta, float g) {
    float g2 = g * g;
    float num = 1.0 - g2;
    float denom = pow(1.0 + g2 - 2.0 * g * cosTheta, 1.5);
    return (0.25 / 3.14159265) * (num / denom);
}

vec3 getScreenSunGlow(vec2 uv) {
    vec4 sunClip = gbufferProjection * vec4(sunPosition, 1.0);
    vec2 sunScreen = (sunClip.xy / sunClip.w) * 0.5 + 0.5;

    float sunVisibility = 0.0;
    
    if (sunClip.w > 0.0 && sunScreen.x > 0.0 && sunScreen.x < 1.0 && sunScreen.y > 0.0 && sunScreen.y < 1.0) {
        vec2 texel = vec2(1.0 / viewWidth, 1.0 / viewHeight) * 1.5;
        
        sunVisibility += step(0.9999, texture2D(depthtex0, sunScreen).r) * 0.50;
        sunVisibility += step(0.9999, texture2D(depthtex0, sunScreen + vec2( texel.x,  texel.y)).r) * 0.125;
        sunVisibility += step(0.9999, texture2D(depthtex0, sunScreen + vec2(-texel.x,  texel.y)).r) * 0.125;
        sunVisibility += step(0.9999, texture2D(depthtex0, sunScreen + vec2( texel.x, -texel.y)).r) * 0.125;
        sunVisibility += step(0.9999, texture2D(depthtex0, sunScreen + vec2(-texel.x, -texel.y)).r) * 0.125;
    }

    if (sunVisibility <= 0.0) return vec3(0.0);

    vec4 clipPos = vec4(uv * 2.0 - 1.0, 1.0, 1.0);
    vec4 viewPos = gbufferProjectionInverse * clipPos;
    vec3 viewDir = normalize(viewPos.xyz);
    vec3 sDir = normalize(sunPosition);
    
    vec3 worldViewDir = normalize(mat3(gbufferModelViewInverse) * viewDir);
    float cosTheta = dot(viewDir, sDir);

    vec3 worldSunDir = normalize(mat3(gbufferModelViewInverse) * sDir);
    float sunH = clamp(worldSunDir.y, -1.0, 1.0);
    
    float sunColorFactor = clamp(sunH * 2.0 - 0.1, 0.0, 1.0);
    float sunFade = smoothstep(-0.0990, 0.1, worldSunDir.y);

    vec3 sunColor = mix(vec3(1.0, 0.35, 0.05), vec3(1.0, 0.9, 0.8), sunColorFactor);

    float sunElev = clamp(worldSunDir.y, 0.0, 1.0);
    float horizonFog = pow(1.0 - sunElev, 3.0); 
    float fogVisibility = 1.0 - horizonFog;     

    float core  = getMiePhase(cosTheta, 0.995) * 2.5;
    float inner = getMiePhase(cosTheta, 0.950) * 0.7;
    float outer = getMiePhase(cosTheta, 0.850) * 0.15;

    return sunColor * (core + inner + outer) * sunFade * sunVisibility * fogVisibility * SUNGLOW_STRENGTH;
}
#endif

vec3 OverallTM(vec3 color) {
    color *= 1.15;
    color = ACESFilm(color);
    float contrastAmount = 1.12;
    color = pow(color, vec3(contrastAmount));

    float luminance = dot(color, vec3(0.299, 0.587, 0.114));
    float saturationAmount = 1.25;
    color = mix(vec3(luminance), color, saturationAmount);
    
    vec3 shadowTint = vec3(0.92, 0.96, 1.05);
    vec3 highlightTint = vec3(1.05, 1.02, 0.95);
    vec3 appliedTint = mix(shadowTint, highlightTint, clamp(luminance * 1.5, 0.0, 1.0));
    color *= appliedTint;

    return color;
}

vec3 applyDither(vec3 color, vec2 uv) {
    float dither[64] = float[64](
         0.0, 32.0,  8.0, 40.0,  2.0, 34.0, 10.0, 42.0,
        48.0, 16.0, 56.0, 24.0, 50.0, 18.0, 58.0, 26.0,
        12.0, 44.0,  4.0, 36.0, 14.0, 46.0,  6.0, 38.0,
        60.0, 28.0, 52.0, 20.0, 62.0, 30.0, 54.0, 22.0,
         3.0, 35.0, 11.0, 43.0, 
         1.0, 33.0,  9.0, 41.0,
        51.0, 19.0, 59.0, 27.0, 49.0, 17.0, 57.0, 25.0,
        15.0, 47.0,  7.0, 39.0, 13.0, 45.0,  5.0, 37.0,
        63.0, 31.0, 55.0, 23.0, 61.0, 29.0, 53.0, 21.0
    );
    int x = int(mod(uv.x * viewWidth, 8.0));
    int y = int(mod(uv.y * viewHeight, 8.0));
    
    float limit = (dither[x + y * 8] + 0.5) / 64.0;
    return color + (limit - 0.5) / 255.0;
}

void main() {
    vec3 sceneColor = texture2D(colortex0, texcoord).rgb;

#ifdef BLOOM
    vec3 bloomColor = getBloom(texcoord);
    sceneColor += bloomColor * BLOOM_STRENGTH;
#endif

#ifdef SUNGLOW
    sceneColor += getScreenSunGlow(texcoord);
#endif

    vec3 gradedColor = OverallTM(sceneColor);

#ifdef GRAIN
    float noise = hash(texcoord + fract(frameTimeCounter));
    gradedColor += (noise - 0.5) * GRAIN_STRENGTH;
#endif

    float distToCenter = distance(texcoord, vec2(0.5));
    float vignette = smoothstep(0.85, 0.3, distToCenter);
    gradedColor *= vignette;

#ifdef DITHERING
    gradedColor = applyDither(gradedColor, texcoord);
#endif

    gl_FragData[0] = vec4(gradedColor, 1.0);
}
