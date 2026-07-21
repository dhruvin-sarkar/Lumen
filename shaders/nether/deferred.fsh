#version 330 compatibility
/*
 * Nether lighting resolve. No directional sun/moon and no analytic sky:
 * ambient is a warm red floor, distance fog uses Minecraft's per-biome
 * fogColor (crimson / warped / soul valley), and block light + emitters
 * (lava, glowstone) carry the scene. Shares gbuffers/composite/final with
 * the base pack via dimension.properties fallback.
 */
#include "/lib/lumen_common.glsl"
#include "/lib/lumen_uniforms.glsl"
#include "/lib/lumen_space.glsl"
#include "/lib/lumen_light.glsl"

uniform vec3 fogColor; // vanilla per-dimension/biome fog colour

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor;
in vec2 texcoord;

void main() {
    float depth   = texture(depthtex0, texcoord).r;
    vec3  viewPos = screenToView(texcoord, depth);
    vec3  fog     = pow(fogColor, vec3(2.2)) * 1.3 + vec3(0.05, 0.012, 0.008); // linear, reddish floor

    vec3 color;
    if (depth >= 1.0) {
        color = fog;
    } else {
        vec3  albedo  = pow(texture(colortex0, texcoord).rgb, vec3(2.2));
        float blockLM = texture(colortex2, texcoord).g;
        vec4  c3      = texture(colortex3, texcoord);

        vec3 ambient = vec3(0.17, 0.075, 0.055);                 // warm nether ambient
        vec3 block   = blockLightColor() * blockLightFalloff(blockLM) * 2.6 * (TORCH_INTENSITY / 100.0);

        color  = albedo * (ambient + block);
        color += c3.rgb * c3.a * 8.0;                            // coloured emitters (lava, glowstone)
        color  = mix(color, fog, 1.0 - exp(-length(viewPos) * 0.045)); // thick nether fog
    }
    outColor = vec4(max(color, 0.0), 1.0);
}
