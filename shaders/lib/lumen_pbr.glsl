/*
 * lumen_pbr.glsl — labPBR specular channel decode (docs/01 section 4).
 * On vanilla (no resource pack) Iris binds a default specular texture, so
 * these read as zeros and the hardcoded fallbacks (lumen_light) take over.
 */
#ifndef LUMEN_PBR_GLSL
#define LUMEN_PBR_GLSL

struct LabSpecular {
    float smoothness; // perceptual smoothness (spec .r)
    float metal;      // 1 if f0 >= ~0.9 (metal range), else 0 (spec .g)
    float emission;   // self-illumination (spec .b)
};

LabSpecular decodeLabSpecular(vec4 spec) {
    LabSpecular s;
    s.smoothness = spec.r;
    s.metal      = step(0.90, spec.g);
    // labPBR encodes "no emission" as 255 in the blue channel; treat that as 0.
    s.emission   = spec.b >= 0.996 ? 0.0 : spec.b;
    return s;
}

#endif
