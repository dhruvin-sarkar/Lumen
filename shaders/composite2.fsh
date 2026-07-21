#version 330 compatibility
/*
 * composite2.fsh — bloom bright-pass (docs/04 section 3).
 * Extracts HDR pixels above a soft luminance threshold into colortex7.
 * final.fsh mip-blurs and composites them. Threshold is high on purpose
 * so bloom marks light sources as luminous instead of smearing the whole
 * screen (the common "every torch blinds you" failure mode).
 */
#include "/lib/lumen_common.glsl"
#include "/lib/lumen_uniforms.glsl"

/* RENDERTARGETS: 7 */
layout(location = 0) out vec4 outBloom;
in vec2 texcoord;

void main() {
    vec3  c = texture(colortex0, texcoord).rgb;
    float l = luminance(c);
    // Soft knee above 1.0 (HDR). Sun disk, glint, lava, torches qualify.
    float w = smoothstep(1.0, 1.6, l);
    outBloom = vec4(c * w, 1.0);
}
