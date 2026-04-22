#version 120

varying vec3 viewDir;
varying vec3 sunDir;
varying vec3 vTimeFactors; 
uniform vec3 fogColor;
uniform float rainStrength;
uniform float frameTimeCounter;

#define PROCEDUL_STARS

void main() {
    vec3 vDir = normalize(viewDir);
    float up = vDir.y;
    float upMapped = smoothstep(-0.1, 0.8, up);

    float dayFactor = vTimeFactors.x;
    float sunsetFactor = vTimeFactors.y;
    float nightFactor = vTimeFactors.z;

    vec3 daySky = mix(vec3(0.55, 0.8, 1.0), vec3(0.05, 0.35, 0.85), upMapped);
    vec3 setSky = mix(mix(vec3(1.0, 0.3, 0.05), vec3(0.85, 0.4, 0.15), smoothstep(-0.1, 0.15, up)), 
                      mix(vec3(0.42, 0.22, 0.35), vec3(0.02, 0.08, 0.18), smoothstep(0.3, 0.8, up)), smoothstep(0.1, 0.4, up));
    vec3 nightSky = mix(vec3(0.02, 0.03, 0.08), vec3(0.005, 0.008, 0.02), upMapped);
    
    vec3 skyBase = mix(nightSky, setSky, sunsetFactor);
    skyBase = mix(skyBase, daySky, dayFactor);
    
    #ifdef PROCEDUL_STARS
    vec3 starCoord = floor(vDir * 350.0); 
    float starHash = fract(sin(dot(starCoord, vec3(12.9898, 78.233, 45.543))) * 43758.5453);

    float stars = smoothstep(0.995, 1.0, starHash) * nightFactor * clamp(up * 3.0, 0.0, 1.0);
    skyBase += vec3(stars) * (1.0 - rainStrength);
    #endif
    float horizon = clamp(1.0 - abs(up + 0.05), 0.0, 1.0);
    horizon = pow(horizon, 4.0) * (dayFactor + sunsetFactor * 1.5 + nightFactor * 0.2);
    vec3 hazeCol = mix(mix(vec3(0.2, 0.3, 0.5), vec3(1.0, 0.4, 0.1), sunsetFactor), vec3(0.7, 0.85, 1.0), dayFactor);
    skyBase += hazeCol * horizon * 0.5;
    
    vec3 finalSky = mix(fogColor, skyBase, smoothstep(-0.2, 0.1, up));

    float distToSun = distance(vDir, sunDir);
    float sunMask = pow(clamp(1.0 - distToSun, 0.0, 1.0), 300.0);
    float sunGlow = pow(clamp(1.0 - distToSun, 0.0, 1.0), 12.0);
    vec3 sunCol = mix(vec3(1.0, 0.4, 0.1), vec3(1.0, 0.98, 0.95), dayFactor);
    finalSky += sunCol * (sunMask * 3.0 + sunGlow * (1.0 + sunsetFactor * 2.0)) * dayFactor * (1.0 - rainStrength);

    vec3 moonDir = -sunDir; 
    float distToMoon = distance(vDir, moonDir);
    float moonMask = pow(clamp(1.0 - distToMoon, 0.0, 1.0), 120.0);
    float moonGlow = pow(clamp(1.0 - distToMoon, 0.0, 1.0), 8.0);
    vec3 moonCol = vec3(0.85, 0.92, 1.0);
    finalSky += moonCol * (moonMask * 2.5 + moonGlow * 0.5) * nightFactor * (1.0 - rainStrength);

    float timeBrightness = dayFactor + sunsetFactor * 0.5;
    vec3 overcastDay = vec3(0.4, 0.4, 0.4);
    vec3 overcastNight = vec3(0.02, 0.03, 0.05); 
    vec3 overcastSky = mix(overcastNight, overcastDay, timeBrightness);
    finalSky = mix(finalSky, overcastSky, rainStrength);

    gl_FragColor = vec4(finalSky, 1.0);
}
