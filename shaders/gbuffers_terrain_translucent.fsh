#version 120

varying vec2 texcoord;
varying vec4 glcolor;
varying vec3 worldNormal;
varying vec3 sunDir;
varying float viewDist;
varying float dayFactor;
varying float sunsetFactor;
varying float nightFactor;

uniform sampler2D texture;
uniform vec3 fogColor;

#define DYNAMIC_SHADOWS 1

void main() {
    vec4 baseColor = texture2D(texture, texcoord) * glcolor;
    if (baseColor.a < 0.1) discard; 

    vec3 n = normalize(worldNormal);
    vec3 l = sunDir;

    vec3 sunLightColor = mix(vec3(1.0, 0.45, 0.1), vec3(1.0, 0.95, 0.8), dayFactor);
    vec3 ambientColor = mix(vec3(0.05, 0.06, 0.15), vec3(0.5, 0.6, 0.8), dayFactor);

    float shadow = 1.0;
    #if DYNAMIC_SHADOWS == 1
        shadow = smoothstep(-0.4, 0.6, dot(n, l));
        shadow *= clamp(n.y * 0.5 + 0.5, 0.3, 1.0);
    #else
        shadow = max(dot(n, l), 0.0) * 0.8 + 0.2;
    #endif

    vec3 moonlight = vec3(0.2, 0.25, 0.45) * nightFactor * clamp(n.y * 0.5 + 0.5, 0.3, 1.0);
    float goldenHour = sunsetFactor * 1.3;
    vec3 light = (shadow * sunLightColor * (dayFactor + goldenHour)) + (ambientColor * 0.45) + moonlight;

    float fog = exp(-viewDist * 0.012);
    vec3 finalRGB = mix(fogColor, baseColor.rgb * light, clamp(fog, 0.0, 1.0));

    gl_FragData[0] = vec4(finalRGB, baseColor.a);
}
