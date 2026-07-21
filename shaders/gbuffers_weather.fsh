#version 330 compatibility
/*
 * Weather (rain/snow) gbuffer fragment stage — lit through the shared pipeline.
 * deferred pass lights clouds with the same sun/moon/sky term as the
 * world (docs/07: clouds are part of the light show, not a flat plane).
 */
#include "/lib/lumen_uniforms.glsl"
#include "/lib/lumen_gbuffer.glsl"

/* RENDERTARGETS: 0,1,2,3 */
layout(location = 0) out vec4 outColor;
layout(location = 1) out vec4 outNormalAO;
layout(location = 2) out vec4 outLightSpec;
layout(location = 3) out vec4 outEmission;

in vec2 v_texcoord;
in vec2 v_lmcoord;
in vec4 v_tint;
in vec3 v_viewNormal;
in vec3 v_viewPos;

void main() {
    GbufferData g = buildGbuffer(v_texcoord, v_lmcoord, v_tint, normalize(v_viewNormal));
    if (g.color.a < 0.1) discard;
    outColor     = g.color;
    outNormalAO  = g.normalAO;
    outLightSpec = g.lightSpec;
    outEmission  = g.emissionSSS;
}
