# Report 008 — Scrolling world (2026-10-27)

Prompt: `../prompts/008-scrolling-world.md`. Inspection, then implementation after approval. Committed and pushed on request as `1efb087` (`42a74ed..1efb087`, `main`).

## 1. Inspection findings (before the change)
Observed from the code; the cause of the device popping was inferred, not measured on the phone.
- The player moved right at 200 px/s (`velocity.x = SPEED`) and teleported from the right edge to the left edge when it passed `play_rect.end.x`, emitting `wrapped`. There was no camera.
- Hazards were static. Exactly two hazard nodes existed. On every wrap they were re-placed and resized for the next pattern (`_show_pattern` and `_place_hazards`). Nothing was ever freed, because every pattern has two hazards.
- Popping cause: hazards never travelled across the screen. They jumped to new positions and sizes at the same moment the player teleported, about every 2.4 s.
- Possible second factor (unconfirmed): physics at 60 Hz with no physics interpolation on a 120 Hz display.

## 2. What changed
| File | Change |
|---|---|
| `scripts/player.gd` | Removed horizontal movement, the wrap, the `wrapped` signal, `SPEED` and `play_rect`. Gravity, `FLIP_SPEED` and the vertical clamp are untouched. |
| `scripts/main.gd` | Added `SCROLL_SPEED = 200`, `SPAWN_AHEAD = 100`, `_scroll`, `_spawn_lap`, `_spawn_spec`. `_physics_process` advances the scroll only while the player runs. `_refresh_hazards` moves, recycles and spawns. `_spawn_hazards` spawns in pattern order. Restart clears hazards and resets the scroll and cursor. Removed `_pattern_index`, `_show_pattern`, `_on_player_wrapped`. |
| `scripts/hazard.gd` | `place()` now records `x_frac` (lap + fraction) and `world_x`, so hazards can be re-placed after a resize. |
| `tests/m3_check.gd` | Rewritten for the scrolling model (see section 4). |

## 3. New behaviour
- The player stays at x = 40 (`START_MARGIN`) and moves only vertically.
- A hazard's x is `world_x - _scroll`. Lap n sits n visible widths to the right, so the gap between the last hazard of one pattern and the first of the next is 0.52 of the width, as before.
- A hazard spawns when its left edge is within 100 px beyond the right edge, so it is always created off-screen. It is freed when its right edge passes the left edge. At most 3 are alive at once.
- Scrolling stops at game over. Restart resets the scroll, frees all hazards and respawns pattern 0.
- A resize re-places the existing hazards for the new rect and keeps the scroll.

## 4. Verification
| Check | Result |
|---|---|
| Baseline suite before the change (old wrap model) | PASS |
| `godot --headless --path . --script res://tests/m3_check.gd` after the change | PASS, 80 checks, 0 failures, `RESULT: ALL PASSED` |
| Mutation check: `SPAWN_AHEAD = -200` | FAIL as intended (6 failures, including "every new hazard spawns fully beyond the right edge"); reverted and re-confirmed at 100 |
| `git diff --check` | No whitespace errors (only CRLF to LF warnings from git) |

Test changes: the horizontal-movement and wrap checks became "player x fixed" and "world scrolls at SCROLL_SPEED". The wrap test became a scrolling test (start positions, entry beyond the right edge, removal, empty pattern list does not hang). New checks cover per-tick continuity of every hazard (no jumps), spawn off-screen, removal only after leaving, pattern sequence over 12 spawned hazards, and resize. The collision, flip, restart/input-lock and bot-survivability checks keep their intent (bot clears 6 laps at 540x960, 540x1200 and 1200x800).

Test-only artifact found: moving a hazard onto the player's old position and moving the player away in the same tick still registered a hit, so that test now moves the player first and waits a tick. This does not occur in play, where hazards move 3.33 px per tick.

## 5. Manual verification
Reported by the user after installing on the Galaxy M52: "the build works". Whether the popping is fully gone and the flip feel and spacing are unchanged was not itemised by the user.

## 6. Limitations and open items
- Physics interpolation was not enabled. Hazards move in the 60 Hz physics tick, so some judder on a 120 Hz display is possible; decide after a playtest.
- The player's x stays at 40, so the first-hazard reaction time is unchanged. A Flappy-style position around 25% of the width would shorten it; not done.
