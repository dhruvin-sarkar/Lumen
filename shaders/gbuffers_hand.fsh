#version 330 compatibility
/*
 * Solid-geometry gbuffer fragment stage.
 * Packs the shared gbuffer (docs/01 section 3) for opaque terrain,
 * entities, held items and basic geometry.
 */
#include "/lib/lumen_uniforms.glsl"
#include "/lib/lumen_gbuffer.glsl"

/* RENDERTARGETS: 0,1,2,3 */
layout(location = 0) out vec4 outColor;      // colortex0
layout(location = 1) out vec4 outNormalAO;   // colortex1
layout(location = 2) out vec4 outLightSpec;  // colortex2
layout(location = 3) out vec4 outEmission;   // colortex3

in vec2 v_texcoord;
in vec2 v_lmcoord;
in vec4 v_tint;
in vec3 v_viewNormal;
in vec3 v_viewPos;

void main() {
    GbufferData g = buildGbuffer(v_texcoord, v_lmcoord, v_tint, normalize(v_viewNormal));

    // Alpha cutout (foliage, glass panes, etc.). Fail loud is fine here:
    // fully-transparent texels contribute nothing to the opaque gbuffer.
    if (g.color.a < 0.1) discard;

    outColor     = g.color;
    outNormalAO  = g.normalAO;
    outLightSpec = g.lightSpec;
    outEmission  = g.emissionSSS;
}
