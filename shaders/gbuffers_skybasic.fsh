#version 120

varying vec3 viewDir;
varying vec3 sunDir;
uniform vec3 fogColor;

void main() {
    float sunHeight = sunDir.y;
    float dayFactor = clamp(sunHeight * 8.0 + 0.1, 0.0, 1.0); 
    float sunsetFactor = clamp(1.0 - abs(sunHeight * 5.0), 0.0, 1.0); 
    float nightFactor = clamp(-sunHeight * 8.0 - 0.5, 0.0, 1.0); 

    vec3 vDir = normalize(viewDir);
    float up = vDir.y;
    float upMapped = smoothstep(-0.1, 0.8, up);

   
    vec3 daySky = mix(vec3(0.55, 0.8, 1.0), vec3(0.05, 0.35, 0.85), upMapped);
    vec3 setSky = mix(mix(vec3(1.0, 0.2, 0.02), vec3(0.85, 0.4, 0.15), smoothstep(-0.1, 0.15, up)), 
                  mix(vec3(0.42, 0.22, 0.35), vec3(0.02, 0.08, 0.18), smoothstep(0.3, 0.8, up)), 
                  smoothstep(0.1, 0.4, up));
    vec3 nightSky = mix(vec3(0.02, 0.03, 0.06), vec3(0.005, 0.008, 0.02), upMapped);

    vec3 skyBase = mix(nightSky, setSky, sunsetFactor);
    skyBase = mix(skyBase, daySky, dayFactor);
    vec3 finalSky = mix(fogColor, skyBase, smoothstep(-0.2, 0.1, up));

    // SUN
    float distToSun = distance(vDir, sunDir);
    float sunMask = pow(clamp(1.0 - distToSun, 0.0, 1.0), 300.0);
    float sunGlow = pow(clamp(1.0 - distToSun, 0.0, 1.0), 10.0); 
    vec3 sunCol = mix(vec3(1.0, 0.5, 0.15), vec3(1.0, 0.98, 0.95), dayFactor);
    finalSky += sunCol * (sunMask * 3.0 + sunGlow * (1.0 + sunsetFactor * 1.5)) * dayFactor;

    vec3 moonDir = -sunDir; 
    float distToMoon = distance(vDir, moonDir);
   
    float moonMask = pow(clamp(1.0 - distToMoon, 0.0, 1.0), 120.0); 
    float moonGlow = pow(clamp(1.0 - distToMoon, 0.0, 1.0), 8.0);
    
    vec3 moonCol = vec3(0.85, 0.92, 1.0);
    finalSky += moonCol * (moonMask * 2.5) * nightFactor;   
    finalSky += moonCol * (moonGlow * 0.4) * nightFactor;     
    gl_FragColor = vec4(finalSky, 1.0);
}
