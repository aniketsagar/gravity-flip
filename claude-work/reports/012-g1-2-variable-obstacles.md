# Report 012 — G1.2 variable-sized obstacles: inspection (2026-10-27)

Prompt: `../prompts/012-g1-2-variable-obstacles.md`. Inspection and planning only. No project file was modified, nothing was run, nothing committed or pushed. Verified = read from the current `main.gd`, `hazard.gd` and the function list and hazard-height references in `tests/m3_check.gd`; the scenes were not re-opened this turn (as last edited). All distances and times below are calculated by hand from the physics constants, not run.

## 1. Current architecture (verified)
- `main.gd` `_spawn_hazards()` walks `PATTERNS` in order; a hazard spawns when its left edge is within `SPAWN_AHEAD` (100 px) beyond the right edge. `_refresh_hazards()` sets `position.x = world_x - _scroll` and frees a hazard when its right edge passes the left edge. Spawn and recycle depend on a hazard's width and x, never its height.
- Each spec has `w` and `h` in pixels; `Hazard.place()` takes them as one `Vector2`. `ceiling_side` selects position and colour.
- Visual and collision dimensions come from one `size` in `Hazard.place()` (new `RectangleShape2D`, `Visual`, `Outline` the same size, `Halo` 8 px larger), so they are already synchronised.
- Spacing: a spec's `x` is a fraction of the visible width (one lap), and lap n is offset by n widths. In-lap 0.45W to 0.93W is 230 px between centres at W = 480; across laps 0.93W to 1.45W is 250 px. Edge to edge that is about 190-210 px.
- Current heights are 120, 160, 180, 160 px, i.e. 15-23% of a 774 px playable height (all "small").
- Resize: `_place_hazards()` re-places hazards from their stored pixel size; x scales with the width but heights stay fixed pixels.

## 2. Playable height
`P = rect.size.y - 2 * SURFACE_THICKNESS` (ceiling inner face to ground inner face). Not computed anywhere today. 774 px at 480x854, 986 px at 480x1066 (the layout I expect on the Galaxy M52 under `expand`; assumption, the 540x1200 test window produces that rect). Hazards attach to the surface faces, so any height at or below 0.66 P stays inside the playable area; test bound 0.67 P.

## 3. Fairness analysis (calculated)
After a flip the player has 600 px/s toward the far surface, accelerating at 2700 to a 1000 px/s cap. To clear an obstacle of height h it must travel about h. Time t(h) = 0.148 s + (h - 118.5)/1000 for h > 118.5. At the 200 px/s scroll speed and with a 32 px player and a reaction margin R, the edge-to-edge gap before a hazard must satisfy:

`gap >= 32 + 200 * t(h) + R`

Using R = 60 px (0.3 s):

| Fraction of P | P = 774: h / required gap | P = 986: h / required gap |
|---|---|---|
| 0.20 | 155 / 129 | 197 / 138 |
| 0.38 | 294 / 157 | 375 / 173 |
| 0.50 | 387 / 175 | 494 / 197 |
| 0.58 | 449 / 188 | 572 / 212 |
| 0.66 | 511 / 200 | 651 / 228 |

Available gaps are about 190-210 px. Result: Small and Medium are fair on both heights; Large is marginal near 0.50 and fails above that on the tall layout; the 0.66 maximum is not fair at the current spacing. Fixed fractions get harder on taller screens because physics is in pixels. The first obstacle has about 145 px of approach, so it must stay small. Opposite-side obstacles overlapping in x would need `P - hA - hB >= 32 + margin`; the gap rule prevents any overlap. Strict ground/ceiling alternation keeps the opposite surface free.

## 4. Proposed strategy
- Selection: authored, deterministic patterns, with `h_frac` (fraction of P) replacing `h`. Category constants: Small 0.15-0.22, Medium 0.30-0.40, Large 0.45-0.58. Weighted random is deferred and would only pick from pairs the fairness test has validated.
- Pixel height = `h_frac * P` at spawn and on resize (Hazard stores `h_frac`). Widths stay 30-50 px.
- Option A (recommended first): keep the lap layout; use Small and Medium plus a few Large near 0.45-0.50. Does not reach 0.66.
- Option B (needed for 0.50-0.66): per-pattern length in pixels (about 540 px or more for two maximum hazards) using a running spawn origin instead of `lap * width`.

## 5. Files and functions that would change
`scripts/main.gd` (`PATTERNS`, playable-height helper, `_spawn_hazards`, `_place_hazards`; Option B also the spawn origin), `scripts/hazard.gd` (`h_frac`, `place()`), `tests/m3_check.gd` (places reading `spec["h"]`: scroll, lifecycle and sequence checks). No scene, player or scroll-speed change.

## 6. Tests
Automatable: each spec's height is in its category, at most 0.67 P and inside the playable area at 480x854, 480x1066 and 1281x854; visual, halo, outline and collision sizes stay synchronised; the fairness rule holds for every consecutive pair including lap boundaries, computed from the player's real constants, with opposite-side clearance and no overlap; a bot that reacts only at `200 * t(h) + R` survives several laps at every size, and a zero-margin bot shows it is physically possible (the existing 100/200 px bot leads are too short for tall obstacles and need per-hazard leads); heights rescale on resize; restart resets sizes and sequence; existing assertions that read `spec["h"]` are adapted, not weakened. Needs a playtest on the M52: whether R = 60 px feels fair, readability of tall obstacles, pacing.

## 7. Risks and open decisions
1. Option A or B, hence whether 0.66 is in scope for G1.2.
2. The reaction margin R (0.3 s is a guess).
3. The M52 layout of 480x1066 is unconfirmed.
4. The new pattern list is a proposal; pattern 0 stays small so the first approach is fair.
5. A taller window makes the same fractions harder (orientation is locked on mobile).

## 8. Commands after implementation
```
godot --headless --path . --script res://tests/m3_check.gd
git diff --check
git diff   # confirm only main.gd, hazard.gd and the tests changed
```
Then F5 in the editor and a playtest on the M52.

## Status
Waiting for approval and the Option A or B decision. Verification of any behaviour: NOT RUN (inspection only).
