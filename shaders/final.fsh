#version 330 compatibility
/*
 * final.fsh
 * ------------------------------------------------------------------
 * Presents the scene to the screen. In Phase 0 this is a straight
 * pass-through of colortex0 (unlit albedo) PLUS the buffer visualizer
 * that satisfies the docs/06 Phase 0 "done" condition: every buffer in
 * the docs/01 table can be raw-viewed on screen.
 *
 * The real tonemap / dither / grading pipeline (docs/04) replaces the
 * pass-through in Phase 4. DEBUG_BUFFER must be 0 for normal play.
 */
#include "/lib/lumen_common.glsl"
#include "/lib/lumen_uniforms.glsl"

layout(location = 0) out vec4 fragColor; // -> screen

in vec2 texcoord;

// View-space linear depth in [0,1] for depth debug.
float linearizeDepth01(float d) {
    float z = d * 2.0 - 1.0;
    float linear = (2.0 * near * far) / (far + near - z * (far - near));
    return clamp(linear / far, 0.0, 1.0);
}

void main() {
    vec3 color;

#if DEBUG_BUFFER == 0
    // Normal render path. Phase 0: pass albedo straight through.
    color = texture(colortex0, texcoord).rgb;
#elif DEBUG_BUFFER == 1
    // colortex1: decode octahedral view normal back to a viewable color.
    vec4 t = texture(colortex1, texcoord);
    color = octDecode(t.xy) * 0.5 + 0.5;
#elif DEBUG_BUFFER == 2
    color = texture(colortex2, texcoord).rgb;   // rg = lightmap, b = smoothness
#elif DEBUG_BUFFER == 3
    color = texture(colortex3, texcoord).rgb;   // emission / subsurface
#elif DEBUG_BUFFER == 4
    color = texture(colortex4, texcoord).rgb;   // sky-view LUT (empty until Phase 1)
#elif DEBUG_BUFFER == 5
    color = texture(colortex5, texcoord).rgb;   // water mask/depth/normal
#elif DEBUG_BUFFER == 6
    color = texture(colortex6, texcoord).rgb;   // volumetrics (empty until Phase 1)
#elif DEBUG_BUFFER == 7
    color = texture(colortex7, texcoord).rgb;   // bloom (empty until Phase 4)
#elif DEBUG_BUFFER == 8
    color = texture(colortex8, texcoord).rgb;   // history (empty until Phase 2)
#elif DEBUG_BUFFER == 9
    color = vec3(texture(colortex9, texcoord).r); // exposure scalar
#elif DEBUG_BUFFER == 10
    color = vec3(linearizeDepth01(texture(depthtex0, texcoord).r));
#else
    color = vec3(1.0, 0.0, 1.0);                 // fail-loud magenta (docs/06)
#endif

    fragColor = vec4(color, 1.0);
}
