/*
 * lumen_water_waves.glsl — shared wave height + analytic normal (docs/03
 * section 1) and caustics (section 5). The SAME functions drive vertex
 * displacement, the fragment normal, AND the underwater caustics, so the
 * whole water system stays in sync.
 */
#ifndef LUMEN_WATER_WAVES_GLSL
#define LUMEN_WATER_WAVES_GLSL
#include "/lib/lumen_common.glsl"

float waveHeight(vec2 p, float t) {
    float h = 0.0;
    h += sin(dot(p, vec2( 0.80,  0.60)) + t * 1.10) * 0.50;
    h += sin(dot(p, vec2(-0.60,  0.90)) + t * 0.90) * 0.28;
    h += sin(dot(p, vec2( 0.20, -1.00)) + t * 1.60) * 0.16;
    h += sin(dot(p, vec2( 1.00,  0.10)) * 2.10 + t * 2.30) * 0.08;
    return h * 0.18;
}

vec3 waveNormal(vec2 p, float t) {
    const float e = 0.12;
    float h0 = waveHeight(p, t);
    float hx = waveHeight(p + vec2(e, 0.0), t);
    float hz = waveHeight(p + vec2(0.0, e), t);
    return normalize(vec3(-(hx - h0) / e, 1.0, -(hz - h0) / e));
}

// Projected caustic intensity for a submerged world-space XZ point. Reuses
// the wave field so the shimmer matches the ripples overhead (docs/03 §5).
float caustics(vec2 p, float t) {
    float n = waveHeight(p * 1.6, t) + waveHeight(p * 2.7 + 5.0, t * 1.25);
    float c = 0.5 + 0.5 * sin(n * 9.0 + t * 0.7);
    return pow(c, 4.0);
}

#endif
