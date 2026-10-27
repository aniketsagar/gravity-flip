# Prompt 009 — Graphics milestone G1: neon arcade (2026-10-27)

Summary of the user's prompts (two steps).

## Step 1 — inspect and report (no file changes)

Visual direction: neon arcade with minimal geometry. Palette: background navy `#080B1A`, player cyan `#00F5FF`, ground hazards magenta `#FF2BD6`, ceiling hazards violet `#9D4DFF`, ground and ceiling accents cyan or blue. G1 focuses on the player and hazards.

Inspect `scenes/main.tscn`, `scenes/hazard.tscn`, `scripts/player.gd`, `scripts/hazard.gd`, `scripts/main.gd`, `tests/m3_check.gd`. Report: how the player and hazards render now; the scene node structure; whether visuals are separate from collision shapes; how ground and ceiling hazards differ; which existing nodes or properties can carry neon visuals without changing gameplay; whether the renderer and project settings support a glow approach, and Android performance considerations; a minimal G1 plan. No project-wide HDR or glow without explaining the implications and getting approval. Stop and wait for approval.

## Step 2 — implementation (approved)

Implement: cyan player with bright outline and subtle halo; magenta ground hazards and violet ceiling hazards, each with outline and halo; a thin cyan accent along the inner edge of the ground and ceiling; a solid navy background (approved as part of this prototype; no grid, parallax or decoration).

Constraints: simple Godot nodes and colours; keep the `Visual` nodes as `ColorRect` with their names and `color` property; halo only a few pixels larger than the core; preserve collision shapes and all gameplay (position, gravity, scrolling, spacing, patterns, restart, game over, input locks); no HDR, `WorldEnvironment` glow, shaders, textures, particles, menus or sound; visuals separate from collision nodes; update tests only if necessary and do not weaken assertions.

Verification: run the real test suite and report exact results; inspect the diff; confirm no gameplay constants, collision geometry or logic changed; explain how to preview in Godot; report limitations and rendering impact. Do not commit or push. Stop after reporting.
