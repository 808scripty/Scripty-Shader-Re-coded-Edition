#version 120

varying vec2 texcoord;

uniform sampler2D colortex0;
uniform float frameTimeCounter;

// Needed for pixel-perfect blurring
uniform float viewWidth;  
uniform float viewHeight; 

// --- SETTINGS ---
#define GRAIN // Minimize the banding in the sky gradients & add textures to the surfaces.
#define GRAIN_STRENGTH 0.025 // Adjust this for more or less visible grain

#define BLOOM // Toggle for Pseudo-Bloom
#define BLOOM_THRESHOLD 0.45 // How bright a pixel must be to glow (0.0 to 1.0)
#define BLOOM_STRENGTH 0.40  // How intense the glowing light is
#define BLOOM_RADIUS 3.0     // How far the light spreads (Keep under 5.0 for mobile)
#define DITHERING

// Pseudo-random values based on coordinates
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

// --- ACES Filmic Tonemapping ---
vec3 ACESFilm(vec3 x) {
    float a = 2.51;
    float b = 0.03;
    float c = 2.43;
    float d = 0.59;
    float e = 0.14;
    return clamp((x * (a * x + b)) / (x * (c * x + d) + e), 0.0, 1.0);
}

vec3 getBloom(vec2 uv) {
    vec2 texel = vec2(1.0 / viewWidth, 1.0 / viewHeight) * BLOOM_RADIUS;
    vec3 bloom = vec3(0.0);

    // Highly optimized 5-tap cross blur to save GPUs texture fetches
    vec2 offsets[5] = vec2[](
        vec2(0.0, 0.0),
        vec2(1.5, 1.5), vec2(-1.5, -1.5),
        vec2(1.5, -1.5), vec2(-1.5, 1.5)
    );
    // Gaussian-like weights prioritizing the center
    float weights[5] = float[](0.35, 0.1625, 0.1625, 0.1625, 0.1625);

    for(int i = 0; i < 5; i++) {
        vec3 color = texture2D(colortex0, uv + offsets[i] * texel).rgb;
        // Calculate brightness (luminance)
        float luma = dot(color, vec3(0.299, 0.587, 0.114));
        
        // Extract only the bright spots, smoothing the cutoff
        float mask = smoothstep(BLOOM_THRESHOLD - 0.1, BLOOM_THRESHOLD + 0.1, luma);
        bloom += (color * mask) * weights[i];
    }
    return bloom;
}

vec3 OverallTM(vec3 color) {
    color *= 1.15;
    color = ACESFilm(color);
    
    float contrastAmount = 1.12; 
    color = pow(color, vec3(contrastAmount));

    float luminance = dot(color, vec3(0.299, 0.587, 0.114));
    float saturationAmount = 1.25;
    color = mix(vec3(luminance), color, saturationAmount);

    vec3 shadowTint = vec3(0.92, 0.96, 1.05);
    vec3 highlightTint = vec3(1.05, 1.02, 0.95);
    vec3 appliedTint = mix(shadowTint, highlightTint, clamp(luminance * 1.5, 0.0, 1.0));
    color *= appliedTint;

    return color;
}

vec3 applyDither(vec3 color, vec2 uv) {
    // 8x8 Bayer Matrix optimization for mobile
    float dither[64] = float[64](
         0.0, 32.0,  8.0, 40.0,  2.0, 34.0, 10.0, 42.0,
        48.0, 16.0, 56.0, 24.0, 50.0, 18.0, 58.0, 26.0,
        12.0, 44.0,  4.0, 36.0, 14.0, 46.0,  6.0, 38.0,
        60.0, 28.0, 52.0, 20.0, 62.0, 30.0, 54.0, 22.0,
         3.0, 35.0, 11.0, 43.0,  1.0, 33.0,  9.0, 41.0,
        51.0, 19.0, 59.0, 27.0, 49.0, 17.0, 57.0, 25.0,
        15.0, 47.0,  7.0, 39.0, 13.0, 45.0,  5.0, 37.0,
        63.0, 31.0, 55.0, 23.0, 61.0, 29.0, 53.0, 21.0
    );
    
    // Get pixel coordinates
    int x = int(mod(uv.x * viewWidth, 8.0));
    int y = int(mod(uv.y * viewHeight, 8.0));
    
    float limit = (dither[x + y * 8] + 0.5) / 64.0;
    
    // Apply dither scale (based on 8-bit color limit)
    return color + (limit - 0.5) / 255.0;
}

void main() {
    vec3 sceneColor = texture2D(colortex0, texcoord).rgb;

#ifdef BLOOM
    //Calculate the bloom based on bright areas
    vec3 bloomColor = getBloom(texcoord);
    //Add bloom BEFORE color grading so it tonemaps correctly
    sceneColor += bloomColor * BLOOM_STRENGTH;
#endif

    vec3 gradedColor = OverallTM(sceneColor);

#ifdef GRAIN
    float noise = hash(texcoord + fract(frameTimeCounter));
    gradedColor += (noise - 0.5) * GRAIN_STRENGTH;
#endif

    float distToCenter = distance(texcoord, vec2(0.5));
    float vignette = smoothstep(0.85, 0.3, distToCenter);
    gradedColor *= vignette;

#ifdef DITHERING
gradedColor = applyDither(gradedColor, texcoord);
#endif
    gl_FragData[0] = vec4(gradedColor, 1.0);
}
