/*
 * lumen_gbuffer.glsl — shared gbuffer packing (docs/01 section 3).
 * Every gbuffers_* fragment stage builds the same GbufferData so the
 * deferred/composite passes decode one consistent format.
 *
 * colortex2.ba now carries labPBR smoothness/metal; colortex3 carries the
 * emitter glow colour (rgb) + strength (a): labPBR emission when present,
 * else the hardcoded emitter table (lumen_light), else none.
 */
#ifndef LUMEN_GBUFFER_GLSL
#define LUMEN_GBUFFER_GLSL

#include "/lib/lumen_common.glsl"
#include "/lib/lumen_light.glsl"
#include "/lib/lumen_pbr.glsl"

struct GbufferData {
    vec4 color;       // colortex0  rgb = albedo, a = alpha
    vec4 normalAO;    // colortex1  xy = oct normal, z = AO, w = spare
    vec4 lightSpec;   // colortex2  rg = lightmap, b = smoothness, a = metal
    vec4 emissionSSS; // colortex3  rgb = emission colour, a = emission strength
};

GbufferData buildGbuffer(vec2 uv, vec2 lmcoord, vec4 tint, vec3 viewNormal, float matId) {
    vec4 albedo = texture(gtexture, uv) * tint;
    LabSpecular lab = decodeLabSpecular(texture(specular, uv));

    // Emission: prefer labPBR emission (self-colour = albedo), else the
    // hardcoded emitter glow colour, else none.
    vec3  emColor = vec3(0.0);
    float emStr   = 0.0;
    if (isEmitter(matId)) {
        emColor = emitterColor(matId);
        emStr   = emitterStrength(matId);
    }
    if (lab.emission > emStr) {
        emColor = albedo.rgb;
        emStr   = lab.emission;
    }

    GbufferData g;
    g.color       = albedo;
    g.normalAO    = vec4(octEncode(viewNormal), 1.0, 0.0);
    g.lightSpec   = vec4(clamp(lmcoord, 0.0, 1.0), lab.smoothness, lab.metal);
    g.emissionSSS = vec4(emColor, emStr);
    return g;
}

#endif
