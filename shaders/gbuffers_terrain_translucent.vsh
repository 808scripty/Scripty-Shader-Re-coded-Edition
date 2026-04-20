#version 120

varying vec2 texcoord;
varying vec4 glcolor;
varying vec3 worldNormal;
varying vec3 sunDir;
varying float viewDist;
varying vec4 lightLevels;


varying vec3 vTimeFactors; // x: day, y: sunset, z: night
varying vec3 vSunCol;
varying vec3 vAmbCol;

varying vec3 vViewVec;
varying vec3 vWorldPos; 

uniform mat4 gbufferModelViewInverse;
uniform vec3 sunPosition;
uniform vec3 cameraPosition; 
uniform float frameTimeCounter;
uniform float rainStrength;

void main() {
    vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
    vWorldPos = (gbufferModelViewInverse * viewPos).xyz + cameraPosition;

    vec4 localPos = gl_Vertex;

    if (gl_Normal.y > 0.8) {
        float wave = sin(vWorldPos.x * 2.0 + frameTimeCounter * 3.0) * 0.05 +
                     cos(vWorldPos.z * 2.0 + frameTimeCounter * 2.5) * 0.05;
        localPos.y += wave;
        
        viewPos = gl_ModelViewMatrix * localPos;
    }

    // Apply the transformed position
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

    // Pre-calculate colors in the vertex shader to save fragment instructions
    vec3 daySun = vec3(1.0, 0.95, 0.85);
    vec3 setSun = vec3(1.0, 0.45, 0.1);
    vec3 dayAmb = vec3(0.5, 0.6, 0.8);
    vec3 setAmb = vec3(0.4, 0.25, 0.2);
    vec3 blueAmb = vec3(0.05, 0.08, 0.15); 

    vSunCol = mix(setSun, daySun, dayFactor);
    vAmbCol = mix(blueAmb, mix(setAmb, dayAmb, dayFactor), dayFactor + sunsetFactor);
    
    vec3 rainColor = vec3(0.35, 0.35, 0.35);
    vSunCol = mix(vSunCol, rainColor * 0.2, rainStrength);
    vAmbCol = mix(vAmbCol, rainColor, rainStrength);
    // Use the potentially modified viewPos for accurate depth fog
    viewDist = length(viewPos.xyz);
    vViewVec = -viewPos.xyz; 
}
