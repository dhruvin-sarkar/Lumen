/*
 * lumen_water_color.glsl — underwater absorption (docs/03 section 4).
 * Beer-Lambert per channel (red absorbed fastest) so shallow water reads
 * near the true terrain colour and deep water goes blue-green then dark.
 * The SAME model must drive underwater fog in Phase 3 (docs/03 section 5).
 */
#ifndef LUMEN_WATER_COLOR_GLSL
#define LUMEN_WATER_COLOR_GLSL

// sceneColor seen through `dist` blocks of water -> absorbed/tinted colour.
vec3 waterAbsorb(vec3 sceneColor, float dist) {
    const vec3 extinction = vec3(0.46, 0.16, 0.11); // per-block, per-channel
    const vec3 deepTint   = vec3(0.02, 0.09, 0.12);
    vec3 transmit = exp(-extinction * dist);
    return mix(deepTint, sceneColor, transmit);
}

#endif
