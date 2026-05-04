#version 120

varying vec3 viewDir;
varying vec3 sunDir;

uniform mat4 gbufferModelViewInverse;
uniform vec3 sunPosition;

void main() {
    gl_Position = ftransform();
    vec4 pos = gl_ModelViewMatrix * gl_Vertex;
    
    viewDir = (gbufferModelViewInverse * pos).xyz;
    
    sunDir = normalize(mat3(gbufferModelViewInverse) * sunPosition);
}
