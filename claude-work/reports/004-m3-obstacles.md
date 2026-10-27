# Report 004 — M3 obstacles and failure conditions (2026-10-26)

> Revision 2 (tuning after hands-on feedback) is at the end of this file. Where earlier sections conflict with it (physics values, pattern positions, check counts), Revision 2 is current.

Prompt: `../prompts/004-m3-obstacles.md`. Not committed. Base: `1f91400` (M2).

## Changed files
- `scripts/hazard.gd` (new): `Area2D` script; `place()` attaches a hazard to the ceiling or ground edge and sizes its shape and visual.
- `scenes/hazard.tscn` (new): reusable hazard (Area2D + CollisionShape2D + red ColorRect). Layer 0, mask 2 (detects only the player).
- `scripts/main.gd` (modified): pattern data, hazard spawning/placement, game-over handling, restart, tap lock.
- `scripts/player.gd` (modified): removed the unused `crashed` signal; added `wrapped` signal and `stop()`.
- `scenes/main.tscn` (modified): `Player.collision_layer = 2`; new `Hazards` Node2D container; ceiling colour changed pink -> blue (see below).
- `tests/m3_check.gd` (new) replaces `tests/m2_check.gd` and its `.uid` (deleted); every M2 check is carried over or extended.
- `claude-work/`: this report and the prompt.
- Untracked and not part of the milestone: `screenshots/`. Godot did not generate `.uid` files for `hazard.gd` / `m3_check.gd` during headless runs (the editor will on first open).

## Gameplay behaviour
- Controls unchanged: click (desktop) or tap (Android) flips gravity.
- Run start: the player starts on the ground 40 px from the left edge (M2 started mid-air at screen centre; changed so the first hazard gives a full reaction time). Moves right at 200 px/s and wraps right -> left, keeping height and gravity.
- Hazards: red rectangles attached to the ground (ground-side) or hanging from the ceiling (ceiling-side). Hazard overlap with the player ends the run: the player stops, "Game Over / Tap to restart" shows. Ground and ceiling stay safe (blue ceiling, green ground).
- Patterns: three fixed patterns in `Main.PATTERNS`, each a ground hazard then a ceiling hazard (alternating), positions as fractions of the visible width, sizes in px:
  | # | ground (x, w, h) | ceiling (x, w, h) |
  |---|---|---|
  | 0 | .50, 30, 120 | .90, 30, 120 |
  | 1 | .50, 40, 160 | .90, 40, 160 |
  | 2 | .55, 30, 180 | .92, 50, 160 |
  One pattern is shown per lap. Each time the player wraps, the next pattern replaces the hazards (cycling 0,1,2,0,...). To add patterns, append a list of `{ceiling, x, w, h}` dictionaries.
