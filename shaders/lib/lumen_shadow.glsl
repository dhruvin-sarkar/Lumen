/*
 * lumen_shadow.glsl — shadow-map distortion + sampling.
 * Shadow mapping exists ONLY to tell direct light where it is occluded
 * and to give ground-contact shadows (docs/02 section 2) — no
 * shadow-quality-as-a-feature scope creep.
 *
 * distortShadow() MUST match between the write (shadow.vsh) and the
 * sample (here), or shadows will not line up.
 */
#ifndef LUMEN_SHADOW_GLSL
#define LUMEN_SHADOW_GLSL
#include "/lib/lumen_common.glsl"
#include "/lib/lumen_uniforms.glsl"
#include "/lib/lumen_space.glsl"

uniform float shadowMapResolution; // Iris-provided

// Higher bias = more precision pulled toward the player.
const float shadowDistortBias = 0.85;

vec2 distortShadow(vec2 pos) {
    float d = length(pos);
    float f = d * shadowDistortBias + (1.0 - shadowDistortBias);
    return pos / f;
}

// World (player-relative) position -> distorted shadow texture space [0,1].
vec3 worldToShadowTex(vec3 worldPos) {
    vec4 sv = shadowModelView * vec4(worldPos, 1.0);
    vec4 sc = shadowProjection * sv;
    sc.xyz /= sc.w;
    sc.xy = distortShadow(sc.xy);
    return sc.xyz * 0.5 + 0.5;
}

// PCF shadow visibility for a view-space fragment position. Returns 1 = lit.
float sampleShadowPCF(vec3 viewPos, float NdotL) {
    vec3 sc = worldToShadowTex(viewToWorldPos(viewPos));
    if (sc.x < 0.0 || sc.x > 1.0 || sc.y < 0.0 || sc.y > 1.0 || sc.z > 1.0)
        return 1.0; // outside the map -> treat as lit (no hard edge)

    float slope = clamp(1.0 - NdotL, 0.0, 1.0);
    float bias  = mix(0.00035, 0.0018, slope);
    float res   = shadowMapResolution > 0.0 ? shadowMapResolution : 2048.0;
    float texel = 1.0 / res;

#if LUMEN_TIER >= TIER_HIGH
    const int R = 2; // 5x5
#else
    const int R = 1; // 3x3 (Low/Medium)
#endif

    float vis = 0.0;
    int   cnt = 0;
    for (int x = -R; x <= R; x++)
    for (int y = -R; y <= R; y++) {
        float d = texture(shadowtex0, sc.xy + vec2(x, y) * texel).r;
        vis += step(sc.z - bias, d);
        cnt++;
    }
    return vis / float(cnt);
}

// Single-tap shadow test — for volumetrics, where PCF per march step would
// be far too costly (docs/05, "runs on a potato"). Returns 1 = lit.
float shadowTestSingle(vec3 viewPos) {
    vec3 sc = worldToShadowTex(viewToWorldPos(viewPos));
    if (sc.x < 0.0 || sc.x > 1.0 || sc.y < 0.0 || sc.y > 1.0 || sc.z > 1.0) return 1.0;
    return step(sc.z - 0.0008, texture(shadowtex0, sc.xy).r);
}

#endif
