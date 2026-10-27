# Report 015 — G1.2 variable-sized obstacles, implemented (2026-10-27)

Prompt: `../prompts/015-g1-2-implementation.md`. Implemented per Report 014. Not committed, not pushed.

## 1. Summary and files changed
- `scripts/main.gd`: `PATTERNS` re-authored as `{"len", "hazards": [{ceiling, x, w, h_frac}]}` with the approved table (P0-P4, P3 = 500 px). `_spawn_lap` replaced by `_spawn_index` plus `_spawn_origin` (px); the origin advances by each pattern's own `len`, also from P4 to P0; both reset in `_restart()`. `_spawn_hazards()` and `_place_hazards()` use pixel positions.
- `scripts/hazard.gd`: `place(rect, thickness, on_ceiling, x_px, width, h_frac)`; height = `round(h_frac x (rect height - 2 x thickness))`, so collision shape, Visual, Outline and Halo all derive from one `size`. Stores `x_px` and `h_frac` (replacing `x_frac`) so resize re-places from the fractions.
- `tests/m3_check.gd`: existing tests adapted to the new format; new G1.2 tests added.
- Unchanged: `player.gd`, scenes, `SCROLL_SPEED`, `MAX_VERTICAL_SPEED = 3000`, visuals, spin, restart and startup code (apart from the two spawn-cursor lines in `_restart`).
- Surface thickness verified: the test measures the Ground/Ceiling collision shapes (40 px each) and the corridor between them (774 px at 480x854, 986 at 480x1066, 774 at 1281x854).

## 2. Clearance results (automated; real Player and Main physics, 60 ticks/s)
Required gap = `32 + 200 x (T + 0.3)`, T measured per height and per viewport by flipping the real player from rest on the opposite surface until its leading edge clears h + 1 px.
- All 19 consecutive pairs of two cycles (20 hazards; corrected from "29" by Report 016), including P0->P1 ... P3->P4 and the P4->P0 cycle boundary, meet the rule at 480x854, 480x1066 and 1281x854.
- Tightest pair at every viewport: the P3 ceiling (0.55) -> P4 ground (0.66) pair (`#7->#8`); slack 14.7 px at 480x1066 (651 px, 31 ticks) and 31.3 px at 480x854 (511 px, 26 ticks). 1281x854 equals 480x854 (same playable height).
- First obstacle: approach 145 px against 90.0 px needed (774) and 96.7 px (986), using the 0.3 s reaction margin.
- Measured clear ticks, e.g. 986: 0.15 -> 11, 0.20 -> 13, 0.25 -> 16, 0.30 -> 18, 0.38 -> 21, 0.45 -> 24, 0.50 -> 26, 0.55 -> 27, 0.66 -> 31 (matches Report 014).
- Bot with a 0.3 s reaction delay survives 4 full cycles (9683 px, 40 flips, 2904 ticks) at all three viewports and passes the 66% hazard 4 times each.
- Negative controls: a 60 px gap is below the 118.7 px geometric minimum, and a zero-delay bot dies on a 0.66/0.66 pair 60 px apart (scroll 340); the same bot passes the pair at 150 px (5 flips), so the death is caused by the spacing.

## 3. Test commands and counts
- `godot --headless --path . --script res://tests/m3_check.gd` (console exe `Godot_v4.7.2-stable_win64_console.exe`): exit 0, `RESULT: ALL PASSED`, 154 PASS, 0 FAIL (the suite had 103 checks before G1.2).
- `git diff --check`: exit 0, no whitespace errors (only the usual CRLF-to-LF warnings for `main.gd` and `m3_check.gd`, which are CRLF in the working tree; I preserved CRLF).

Existing-test adaptations (no assertion removed; the same checks now use the new format):
- Pattern data access (`["hazards"]`, `h_frac`, `x_px`, `_spawn_index`), `EMPTY` fixture format, expected-sequence generator (origin + `len`, heights from fractions).
- The suite now starts with the window set to 480x854 (previously the default 854x854 headless window). Reason: patterns are in pixels, so a wider window shows more hazards at once and "pattern 0's 2 hazards" is only true at the real 480 px width. The existing resize and bot tests still cover other widths.
- Three tests waited 0.67 s (corrected from "Four" by Report 016) (`_wait_unlocked`) before their first tap; with the real 145 px first approach (0.725 s) that now lands on the first hazard. They wait 10 ticks (just past the 0.15 s lock) instead. Assertions unchanged.
- The legacy crude solvability bot's ground lead went from 100 to 140 px: a 0.66 hazard at 986 px needs 103 px of travel, so a 100 px lead cannot clear it. The 6-lap survival assertions are unchanged and pass at 540x960, 540x1200 and 1200x800.

## 4. Diff review
- `git status`: modified `scripts/main.gd`, `scripts/hazard.gd`, `tests/m3_check.gd` (mine); pre-existing and untouched by me: `README.md`, `scenes/main.tscn` (editor ids), `scripts/player.gd` (`MAX_VERTICAL_SPEED = 3000`); untracked `.claude/`, `claude-work/`, `image/`, `screenshots/`.
- No unrelated changes in my three files. Scroll speed and physics constants untouched.
- Observed: before the fixture fix, one spin test failed ("restart during/after a spin..."). Its tap landed after the first hazard had already ended the run; with the earlier tap it passes. I did not investigate beyond that, per the deferral.

## 5. Known deferred issues (not investigated, not changed)
- Possible first-frame collision from the player's scene position (240, 427) at the first spawn; the authored first hazards (0.15 ground at x 216) do not overlap it.
- Possible stale overlap event after restart.

## 6. Verified vs assumed
Verified (automated): everything in sections 2-3. Assumed / not verified: the M52 visible rect is 480x1066 (a 540x1200 window yields it); touch latency and human reaction on the device; the 0.3 s margin feel; slack of 15-35 px on the tightest pairs; the pre-existing question of ColorRects swallowing taps.

## 7. Manual playtest checklist (M52)
1. F5 / install the build; first obstacle (small, pink) should be clearly avoidable after the start.
2. Play to the 0.66 (tallest pink) ground obstacle in the fifth pattern and the 0.55 ceiling (purple) before it; note whether the timing feels fair, tight or impossible.
3. Check obstacles still scroll smoothly with no popping, and the neon look and spin are unchanged.
4. Watch the cycle boundary (after the 0.20 ceiling of P4 the small 0.15 ground of P0 returns).
5. Report: tightest-feeling pattern number, any hit that felt unfair, overall difficulty progression.

## Status
Implemented and automatically verified; PENDING MANUAL TEST on the device. Next step: playtest, then decide on commit.
