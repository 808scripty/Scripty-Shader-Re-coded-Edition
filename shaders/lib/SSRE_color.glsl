#ifndef SSRE_COLOR_INCLUDED
#define SSRE_COLOR_INCLUDED

float getLuminance(vec3 color) {
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

vec3 colorGrading(vec3 color, float sat, float con) {
    float luma = getLuminance(color);
    vec3 graded = mix(vec3(luma), color, sat);
    graded = pow(max(graded / 0.18, 0.0), vec3(con)) * 0.18;
    return graded;
}

vec3 ACESFilm(vec3 x) {
    float a = 2.51;
    float b = 0.03;
    float c = 2.43;
    float d = 0.59;
    float e = 0.14;
    return clamp((x * (a * x + b)) / (x * (c * x + d) + e), 0.0, 1.0);
}

#endif