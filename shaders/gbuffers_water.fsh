#version 330 compatibility
/*
 * Water gbuffer fragment stage. Water pixels write their per-pixel wave
 * normal + mask + view depth to colortex5 for the composite water
 * resolve; non-water translucents just pass their texture through.
 * Real shading (Fresnel/reflection/refraction) happens in composite.
 */
#include "/lib/lumen_common.glsl"
#include "/lib/lumen_uniforms.glsl"
#include "/lib/lumen_water_waves.glsl"

/* RENDERTARGETS: 0,5 */
layout(location = 0) out vec4 outColor; // colortex0 base
layout(location = 1) out vec4 outWater; // colortex5: mask, viewDepth, octNormal

in vec2  v_texcoord;
in vec4  v_tint;
in vec3  v_viewPos;
in vec3  v_worldPos;
in float v_isWater;

void main() {
    if (v_isWater < 0.5) {
        vec4 c = texture(gtexture, v_texcoord) * v_tint; // glass/ice
        if (c.a < 0.1) discard;
        outColor = c;
        outWater = vec4(0.0);
        return;
    }

    // Per-pixel analytic wave normal (world space, up = +Y).
    vec3 n = waveNormal(v_worldPos.xz, frameTimeCounter);

    outColor = vec4(0.02, 0.05, 0.07, 1.0);            // placeholder; composite replaces
    outWater = vec4(1.0, -v_viewPos.z, octEncode(n));  // mask, view depth, normal
}
