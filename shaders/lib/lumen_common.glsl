/*
 * lumen_common.glsl
 * ------------------------------------------------------------------
 * Shared constants, quality-tier selection, colortex buffer format
 * declarations, debug switches, and small stateless helpers used by
 * every Lumen program.
 *
 * This file is the single source of truth for the buffer layout in
 * docs/01_TECHNICAL_ARCHITECTURE.md section 3.
 *
 * Contains NO stage-specific declarations (no attributes / varyings /
 * `in` / `out`) so it is safe to include from both .vsh and .fsh.
 */
#ifndef LUMEN_COMMON_GLSL
#define LUMEN_COMMON_GLSL

/* ================================================================
 * Math constants
 * ================================================================ */
const float PI      = 3.14159265358979323846;
const float TAU     = 6.28318530717958647692;
const float HALF_PI = 1.57079632679489661923;

/* ================================================================
 * Quality tier (docs/05). One driving option; every tier-gated
 * feature keys off LUMEN_TIER rather than testing features
 * individually.
 * ================================================================ */
#define TIER_LOW    0
#define TIER_MEDIUM 1
#define TIER_HIGH   2
#define TIER_ULTRA  3

// User-facing option (Iris reads the //[..] value list). 0=Low 1=Medium 2=High 3=Ultra.
#define QUALITY_TIER 1 //[0 1 2 3]
#define LUMEN_TIER QUALITY_TIER

/* ================================================================
 * Debug visualization (docs/06 Phase 0 "done" condition).
 * Set DEBUG_BUFFER in the options screen to raw-view a buffer in
 * final.fsh. 0 = off (normal image). 1..9 = colortex1..9, 10 = depth.
 * ================================================================ */
#define DEBUG_BUFFER 0 //[0 1 2 3 4 5 6 7 8 9 10]

// ---- Lighting / exposure user options (docs/02 section 7). Ints: percent / EV*100. ----
#define SUN_INTENSITY   100 //[25 50 75 100 125 150 200]
#define TORCH_INTENSITY 100 //[25 50 75 100 125 150 200]
#define EXPOSURE_COMP   0   //[-200 -150 -100 -50 0 50 100 150 200]

// ---- Water user options (docs/03 section 7). Percent ints. ----
#define WAVE_HEIGHT      100 //[0 25 50 75 100 150 200]
#define REFRACT_STRENGTH 100 //[0 25 50 75 100 150 200]

// ---- Color / post user options (docs/04 section 7). ----
#define BLOOM_INTENSITY 100 //[0 25 50 75 100 150 200]

// ---- Underwater user options (docs/03 section 5). ----
#define CAUSTICS       1   //[0 1]
#define UW_FOG_DENSITY 100 //[25 50 75 100 150 200]

// ---- Ambient occlusion + grading options. ----
#define AO_STRENGTH    100 //[0 25 50 75 100 150 200]
#define DAYNIGHT_GRADE 100 //[0 25 50 75 100 150 200]

// ================================================================
// colortex buffer FORMATS (docs/01 section 3 buffer table).
// These are Iris buffer-format directives, NOT compiled GLSL: the format
// names (RGBA16F, R11F_G11F_B10F, ...) are not GLSL tokens. Per the Iris
// buffer-format docs they must live inside a BLOCK COMMENT (Iris parses
// them here) with one bare directive per line -- no leading '*' and no
// trailing text on a directive line, or detection fails.
// ================================================================
/*
const int colortex0Format = RGBA16F;
const int colortex1Format = RGBA16F;
const int colortex2Format = RGBA8;
const int colortex3Format = RGBA8;
const int colortex4Format = RGBA16F;
const int colortex5Format = RGBA16F;
const int colortex6Format = RGBA16F;
const int colortex7Format = R11F_G11F_B10F;
const int colortex8Format = RGBA16F;
const int colortex9Format = R16F;
*/

/* History / accumulation buffers must NOT clear every frame (default is
 * clear). These are valid GLSL consts, so Iris reads them directly.
 * colortex8 = last-frame color (SSR / TAA-lite); colortex9 = smoothed
 * exposure value. */
const bool colortex8Clear = false;
const bool colortex9Clear = false;

/* ================================================================
 * Octahedral normal encode/decode.
 * Stores a unit vec3 normal in two components (colortex1.xy). Cheaper
 * and more precise than storing raw xyz in 8-bit; kept here so gbuffers
 * (encode) and deferred/composite (decode) never drift.
 * Reference: Cigolle et al., "A Survey of Efficient Representations
 * for Independent Unit Vectors".
 * ================================================================ */
vec2 octEncode(vec3 n) {
    n /= (abs(n.x) + abs(n.y) + abs(n.z));
    vec2 e = n.xy;
    if (n.z < 0.0) {
        e = (1.0 - abs(e.yx)) * vec2(e.x >= 0.0 ? 1.0 : -1.0,
                                     e.y >= 0.0 ? 1.0 : -1.0);
    }
    return e * 0.5 + 0.5; // map [-1,1] -> [0,1] for unorm-friendly storage
}

vec3 octDecode(vec2 e) {
    e = e * 2.0 - 1.0;
    vec3 n = vec3(e.xy, 1.0 - abs(e.x) - abs(e.y));
    float t = max(-n.z, 0.0);
    n.x += n.x >= 0.0 ? -t : t;
    n.y += n.y >= 0.0 ? -t : t;
    return normalize(n);
}

/* Rec. 709 luminance — used by exposure and bright-pass later. */
float luminance(vec3 c) {
    return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

#endif // LUMEN_COMMON_GLSL
