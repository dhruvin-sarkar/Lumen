#version 330 compatibility
/*
 * deferred.fsh — primary lighting resolve (docs/02) + scene capture.
 * Lights the opaque gbuffer into HDR colortex0 and copies the lit
 * opaque+sky result into colortex8 (refraction backdrop, docs/03 sec 3).
 * SSAO darkens contact points on the ambient term only (docs/02 sec 4).
 */
#include "/lib/lumen_common.glsl"
#include "/lib/lumen_uniforms.glsl"
#include "/lib/lumen_space.glsl"
#include "/lib/lumen_sky.glsl"
#include "/lib/lumen_shadow.glsl"
#include "/lib/lumen_light.glsl"

/* RENDERTARGETS: 0,8 */
layout(location = 0) out vec4 outColor;
layout(location = 1) out vec4 outSceneCapture;

in vec2 texcoord;

// Cheap hemisphere SSAO from depth + view normal. Off at Low tier.
float computeAO(vec2 uv, vec3 viewPos, vec3 n) {
#if LUMEN_TIER == TIER_LOW
    return 1.0;
#else
    vec2 k[8] = vec2[8](vec2(1,0), vec2(-1,0), vec2(0,1), vec2(0,-1),
                        vec2(0.7,0.7), vec2(-0.7,0.7), vec2(0.7,-0.7), vec2(-0.7,-0.7));
    float jitter = fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
    float scale  = 0.6 / max(-viewPos.z, 0.5);
    float ao = 0.0;
    for (int i = 0; i < 8; i++) {
        vec2 suv = uv + k[i] * scale * (0.6 + 0.4 * jitter);
        float sd = texture(depthtex0, suv).r;
        if (sd >= 1.0) continue;
        vec3 diff = screenToView(suv, sd) - viewPos;
        float dist = length(diff);
        ao += max(dot(n, diff / max(dist, 1e-4)) - 0.02, 0.0) / (1.0 + dist * dist);
    }
    return 1.0 - clamp(ao * 0.5 * (AO_STRENGTH / 100.0), 0.0, 1.0);
#endif
}

void main() {
    float depth = texture(depthtex0, texcoord).r;
    vec3 viewPos = screenToView(texcoord, depth);
    vec3 wDir  = viewToWorldDir(normalize(viewPos));
    vec3 wSun  = viewToWorldDir(normalize(sunPosition));
    vec3 wMoon = viewToWorldDir(normalize(moonPosition));

    vec3 color;

    if (depth >= 1.0) {
        color = sampleSky(wDir, wSun, wMoon, wetness);
    } else {
        vec3  albedo   = pow(texture(colortex0, texcoord).rgb, vec3(2.2));
        vec4  c1       = texture(colortex1, texcoord);
        vec3  n        = octDecode(c1.xy);
        float matAO    = c1.z;
        vec4  c2       = texture(colortex2, texcoord);
        float skyLM    = c2.r;
        float blockLM  = c2.g;
        albedo *= mix(1.0, 0.72, wetness * skyLM * skyLM); // wet surfaces darken (docs/07)
        vec4  c3       = texture(colortex3, texcoord); // rgb = emission colour, a = strength

        vec3  lightDir = normalize(shadowLightPosition);
        float NdotL    = max(dot(n, lightDir), 0.0);
        float vis      = sampleShadowPCF(viewPos, NdotL);
        bool  isDay    = wSun.y > 0.0;
        vec3  directCol = isDay ? sunlightColor(wSun.y) : moonlightColor(wMoon.y);
        vec3  direct    = directCol * NdotL * vis * (SUN_INTENSITY / 100.0);

        float ao       = computeAO(texcoord, viewPos, n) * matAO;
        vec3  skyAmb   = skyAmbientColor(wSun, wMoon, wetness);
        vec3  ambient  = skyAmb * (skyLM * skyLM);
        vec3  bounceFloor = vec3(0.055, 0.052, 0.050);
        vec3  block = blockLightColor() * blockLightFalloff(blockLM) * 2.6 * (TORCH_INTENSITY / 100.0);

        color  = albedo * ((ambient + bounceFloor) * ao + direct + block);
        color += c3.rgb * c3.a * 8.0; // coloured self-illumination (HDR, feeds bloom)
        color = aerialPerspective(color, length(viewPos), wDir, wSun, wMoon, wetness);
    }

    vec4 lit = vec4(max(color, 0.0), 1.0);
    outColor        = lit;
    outSceneCapture = lit;
}
