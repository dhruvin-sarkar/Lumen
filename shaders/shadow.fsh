#version 330 compatibility
/*
 * Shadow fragment stage. Depth is written automatically; we only need
 * the alpha cutout so foliage/pane shadows are correctly shaped, and a
 * color write to shadowcolor0 (kept for future colored-shadow work,
 * docs/02 section 2 — a clearly-scoped stretch item, not used yet).
 */
#include "/lib/lumen_uniforms.glsl"

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outShadowColor; // shadowcolor0

in vec2 v_texcoord;
in vec4 v_tint;

void main() {
    vec4 albedo = texture(gtexture, v_texcoord) * v_tint;
    if (albedo.a < 0.1) discard;   // shape cutout shadows
    outShadowColor = albedo;
}
