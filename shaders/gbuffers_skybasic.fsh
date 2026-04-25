#version 120

varying vec3 viewDir;
varying vec3 sunDir;
varying vec3 vTimeFactors;

uniform float rainStrength;

void main() {
    vec3 vDir = normalize(viewDir);
    float up = vDir.y;
    float upMapped = smoothstep(-0.2, 1.0, up);

    float day = vTimeFactors.x;
    float sunset = vTimeFactors.y;
    float night = vTimeFactors.z;

    //  Sky Gradients
    // Blends colors based on the sunset factor
    vec3 skyTop = mix(vec3(0.1, 0.2, 0.6), vec3(0.2, 0.1, 0.4), sunset);
    vec3 skyMid = mix(vec3(0.5, 0.7, 0.9), vec3(0.9, 0.4, 0.2), sunset);
    vec3 skyBottom = mix(vec3(0.8, 0.9, 1.0), vec3(1.0, 0.3, 0.1), sunset);

    // Construct the vertical sky gradient
    vec3 sky = mix(skyMid, skyTop, upMapped);
    sky = mix(skyBottom, sky, smoothstep(0.0, 0.3, up));

    //  Night &  Rain integration
    vec3 nightSky = vec3(0.01, 0.02, 0.05);
    sky = mix(nightSky, sky, day + sunset);
    sky = mix(sky, vec3(0.2, 0.2, 0.25), rainStrength);

    //  Horizon Haze
    // Adds that warm glow near the horizon during sunset
    float horizon = pow(1.0 - max(up, 0.0), 3.0);
    sky += vec3(1.0, 0.5, 0.3) * horizon * sunset * 0.6;

    gl_FragColor = vec4(sky, 1.0);
}
