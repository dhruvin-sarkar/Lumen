#version 330 compatibility
/*
 * Water gbuffer fragment stage. Water pixels write wave normal + mask +
 * view depth to colortex5 for the composite resolve. The normal is the
 * base swell + a distance-faded fine detail layer (docs/03 sec 1, for
 * close-up shimmer / a crisp glint) + rain ripples when wet (docs/07).
 */
#include "/lib/lumen_common.glsl"
#include "/lib/lumen_uniforms.glsl"
#include "/lib/lumen_water_waves.glsl"

/* RENDERTARGETS: 0,5 */
layout(location = 0) out vec4 outColor;
layout(location = 1) out vec4 outWater;

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

    vec3 n = waveNormal(v_worldPos.xz, frameTimeCounter);

    // Fine detail layer, faded out with distance (avoids far-water aliasing).
    float detailFade = exp(-length(v_viewPos) * 0.03);
    vec3  dn = waveNormal(v_worldPos.xz * 3.3 + frameTimeCounter * 0.5, frameTimeCounter * 1.7);
    n = normalize(n + (dn - vec3(0.0, 1.0, 0.0)) * detailFade * 0.8);

    // Rain ripples (docs/07).
    if (wetness > 0.01) {
        float r = sin(v_worldPos.x * 9.0 + frameTimeCounter * 11.0) * cos(v_worldPos.z * 9.0 - frameTimeCounter * 9.0);
        n = normalize(n + vec3(r, 0.0, r) * 0.05 * wetness);
    }

    outColor = vec4(0.02, 0.05, 0.07, 1.0);
    outWater = vec4(1.0, -v_viewPos.z, octEncode(n));
}
