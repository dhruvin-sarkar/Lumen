/*
 * lumen_color.glsl — tonemapping / encode (docs/04).
 * ONE tonemap operator applied once in final.fsh; no pass applies its
 * own ad-hoc clamping. Grading, bloom and dithering join here in Phase 4.
 */
#ifndef LUMEN_COLOR_GLSL
#define LUMEN_COLOR_GLSL

// ACES filmic approximation (Narkowicz). Rolls off highlights smoothly
// so the sun glint stays a bright saturated highlight, not a white blob.
vec3 tonemapACES(vec3 x) {
    const float a = 2.51, b = 0.03, c = 2.43, d = 0.59, e = 0.14;
    return clamp((x * (a * x + b)) / (x * (c * x + d) + e), 0.0, 1.0);
}

vec3 linearToSRGB(vec3 c) { return pow(clamp(c, 0.0, 1.0), vec3(1.0 / 2.2)); }

#endif
