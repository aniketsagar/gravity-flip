# Report 009 — Graphics milestone G1: neon arcade (2026-10-27)

Prompt: `../prompts/009-g1-neon-arcade.md`. Inspection, then implementation after approval. **Not committed or pushed** (as instructed); the changes are in the working tree.

## 1. Inspection findings (before the change)
- Everything was a flat `ColorRect`: player yellow 32x32, ground green and ceiling blue (40 px each), hazards all the same red. No textures, shaders, theme or `WorldEnvironment`; default grey clear colour.
- Visuals were separate sibling nodes from the `CollisionShape2D`s. The only link was code setting `Visual.size` and `Visual.position` from the same size as the shape.
- Ground and ceiling hazards used the same scene and colour; they differed only by `ceiling_side` and placement.
- The test suite reads `get_node("Visual").color` on the player, hazard, ground and ceiling, so `Visual` had to stay a `ColorRect`.
- Renderer: GL Compatibility on Godot 4.7. Glow would need `WorldEnvironment` and HDR 2D (project-wide); I did not verify glow support for 4.7. G1 uses layered alpha rects instead.

## 2. What changed
| File | Change |
|---|---|
| `scenes/main.tscn` | Player `Visual` colour to cyan; new `Halo` (`ColorRect`, 25% alpha, 4 px larger each side, behind) and `Outline` (`ReferenceRect`, 2 px, lighter cyan). Ground and ceiling `Visual` colour to dark blue `(0.07, 0.12, 0.28)`; new 3 px cyan `Accent` on each. |
| `scenes/hazard.tscn` | New `Halo` and `Outline` nodes around `Visual`; default colours magenta. |
| `scripts/hazard.gd` | `GROUND_COLOR` `#ff2bd6`, `CEILING_COLOR` `#9d4dff`, `HALO_PAD = 4`, `HALO_ALPHA = 0.25`. `place()` picks the colour by `ceiling_side` and sizes the halo and outline with `Visual`. |
| `scripts/main.gd` | `ACCENT_THICKNESS = 3`; `_place_surface` gains `accent_on_top` and positions the `Accent` (top edge for ground, bottom edge for ceiling). |
| `project.godot` | `environment/defaults/default_clear_color` = navy `#080B1A`. No HDR, no glow. |

All new nodes have `mouse_filter = 2` (ignore). `Visual` nodes keep their names and `color` property. No collision node was touched.

## 3. Verification
| Check | Result |
|---|---|
| `godot --headless --path . --script res://tests/m3_check.gd` | PASS, 80 checks, 0 failures, `RESULT: ALL PASSED` (the existing "hazard colour differs clearly from ground, ceiling and player" check passes unchanged) |
| Diff review | No gameplay constant, collision shape or gameplay logic changed; the new code only sets colours, sizes and positions of visual nodes |
| `git diff --check` | No whitespace errors |
| Test file | Not edited |
| Appearance in the editor or on the phone | NOT RUN (pending manual test) |

The tests do not assess how it looks.

## 4. Preview
Open the project in the Godot editor, open `scenes/main.tscn` and press F5. Press F6 in `scenes/hazard.tscn` to see one hazard.

## 5. Limitations and concerns
- Draw cost: each hazard now draws 3 rects instead of 1. Expected to be negligible; not measured on the M52.
- Halo alpha and outline brightness are first guesses and may need tuning against the navy background.
- The halo extends 4 px past the collision box, so near-misses can look slightly tighter than they are.
- Existing, unverified: `ColorRect`s default to swallowing mouse input, and the game reads taps in `_unhandled_input`, so a tap on a hazard or the ground strip might not flip gravity. Pre-existing and not changed by G1.
- Next step: review the look on the navy background, then decide further graphics work (background and environment are a later milestone).
