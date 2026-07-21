/*
 * lumen_gbuffer.glsl
 * ------------------------------------------------------------------
 * Shared gbuffer packing. Every gbuffers_* fragment stage builds the
 * same GbufferData and writes it into the colortex layout from
 * docs/01 section 3, so the deferred/composite passes can decode one
 * consistent format regardless of which geometry produced it.
 *
 * PHASE 0 SCOPE: material data (smoothness / metal / emission /
 * subsurface) is written as conservative defaults. Real labPBR decode
 * (docs/01 section 4) lands in Phase 1 via lumen_pbr.glsl — this
 * builder is the single place that will change when it does.
 */
#ifndef LUMEN_GBUFFER_GLSL
#define LUMEN_GBUFFER_GLSL

#include "/lib/lumen_common.glsl"

struct GbufferData {
    vec4 color;       // -> colortex0  rgb = albedo (HDR-ready), a = alpha
    vec4 normalAO;    // -> colortex1  xy = octahedral view normal, z = AO, w = spare
    vec4 lightSpec;   // -> colortex2  rg = lightmap(sky,block), b = smoothness, a = metalness
    vec4 emissionSSS; // -> colortex3  r = emission, g = subsurface, ba = spare
};

/*
 * buildGbuffer: sample the bound atlas, tint it, and pack the shared
 * gbuffer channels. viewNormal is expected already normalized and in
 * view space. lmcoord is the vanilla lightmap coordinate (sky, block)
 * already mapped to [0,1] by the vertex stage.
 */
GbufferData buildGbuffer(vec2 texcoord, vec2 lmcoord, vec4 tint, vec3 viewNormal) {
    vec4 albedo = texture(gtexture, texcoord) * tint;

    GbufferData g;
    g.color       = albedo;
    // z = material AO (1 = unoccluded default until SSAO writes it in deferred).
    g.normalAO    = vec4(octEncode(viewNormal), 1.0, 0.0);
    // Conservative non-metal, low-smoothness default so surfaces are not plastic.
    g.lightSpec   = vec4(clamp(lmcoord, 0.0, 1.0), 0.0, 0.0);
    g.emissionSSS = vec4(0.0);
    return g;
}

#endif // LUMEN_GBUFFER_GLSL