- Why both sides kill: sitting on the ground hits the ground hazard; sitting on the ceiling hits the ceiling hazard, so the player must alternate. Flips keep vertical speed (momentum), so the flip after a ground hazard must come soon after passing it or the player reaches the ceiling hazard.
- Game over: `Main._on_hazard_body_entered` only acts if the body is the player and `player.running`; it stops the player and shows the label once. Later overlaps are ignored.
- Restart: tap/click after game over. Resets player position (on ground, left), velocity, gravity (down), pattern index (0), hazards (pattern 0), label hidden.
- Tap lock (new): taps are ignored for 0.4 s after a crash (so frantic taps don't skip the game-over screen) and 0.15 s after a restart (so the restart tap or a duplicate event can never flip gravity in the new run). The lock counts down in `_physics_process`, so it is frame-rate independent. Behaviour change to be aware of: restart is not instant after a crash.
- Collision layers: player on layer 2 (still collides with ground/ceiling on layer 1); hazard areas only monitor layer 2, so they never react to the ground/ceiling.
- Visual change outside the brief: ceiling colour pink -> blue so that the warm red hazards are clearly distinct from the "safe" cool-coloured surfaces. Hazards draw above the player.

## Verification (actually run)
Godot = `E:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`, from the project directory.
1. `--headless --path . --quit-after 5` -> banner only, exit 0, no output errors. (Note: this command's exit code stays 0 even when GDScript errors are printed, so the output was checked too.)
2. `--headless --path . --script res://tests/m3_check.gd` -> **52 PASS, 0 FAIL, 0 ERROR/WARNING lines, exit 0**, `RESULT: ALL PASSED`.
3. Windowed scripted render (scratch script, outside the repo): `--path . --rendering-driver opengl3 --script <scratchpad>\shot.gd` at 480x854 saved two screenshots of the real rendered frame (OpenGL, RTX 3070): the start state (player on green ground, red ground hazard, red ceiling hazard under the blue ceiling) and a forced-hit state (game-over text shown). Inspected by eye; this checks drawing only, not play.

### What the test covers (headless, real physics)
- Movement/flip/surfaces (no hazards): moves right; rests on ground and ceiling within 1.5 px; never above the ceiling (min y 56.07 vs 56.00); constant horizontal speed; click flips; two 900-tick stretches on ceiling and ground never end the run.
- Wrap: wraps at the edge, keeps y and gravity, carries overshoot, keeps moving; wrapping advances pattern 0 -> 1 and re-places hazards.
- Layout: pattern 0 alternates ground/ceiling; hazards sit on the ground / hang from the ceiling; all patterns alternate and start at x >= 0.5 W; hazard colour differs from ground, ceiling and player.
- Collisions: teleporting the player into a ground hazard and into a ceiling hazard each ends the run (stopped, label shown); a repeated hit does not re-trigger or move the player; with no input the player actually drives into the first ground hazard; staying on the ceiling ends at the ceiling hazard; resting on the ground or ceiling just before a hazard, and passing over a ground hazard near the ceiling, stay safe.
- Restart/input: a tap right after a crash is ignored; after the delay it restarts and the same tap does not flip; velocity, position (on ground), gravity, pattern index and hazard positions are reset; taps/touch within the post-restart delay do not flip; one tap = one flip; the emulated mouse copy of a touch, touch release and right click do not flip; a second crash after restart works.
- Solvability: a simple scripted player (flips when the next hazard is within 100 px (ground) / 200 px (ceiling)) survives 6 laps (all 3 patterns twice) at viewport sizes 480x854, 480x1066 and 1281x854 (windows set via `root.size`).
- Offline model check (Python, scratchpad, not in the repo) showed that pattern pairs like these have wide valid flip windows (tens of ticks for the first flip, about one second for the second flip) with the real physics constants; that informed the pattern spacing, it is not a test.

### What the headless test does NOT cover
- Real input dispatch: taps call `Main._unhandled_input` with constructed events (pushed/parsed events do not reach the scene in headless script mode). Real mouse clicks in a running window and Android touch (including the emulated-mouse suppression) are untested.
- Human playability: the bot proves the patterns are survivable, not that they feel fair or fun; difficulty and timing are unjudged.
- Exact collision-depth look (the player stops up to ~3 px inside a hazard on the tick of detection).
- No Android device/export; no performance testing.
- The default headless window is 854x854, so tests outside `_test_bot` run at W=854, not the 480-wide phone layout.

## Known limitations / risks
- Hazards are placed by fraction of width, so on wider windows they spread out (more time between hazards); on very tall screens the corridor is longer but hazard sizes are fixed.
- Window resize mid-run re-places hazards but does not re-clamp the player vertically.
- Restart delay 0.4 s after a crash may feel slow; tunable constants `GAME_OVER_TAP_DELAY` and `RESTART_TAP_DELAY`.
- Difficulty is untuned (speed 200, gravity 1800 unchanged). With 2 hazards per 2.4 s lap the pace may be fast; manual play is needed.
- The player is drawn under hazards when overlapping.

## Manual testing needed
1. F5 in the editor or `godot --path .`: the player begins on the ground; flip before the red ground block, flip back before the red ceiling block; confirm you can pass at least a full cycle of 3 patterns, and that the layout changes each lap.
2. Confirm the game-over text appears on a hit, that a click right after dying is ignored briefly, then restarts a clean run, and that the restart click does not flip.
3. Confirm touching the blue ceiling and green ground never ends the run.
4. Android build (needs SDK/JDK17/templates): tap flips once, restart works, layout correct on a real phone aspect ratio.

## Decisions needed
- Is the 0.4 s / 0.15 s tap lock acceptable?
- Keep the blue ceiling recolour?
- Should the player spawn on the ground (changed from M2's mid-air centre)?
- Difficulty tuning (hazard heights/widths/spacing, speed) after hands-on play.

---

# Revision 2 — snappy flip and spacing

Prompt: `../prompts/005-m3-tuning.md`. Not committed. Base: `37d8bb2` (M3).

## Feedback addressed
Playable; first obstacle visible early enough; game over/restart correct. Too short a gap between the two hazards, rushed feeling, laggy/boaty gravity flip.

## Changed files
- `scripts/player.gd`: new physics constants and snappy flip.
- `scripts/main.gd`: pattern x positions only.
- `tests/m3_check.gd`: new snappy-flip section, one threshold updated.
- `claude-work/`: prompt 005 and this section.
(`scenes/hazard.tscn` inspected, unchanged.)

## Physics values (all constants at the top of `player.gd`)
| Constant | Before | Now |
|---|---|---|
| `GRAVITY` | 1800 px/s^2 | 2400 |
| `MAX_VERTICAL_SPEED` (was `MAX_FALL_SPEED`) | 900 px/s | 1000 |
| `FLIP_SPEED` (new) | - | 600 px/s |
| `SPEED` (horizontal) | 200 px/s | 200 (unchanged) |

`FLIP_SPEED = 600` is my choice; the prompt did not give a value. Raise it for a harsher snap, lower it for a softer one.

## Flip behaviour
`flip()` now: ignores the call unless the run is live; reverses `gravity_dir`; sets `velocity.y = gravity_dir * FLIP_SPEED` (replaces the old vertical velocity, so there is no momentum overshoot). It does not touch position or horizontal velocity; the player moves on the next `move_and_slide()` as usual, so collisions work normally. From the ground or ceiling the player leaves the surface on the next physics tick (surface contact had zeroed the velocity). Everything still runs in `_physics_process` with the fixed `delta`.

## Obstacle spacing
Patterns keep the alternating ground -> ceiling structure and sizes. The ceiling hazard moves right and the ground hazard slightly left (a ceiling hazard at 1.0 W would sit off-screen, so part of the gap had to come from moving the first hazard left):

| # | ground x | ceiling x | centre gap before -> now |
|---|---|---|---|
| 0 | .50 -> .45 | .90 -> .93 | .40 W -> .48 W (+20%) |
| 1 | .50 -> .45 | .90 -> .93 | .40 W -> .48 W (+20%) |
| 2 | .55 -> .48 | .92 -> .93 | .37 W -> .45 W (+22%) |

At W = 480 the centre gap is 192 -> 230 px (patterns 0/1) and 178 -> 216 px (pattern 2); edge-to-edge gaps are smaller by the hazard widths. The first obstacle moved 24 px (patterns 0/1) / 34 px (pattern 2) closer to the spawn (about 0.12-0.17 s earlier): "approximately" its old place, not identical. The last ceiling hazard's right edge is at most 471 px (< 480), so nothing is clipped at the wrap.

## Verification (actually run, after the final edit)
Godot = `E:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`, from the project directory.
- Results: see "Final run" at the bottom of this section.

New/updated checks (headless, real physics):
- Falling player: flip gives `vy == -FLIP_SPEED` at once; position unchanged (no teleport); horizontal velocity unchanged (200); moves up on the next tick.
- Rising player: flip gives `vy == +FLIP_SPEED` at once; no teleport; moves down on the next tick.
- Resting on the ground: flip leaves the ground within 3 ticks. Resting on the ceiling: same.
- Vertical speed never exceeds `MAX_VERTICAL_SPEED`; 12 rapid flips stay inside the corridor and the run continues.
- `flip()` after game over is ignored (gravity, velocity and state unchanged).
- Existing checks still pass: hazard hits end the run (ground, ceiling, driving into one), safe surfaces stay safe, restart resets state, tap locks (0.4 s after crash / 0.15 s after restart), no double flip, wrapping, pattern cycling, layout (the "starts well after spawn" threshold was lowered from x >= 0.5 W to >= 0.4 W to match the new positions).
- Survivability: the scripted player (ground lead 100 px, ceiling lead 200 px, unchanged) survives 6 laps (each pattern twice) at 480x854, 480x1066 and 1281x854 with the new physics.

Non-triviality probe (scratch script outside the repo, not part of the suite; 480x854, 6 laps): scripted players with different flip timing did not all succeed. A ground lead of 40 px failed with every ceiling lead; leads of 60-80 px survived only with ceiling leads of 60-150 px; a ground lead of 100 px survived every tried ceiling lead (60-300). So badly timed flips still die; the patterns are survivable but not automatic. The probe was cut off by my timeout after 4 of 6 ground-lead rows; the remaining rows were not examined, and the ERROR/leak lines at its exit came from the killed scratch process, not from the game or the suite.

An offline model (Python, scratchpad) with the new physics gave flip windows of roughly 35 ticks (0.6 s) for the first flip and about 1 s for the second per pattern; it guided positions and is not a test.

## Known limitations
- Nothing here has been playtested. Whether the flip now feels snappy, and whether the gap is fair rather than too easy, needs manual play. I make no claim that it feels better.
- Because a flip replaces vertical velocity, long falls/rises still reach the 1000 px/s cap; ground-to-ceiling transit is roughly 0.9 s on an 854-tall screen (modelled, not measured).
- Taller screens lengthen the corridor without changing hazard sizes; wider windows spread hazards out (positions are fractions of width).
- `FLIP_SPEED` and spacing are first guesses.
- Real mouse/touch dispatch, Android, and the 480-wide window outside the solvability test remain untested, as before.

## Manual testing needed
1. Play several laps: check the flip response (immediate, no float), whether 600 px/s flip speed feels right, and the timing window between the ground and ceiling hazards.
2. Check you can never be stuck on a surface after tapping.
3. Re-check restart and tap-lock feel.

## Final run
- `--headless --path . --quit-after 5`: banner only, exit 0, no errors (exit code is 0 even on script errors, so the output was checked).
- `--headless --path . --script res://tests/m3_check.gd`: **69 PASS, 0 FAIL, 0 ERROR/WARNING lines, exit 0**, `RESULT: ALL PASSED` (52 checks before; 17 new).
- `git diff --stat`: `scripts/main.gd`, `scripts/player.gd`, `tests/m3_check.gd` only (+85/-10); nothing committed.
