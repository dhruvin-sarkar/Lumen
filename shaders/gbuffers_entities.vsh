#version 330 compatibility
/*
 * Shared Lumen gbuffer vertex stage.
 * Transforms geometry and forwards the attributes the fragment stage
 * needs to pack the gbuffer (docs/01 section 3). Kept identical across
 * every gbuffers_* program in Phase 0; wave displacement (water) and
 * any per-program specialisation arrive in later phases.
 */
#include "/lib/lumen_common.glsl"
#include "/lib/lumen_uniforms.glsl"

out vec2 v_texcoord;   // atlas UV
out vec2 v_lmcoord;    // vanilla lightmap coord (sky, block), [0,1]
out vec4 v_tint;       // per-vertex color / biome tint
out vec3 v_viewNormal; // view-space normal
out vec3 v_viewPos;    // view-space position (used by water for depth)

void main() {
    vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
    v_viewPos    = viewPos.xyz;
    gl_Position  = gl_ProjectionMatrix * viewPos;

    v_texcoord   = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    v_lmcoord    = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    v_tint       = gl_Color;
    v_viewNormal = normalize(gl_NormalMatrix * gl_Normal);
}
