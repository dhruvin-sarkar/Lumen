#version 330 compatibility
/*
 * final.fsh — present to screen (docs/04). Normal path: bloom + exposure,
 * day/night grade, filmic tonemap, sRGB encode, dither. Debug path
 * raw-views a buffer.
 */
#include "/lib/lumen_common.glsl"
#include "/lib/lumen_uniforms.glsl"
#include "/lib/lumen_color.glsl"

layout(location = 0) out vec4 fragColor;
in vec2 texcoord;

const bool colortex7MipmapEnabled = true; // for mip-blurred bloom

float linearizeDepth01(float d) {
    float z = d * 2.0 - 1.0;
    return clamp((2.0 * near * far) / (far + near - z * (far - near)) / far, 0.0, 1.0);
}

vec3 sampleBloom(vec2 uv) {
    vec3 b = vec3(0.0);
    b += textureLod(colortex7, uv, 1.0).rgb * 0.30;
    b += textureLod(colortex7, uv, 2.0).rgb * 0.26;
    b += textureLod(colortex7, uv, 3.0).rgb * 0.22;
    b += textureLod(colortex7, uv, 4.0).rgb * 0.14;
    b += textureLod(colortex7, uv, 5.0).rgb * 0.08;
    return b;
}

void main() {
    vec3 color;

#if DEBUG_BUFFER == 0
    vec2 uv = texcoord;
    if (isEyeInWater == 1) uv += vec2(sin(uv.y * 22.0 + frameTimeCounter * 2.3), cos(uv.x * 19.0 + frameTimeCounter * 1.9)) * 0.0022; // underwater warp / meniscus (docs/03 sec 5)
    vec3  hdr = texture(colortex0, uv).rgb;
    hdr += sampleBloom(uv) * (BLOOM_INTENSITY / 100.0);
    float exposure = texture(colortex9, vec2(0.5)).r;
    if (!(exposure > 0.0)) exposure = 1.0;
    exposure *= exp2(EXPOSURE_COMP / 100.0);
    hdr *= exposure;

    float sunY = normalize(mat3(gbufferModelViewInverse) * sunPosition).y;
    hdr = dayNightGrade(hdr, sunY, DAYNIGHT_GRADE / 100.0);

    color  = linearToSRGB(tonemapACES(hdr));
    color += ditherLSB(gl_FragCoord.xy) / 255.0; // break 8-bit banding
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
