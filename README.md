# Lumen

A lighting and water focused shader pack for Minecraft Java Edition
1.21.11, built on the Iris shader loader.

Lumen has a single focus: make Minecraft light and water look
physically grounded and emotionally right, from warm torchlit caves to
golden-hour sun on rippling water, while staying playable across a wide
range of hardware.

## Status

Early work in progress. The rendering pipeline skeleton (Phase 0) is in
place: the gbuffer layout, a shadow depth pass, and an on-screen debug
buffer viewer. Lighting, water, and the color pipeline are next.

## Requirements

- Minecraft Java Edition 1.21.11
- Iris (Fabric/Quilt or NeoForge)
- No resource pack required. labPBR resource packs are supported and
  look better, but Lumen is designed to look correct on vanilla
  textures.

## Install

1. Install Iris for Minecraft 1.21.11.
2. Download or clone this repository.
3. Put the folder (or a zip of it) into .minecraft/shaderpacks
4. In game: Video Settings, Shader Packs, select Lumen.

## Quality tiers

Lumen exposes a single Quality Tier option with four settings: Low,
Medium, High, and Ultra. Each tier is a complete, coherent look rather
than the top tier with features removed. Lower tiers reduce resolution
and step counts, not the presence of a feature.
