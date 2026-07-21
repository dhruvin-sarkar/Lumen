#version 330 compatibility
/*
 * composite.fsh — water surface resolve (docs/03 sections 2-4) AND the
 * underwater experience (section 5), so no extra full-screen pass.
 *
 * Water pixels get Fresnel reflection (sky + glint) / refraction (colortex8
 * backdrop) / absorption / shoreline foam. Then, when the camera is
 * submerged, the WHOLE frame gets exponential fog tinted by the same
 * absorption model plus wave-synced caustics on lit surfaces.
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
        vec3  wDir    = viewToWorldDir(normalize(viewPos));
        vec3  V       = -wDir;
        float fres    = fresnelSchlick(clamp(dot(V, wnormal), 0.0, 1.0), 0.02);

        vec3 R = reflect(wDir, wnormal);
        R.y = max(R.y, 0.02);
        vec3 reflection = skyRadiance(R, wSun, wMoon, wetness);
        reflection += sunlightColor(wSun.y) * pow(max(dot(R, wSun), 0.0), 220.0) * 3.0;

        vec2 refrUV   = clamp(texcoord + wnormal.xz * 0.045 * (REFRACT_STRENGTH / 100.0), 0.001, 0.999);
        vec3 backdrop = texture(colortex8, refrUV).rgb;

        float opaqueDepth = texture(depthtex1, texcoord).r;
        vec3  opaqueView  = screenToView(texcoord, opaqueDepth);
        float pathLen     = max(length(opaqueView) - length(viewPos), 0.0);
        vec3  refracted   = waterAbsorb(backdrop, pathLen);

        col = mix(refracted, reflection, fres);
        float foam = (1.0 - smoothstep(0.0, 0.9, pathLen)) * smoothstep(0.02, 0.18, pathLen);
        col = mix(col, col + vec3(0.6), foam * 0.35);
    } else {
        col = sceneColor;
    }

    // ---- Underwater experience (docs/03 section 5) ----
    if (isEyeInWater == 1) {
        vec3  amb = skyAmbientColor(wSun, wMoon, wetness);

#if CAUSTICS == 1
        if (depth < 1.0) {
            vec3  worldPos = cameraPosition + viewToWorldPos(viewPos);
            float skyLM    = texture(colortex2, texcoord).r;
            float ca       = caustics(worldPos.xz, frameTimeCounter);
            col += sunlightColor(max(wSun.y, 0.0)) * ca * skyLM * 0.6;
        }
#endif
        float density = 0.12 * (UW_FOG_DENSITY / 100.0);
        float fog     = 1.0 - exp(-length(viewPos) * density);
        col = mix(col, underwaterFogColor(amb), fog);
    }

    outColor = vec4(max(col, 0.0), 1.0);
}
