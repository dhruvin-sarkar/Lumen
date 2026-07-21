/*
 * lumen_sky.glsl — the single source of truth for sky and direct-light
 * colour (docs/02 section 1, docs/07). Sun/moon direct colour, sky
 * ambient, aerial perspective and water reflections ALL read from here,
 * so golden-hour is consistent everywhere instead of per-effect hacks.
 *
 * Hand-tuned analytic model (Preetham-flavoured, not strictly physical):
 * the goal is "light as it should feel", pushed hard at sunrise/sunset
 * per the ambition directive.
 */
#ifndef LUMEN_SKY_GLSL
#define LUMEN_SKY_GLSL
#include "/lib/lumen_common.glsl"
#include "/lib/lumen_uniforms.glsl"

// Direct sunlight colour as a function of world-space sun elevation (y).
// Warm orange near the horizon, near-neutral bright at noon, fades out
// through the blue hour as the sun drops below the horizon.
vec3 sunlightColor(float sunY) {
    float d = clamp(sunY, 0.0, 1.0);
    vec3 horizon = vec3(1.00, 0.42, 0.16); // sunrise/sunset
    vec3 noon    = vec3(1.00, 0.96, 0.90);
    vec3 c = mix(horizon, noon, smoothstep(0.0, 0.30, d));
    float intensity = smoothstep(-0.08, 0.14, sunY);
    return c * intensity * 3.0;
}

// Direct moonlight: cool, dim, scaled by vanilla moon phase (0 = full).
vec3 moonlightColor(float moonY) {
    float d = smoothstep(-0.06, 0.20, moonY);
    float mp = float(moonPhase);
    float fullness = 1.0 - min(mp, 8.0 - mp) / 4.0; // 1 at full, 0 at new
    return vec3(0.50, 0.66, 1.00) * d * (0.20 + 0.80 * fullness) * 0.35;
}

// Full sky radiance for a world-space view direction.
vec3 skyRadiance(vec3 dir, vec3 sunDir, vec3 moonDir, float rain) {
    float up   = clamp(dir.y * 0.5 + 0.5, 0.0, 1.0);
    float sunY = sunDir.y;
    float dayF = smoothstep(-0.10, 0.20, sunY);

    vec3 zenith  = mix(vec3(0.010, 0.020, 0.055), vec3(0.14, 0.34, 0.78), dayF);
    vec3 horizon = mix(vec3(0.030, 0.050, 0.100), vec3(0.62, 0.76, 0.96), dayF);

    // Warm horizon band peaking when the sun is low (sunrise/sunset).
    float low  = smoothstep(0.0, 0.22, sunY) * (1.0 - smoothstep(0.22, 0.55, sunY));
    float band = pow(1.0 - up, 3.0) * low;
    horizon = mix(horizon, vec3(1.0, 0.45, 0.20), band);

    vec3 col = mix(horizon, zenith, pow(up, 0.6));

    // Sun: broad Mie glow, tight near-disk glow, and a crisp disk.
    float sd = max(dot(dir, sunDir), 0.0);
    vec3  sunC = sunlightColor(sunY);
    col += sunC * (pow(sd, 8.0) * 0.20 + pow(sd, 256.0) * 1.2);
    col += sunC * smoothstep(0.9992, 0.9996, sd) * 8.0;      // disk

    // Moon: soft glow + small disk.
    float md = max(dot(dir, moonDir), 0.0);
    vec3  moonC = moonlightColor(moonDir.y);
    col += moonC * (pow(md, 32.0) * 0.6 + smoothstep(0.9993, 0.9997, md) * 6.0);

    // Rain flattens + desaturates + darkens the whole model.
    float lum = luminance(col);
    col = mix(col, vec3(lum) * 0.55, rain * 0.7);
    return max(col, 0.0);
}

// Cheap hemispheric ambient: blend of zenith and horizon sky radiance.
vec3 skyAmbientColor(vec3 sunDir, vec3 moonDir, float rain) {
    vec3 zen = skyRadiance(vec3(0.0, 1.0, 0.0), sunDir, moonDir, rain);
    vec3 hor = skyRadiance(normalize(vec3(1.0, 0.15, 0.0)), sunDir, moonDir, rain);
    return zen * 0.55 + hor * 0.45;
}

#endif
