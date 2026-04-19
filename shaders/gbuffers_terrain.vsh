#version 120

varying vec2 texcoord;
varying vec4 glcolor;
varying vec3 worldNormal;
varying vec3 sunDir;
varying float viewDist;
varying float dayFactor;
varying float sunsetFactor;
varying float nightFactor;

uniform mat4 gbufferModelViewInverse;
uniform vec3 sunPosition;

void main() {
    gl_Position = ftransform();
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    glcolor = gl_Color;
    worldNormal = mat3(gbufferModelViewInverse) * (gl_NormalMatrix * gl_Normal);
    sunDir = normalize(mat3(gbufferModelViewInverse) * sunPosition);
    
   
    float sunHeight = sunDir.y;
    dayFactor = clamp(sunHeight * 8.0 + 0.1, 0.0, 1.0);
    sunsetFactor = clamp(1.0 - abs(sunHeight * 5.0), 0.0, 1.0);
    nightFactor = clamp(-sunHeight * 8.0 - 0.5, 0.0, 1.0);

    vec4 pos = gl_ModelViewMatrix * gl_Vertex;
    viewDist = length(pos.xyz);
}
