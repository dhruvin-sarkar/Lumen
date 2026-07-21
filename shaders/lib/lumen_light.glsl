/*
 * lumen_light.glsl — block/emitted light (docs/02 section 3).
 * Reconstructs a smooth falloff from the vanilla stepped block-light
 * lightmap coord and gives it a warm colour so torch-lit interiors read
 * warm and legible without any resource pack.
 *
 * NOTE (Phase 1): a single warm default colour is used for all emitters.
 * The per-block-ID colour table (torch orange vs lava red vs sculk teal,
 * docs/02 section 3) needs block.properties + an mc_Entity material id
 * plumbed through gbuffers; it is a scoped follow-up, wired through THIS
 * function so callers never change.
 */
#ifndef LUMEN_LIGHT_GLSL
#define LUMEN_LIGHT_GLSL
#include "/lib/lumen_common.glsl"

// Smooth, non-stepped falloff from the block-light lightmap coord [0,1].
float blockLightFalloff(float bl) {
    float x = clamp(bl, 0.0, 1.0);
    // Sharpen toward the source: quadratic ramp on a smoothed base.
    float s = x * x * (3.0 - 2.0 * x);
    return s * s;
}

// Warm torch-family default (Phase 1 fallback colour).
vec3 blockLightColor() {
    return vec3(1.00, 0.52, 0.22);
}

#endif
