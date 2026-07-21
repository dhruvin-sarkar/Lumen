#version 330 compatibility
/*
 * final.fsh — present to screen.
 * Normal path: apply exposure, filmic tonemap, sRGB encode (docs/04).
 * Debug path (DEBUG_BUFFER): raw-view any pipeline buffer (docs/06
 * Phase 0). Auto-exposure (colortex9) replaces the constant in Phase 1c.
 */
#include "/lib/lumen_common.glsl"
#include "/lib/lumen_uniforms.glsl"
#include "/lib/lumen_color.glsl"

layout(location = 0) out vec4 fragColor; // -> screen
in vec2 texcoord;

float linearizeDepth01(float d) {
    float z = d * 2.0 - 1.0;
    float linear = (2.0 * near * far) / (far + near - z * (far - near));
    return clamp(linear / far, 0.0, 1.0);
}

void main() {
    vec3 color;

#if DEBUG_BUFFER == 0
    vec3 hdr = texture(colortex0, texcoord).rgb;
    const float exposure = 1.1; // constant until Phase 1c auto-exposure
    color = linearToSRGB(tonemapACES(hdr * exposure));
#elif DEBUG_BUFFER == 1
    color = octDecode(texture(colortex1, texcoord).xy) * 0.5 + 0.5;
#elif DEBUG_BUFFER == 2
    color = texture(colortex2, texcoord).rgb;
#elif DEBUG_BUFFER == 3
    color = texture(colortex3, texcoord).rgb;
#elif DEBUG_BUFFER == 4
    color = texture(colortex4, texcoord).rgb;
#elif DEBUG_BUFFER == 5
    color = texture(colortex5, texcoord).rgb;
#elif DEBUG_BUFFER == 6
    color = texture(colortex6, texcoord).rgb;
#elif DEBUG_BUFFER == 7
    color = texture(colortex7, texcoord).rgb;
#elif DEBUG_BUFFER == 8
    color = texture(colortex8, texcoord).rgb;
#elif DEBUG_BUFFER == 9
    color = vec3(texture(colortex9, texcoord).r);
#elif DEBUG_BUFFER == 10
    color = vec3(linearizeDepth01(texture(depthtex0, texcoord).r));
#else
    color = vec3(1.0, 0.0, 1.0);
#endif

    fragColor = vec4(color, 1.0);
}
