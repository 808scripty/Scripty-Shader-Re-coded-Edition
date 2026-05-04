#ifndef SSRE_MATH_INCLUDED
 #define SSRE_MATH_INCLUDED

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise(vec2 x) {
    vec2 p = floor(x); 
    vec2 f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(hash(p), hash(p + vec2(1.0, 0.0)), f.x), 
        mix(hash(p + vec2(0.0, 1.0)), hash(p + vec2(1.0, 1.0)), f.x), 
        f.y
    );
}

float fastPow3(float x) { 
    return x * x * x; 
}

float fastPow4(float x) { 
    float x2 = x * x; 
    return x2 * x2; 
}

float fastPow14(float x) { 
    float x2 = x * x; 
    float x4 = x2 * x2; 
    float x8 = x4 * x4; 
    return x8 * x4 * x2; 
}

float fastPow52(float x) { 
    float x2 = x * x; 
    float x4 = x2 * x2; 
    float x8 = x4 * x4; 
    float x16 = x8 * x8; 
    float x32 = x16 * x16; 
    return x32 * x16 * x4; 
}


#endif
