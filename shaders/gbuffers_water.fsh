#version 330 compatibility
/*
 * Water gbuffer fragment stage.
 * Writes the shared gbuffer plus colortex5 (water mask + view depth +
 * normal) that composite passes use for refraction and underwater
 * detection (docs/01 section 3, docs/03 sections 3 & 5).
 *
 * PHASE 0: flat surface, geometry normal only. Wave displacement and
 * analytic wave normals (lumen_water_waves.glsl) arrive in Phase 2.
 */
#include "/lib/lumen_uniforms.glsl"
#include "/lib/lumen_gbuffer.glsl"

/* RENDERTARGETS: 0,1,2,3,5 */
layout(location = 0) out vec4 outColor;      // colortex0
layout(location = 1) out vec4 outNormalAO;   // colortex1
layout(location = 2) out vec4 outLightSpec;  // colortex2
layout(location = 3) out vec4 outEmission;   // colortex3
layout(location = 4) out vec4 outWater;      // colortex5

in vec2 v_texcoord;
in vec2 v_lmcoord;
in vec4 v_tint;
in vec3 v_viewNormal;
in vec3 v_viewPos;

void main() {
    vec3 n = normalize(v_viewNormal);
    GbufferData g = buildGbuffer(v_texcoord, v_lmcoord, v_tint, n);

    outColor     = g.color;
    outNormalAO  = g.normalAO;
    outLightSpec = g.lightSpec;
    outEmission  = g.emissionSSS;

    // colortex5: r = water mask, g = view-space depth (positive), ba = oct normal.
    outWater = vec4(1.0, -v_viewPos.z, octEncode(n));
}
