#version 330 compatibility
/*
 * Shared Lumen gbuffer vertex stage. Transforms geometry, forwards the
 * attributes the fragment stage packs into the gbuffer, and passes the
 * block material id (mc_Entity.x) so emitters can be coloured (docs/02).
 */
#include "/lib/lumen_common.glsl"
#include "/lib/lumen_uniforms.glsl"

in vec4 mc_Entity; // .x = block id from block.properties

out vec2  v_texcoord;
out vec2  v_lmcoord;
out vec4  v_tint;
out vec3  v_viewNormal;
out vec3  v_viewPos;
out float v_matId;

void main() {
    vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
    v_viewPos    = viewPos.xyz;
    gl_Position  = gl_ProjectionMatrix * viewPos;
    v_texcoord   = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    v_lmcoord    = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    v_tint       = gl_Color;
    v_viewNormal = normalize(gl_NormalMatrix * gl_Normal);
    v_matId      = mc_Entity.x;
}
