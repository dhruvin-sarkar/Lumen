# Lumen — Documentation Set for Coding Agents

This folder is the full brief for building **Lumen**, a Minecraft: Java Edition
1.21.11 shader pack built on the **Iris** shader loader. Feed these files to
your coding agent (Claude Opus 4.8 or otherwise) as project context before
any implementation work begins.

## Reading order

1. **00_VISION_AND_SCOPE.md** — What Lumen is, what it deliberately is not,
   and the design principles that should resolve every ambiguous decision.
2. **01_TECHNICAL_ARCHITECTURE.md** — The Iris rendering pipeline, buffer
   layout, program map, and repo/file structure. Read this before writing
   any GLSL.
3. **02_LIGHTING_SYSTEM_SPEC.md** — Sky, sun/moon, block light, ambient
   occlusion, bounce light, volumetrics, exposure. The core of the pack.
4. **03_WATER_SYSTEM_SPEC.md** — Surface waves, reflections, refraction,
   foam, underwater color/fog/caustics, connection to the lighting system.
5. **04_COLOR_AND_POST_SPEC.md** — Tonemapping, white balance, bloom,
   dithering — how raw lighting data becomes the final image.
6. **05_PERFORMANCE_AND_QUALITY_TIERS.md** — The performance budget,
   the quality-tier ladder, and the specific techniques allowed/forbidden
   at each tier.
7. **06_CODING_STANDARDS_AND_ROADMAP.md** — Naming conventions, GLSL
   style, `shaders.properties` conventions, and the phased build plan
   with a definition-of-done per phase.

## How the agent should use this set

- Treat **00** as the constitution: if a technical decision in 01–05
  conflicts with it, 00 wins.
- Treat **01** as load-bearing: buffer assignments and program names
  defined there are the single source of truth. Don't invent a new
  colortex layout mid-project — update the doc first, then the code.
- **02–04** are feature specs, not tutorials. They describe *what* the
  effect must achieve and the *constraints* it must respect (performance
  tier, buffer budget, art direction). The agent chooses the exact GLSL.
- **05** is not optional polish — every feature spec is written assuming
  its tier limits will be enforced. A feature that only works at Ultra
  and silently tanks performance at Medium is a bug.
- **06** defines what "done" means for each phase so the agent can stop
  and request review at the right checkpoints instead of building the
  entire pack in one uninterrupted pass.

## One-line project summary

Lumen is a **lighting-and-water specialist** shader pack: no attempt is
made to be the best at shadows-as-a-feature, stylized post effects, or
generic "everything" shader bloat. Every decision should ask "does this
make lighting or water more beautiful, more correct, or cheaper to
render?" — if the answer is no to all three, it doesn't belong in Lumen.
