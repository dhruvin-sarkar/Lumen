#version 330 compatibility
/*
 * Color-only gbuffer fragment stage for forward-shaded elements
 * (clouds, weather particles). These are not deferred-lit, so they
 * write scene color only (colortex0) and deliberately leave the
 * normal / material buffers untouched.
 */
#include "/lib/lumen_uniforms.glsl"

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor; // colortex0

in vec2 v_texcoord;
in vec4 v_tint;

void main() {
    vec4 albedo = texture(gtexture, v_texcoord) * v_tint;
    if (albedo.a < 0.1) discard;
    outColor = albedo;
}
