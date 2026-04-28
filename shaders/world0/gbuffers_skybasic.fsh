#version 120

varying vec3 viewDir;
varying vec3 sunDir;

uniform float rainStrength;

float getMiePhase(float cosTheta, float g) {
    float g2 = g * g;
    float num = 1.0 - g2;
    float denom = pow(1.0 + g2 - 2.0 * g * cosTheta, 1.5);
    return (0.25 / 3.14159265) * (num / denom);
}

void main() {
    vec3 vDir = normalize(viewDir);
    vec3 sDir = normalize(sunDir);

    float sunH = clamp(sDir.y, -1.0, 1.0);
    float dayFactor = clamp(sunH * 4.0 + 0.2, 0.0, 1.0);
    float sunsetFactor = clamp(1.0 - abs(sunH * 5.0), 0.0, 1.0);
    
    vec3 dayZenith   = vec3(0.12, 0.28, 0.65);
    vec3 dayHorizon  = vec3(0.45, 0.65, 0.85);
    
    vec3 sunsetZenith  = vec3(0.15, 0.20, 0.40);
    vec3 sunsetHorizon = vec3(0.85, 0.35, 0.15);
    
    vec3 nightZenith   = vec3(0.01, 0.02, 0.05);
    vec3 nightHorizon  = vec3(0.02, 0.05, 0.12);

    vec3 zenith  = mix(nightZenith, mix(sunsetZenith, dayZenith, dayFactor), dayFactor + sunsetFactor);
    vec3 horizon = mix(nightHorizon, mix(sunsetHorizon, dayHorizon, dayFactor), dayFactor + sunsetFactor);

    float viewElev = clamp(vDir.y, 0.0, 1.0);
    float gradient = pow(1.0 - viewElev, 4.0); 
    vec3 sky = mix(zenith, horizon, gradient);

    float cosTheta = dot(vDir, sDir);
    if (sDir.y > -0.1) {
        float mie = getMiePhase(cosTheta, 0.85); 
        vec3 sunColor = mix(vec3(1.0, 0.4, 0.1), vec3(1.0, 0.9, 0.8), dayFactor);
        
        sky += sunColor * mie * 0.015 * (1.0 - viewElev * 0.5); 
    }

    vec3 rainSky = vec3(0.15, 0.18, 0.22);
    sky = mix(sky, rainSky, rainStrength);

    sky = 1.0 - exp(-1.5 * sky);

    gl_FragColor = vec4(sky, 1.0);
}
