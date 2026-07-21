#version 330 compatibility
/*
 * composite.fsh — auto-exposure metering (docs/02 section 6, docs/04
 * section 4). Reads an averaged mip of the HDR scene, computes a target
 * exposure, and eases toward it via the colortex9 history buffer (no
 * clear) so exposure adapts smoothly instead of pumping.
 */
#include "/lib/lumen_common.glsl"
#include "/lib/lumen_uniforms.glsl"

/* RENDERTARGETS: 9 */
layout(location = 0) out vec4 outExposure; // colortex9 (R16F)

in vec2 texcoord;

// Ask Iris to generate mipmaps for colortex0 so textureLod can average it.
const bool colortex0MipmapEnabled = true;

void main() {
    float lod = max(log2(max(viewWidth, viewHeight)) - 1.0, 1.0);
    vec3  avg = textureLod(colortex0, vec2(0.5), lod).rgb;
    float lum = max(luminance(avg), 1e-4);

    // Key-value target with clamped range (avoid over-brightening caves /
    // over-darkening noon).
    float target = clamp(0.16 / lum, 0.05, 8.0);

    float prev = texture(colortex9, vec2(0.5)).r;
    if (!(prev > 0.0)) prev = target;          // first frame / NaN guard
    float exposure = mix(prev, target, 0.04);  // per-frame EMA

    outExposure = vec4(exposure, 0.0, 0.0, 1.0);
}
