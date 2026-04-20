#version 120

uniform sampler2D texture;
uniform sampler2D lightmap;
uniform vec3 fogColor;
varying vec2 texcoord;
varying vec4 glcolor;
varying vec3 worldNormal;
varying vec3 sunDir;
varying float viewDist;
varying vec4 lightLevels;
varying float dayFactor;
varying float sunsetFactor;
varying float nightFactor;

#define DYNAMIC_SHADOWS 1

void main() {
    vec4 baseColor = texture2D(texture, texcoord) * glcolor;
    if (baseColor.a < 0.1) discard; // Kept for mobs

    vec3 n = normalize(worldNormal);
    vec3 l = sunDir; 

    vec3 sunLightColor = mix(vec3(1.0, 0.45, 0.1), vec3(1.0, 0.95, 0.8), dayFactor);
    vec3 ambientColor = mix(vec3(0.05, 0.06, 0.15), vec3(0.5, 0.6, 0.8), dayFactor);

    float shadow = 1.0;
    #if DYNAMIC_SHADOWS == 1
        shadow = smoothstep(-0.3, 0.6, dot(n, l));
    #else
        shadow = max(dot(n, l), 0.0) * 0.8 + 0.2;
    #endif

    vec3 moonlight = vec3(0.1, 0.15, 0.3) * nightFactor * clamp(n.y * 0.5 + 0.5, 0.5, 1.0);
    float goldenHour = sunsetFactor * 1.3;
    vec3 light = (shadow * sunLightColor * (dayFactor + goldenHour)) + (ambientColor * 0.6) + moonlight;
    
    vec3 lm = texture2D(lightmap, lightLevels.st).rgb;
    vec3 finalRGB = baseColor.rgb * light * lm;

    float fog = exp(-viewDist * 0.012);
    finalRGB = mix(fogColor, finalRGB, clamp(fog, 0.0, 1.0));

    gl_FragColor = vec4(finalRGB, baseColor.a);
}
