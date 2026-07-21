/*
 * lumen_water_color.glsl — underwater absorption + fog colour (docs/03
 * sections 4-5). Beer-Lambert per channel; the underwater fog colour is
 * the SAME hue family so "water from above" and "water from inside" match.
 */
#ifndef LUMEN_WATER_COLOR_GLSL
#define LUMEN_WATER_COLOR_GLSL
#include "/lib/lumen_common.glsl"

vec3 waterAbsorb(vec3 sceneColor, float dist) {
    const vec3 extinction = vec3(0.46, 0.16, 0.11);
    const vec3 deepTint   = vec3(0.02, 0.09, 0.12);
    vec3 transmit = exp(-extinction * dist);
    return mix(deepTint, sceneColor, transmit);
}

// Underwater fog colour, brightened by the current ambient sky light so
// night dives are dark and day dives are luminous blue-green.
vec3 underwaterFogColor(vec3 skyAmbient) {
    float bright = clamp(luminance(skyAmbient) * 3.0, 0.05, 1.0);
    return vec3(0.05, 0.20, 0.24) * bright;
}

#endif
