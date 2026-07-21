#version 330 compatibility
/*
 * Water gbuffer vertex stage. Displaces water vertices by the shared
 * wave height (docs/03 section 1) in world space so the swell is
 * camera-stable; non-water translucents (glass, ice) pass through flat.
 */
#include "/lib/lumen_common.glsl"
#include "/lib/lumen_uniforms.glsl"
#include "/lib/lumen_water_waves.glsl"

in vec4 mc_Entity; // .x = block id from block.properties (10000 = water)

out vec2  v_texcoord;
out vec4  v_tint;
out vec3  v_viewPos;
out vec3  v_worldPos;
out float v_isWater;

void main() {
    vec4 viewPos   = gl_ModelViewMatrix * gl_Vertex;
    vec3 playerPos = (gbufferModelViewInverse * viewPos).xyz;
    vec3 worldPos  = playerPos + cameraPosition;

    v_isWater = (mc_Entity.x == 10000.0) ? 1.0 : 0.0;

    // Displace along world up (docs/03: Low tier is vertex-only, no tess).
    float h = waveHeight(worldPos.xz, frameTimeCounter) * (WAVE_HEIGHT / 100.0) * v_isWater;
    playerPos.y += h;
    worldPos.y  += h;

    vec4 vpos   = gbufferModelView * vec4(playerPos, 1.0);
    gl_Position = gl_ProjectionMatrix * vpos;

    v_viewPos  = vpos.xyz;
    v_worldPos = worldPos;
    v_texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    v_tint     = gl_Color;
}
