# Report 011 — G1.1 player spin on flip (2026-10-27)

Prompt: `../prompts/011-g1-1-player-spin.md` (follows report 010). Implemented after approval. **Not committed or pushed.**

## 1. Visual node types and pivot choice (inspected before coding)
The player visuals are `Halo` (`ColorRect`), `Visual` (`ColorRect`) and `Outline` (`ReferenceRect`), all `Control`-derived and all centred on the body origin. A `Control` rotates about `pivot_offset`, which defaults to its top-left corner. Chosen approach: set each node's `pivot_offset = size / 2` in `_ready` (Halo 20,20; Visual and Outline 16,16) and tween the three nodes' `rotation` in parallel. No scene-tree or `.tscn` change. The `Player` root and the `CollisionShape2D` are never rotated.

## 2. What changed
| File | Change |
|---|---|
| `scripts/player.gd` | `SPIN_TIME = 0.12`; `_spin_turns`, `_spin_tween`, `_visuals`; `_ready` sets pivots and resets the spin; `flip()` calls `_spin()` after the existing `running` guard and after the immediate gravity and velocity change; `start()` calls `_reset_spin()`. Added `_spin()` and `_reset_spin()`. Gravity, velocity and flip-speed code is untouched. |
| `tests/m3_check.gd` | New `_test_rotation` (23 checks), called before `_test_resize`. No existing line removed or edited. |

Behaviour: each successful flip adds one quarter turn (the target is `turns * PI / 2`, always a whole number of quarter turns), eased over 0.12 s. A new flip kills the running tween and retargets from the current angle, so rapid flips end exactly aligned. `flip()` is the only trigger, so the tap lock, the emulated-mouse filter and the game-over guard already prevent spins for ignored flips.

## 3. Verification
| Check | Result |
|---|---|
| `godot --headless --path . --script res://tests/m3_check.gd` | PASS, 103 checks (80 existing plus 23 new), 0 failures, `RESULT: ALL PASSED` (run twice, including once after the mutation test below) |
| Mutation test: removed the pivot setup and the `_reset_spin()` call in `start()` | FAIL as intended (6 failures: pivot checks, centred spin, and the three restart checks); file restored and the suite re-run clean |
| `git diff --check` | No whitespace errors (only CRLF to LF warnings from git) |
| Existing assertions | None removed or changed (the test diff has no deleted lines) |

New checks cover: starts unrotated; pivots at each node's centre and on the body centre; the flip tick changes gravity and velocity at once while the angle has not jumped; the angle rises smoothly through intermediate values to exactly +90 degrees; the collision shape stays 32x32 and unrotated, and the `Player` root never rotates, on every sampled frame of the spin; the visuals stay in sync and centred; four flips equal a full turn; 12 rapid flips end on exactly 12 quarter turns with the player inside the corridor; taps during the restart lock, emulated mouse, touch release and right click do not spin; flips after game over (tap lock and direct calls) do not spin; restart resets the rotation at once, no stale animation remains, and a crash mid-spin followed by restart starts at zero.

## 4. Diff review
`scripts/player.gd` and `tests/m3_check.gd` carry the G1.1 changes. No gameplay constant, collision geometry, scene, scrolling, hazard or input-lock code was modified for G1.1. The working tree also still holds the uncommitted G1 changes (`scenes/*.tscn`, `scripts/hazard.gd`, `scripts/main.gd`, `project.godot`) and an unrelated `README.md` modification; these are not part of G1.1.

## 5. Limits of headless animation testing
- Headless mode renders nothing, so the tests prove the node angles, pivots and collision values, not how the spin looks. Smoothness and feel are PENDING MANUAL TEST.
- Tween progress follows process-frame time. The tests sample once per physics frame, and the "saw intermediate angles" check depends on the headless frame rate being close to real time (it was).
- Because the player is a symmetric square, only the in-between frames show the rotation; the start and end poses look identical.

## 6. Manual checks (Galaxy M52 or editor F5)
1. Tap to flip: the square should spin a quarter turn clockwise around its centre, with the halo and outline staying aligned to it.
2. The flip itself (direction change and speed) should feel exactly as before.
3. Tap rapidly: it should keep spinning cleanly and settle with no wobble or offset.
4. Crash and restart: the new run should start unrotated.

## 7. Concerns
- 0.12 s is a first guess for the spin time and may need tuning by feel.
- The halo is a larger square, so it sweeps a wider area while spinning (up to about 28 px from the centre at 45 degrees); this is visual only and does not affect collision.
