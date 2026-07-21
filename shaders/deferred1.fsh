#version 330 compatibility
/*
 * deferred1.fsh — volumetric light shafts / god rays (docs/02 section 5).
 * Marches from camera toward the scene, single-tap shadow test per step
 * (PCF would be far too costly here), accumulating in-scattered sun/moon
 * light. A forward-scatter phase concentrates the shafts toward the sun so
 * they read as crepuscular rays, not uniform haze. Written to colortex6,
 * composited before bloom. Off at Low tier (docs/05). Runs before water,
 * so depthtex0 holds the opaque scene.
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

    vec3 wDir  = viewToWorldDir(dir);
    vec3 wSun  = viewToWorldDir(normalize(sunPosition));
    vec3 wMoon = viewToWorldDir(normalize(moonPosition));
    vec3 lightCol = wSun.y > 0.0 ? sunlightColor(wSun.y) : moonlightColor(wMoon.y);

    // Forward-scatter toward the active light so shafts point at the sun/moon.
    vec3  toLight = wSun.y > 0.0 ? wSun : wMoon;
    float phase   = 0.35 + 0.65 * pow(max(dot(wDir, toLight), 0.0), 5.0);

    float accum = 0.0;
    float t = dither * stepLen + stepLen * 0.5;
    for (int i = 0; i < steps; i++) {
        accum += shadowTestSingle(dir * t);
        t += stepLen;
    }
    accum /= float(steps);

    outVol = vec4(lightCol * accum * phase * 0.45, 1.0);
#endif
}
