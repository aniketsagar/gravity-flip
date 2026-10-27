# Report 003 — M2 first playable loop (2026-10-26)

Prompts: `../prompts/003-m2-playable-loop.md` (initial) and the wrap adjustment (below). Not committed. Base: `4c326f8` (M1).

## Revision history
1. Initial M2: constant-speed run, tap to flip gravity, right edge = game over, tap to restart.
2. Adjustment (this version): right-edge game over removed; the player wraps from the right edge to the left edge. Ground and ceiling are safe.

## Changed files (vs. `4c326f8`)
- `scripts/player.gd` (new): movement, gravity, flip, wrap. Attached to `Player`.
- `scripts/main.gd` (modified): input, restart, game-over label, layout (no longer re-centres the player on resize).
- `scenes/main.tscn` (modified): `player.gd` attached to Player; new `GameOverLabel` (Label, hidden).
- `tests/m2_check.gd` (new): headless check script.
- Untracked, not part of the milestone code: `scripts/main.gd.uid`, `scripts/player.gd.uid` (Godot-generated), `screenshots/`, `claude-work/`.

## Controls
- Desktop: left mouse click flips gravity.
- Android: screen tap flips gravity.
- Restart on tap exists but is currently unreachable in normal play (see limitations).

## Final mechanics
- Player starts 40 px from the left edge, vertically centred, gravity downward.
- `_physics_process`: `velocity.x = 200 px/s`; `velocity.y += gravity_dir * 1800 * delta`, clamped to +/-900; `move_and_slide()`. Ground and Ceiling are StaticBody2D, so the player rests on them and cannot pass through. Everything uses the fixed physics `delta` (frame-rate independent).
- Wrap: when `position.x >= play_rect.end.x` (the visible rect's right edge), `position.x -= play_rect.size.x`. The overshoot carries over, so horizontal motion is continuous. Y, vertical velocity and gravity direction are untouched. The wrap triggers on the player's centre, so the square is half off-screen at the instant of the wrap and shows on the left edge from then on; there is no mirrored copy while straddling the edge.
- Ground and ceiling never end the run.
- Input in `_unhandled_input`: left click or `InputEventScreenTouch` press flips gravity. The mouse event Android synthesises from touch (`device == InputEvent.DEVICE_ID_EMULATION`) is ignored so one tap flips once.
- `play_rect` is taken from the viewport visible rect (valid under the `expand` stretch aspect) and refreshed on `size_changed`.

## Verification (actually run, after the final edit)
Godot = `E:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`, run from the project directory.
1. `--headless --path . --quit-after 5` -> version banner only, exit 0, no errors or warnings.
2. `--headless --path . --script res://tests/m2_check.gd` -> 19/19 PASS, `RESULT: ALL PASSED`, exit 0:
   - run starts; gravity starts down; moves right; rests on ground (y 797.93 vs 798.00);
   - click flips; never above ceiling (min y 56.07 vs limit 56.00);
   - emulated mouse event ignored; touch flips; constant horizontal speed (wrap-aware);
   - wraps to left edge (x=2.33 after placing the player at right edge - 1); vertical position kept (797.93 -> 797.93); gravity kept; keeps moving right; overshoot carried over;
   - two 900-tick (15 s) stretches, one on each surface (a tap flips between them), stay running and in bounds with no game-over label;
   - tap restarts a manually stopped run, resets the player, hides the label.
3. A first run of the updated test had 3 failures that were bugs in the test setup (player was mid-air when sampled; placed 5 px from the edge, which one tick does not cross). I fixed the test, not the game code, and re-ran; the result above is from the final run. A later removal of an unused constant (`HALF_WIDTH`) was followed by a re-run of both commands (both OK).

Test caveats:
- Taps call `Main._unhandled_input(event)` directly with constructed events: `push_input` and `Input.parse_input_event` did not reach the scene in headless `--script` mode. This verifies tap classification and game logic, not real engine input dispatch.
- The headless visible rect was 854x854, not the 480x854 window.
- The wrap tests teleport the player to the edge rather than waiting for a natural crossing; natural crossing is covered only indirectly by the multi-lap check, which would fail if the player left the rect.

## Known limitations / remaining issues
- Not verified: real mouse clicks in a window, touch on Android, any visuals (no windowed run or screenshot), layout on real phones.
- Dead-ish code: nothing can stop the run now. `signal crashed`, `_on_player_crashed`, `GameOverLabel` and the tap-to-restart branch are kept (as requested for restart behaviour) but unreachable in normal play; the `crashed` signal is never emitted. Remove or reuse them when M3 adds a failure condition.
- With nothing to dodge and safe surfaces, the loop has no failure or goal yet.
- Window resize mid-run changes the play area; a player beyond the new right edge wraps on the next tick, and a shrunken height can leave the player outside the surfaces until the next resize/restart (no re-clamp in M2).

## Manual testing needed
1. Run (F5 or `godot --path .`): the player falls to the ground and slides right, wraps to the left at the right edge at the same height, a click flips gravity to the ceiling and it keeps wrapping.
2. Confirm one click = one flip, and the wrap looks acceptable visually (half-visible at the instant of the wrap).
3. Android: tap flips exactly once.

## Decisions needed
- Speed 200 px/s and gravity 1800 px/s^2 are guesses; tune by feel.
- Whether to wrap on the player's centre (current) or on the full body leaving the screen with a mirrored copy.
