#version 120

#include "/lib/ssre_math.glsl"
#include "/lib/ssre_atmos.glsl"
#include "/lib/ssre_water.glsl"
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
    vec3 sDir = normalize(sunDir);
    
    float sunH = clamp(sDir.y, -1.0, 1.0);
    float skyDayFactor = clamp(sunH * 4.0 + 0.2, 0.0, 1.0);
    float skySunsetFactor = clamp(1.0 - abs(sunH * 5.0), 0.0, 1.0);

    vec3 dayZenith   = vec3(0.30, 0.29, 0.20);
    vec3 dayHorizon  = vec3(0.45, 0.65, 0.85);
    vec3 sunsetZenith  = vec3(0.25, 0.20, 0.30);
    vec3 sunsetHorizon = vec3(0.75, 0.35, 0.15);
    vec3 nightZenith   = vec3(0.01, 0.02, 0.05);
    vec3 nightHorizon  = vec3(0.02, 0.05, 0.12);

    vec3 zenith  = mix(nightZenith, mix(sunsetZenith, dayZenith, skyDayFactor), skyDayFactor + skySunsetFactor);
    vec3 horizon = mix(nightHorizon, mix(sunsetHorizon, dayHorizon, skyDayFactor), skyDayFactor + skySunsetFactor);

    vec3 refDir = reflect(-viewDir, n);
    float refElev = clamp(refDir.y, 0.0, 1.0);
    float skyGradient = pow(1.0 - refElev, 4.0); 
    vec3 fakeSky = mix(zenith, horizon, skyGradient);
    
    float cosTheta = dot(refDir, sDir);
    if (sDir.y > -0.1) {
        float g2 = 0.7225;
        float num = 0.2775;
        float denom = pow(1.0 + g2 - 1.7 * cosTheta, 1.5);
        float mie = (0.079577) * (num / denom); 
        vec3 sunColor = mix(vec3(1.0, 0.4, 0.1), vec3(1.0, 0.9, 0.8), skyDayFactor);
        fakeSky += sunColor * mie * 0.015 * (1.0 - refElev * 0.5);
    }

    float viewAngle = max(dot(n, viewDir), 0.0);
    float fRange = 1.0 - viewAngle;
    float fresnel = pow(fRange, 5.0); 
    float reflectionStrength = mix(0.1, 0.4, fresnel); 

    vec3 halfVector = normalize(sDir + viewDir);
    float NdotH = max(0.0, dot(n, halfVector));
    float sunSpecular = pow(NdotH, 128.0) * vTimeFactors.x; 
    vec3 sunFinal = vSunCol * sunSpecular * 15.0; 

    vec3 waterSurface = fakeSky * reflectionStrength; 
    vec3 waterBody = (baseColor.rgb * 0.1) * lm;
    
    vec3 finalRGB = waterBody + waterSurface + sunFinal;
    
    vec3 fogDay = vec3(0.50, 0.65, 0.85); 
    vec3 fogSunset = vec3(0.29, 0.25, 0.40); 
    vec3 fogNight  = vec3(0.02, 0.04, 0.01); 

    vec3 dynamicFog = (fogDay * vTimeFactors.x) + (fogSunset * vTimeFactors.y) + (fogNight * vTimeFactors.z);
    dynamicFog = mix(dynamicFog, vec3(0.2, 0.2, 0.25), rainStrength);

    float fogDensity = 50.0 - (vTimeFactors.y * 8.0) - (rainStrength * 12.0);
    float distanceFactor = clamp(viewDist / 128.0, 0.0, 1.0);
    vec3 blueShift = vec3(0.05, 0.1, 0.25) * distanceFactor * vTimeFactors.x;
    vec3 finalFogColor = mix(dynamicFog, dynamicFog + blueShift, distanceFactor);

    finalRGB = applySSREFog(finalRGB, vWorldPos, viewDist, rainStrength, finalFogColor, vTimeFactors, fogDensity, 12.0);
    finalRGB = ACESFilm(finalRGB);
    finalRGB = pow(max(finalRGB, vec3(0.0)), vec3(1.0)); 
    
    float waterAlpha = 0.60;
    float finalAlpha = clamp(waterAlpha + sunSpecular, 0.0, 1.0);

    gl_FragData[0] = vec4(finalRGB, finalAlpha); 
}
