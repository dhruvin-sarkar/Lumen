# Lumen

A lighting-and-water specialist shader pack for Minecraft Java Edition
1.21.11, built on the Iris shader loader.

Lumen has one focus: make Minecraft's **light** and **water** look
physically grounded and emotionally right — warm torch-lit caves, cold
moonlight through leaves, golden-hour sun on rippling water — while
still running across a wide range of hardware.

> Status: active development. The full lighting, water, underwater, and
> colour pipelines are implemented. It has not yet been through a formal
> in-game QA pass, so treat it as a preview: expect rough edges and
> please report anything that looks wrong.

## Features

**Lighting**
- Analytic sky across the full day/night cycle: warm sunrise/sunset,
  blue-hour, night with twinkling stars, sun & moon discs with glow
- Sun/moon shadows (PCF, softness scales with quality tier)
- Coloured block light with no resource pack required — lava, glowstone,
  sea lanterns, sculk, soul fire, redstone each glow in their own colour
  (labPBR emission is used when a resource pack provides it)
- SSAO, a ground-bounce approximation, and aerial perspective so distant
  terrain dissolves into the sky
- Volumetric light shafts (god rays) and smooth auto-exposure

**Water**
- Layered wave displacement with distance-faded detail normals and rain
  ripples
- Fresnel reflection, screen-space reflections with a sky fallback, a
  sharp sun/moon glint, refraction, and depth-based colour absorption
- Shoreline foam, wave-crest foam, and turbulent waterfall foam

**Underwater**
- Depth-correct fog matching the surface absorption, plus caustics driven
  by the same waves as the surface above

**Colour**
- Filmic (ACES) tonemapping, conservative bloom on light sources, a
  subtle day/night grade, and dithering to keep gradients band-free

## Quality tiers

One **Quality Tier** option (Low / Medium / High / Ultra). Each tier is a
complete, coherent look rather than the top tier with features removed —
lower tiers reduce trace counts, sample counts, and shadow kernel size,
and drop the heaviest effects (SSR, god rays, caustics), but the sky,
water, glint, foam, bloom, and colour pipeline are present at every tier.

## Requirements

- Minecraft Java Edition 1.21.11
- Iris (Fabric/Quilt or NeoForge)
- No resource pack required. labPBR resource packs are supported and add
  detail, but Lumen is designed to look correct on vanilla textures.

## Install

1. Install Iris for Minecraft 1.21.11.
2. Download this repository as a ZIP (or clone and zip the folder so the
   archive root contains the `shaders/` folder and `pack.mcmeta`).
3. Put the ZIP into `.minecraft/shaderpacks/`.
4. In game: Options, Video Settings, Shader Packs, select Lumen.

## Options

All settings live under domain tabs — Lighting, Water, Color & Exposure,
Performance — each with an in-game tooltip. A developer "View Buffer"
debug option can raw-view any pipeline buffer.

## Dimensions

The Overworld gets the full pipeline. The **Nether** and **End** have their
own lighting: no directional sun, dimension-appropriate ambient and fog
(the Nether picks up its biome fog colour; the End is a dim purple void
with faint stars), and god rays disabled. Block light and coloured
emitters (lava, glowstone, shroomlight) carry those scenes.
