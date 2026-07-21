#version 330 compatibility
/*
 * deferred1.fsh — volumetric light shafts / god rays (docs/02 section 5).
 * Marches from the camera toward the scene, sampling the shadow map at
 * each step; lit steps in-scatter sun/moon light (shared sky colour).
 * Written to colortex6, composited before bloom so shafts glow. Off at
 * Low tier (docs/05). Runs before translucent water, so it uses the
 * opaque depth already present in depthtex0.
 */
#include "/lib/lumen_common.glsl"
#include "/lib/lumen_uniforms.glsl"
#include "/lib/lumen_space.glsl"
#include "/lib/lumen_sky.glsl"
#include "/lib/lumen_shadow.glsl"

/* RENDERTARGETS: 6 */
layout(location = 0) out vec4 outVol;
in vec2 texcoord;

void main() {
#if LUMEN_TIER == TIER_LOW
    outVol = vec4(0.0);
#else
    float depth   = texture(depthtex0, texcoord).r;
    vec3  endView = screenToView(texcoord, depth);
    float maxDist = min(length(endView), 64.0);
    vec3  dir     = normalize(endView);

    int   steps   = (LUMEN_TIER >= TIER_HIGH) ? 24 : 12;
    float stepLen = maxDist / float(steps);
    float dither  = fract(sin(dot(texcoord, vec2(12.9898, 78.233))) * 43758.5453);

    vec3 wSun  = viewToWorldDir(normalize(sunPosition));
    vec3 wMoon = viewToWorldDir(normalize(moonPosition));
    vec3 lightCol = wSun.y > 0.0 ? sunlightColor(wSun.y) : moonlightColor(wMoon.y);

    float accum = 0.0;
    float t = dither * stepLen + stepLen * 0.5;
    for (int i = 0; i < steps; i++) {
        accum += sampleShadowPCF(dir * t, 1.0);
        t += stepLen;
    }
    accum /= float(steps);

    outVol = vec4(lightCol * accum * 0.35, 1.0);
#endif
}
