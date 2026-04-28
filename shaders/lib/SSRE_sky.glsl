#ifndef SKY_INCLUDED
#define SKY_INCLUDED

vec3 getSkyGradient(vec3 vDir, vec3 vTimeFactors) {
    float up = vDir.y;
    float upMapped = smoothstep(-0.1, 0.8, up);
    
    float dayFactor = vTimeFactors.x;
    float sunsetFactor = vTimeFactors.y;
    float nightFactor = vTimeFactors.z;

    vec3 daySky = mix(vec3(0.4, 0.7, 1.0), vec3(0.01, 0.2, 0.7), upMapped);

    vec3 sunsetTop = vec3(0.15, 0.12, 0.25);
    vec3 sunsetMid = vec3(0.6, 0.2, 0.15);
    vec3 sunsetBottom = vec3(1.4, 0.4, 0.05);
    
    vec3 setSky = mix(sunsetBottom, sunsetMid, smoothstep(-0.1, 0.2, up));
    setSky = mix(setSky, sunsetTop, smoothstep(0.2, 0.7, up));

    vec3 nightSky = mix(vec3(0.01, 0.01, 0.03), vec3(0.002, 0.004, 0.01), upMapped);

    vec3 finalSky = mix(nightSky, setSky, sunsetFactor);
    finalSky = mix(finalSky, daySky, dayFactor);

    return finalSky;
}

vec3 getSunMoon(vec3 vDir, vec3 sunDir, vec3 vTimeFactors) {
    float sunAmount = max(dot(vDir, sunDir), 0.0);
    float moonAmount = max(dot(vDir, -sunDir), 0.0);

    float sunMask = pow(sunAmount, 450.0) * 10.0;
    float sunGlow = pow(sunAmount, 16.0) * mix(1.0, 4.0, vTimeFactors.y);
    vec3 sunCol = mix(vec3(1.0, 0.4, 0.1), vec3(1.0, 0.95, 0.8), vTimeFactors.x);
    
    float moonMask = pow(moonAmount, 300.0) * 3.0;
    vec3 moonCol = vec3(0.8, 0.9, 1.0);

    return (sunCol * (sunMask + sunGlow) * vTimeFactors.x) + 
           (sunCol * (sunMask + sunGlow) * vTimeFactors.y) +
           (moonCol * moonMask * vTimeFactors.z);
}

#endif
