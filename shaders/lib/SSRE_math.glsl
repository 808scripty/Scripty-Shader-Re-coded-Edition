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

#endif
