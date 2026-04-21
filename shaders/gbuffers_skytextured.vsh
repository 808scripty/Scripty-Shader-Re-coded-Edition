#version 120

varying vec4 glcolor;
varying float starFade;
uniform vec3 sunPosition;

void main() {
    gl_Position = ftransform();
    glcolor = gl_Color;
    
    // Normalize sun position and calculate fade based on negative Y (Night)
    vec3 sunDir = normalize(sunPosition);
    // Stars appear when sun is below -0.2 (Night)
    starFade = clamp(-sunDir.y * 10.0 - 1.0, 0.0, 1.0);
}
