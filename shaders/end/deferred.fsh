#version 330 compatibility
/*
 * End lighting resolve. Dim, directionless: a cool purple ambient, a dark
 * void "sky" with faint stars, and block light + emitters. Shares the rest
 * of the pipeline with the base pack via dimension.properties fallback.
 */
#include "/lib/lumen_common.glsl"
#include "/lib/lumen_uniforms.glsl"
#include "/lib/lumen_space.glsl"
#include "/lib/lumen_sky.glsl"
#include "/lib/lumen_light.glsl"

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor;
in vec2 texcoord;

void main() {
    float depth   = texture(depthtex0, texcoord).r;
    vec3  viewPos = screenToView(texcoord, depth);
    vec3  voidCol = vec3(0.028, 0.020, 0.045);

    vec3 color;
    if (depth >= 1.0) {
        vec3 wDir = viewToWorldDir(normalize(viewPos));
        color = voidCol + vec3(0.7, 0.75, 0.9) * starField(wDir) * 0.6; // faint end stars
    } else {
        vec3  albedo  = pow(texture(colortex0, texcoord).rgb, vec3(2.2));
        float blockLM = texture(colortex2, texcoord).g;
        vec4  c3      = texture(colortex3, texcoord);

        vec3 ambient = vec3(0.11, 0.085, 0.15);                  // cool purple ambient
        vec3 block   = blockLightColor() * blockLightFalloff(blockLM) * 2.6 * (TORCH_INTENSITY / 100.0);

        color  = albedo * (ambient + block);
        color += c3.rgb * c3.a * 8.0;
        color  = mix(color, voidCol, 1.0 - exp(-length(viewPos) * 0.02));
    }
    outColor = vec4(max(color, 0.0), 1.0);
}
