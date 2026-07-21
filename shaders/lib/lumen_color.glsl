/*
 * lumen_color.glsl — the whole colour finish (docs/04). ONE tonemap, a
 * subtle time-of-day grade, and a dither applied once in final.fsh.
 */
#ifndef LUMEN_COLOR_GLSL
#define LUMEN_COLOR_GLSL
#include "/lib/lumen_common.glsl"

// ACES filmic approximation (Narkowicz) — smooth highlight roll-off.
vec3 tonemapACES(vec3 x) {
    const float a = 2.51, b = 0.03, c = 2.43, d = 0.59, e = 0.14;
    return clamp((x * (a * x + b)) / (x * (c * x + d) + e), 0.0, 1.0);
}

vec3 linearToSRGB(vec3 c) { return pow(clamp(c, 0.0, 1.0), vec3(1.0 / 2.2)); }

/*
 * Subtle day/night grade (docs/04 section 2): reinforce, don't fight, the
 * sky model's own colour shift. Warm lift near sunrise/sunset, cool + gently
 * desaturated at night, neutral midday. strength01 scales the whole effect.
 */
vec3 dayNightGrade(vec3 c, float sunY, float strength01) {
    float night = smoothstep(0.06, -0.16, sunY);
    float low   = smoothstep(0.0, 0.24, sunY) * (1.0 - smoothstep(0.24, 0.52, sunY));
    vec3 warm = c * vec3(1.07, 1.00, 0.92);
    vec3 cool = mix(c, vec3(luminance(c)), 0.16) * vec3(0.92, 0.97, 1.09);
    c = mix(c, warm, low  * 0.5 * strength01);
    c = mix(c, cool, night * 0.5 * strength01);
    return c;
}

// Hash-based dither (docs/04 section 5) — breaks 8-bit banding in the sky
// and deep-water gradients. Returns a value in [-0.5, 0.5] LSB.
float ditherLSB(vec2 fragCoord) {
    vec3 p = fract(vec3(fragCoord.xyx) * 0.1031);
    p += dot(p, p.yzx + 33.33);
    return fract((p.x + p.y) * p.z) - 0.5;
}

#endif
