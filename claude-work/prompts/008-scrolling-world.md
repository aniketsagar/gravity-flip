# Prompt 008 — Scrolling world: obstacles move right-to-left (2026-10-27)

Summary of the user's prompts (two steps).

## Step 1 — inspection (read-only)

On the Samsung Galaxy M52 the obstacles look like they flash or pop into view instead of moving continuously. Compare the current horizontal movement with the Flappy Bird model: the player stays at a roughly fixed x, obstacles move continuously right to left, enter from the right and leave on the left; gravity flipping unchanged; patterns, collisions, restart and tuning preserved.

Inspect `scripts/main.gd`, `scripts/player.gd`, `scenes/main.tscn` and the tests. Determine: how horizontal movement works now; whether the player or the obstacles move; how obstacles are created, repositioned, wrapped and removed; why it looks like popping on the device; the smallest safe change. Do not modify files, do not change constants, no background yet. Return findings and a plan.

## Step 2 — implementation (after approval)

Decisions: keep the player's start x (`START_MARGIN`, 40); keep gravity, flip speed and vertical limits; keep 200 px/s; ground and ceiling stay still; keep patterns, sizes, colours, collision, game over and the restart input locks; no background; no difficulty change.

Requirements: player no longer moves horizontally or wraps; hazards scroll in `main.gd`; hazards spawn or recycle from the right edge and leave on the left, keeping pattern order and spacing across pattern boundaries; collisions and game over keep working with moving hazards; restart resets scroll, hazards and pattern sequence; viewport resize does not leave stale positions; keep it simple and reuse the hazard scene and pattern definitions; update `tests/m3_check.gd` for the scrolling model without dropping coverage of flip, collision/game over, restart and input locks, placement, pattern sequence and survivability; run the tests and do not claim a pass that was not run; inspect the final diff.

Report: files changed and why, the new movement and lifecycle behaviour, tests and actual results, limitations, manual checks needed on the M52. Do not commit or push unless asked.

Follow-up: the user confirmed the build works on the device and asked for the commit and push (`1efb087`).
