/*
 * lumen_light.glsl — block/emitted light (docs/02 section 3).
 *   - blockLightFalloff/blockLightColor: the ambient block-light TERM that
 *     warms surfaces near any light source (we can't know which emitter lit
 *     a given pixel, so this stays a warm default; real colored propagation
 *     is out of scope for v1, docs/02 section 3).
 *   - emitter* : per-block-type glow colour for the emitter blocks THEMSELVES
 *     (torch/lava/glowstone/sculk/...), so vanilla Lumen keeps its identity
 *     and bloom (Phase 4) has coloured HDR sources to feed on.
 */
#ifndef LUMEN_LIGHT_GLSL
#define LUMEN_LIGHT_GLSL
#include "/lib/lumen_common.glsl"

float blockLightFalloff(float bl) {
    float x = clamp(bl, 0.0, 1.0);
    float s = x * x * (3.0 - 2.0 * x);
    return s * s;
}

vec3 blockLightColor() { return vec3(1.00, 0.52, 0.22); }

// True for a block.properties emitter id (10001+).
bool isEmitter(float id) { return id > 10000.5; }

// Per-emitter glow colour (matches the docs/02 section 3 table).
vec3 emitterColor(float id) {
    if (id < 10001.5) return vec3(1.00, 0.55, 0.22); // torch/lantern/fire  warm orange
    if (id < 10002.5) return vec3(1.00, 0.30, 0.07); // lava/magma          deep orange-red
    if (id < 10003.5) return vec3(1.00, 0.84, 0.52); // glowstone/froglight warm yellow-white
    if (id < 10004.5) return vec3(0.55, 0.90, 1.00); // sea lantern         cyan-white
    if (id < 10005.5) return vec3(0.10, 0.85, 0.78); // sculk               teal
    if (id < 10006.5) return vec3(0.24, 0.62, 1.00); // soul fire family    cyan-blue
    return vec3(1.00, 0.11, 0.05);                    // redstone            red
}

// Relative glow strength per emitter family (0..1; scaled to HDR in deferred).
float emitterStrength(float id) {
    if (id < 10001.5) return 0.70; // torch
    if (id < 10002.5) return 1.00; // lava (brightest)
    if (id < 10003.5) return 0.95; // glowstone
    if (id < 10004.5) return 0.85; // sea lantern
    if (id < 10005.5) return 0.55; // sculk (subtle)
    if (id < 10006.5) return 0.70; // soul
    return 0.65;                    // redstone
}

#endif
