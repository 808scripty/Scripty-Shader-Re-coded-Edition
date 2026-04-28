#version 120

varying vec2 texcoord;
varying vec4 glcolor;
varying vec3 worldNormal;
varying vec3 sunDir;
varying float viewDist;
varying vec4 lightLevels;
varying vec3 vTimeFactors; 
varying vec3 vSunCol;
varying vec3 vAmbCol;
varying vec3 vWorldPos; 

uniform mat4 gbufferModelViewInverse;
uniform vec3 sunPosition;
uniform vec3 cameraPosition; 
uniform float frameTimeCounter;
uniform float rainStrength;

#include "/lib/ssre_water.glsl"

void main() {
    vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
    vWorldPos = (gbufferModelViewInverse * viewPos).xyz + cameraPosition;
    vec4 localPos = gl_Vertex;

    if (gl_Normal.y > 0.8) {
        localPos.xyz += getWaterWaves(vWorldPos, frameTimeCounter);
        viewPos = gl_ModelViewMatrix * localPos;
    }

    gl_Position = gl_ProjectionMatrix * viewPos;
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    glcolor = gl_Color;
    lightLevels = gl_TextureMatrix[1] * gl_MultiTexCoord1;

    worldNormal = mat3(gbufferModelViewInverse) * (gl_NormalMatrix * gl_Normal);
    sunDir = normalize(mat3(gbufferModelViewInverse) * sunPosition);

    float sunHeight = sunDir.y;
    float dayFactor = clamp(sunHeight * 8.0 + 0.1, 0.0, 1.0);
    float sunsetFactor = clamp(1.0 - abs(sunHeight * 5.0), 0.0, 1.0);
    float nightFactor = clamp(-sunHeight * 8.0 - 0.5, 0.0, 1.0);
    vTimeFactors = vec3(dayFactor, sunsetFactor, nightFactor);

    // Syncing colors with gbuffers_terrain
    vec3 daySun = vec3(1.0, 0.95, 0.85);
    vec3 setSun = vec3(1.0, 0.45, 0.1);
    vec3 dayAmb = vec3(0.5, 0.6, 0.8);
    vec3 setAmb = vec3(0.4, 0.25, 0.2);
    vec3 blueAmb = vec3(0.15, 0.20, 0.30);

    vSunCol = mix(setSun, daySun, dayFactor);
    vAmbCol = mix(blueAmb, mix(setAmb, dayAmb, dayFactor), dayFactor + sunsetFactor);

    viewDist = length(viewPos.xyz);
}
