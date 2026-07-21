#version 330 compatibility
/*
 * deferred.fsh — primary lighting resolve (docs/02) + scene capture.
 * Turns the Phase 0 gbuffer into a lit HDR image in colortex0, and
 * copies that lit opaque+sky result into colortex8 BEFORE translucent
 * water draws, so the water composite has an un-occluded backdrop to
 * refract (docs/03 section 3).
 */
#include "/lib/lumen_common.glsl"
#include "/lib/lumen_uniforms.glsl"
#include "/lib/lumen_space.glsl"
#include "/lib/lumen_sky.glsl"
#include "/lib/lumen_shadow.glsl"
#include "/lib/lumen_light.glsl"

/* RENDERTARGETS: 0,8 */
layout(location = 0) out vec4 outColor;        // colortex0 (HDR)
layout(location = 1) out vec4 outSceneCapture; // colortex8 refraction backdrop

in vec2 texcoord;

void main() {
    float depth = texture(depthtex0, texcoord).r;

    vec3 viewPos = screenToView(texcoord, depth);
    vec3 wDir    = viewToWorldDir(normalize(viewPos));
    vec3 wSun    = viewToWorldDir(normalize(sunPosition));
    vec3 wMoon   = viewToWorldDir(normalize(moonPosition));

    vec3 color;

    if (depth >= 1.0) {
        color = skyRadiance(wDir, wSun, wMoon, wetness);
    } else {
        vec3  albedo   = pow(texture(colortex0, texcoord).rgb, vec3(2.2)); // sRGB -> linear
        vec4  c1       = texture(colortex1, texcoord);
        vec3  n        = octDecode(c1.xy);
        float matAO    = c1.z;
        vec4  c2       = texture(colortex2, texcoord);
        float skyLM    = c2.r;
        float blockLM  = c2.g;
        vec4  c3 = texture(colortex3, texcoord); // rgb = emission colour, a = strength

        vec3  lightDir = normalize(shadowLightPosition);
        float NdotL    = max(dot(n, lightDir), 0.0);
        float vis      = sampleShadowPCF(viewPos, NdotL);
        bool  isDay    = wSun.y > 0.0;
        vec3  directCol = isDay ? sunlightColor(wSun.y) : moonlightColor(wMoon.y);
        vec3  direct    = directCol * NdotL * vis * (SUN_INTENSITY / 100.0);

        vec3  skyAmb   = skyAmbientColor(wSun, wMoon, wetness);
        vec3  ambient  = skyAmb * (skyLM * skyLM);
        vec3  bounceFloor = vec3(0.055, 0.052, 0.050);
        vec3  block = blockLightColor() * blockLightFalloff(blockLM) * 2.6 * (TORCH_INTENSITY / 100.0);

        color  = albedo * ((ambient + bounceFloor) * matAO + direct + block);
        color += c3.rgb * c3.a * 8.0; // coloured self-illumination (HDR, feeds bloom)
    }

    vec4 lit = vec4(max(color, 0.0), 1.0);
    outColor        = lit;
    outSceneCapture = lit;
}
