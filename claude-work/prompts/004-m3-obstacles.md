# Prompt 004 — M3 obstacles and failure conditions (2026-10-26)

Summary of the user's prompt:

Implement M3 in `E:\dev\projects\gravity-flip` (Godot 4.7.2, GDScript). First inspect M1/M2, tests, structure and the M2 report; preserve the gravity-flip mechanics.

1. Obstacles: a small set of predefined patterns of simple rectangular hazards, alternating ceiling-side / ground-side in the play area; patterns must force gravity switches; enough time/space to react; visually distinct from ceiling, ground and player; Godot-native nodes/collision shapes, no external assets.
2. Collision/game over: reliable player-hazard detection; a hit stops the run and shows game over; ceiling/ground stay safe; game over must not retrigger or corrupt state.
3. Restart: tap/click after game over starts a fresh run; reset player position, velocity, gravity direction, obstacles and state; the restart input must not immediately flip gravity.
4. Preserve: automatic horizontal movement, tap/click flip, safe surfaces, horizontal wrapping, desktop mouse + Android touch handling.
5. Scope: no scoring, menus, sound, particles, persistence, monetization, external deps, or procedural generation; keep the pattern system simple and extensible; prefer a few reusable scenes/nodes.
6. Tests: headless tests for movement/flip, safe landing on ceiling and ground, hazard collisions -> game over, safe surfaces not triggering game over, restart reset, wrapping, no double flip / no flip right after restart. Run headless validation and tests with the installed 4.7.2 exe. Be explicit about headless vs. manual coverage.
7. Reporting/Git: update the M3 report in `claude-work/reports/` (changed files, behavior, test commands/results, limitations, manual test steps); review the final diff; do not commit, push, change remotes, or install tools.

Final answer: implementation + verification summary; anything needing a decision or manual testing.
