#version 330 compatibility
/*
 * deferred.fsh — primary lighting resolve (docs/02).
 * Turns the Phase 0 gbuffer into a lit HDR image in colortex0:
 *   - sky pixels (far depth) get the analytic sky (lumen_sky)
 *   - surfaces get sky ambient + sun/moon direct (PCF shadowed) + block
 *     light + emission, plus a cheap ground-bounce floor so enclosed
 *     torch-lit rooms are never pure black (docs/02 section 4 — an
 *     intentional approximation, NOT global illumination).
 */
#include "/lib/lumen_common.glsl"
#include "/lib/lumen_uniforms.glsl"
#include "/lib/lumen_space.glsl"
#include "/lib/lumen_sky.glsl"
#include "/lib/lumen_shadow.glsl"
#include "/lib/lumen_light.glsl"

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor; // colortex0 (HDR)

in vec2 texcoord;

void main() {
    float depth = texture(depthtex0, texcoord).r;

    vec3 viewPos = screenToView(texcoord, depth);
    vec3 wDir    = viewToWorldDir(normalize(viewPos));
    vec3 wSun    = viewToWorldDir(normalize(sunPosition));
    vec3 wMoon   = viewToWorldDir(normalize(moonPosition));

    vec3 color;

    if (depth >= 1.0) {
        // Sky: replace whatever forward geometry left with the analytic sky.
        color = skyRadiance(wDir, wSun, wMoon, wetness);
    } else {
        vec3  albedo   = pow(texture(colortex0, texcoord).rgb, vec3(2.2)); // sRGB -> linear
        vec4  c1       = texture(colortex1, texcoord);
        vec3  n        = octDecode(c1.xy);
        float matAO    = c1.z;
        vec4  c2       = texture(colortex2, texcoord);
        float skyLM    = c2.r;
        float blockLM  = c2.g;
        float emission = texture(colortex3, texcoord).r;

        // Direct sun/moon: colour + direction from the shared sky model.
        vec3  lightDir = normalize(shadowLightPosition); // view space
        float NdotL    = max(dot(n, lightDir), 0.0);
        float vis      = sampleShadowPCF(viewPos, NdotL);
        bool  isDay    = wSun.y > 0.0;
        vec3  directCol = isDay ? sunlightColor(wSun.y) : moonlightColor(wMoon.y);
        vec3  direct    = directCol * NdotL * vis * (SUN_INTENSITY / 100.0);

        // Sky ambient re-tinted by the current sky colour (docs/02 section 4).
        vec3  skyAmb   = skyAmbientColor(wSun, wMoon, wetness);
        vec3  ambient  = skyAmb * (skyLM * skyLM);

        // Ground-bounce floor: enclosed dark spaces never go pure black.
        vec3  bounceFloor = vec3(0.055, 0.052, 0.050);

        // Block light: warm, smooth falloff (colour table is a follow-up).
        vec3  block = blockLightColor() * blockLightFalloff(blockLM) * 2.6 * (TORCH_INTENSITY / 100.0);

        color  = albedo * ((ambient + bounceFloor) * matAO + direct + block);
        color += albedo * emission * 4.0; // labPBR emission (0 until decoded)
    }

    outColor = vec4(max(color, 0.0), 1.0);
}
