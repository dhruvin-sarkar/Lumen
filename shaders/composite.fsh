#version 330 compatibility
/*
 * composite.fsh — water surface resolve (docs/03 sec 2-4) + underwater
 * (sec 5). Water pixels: SSR (sky fallback) / refraction / absorption /
 * shoreline + wave-crest foam. Then, submerged, the whole frame gets
 * absorption fog + wave-synced caustics.
 */
#include "/lib/lumen_common.glsl"
#include "/lib/lumen_uniforms.glsl"
#include "/lib/lumen_space.glsl"
#include "/lib/lumen_sky.glsl"
#include "/lib/lumen_water_color.glsl"
#include "/lib/lumen_water_waves.glsl"

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor;
in vec2 texcoord;

float fresnelSchlick(float cosTheta, float F0) {
    return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
}

// Reflected colour off the water: SSR against the opaque scene, falling
// back to the sky model + sun glint whenever the ray misses (docs/03 §2).
vec3 waterReflection(vec3 viewPos, vec3 worldNormal, vec3 wSun, vec3 wMoon) {
    vec3 wDir = viewToWorldDir(normalize(viewPos));
    vec3 wR   = reflect(wDir, worldNormal);
    wR.y = max(wR.y, 0.02);
    vec3 skyRefl = skyRadiance(wR, wSun, wMoon, wetness)
                 + sunlightColor(wSun.y) * pow(max(dot(wR, wSun), 0.0), 220.0) * 3.0;

#if LUMEN_TIER == TIER_LOW
    return skyRefl; // Low tier: sky + glint only (docs/05)
#else
    vec3 vN   = normalize(mat3(gbufferModelView) * worldNormal);
    vec3 refl = reflect(normalize(viewPos), vN);

    float stepLen = 0.5;
    vec3  rayPos  = viewPos + vN * 0.05;
    int   steps   = (LUMEN_TIER >= TIER_HIGH) ? 32 : 16;

    for (int i = 0; i < steps; i++) {
        rayPos += refl * stepLen;
        vec4 clip = gbufferProjection * vec4(rayPos, 1.0);
        vec2 uv   = clip.xy / clip.w * 0.5 + 0.5;
        if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) break;

        float sd = texture(depthtex1, uv).r;
        if (sd < 1.0) {
            vec3  sp = screenToView(uv, sd);
            float dz = rayPos.z - sp.z;
            if (dz < 0.0 && dz > -0.6) {           // ray crossed behind geometry -> hit
                float edge = smoothstep(0.0, 0.15, min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y)));
                return mix(skyRefl, texture(colortex8, uv).rgb, edge);
            }
        }
        stepLen *= 1.18; // accelerate the march with distance
    }
    return skyRefl;
#endif
}

void main() {
    vec3  sceneColor = texture(colortex0, texcoord).rgb;
    vec4  water      = texture(colortex5, texcoord);
    float depth      = texture(depthtex0, texcoord).r;
    vec3  viewPos    = screenToView(texcoord, depth);
    vec3  wSun       = viewToWorldDir(normalize(sunPosition));
    vec3  wMoon      = viewToWorldDir(normalize(moonPosition));

    vec3 col;

    if (water.r > 0.5) {
        vec3  wnormal = octDecode(water.ba);
        vec3  V       = -viewToWorldDir(normalize(viewPos));
        float fres    = fresnelSchlick(clamp(dot(V, wnormal), 0.0, 1.0), 0.02);

        vec3 reflection = waterReflection(viewPos, wnormal, wSun, wMoon);

        vec2 refrUV   = clamp(texcoord + wnormal.xz * 0.045 * (REFRACT_STRENGTH / 100.0), 0.001, 0.999);
        vec3 backdrop = texture(colortex8, refrUV).rgb;

        float opaqueDepth = texture(depthtex1, texcoord).r;
        float pathLen     = max(length(screenToView(texcoord, opaqueDepth)) - length(viewPos), 0.0);
        vec3  refracted   = waterAbsorb(backdrop, pathLen);

        col = mix(refracted, reflection, fres);

        // Shoreline foam + wave-crest foam (crest is Medium+, docs/05).
        float foam = (1.0 - smoothstep(0.0, 0.9, pathLen)) * smoothstep(0.02, 0.18, pathLen);
#if LUMEN_TIER >= TIER_MEDIUM
        vec3  worldPos = cameraPosition + viewToWorldPos(viewPos);
        float crest = smoothstep(0.10, 0.16, waveHeight(worldPos.xz, frameTimeCounter));
        foam = max(foam, crest * 0.7);
#endif
        col = mix(col, col + vec3(0.6), clamp(foam, 0.0, 1.0) * 0.35);
    } else {
        col = sceneColor;
    }

    // ---- Underwater (docs/03 section 5) ----
    if (isEyeInWater == 1) {
        vec3 amb = skyAmbientColor(wSun, wMoon, wetness);
#if (CAUSTICS == 1) && (LUMEN_TIER >= TIER_MEDIUM)
        if (depth < 1.0) {
            vec3  worldPos = cameraPosition + viewToWorldPos(viewPos);
            float skyLM    = texture(colortex2, texcoord).r;
            col += sunlightColor(max(wSun.y, 0.0)) * caustics(worldPos.xz, frameTimeCounter) * skyLM * 0.6;
        }
#endif
        float fog = 1.0 - exp(-length(viewPos) * 0.12 * (UW_FOG_DENSITY / 100.0));
        col = mix(col, underwaterFogColor(amb), fog);
    }

    outColor = vec4(max(col, 0.0), 1.0);
}
