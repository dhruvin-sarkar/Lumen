/*
 * lumen_sky.glsl — single source of truth for sky + direct-light colour
 * (docs/02 section 1, docs/07). Sun/moon direct, sky ambient, aerial
 * perspective, water reflection all read from here.
 */
#ifndef LUMEN_SKY_GLSL
#define LUMEN_SKY_GLSL
#include "/lib/lumen_common.glsl"
#include "/lib/lumen_uniforms.glsl"

vec3 sunlightColor(float sunY) {
    float d = clamp(sunY, 0.0, 1.0);
    vec3 c = mix(vec3(1.00, 0.42, 0.16), vec3(1.00, 0.96, 0.90), smoothstep(0.0, 0.30, d));
    return c * smoothstep(-0.08, 0.14, sunY) * 3.0;
}

vec3 moonlightColor(float moonY) {
    float d = smoothstep(-0.06, 0.20, moonY);
    float mp = float(moonPhase);
    float fullness = 1.0 - min(mp, 8.0 - mp) / 4.0;
    return vec3(0.50, 0.66, 1.00) * d * (0.20 + 0.80 * fullness) * 0.35;
}

// Sparse twinkling star field for upward night directions.
float starField(vec3 dir) {
    if (dir.y < 0.05) return 0.0;
    vec2 uv = dir.xz / (dir.y + 0.25);
    vec2 g  = floor(uv * 90.0);
    vec2 h2 = fract(g * vec2(123.34, 456.21));
    h2 += dot(h2, h2 + 45.32);
    float h = fract(h2.x * h2.y);
    float s = smoothstep(0.992, 1.0, h);
    return s * (0.5 + 0.5 * sin(frameTimeCounter * 2.5 + h * 100.0)); // twinkle
}

vec3 skyRadiance(vec3 dir, vec3 sunDir, vec3 moonDir, float rain) {
    float up   = clamp(dir.y * 0.5 + 0.5, 0.0, 1.0);
    float sunY = sunDir.y;
    float dayF = smoothstep(-0.10, 0.20, sunY);

    vec3 zenith  = mix(vec3(0.010, 0.020, 0.055), vec3(0.14, 0.34, 0.78), dayF);
    vec3 horizon = mix(vec3(0.030, 0.050, 0.100), vec3(0.62, 0.76, 0.96), dayF);

    // Warm sunrise/sunset band, pushed hard (docs/07).
    float low  = smoothstep(0.0, 0.22, sunY) * (1.0 - smoothstep(0.22, 0.55, sunY));
    float band = pow(1.0 - up, 2.6) * low;
    horizon = mix(horizon, vec3(1.05, 0.42, 0.16), band * 1.15);

    vec3 col = mix(horizon, zenith, pow(up, 0.6));

    // Stars first (so sun/moon glow sits on top), fading out with daylight.
    col += vec3(0.85, 0.90, 1.00) * starField(dir) * (1.0 - dayF) * 1.6;

    // Sun: broad glow, tight glow, crisp disk.
    float sd = max(dot(dir, sunDir), 0.0);
    vec3  sunC = sunlightColor(sunY);
    col += sunC * (pow(sd, 8.0) * 0.20 + pow(sd, 256.0) * 1.2);
    col += sunC * smoothstep(0.9992, 0.9996, sd) * 8.0;

    // Moon: soft glow + disk.
    float md = max(dot(dir, moonDir), 0.0);
    vec3  moonC = moonlightColor(moonDir.y);
    col += moonC * (pow(md, 32.0) * 0.6 + smoothstep(0.9993, 0.9997, md) * 6.0);

    float lum = luminance(col);
    col = mix(col, vec3(lum) * 0.55, rain * 0.7);
    return max(col, 0.0);
}

vec3 skyAmbientColor(vec3 sunDir, vec3 moonDir, float rain) {
    vec3 zen = skyRadiance(vec3(0.0, 1.0, 0.0), sunDir, moonDir, rain);
    vec3 hor = skyRadiance(normalize(vec3(1.0, 0.15, 0.0)), sunDir, moonDir, rain);
    return zen * 0.55 + hor * 0.45;
}

// Aerial perspective: distant geometry dissolves into the horizon sky
// (docs/07) instead of hard-cutting. dist in blocks.
vec3 aerialPerspective(vec3 color, float dist, vec3 dir, vec3 sunDir, vec3 moonDir, float rain) {
    float f = (1.0 - exp(-dist * 0.0025)) * 0.7 * (1.0 + rain);
    vec3  horizonSky = skyRadiance(normalize(vec3(dir.x, 0.10, dir.z)), sunDir, moonDir, rain);
    return mix(color, horizonSky, clamp(f, 0.0, 0.85));
}

#endif
