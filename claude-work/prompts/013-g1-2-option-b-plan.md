# Prompt 013 — G1.2 variable-sized obstacles, Option B planning (2026-10-27)

Summary of the user's prompt (planning only; no implementation).

Option B was selected: patterns may use larger gaps so large obstacles (up to about 66% of playable height) can be introduced without changing scroll speed or player physics. Do not modify project files, run modifying formatters, commit or push. Stop after the plan.

Required: reinspect `main.gd`, `hazard.gd`, `main.tscn`, `hazard.tscn`, `tests/m3_check.gd` rather than relying on the previous report; describe the spawn sequence, spacing, recycling, collision geometry and playable-area calculation, separating verified behaviour from estimates.

Sizing: playable height (between the inner faces of ground and ceiling) is the reference; categories Small 15-25%, Medium 30-45%, Large 50-66%, maximum about 66%; explain how height derives from playable height, how visual and collision geometry stay synchronised, how sizing behaves on viewport change, how to avoid unexpected size changes on recycling; keep existing widths unless there is a compelling reason.

Clearance: do not rely on the earlier hand-calculated gaps; derive a conservative, testable rule from the real player and hazard geometry (player size, position and movement, flip velocity and acceleration, scroll speed, hazard height and width, time to reach the opposite surface, a provisional 0.3 s reaction margin, alternating surfaces, pattern boundaries and cycle transitions). Separate (1) minimum physically possible clearance, (2) clearance with the reaction margin, (3) recommended initial gameplay clearance. If exact values cannot be established, name the missing evidence. Do not reduce the reaction margin to fit larger obstacles; give obstacles more room instead.

Option B design: preserve the spawn architecture; address how sizes and positions are represented, how the next spawn position is calculated, how patterns of different lengths transition, interaction with recycling, deterministic ordering, a small approachable first obstacle, avoiding consecutive configurations with no viable route. Do not assume the earlier 540 px length; derive it. If too complex, explain the smallest alternative.

Tests: size categories, maximum fraction, visual/outline/halo/collision synchronisation, hazards inside the playable area, clearance for every consecutive pair including pattern and cycle boundaries, first obstacle small, resize, restart, and existing scrolling, collision and G1.1 rotation tests intact; say what is provable and what needs device testing; do not weaken assertions.

Scope: preserve player physics, spin, scroll speed, game over, restart, neon visuals and input handling; no jumbo gravity fields, projectiles, unrestricted random generation, menus or effects. List exact files and functions to change.

Report sections: verified architecture; sizing rules; clearance derivation and assumptions; pattern and spacing strategy; implementation changes by file; automated tests; risks and open questions; commands; and a clear split between mathematically established, inferred, and needs playtesting. Stop and wait for approval.
