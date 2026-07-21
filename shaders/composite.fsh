#version 330 compatibility
/*
 * composite.fsh — water surface resolve (docs/03 sections 2-4).
 * Re-shades water pixels (flagged in colortex5 by gbuffers_water):
 *   reflection  = sky in the reflected wave direction + sun/moon glint
 *                 (the sky is the SSR fallback, docs/03 section 2)
 *   refraction  = pre-water backdrop (colortex8) bent by the wave normal
 *   absorption  = Beer-Lambert tint by water path length (lumen_water_color)
 *   Fresnel     = blends refraction (looking down) vs reflection (grazing)
 *   foam        = thin shoreline band where opaque geometry is just behind
 * Non-water pixels pass straight through. SSR / wave-crest foam / caustics
 * are Medium+ additions in later increments (docs/05 tier matrix).
 */
#include "/lib/lumen_common.glsl"
#include "/lib/lumen_uniforms.glsl"
#include "/lib/lumen_space.glsl"
#include "/lib/lumen_sky.glsl"
#include "/lib/lumen_water_color.glsl"

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor;
in vec2 texcoord;

float fresnelSchlick(float cosTheta, float F0) {
    return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
}

void main() {
    vec3 sceneColor = texture(colortex0, texcoord).rgb;
    vec4 water      = texture(colortex5, texcoord);

    if (water.r < 0.5) {         // not water -> unchanged
        outColor = vec4(sceneColor, 1.0);
        return;
    }

    vec3  wnormal = octDecode(water.ba);            // world space, up = +Y
    float depth   = texture(depthtex0, texcoord).r;
    vec3  viewPos = screenToView(texcoord, depth);
    vec3  wDir    = viewToWorldDir(normalize(viewPos)); // camera -> fragment
    vec3  V       = -wDir;
    vec3  wSun    = viewToWorldDir(normalize(sunPosition));
    vec3  wMoon   = viewToWorldDir(normalize(moonPosition));

    float cosT = clamp(dot(V, wnormal), 0.0, 1.0);
    float fres = fresnelSchlick(cosT, 0.02);

    // Reflection: sky in the reflected direction + a sharp sun glint.
    vec3 R = reflect(wDir, wnormal);
    R.y = max(R.y, 0.02);
    vec3 reflection = skyRadiance(R, wSun, wMoon, wetness);
    reflection += sunlightColor(wSun.y) * pow(max(dot(R, wSun), 0.0), 220.0) * 3.0;

    // Refraction: pre-water backdrop, bent by the wave normal.
    vec2 refrUV   = clamp(texcoord + wnormal.xz * 0.045 * (REFRACT_STRENGTH / 100.0), 0.001, 0.999);
    vec3 backdrop = texture(colortex8, refrUV).rgb;

    // Water path length -> absorption tint + shoreline foam.
    float opaqueDepth = texture(depthtex1, texcoord).r;
    vec3  opaqueView  = screenToView(texcoord, opaqueDepth);
    float pathLen     = max(length(opaqueView) - length(viewPos), 0.0);
    vec3  refracted   = waterAbsorb(backdrop, pathLen);

    vec3 col = mix(refracted, reflection, fres);

    // Lit shoreline foam (fades out at the very edge to dodge z-fighting).
    float foam = (1.0 - smoothstep(0.0, 0.9, pathLen)) * smoothstep(0.02, 0.18, pathLen);
    col = mix(col, col + vec3(0.6), foam * 0.35);

    outColor = vec4(max(col, 0.0), 1.0);
}
