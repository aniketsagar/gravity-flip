# Prompt 014 — G1.2 final plan corrections (2026-10-27)

Summary of the user's prompt (planning only; do not modify project files; stop and wait for explicit approval).

Confirmed decisions: `MAX_VERTICAL_SPEED = 3000` is intentional and must be preserved; the existing obstacle patterns are re-authored to the new size categories; Option B (variable pattern lengths and larger gaps) is approved in principle.

Corrections to address before implementation:

1. Clearance: verify the conservative rule `required_gap >= player_width + scroll_speed * (clear_time(next_obstacle) + reaction_margin)` using the actual collision width, the 200 px/s scroll speed, a 0.3 s reaction margin and clear times measured with the current Player physics. Do not apply it blindly; explain any correction for the player geometry, previous and next obstacle, and alternating surfaces. Distinguish geometric clearance, clearance with the reaction margin, and what still needs playtesting.
2. Pattern lengths: derive them from the corrected rule across every consecutive pair, the cycle boundary, the final hazard of one pattern to the first of the next, the first obstacle's approach, the existing widths and deterministic ordering. Do not assume 480 or 540 px is sufficient.
3. Categories (playable height as reference): Small 15-25%, Medium 30-45%, Large 50-66%, maximum 66%. Re-author the existing patterns instead of keeping fixed pixel heights; first obstacle Small with a fair approach; controlled deterministic patterns, no unrestricted randomness.
4. Preserve: `MAX_VERTICAL_SPEED = 3000` and all other player constants, flip behaviour and G1.1 rotation, scroll speed, collision and game over, restart and input locks, neon visuals; no gravity fields, projectiles or new mechanics.
5. Tests to confirm: category bounds and the 66% maximum, visual/collision synchronisation, valid placement, clearance for all pairs and cycle boundaries, first-obstacle size and approach, resize, restart, and the existing scroll, collision and G1.1 tests; no assertion removed or weakened.

Required response: the verified clearance formula and assumptions; derived pattern lengths and spacing; exact files and functions; test additions; remaining risks and required playtests. Stop and wait for explicit approval.
