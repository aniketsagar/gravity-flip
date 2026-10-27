# Report 010 — G1.1 player rotation: inspection (2026-10-27)

Prompt: `../prompts/010-g1-1-player-rotation.md`. Inspection and planning only. No project file was modified, nothing was run, nothing committed or pushed. Findings come from `player.gd`, `main.gd`, `main.tscn` and `tests/m3_check.gd` as read earlier in the session; rotation behaviour itself is assumption until implemented and tested.

## Key finding
The player is a symmetric 32x32 square, so a 90 degree rotation looks identical to the starting pose and leaves the collision geometry unchanged. An instant rotation would be invisible; it only shows if animated, or once the shape is not a square.

## Verified findings (from the code)
- `Player` is a `CharacterBody2D` running `player.gd`; it owns `position`, `velocity`, `gravity_dir`, `running` and calls `move_and_slide()`.
- Collision: a `CollisionShape2D` child of `Player` with a 32x32 `RectangleShape2D`, no offset, centred on the origin. Visual children `Halo`, `Visual`, `Outline` are siblings, symmetric around the origin.
- A successful flip happens only in `Player.flip()`, after its `if not running: return` guard. `main.gd` `_unhandled_input` decides whether a tap counts (real tap, not the emulated mouse copy, `_tap_lock` at zero) and calls `_player.flip()` when running, otherwise restarts.
- The flip is immediate: `gravity_dir` toggles and `velocity.y = gravity_dir * FLIP_SPEED` in one call; no tween.
- Locks: `_tap_lock` is 0.4 s after a crash and 0.15 s after a restart. `stop()` clears `running` and velocity. `start()` resets position, velocity and gravity.
- Existing tests cover flip velocities, no teleport, flip from ground and ceiling, ignored flips after game over, rapid flips, collisions, restart and input locks, and bot survivability.

## Assumptions (not yet tested)
- Floor detection uses the global `up_direction`, so rotating the body should not change it.
- A square rotated by 90 degrees has identical bounds, so resting heights and hazard overlaps are unchanged.
- `Halo` and `Outline` rotate in place because they are symmetric around the origin.

## Proposed implementation
Rotate the `Player` root so the collision shape and all visuals turn together, with no scene-tree changes. In `scripts/player.gd`: a quarter-turn counter advanced in `flip()` after the `running` guard, with `rotation = quarter_turns * PI / 2` (an integer source, so no float drift); `start()` resets the counter and rotation to 0. `main.gd` and the scenes need no change. Gravity, velocity, flip speed and the locks are untouched.

## Risks and unresolved questions
- Instant or animated? An animation is the only way the rotation is visible for a square. If animated, the collision shape passes through 45 degrees, where a square's half-extent grows from 16 to about 22.6 px; that could cause depenetration jitter or false hazard hits, so the collision shape should stay snapped while only the visuals animate. Rotating the `Control` visuals separately turns them about their top-left corner unless `pivot_offset` is set.
- Direction: always clockwise (recommended, exactly 90 degrees per flip) or following the gravity direction.
- `start()` must reset the rotation or the next run inherits the old angle.

## Tests to add
Each successful flip adds exactly 90 degrees; four flips return to 0 degrees; the collision shape's global rotation equals the visual's and its size stays 32x32; ignored flips (game over, tap lock, emulated mouse, touch release, right click) do not rotate; restart resets the rotation; resting height on ground and ceiling unchanged; rapid flips stay bounded; a hazard hit still ends the run while rotated; the existing bot survival runs unchanged.

## Commands after implementation
```
godot --headless --path . --script res://tests/m3_check.gd
git diff --check
git diff   # confirm only player.gd and the test file changed
```
Then F5 in the editor and a playtest on the Galaxy M52.

## Status
Waiting for the user's approval and answers on instant versus animated rotation and on rotation direction. Verification of any behaviour: NOT RUN (inspection only).
