#version 330 compatibility
/*
 * Shadow vertex stage. During the shadow pass Iris binds the light's
 * ortho matrices as the current GL matrices, so ftransform() yields
 * shadow clip space directly. We apply the shared distortion so the
 * map matches how Phase 1 will sample it.
 */
#include "/lib/lumen_uniforms.glsl"
#include "/lib/lumen_shadow.glsl"

out vec2 v_texcoord;
out vec4 v_tint;

void main() {
    gl_Position    = ftransform();
    gl_Position.xy = distortShadow(gl_Position.xy);

    v_texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    v_tint     = gl_Color;
}
