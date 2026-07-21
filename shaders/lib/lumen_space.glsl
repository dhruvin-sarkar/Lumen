/*
 * lumen_space.glsl — coordinate-space reconstruction.
 * One shared implementation (design principle #5) used by deferred and,
 * later, the water composite passes.
 */
#ifndef LUMEN_SPACE_GLSL
#define LUMEN_SPACE_GLSL
#include "/lib/lumen_uniforms.glsl"

// Screen UV + hardware depth [0,1] -> view-space position.
vec3 screenToView(vec2 uv, float depth) {
    vec3 ndc = vec3(uv, depth) * 2.0 - 1.0;
    vec4 view = gbufferProjectionInverse * vec4(ndc, 1.0);
    return view.xyz / view.w;
}

// View-space direction/position -> world (player-relative) space.
vec3 viewToWorldDir(vec3 v) { return normalize(mat3(gbufferModelViewInverse) * v); }
vec3 viewToWorldPos(vec3 v) { return (gbufferModelViewInverse * vec4(v, 1.0)).xyz; }

#endif
