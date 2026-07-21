#version 330 compatibility
/*
 * prepare1.fsh — sky-view LUT (docs/02 section 1, docs/05).
 * Precomputes the smooth atmosphere once per frame into colortex4
 * (half-res, lat-long mapped) so deferred/composite sample it cheaply
 * instead of evaluating the sky per pixel. Sun/moon disc + stars are
 * added analytically at sample time (see lumen_sky sampleSky()).
 */
#include "/lib/lumen_common.glsl"
#include "/lib/lumen_uniforms.glsl"
#include "/lib/lumen_space.glsl"
#include "/lib/lumen_sky.glsl"

/* RENDERTARGETS: 4 */
layout(location = 0) out vec4 outLUT;
in vec2 texcoord;

void main() {
    vec3 dir  = skyUVToDir(texcoord);
    vec3 wSun = viewToWorldDir(normalize(sunPosition));
    vec3 wMoon = viewToWorldDir(normalize(moonPosition));
    outLUT = vec4(skyAtmosphere(dir, wSun, wMoon, wetness), 1.0);
}
