#version 120

varying vec2 texcoord;
varying vec4 glcolor;
varying float viewDist;
varying vec3 vTimeFactors; 

uniform mat4 gbufferModelViewInverse; 
uniform vec3 sunPosition; 

void main() {
    gl_Position = ftransform();
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    glcolor = gl_Color;
    
    vec4 pos = gl_ModelViewMatrix * gl_Vertex;
    viewDist = length(pos.xyz);

    // Get time of day for the fragment shader
    vec3 sunDir = normalize(mat3(gbufferModelViewInverse) * sunPosition);
    float sunHeight = sunDir.y;
    float dayFactor = clamp(sunHeight * 8.0 + 0.1, 0.0, 1.0);
    float sunsetFactor = clamp(1.0 - abs(sunHeight * 5.0), 0.0, 1.0);
    float nightFactor = clamp(-sunHeight * 8.0 - 0.5, 0.0, 1.0);
    vTimeFactors = vec3(dayFactor, sunsetFactor, nightFactor);
}
