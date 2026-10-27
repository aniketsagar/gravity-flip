# Report 013 — G1.2 Option B: implementation plan (2026-10-27)

Prompt: `../prompts/013-g1-2-option-b-plan.md`. Planning only. No project file was modified, nothing committed or pushed. A scratch measurement script (outside the repo, in the session scratchpad) ran the real `Player` physics headless to measure flip travel; its output is the evidence for the clearance table.

## 0. Correction to report 012
The working tree has `MAX_VERTICAL_SPEED = 3000.0` in `scripts/player.gd` (uncommitted; it was 1000 at commit `958ac35` and I did not change it). Report 012's clearance numbers assumed 1000 and overstated the room large obstacles need. The user should confirm 3000 is intended. Other uncommitted diffs present: `README.md`, and `scenes/main.tscn` (editor-added node ids only).

## 1. Verified architecture (read from current files)
- `main.gd` `_spawn_hazards()` walks `PATTERNS` in order; pattern lap n sits at `lap * visible width + x * width` (x a fraction); a hazard spawns when its left edge is within `SPAWN_AHEAD` (100 px) beyond the right edge. All three patterns have two hazards (ground then ceiling); lap = one visible width (480 px on the M52).
- `_refresh_hazards()` frees a hazard when its right edge passes the left edge; hazards are never reused; at most 3 alive.
- `Hazard.place()` builds collision shape, `Visual` and `Outline` from one `size`; `Halo` is 8 px larger. Heights are fixed pixels; only x uses fractions. Player: 32x32 body at x = 40, 32x32 collision.
- Playable height is not computed anywhere. Ground and ceiling are 40 px thick, so `P = visible height - 80`: 774 px at 480x854, 986 px at 480x1066.

## 2. Sizing rules
Pixel height = `round(h_frac * P)` (pure function of the pattern entry and P; Hazard stores `h_frac` and recomputes on resize; hazards are re-created not recycled, so no stale size). Categories by `h_frac`: Small 0.15-0.25, Medium 0.30-0.45, Large 0.50-0.66; cap 0.66, test bound 0.67. Widths stay 30-50 px. Side effect: existing heights (120/160/180 px) are 12-18% of P = 986, so pattern 0's first hazard is below the Small range; converting to fractions changes existing obstacle sizes on the M52 unless the patterns are re-authored (recommended).

## 3. Clearance rule
Measured (real physics, 60 ticks/s, flip from rest; identical from ground and ceiling; full 742 px corridor in about 0.55 s at P = 774). Ticks and scroll pixels to rise past height h + 1 px:

| Fraction | P=986: h / ticks / scroll px | P=774: h / ticks / scroll px |
|---|---|---|
| 0.20 | 197 / 13 / 43 | 155 / 11 / 37 |
| 0.38 | 375 / 21 / 70 | 294 / 18 / 60 |
| 0.50 | 493 / 26 / 87 | 387 / 22 / 73 |
| 0.60 | 592 / 29 / 97 | 464 / 24 / 80 |
| 0.66 | 651 / 31 / 103 | 511 / 26 / 87 |

Rule (alternating sides; the player flips when its left edge passes the previous hazard's right edge; T(h) = measured clear time):
1. Physical minimum, conservative: `gap >= 32 + 200 * T(h)`. A flip slightly before passing the previous hazard could save distance but needs pixel-exact timing; that smaller true minimum is not established.
2. With the reaction margin: add 200 * 0.3 = 60 px.
3. Recommended initial gameplay clearance: (2) plus one tick (3.3 px), rounded up to 10 px. At P = 986: 140 (0.20), 170 (0.38), 190 (0.50), 200 (0.66).
First hazard of a run: `left edge - 56 >= 200 * (T(h) + 0.3)` (the 0.15 s restart lock is inside the 0.3 s margin). Today's first gap is 145 px, so the first hazard cannot exceed about 0.60 P; keep it Small. The 0.3 s margin is not reduced.

Not established: real touch-input latency on the M52 and human reaction time.

## 4. Pattern and spacing strategy
- Patterns become `{"len": px, "hazards": [{ceiling, x_px, w, h_frac}, ...]}`, x in pixels from the pattern start. Existing patterns convert exactly at 480 px (0.45 to 216, 0.93 to 446, 0.48 to 230).
- `_spawn_origin` (pixels) replaces `lap * width`; after a pattern's last hazard, origin += `len`. Deterministic cyclic order; `_refresh_hazards` unchanged; an empty pattern still advances the origin by `len`.
- Derived length: `len >= sum(required gap + (previous width + this width)/2)` over cyclic pairs. Worst case, two 0.66 hazards at width 50 on P = 986: 2 * (200 + 50) = 500 px. Medium and Large pairs at width 40 fit 480 px. The earlier 540 px was wrong.
- Smallest alternative: keep one visible width per pattern and add only `h_frac`; supports Large up to about 0.60 at width 40 but not 0.66 at width 50. Option B costs about 15 lines and also makes fairness independent of window width, so it is recommended.
- A test enforces strict alternation across pattern boundaries.

## 5. Changes by file
- `scripts/main.gd`: new `PATTERNS` format and values, `_playable_height()`, `_spawn_origin` (reset in `_restart`), `_spawn_hazards`, `_place_hazards`.
- `scripts/hazard.gd`: store `x_px` and `h_frac`; `place()` takes pixel x.
- `tests/m3_check.gd`: update checks that read x as a fraction, h in pixels, `x_frac` and the lap count (scroll, layout, lifecycle, restart, resize); the empty-pattern fixture changes format; no assertion removed or loosened.
- No change to `player.gd`, the scenes or the scroll speed.

## 6. Automated tests
Category and bound checks for every spec at 480x854, 480x1066, 1281x854; collision/Visual/Outline/Halo synchronisation; the clearance rule for every cyclic consecutive pair, with required gaps measured by running the real `Player` in the test; strict alternation; first hazard Small and approach distance; a reaction-delay bot (waits 0.3 s after the earliest legal flip) survives several cycles at all sizes; a deliberately too-tight pattern kills a zero-margin bot (negative control); resize re-scales heights and keeps positions valid; restart restores origin, sizes and sequence; existing scroll, collision and G1.1 rotation tests kept. Needs M52 playtest: reaction margin feel, input latency, readability of tall obstacles, pacing.

## 7. Risks and open questions
1. Confirm `MAX_VERTICAL_SPEED = 3000` is intended.
2. Re-author the existing three patterns to the new categories (recommended) or keep old pixel heights.
3. The M52 layout of 480x1066 is an assumption.
4. Taller viewports make the same fractions harder (orientation is locked on mobile).

## 8. Commands after implementation
```
godot --headless --path . --script res://tests/m3_check.gd
git diff --check
git diff   # only main.gd, hazard.gd and the tests should change
```
Then F5 and a playtest on the M52.

## Status
Waiting for approval. Behaviour verification of the implementation: NOT RUN (planning only). The flip-travel measurements are real-physics headless results at 60 ticks/s.
