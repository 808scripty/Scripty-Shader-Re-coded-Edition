#version 120

varying vec4 glcolor;
varying float starFade;
uniform vec3 sunPosition;

void main() {
    gl_Position = ftransform();
    glcolor = gl_Color;
    
    // based on nega y
    vec3 sunDir = normalize(sunPosition);
    starFade = clamp(-sunDir.y * 10.0 - 1.0, 0.0, 1.0);
}
