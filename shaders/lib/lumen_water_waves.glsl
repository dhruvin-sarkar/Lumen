/*
 * lumen_water_waves.glsl — shared wave height + analytic normal (docs/03
 * section 1). The SAME functions drive vertex displacement AND the
 * fragment normal, so geometry and shading never drift apart.
 *
 * Layered directional sines standing in for Gerstner swell: different
 * direction / wavelength / speed so the surface reads as real swell, not
 * one repeating ripple (docs/07: "real swell, not a repeating loop").
 */
#ifndef LUMEN_WATER_WAVES_GLSL
#define LUMEN_WATER_WAVES_GLSL
#include "/lib/lumen_common.glsl"

// World-space XZ + time -> surface height (world units, ~[-1,1] scale).
float waveHeight(vec2 p, float t) {
    float h = 0.0;
    h += sin(dot(p, vec2( 0.80,  0.60)) + t * 1.10) * 0.50;
    h += sin(dot(p, vec2(-0.60,  0.90)) + t * 0.90) * 0.28;
    h += sin(dot(p, vec2( 0.20, -1.00)) + t * 1.60) * 0.16;
    h += sin(dot(p, vec2( 1.00,  0.10)) * 2.10 + t * 2.30) * 0.08; // detail
    return h * 0.18;
}

// Analytic surface normal (world space, up = +Y) via finite differences.
vec3 waveNormal(vec2 p, float t) {
    const float e = 0.12;
    float h0 = waveHeight(p, t);
    float hx = waveHeight(p + vec2(e, 0.0), t);
    float hz = waveHeight(p + vec2(0.0, e), t);
    return normalize(vec3(-(hx - h0) / e, 1.0, -(hz - h0) / e));
}

#endif
