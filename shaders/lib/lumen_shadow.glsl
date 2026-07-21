/*
 * lumen_shadow.glsl
 * ------------------------------------------------------------------
 * Shadow-space helpers. Phase 0 provides only the shadow-map
 * distortion used to concentrate depth precision near the camera
 * (standard for a single non-cascaded shadow map, docs/02 section 2).
 * The SAME distort() must be applied when writing the map (shadow.vsh)
 * and when sampling it (Phase 1 deferred), or shadows will not line up.
 *
 * PCF sampling helpers land in Phase 1 alongside the lighting resolve.
 */
#ifndef LUMEN_SHADOW_GLSL
#define LUMEN_SHADOW_GLSL

// Bias in [0,1]: higher = more precision pulled toward the player.
const float shadowDistortBias = 0.85;

// Warp shadow clip-space XY so texels cluster near the origin (camera).
vec2 distortShadow(vec2 pos) {
    float dist = length(pos);
    float factor = dist * shadowDistortBias + (1.0 - shadowDistortBias);
    return pos / factor;
}

#endif // LUMEN_SHADOW_GLSL
