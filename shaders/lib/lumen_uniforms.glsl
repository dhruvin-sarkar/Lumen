/*
 * lumen_uniforms.glsl
 * ------------------------------------------------------------------
 * Central declaration of the Iris-provided uniforms and samplers Lumen
 * uses, plus (later) Lumen's own custom uniforms. Declaring them once
 * keeps every program consistent and avoids "which name did we use for
 * the atlas sampler again?" drift.
 *
 * Uniform DECLARATIONS only — safe to include from .vsh and .fsh.
 * Unused declarations are stripped by the compiler, so it is fine for a
 * vertex stage to include sampler declarations it never reads.
 *
 * NOTE (docs/01 section 7): a handful of these are flagged as
 * "verify against the pinned Iris version" — normal-encoding samplers
 * and depthtex semantics in particular. They are declared here but not
 * yet consumed in Phase 0.
 */
#ifndef LUMEN_UNIFORMS_GLSL
#define LUMEN_UNIFORMS_GLSL

/* ---- Camera / projection matrices ---- */
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferPreviousProjection;

/* ---- Shadow-space matrices ---- */
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowProjectionInverse;

/* ---- World / light directions & positions ---- */
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform vec3 sunPosition;          // view-space
uniform vec3 moonPosition;         // view-space
uniform vec3 shadowLightPosition;  // view-space (sun by day, moon by night)
uniform vec3 upPosition;           // view-space up

/* ---- Time / world state ---- */
uniform float frameTimeCounter;    // seconds since load, wraps
uniform int   frameCounter;
uniform int   worldTime;           // ticks 0..23999
uniform int   worldDay;
uniform int   moonPhase;           // 0..7
uniform float sunAngle;            // 0..1 over full day
uniform float rainStrength;        // 0..1
uniform float wetness;             // smoothed rainStrength

/* ---- Viewport / frustum ---- */
uniform float viewWidth;
uniform float viewHeight;
uniform float aspectRatio;
uniform float near;
uniform float far;

/* ---- Player / eye state ---- */
uniform int   isEyeInWater;        // 0 air, 1 water, 2 lava, 3 powder snow
uniform float blindness;
uniform float nightVision;
uniform float darknessFactor;

/* ---- Scene color / gbuffer attachments ---- */
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D colortex6;
uniform sampler2D colortex7;
uniform sampler2D colortex8;
uniform sampler2D colortex9;

/* ---- Depth attachments (docs/01 section 3 note: confirm exact
 *      depthtex semantics against the pinned Iris release) ---- */
uniform sampler2D depthtex0;       // full scene depth
uniform sampler2D depthtex1;       // translucents excluded
uniform sampler2D depthtex2;       // water/handheld excluded

/* ---- Shadow attachments ---- */
uniform sampler2D shadowtex0;      // all geometry
uniform sampler2D shadowtex1;      // opaque only (translucents excluded)
uniform sampler2D shadowcolor0;
uniform sampler2D shadowcolor1;

/* ---- Material / texture samplers (gbuffers stages) ---- */
uniform sampler2D gtexture;        // bound block/entity atlas
uniform sampler2D lightmap;        // vanilla lightmap texture
uniform sampler2D normals;         // labPBR normal atlas
uniform sampler2D specular;        // labPBR specular atlas
uniform sampler2D noisetex;        // noise texture (if declared in properties)

#endif // LUMEN_UNIFORMS_GLSL
