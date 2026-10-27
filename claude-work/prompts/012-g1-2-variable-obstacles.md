# Prompt 012 — G1.2: variable-sized obstacles, inspection (2026-10-27)

Summary of the user's prompt (inspection only; no implementation yet).

Goal: more gameplay variety through variable-sized obstacles while keeping generation fair and predictable. Inspect only: no file changes, no formatters, no commit or push. Preserve G1.1 player rotation (accepted).

Size reference is the playable height, not the whole screen. Proposed categories: Small 15-25%, Medium 30-45%, Large 50-66%, maximum about two-thirds. These are target ranges, not permission for arbitrary randomness: recommend concrete sizes or ranges.

Inspect the current `scripts/hazard.gd`, `scripts/main.gd`, `scenes/hazard.tscn`, `scenes/main.tscn`, `tests/m3_check.gd` and anything else relevant; do not rely only on earlier reports.

Questions: how hazards are spawned, positioned, sized and recycled; how ground and ceiling hazards are distinguished; where visual and collision dimensions are configured; how playable height is calculated including resize; how spacing is determined; whether variable sizes fit without changing scroll speed or the spawn/recycle architecture; what keeps a viable route; how size should be selected (fixed sequence, controlled pattern, weighted random); what happens on resize; which tests cover placement, collision geometry, scrolling and restart; which new tests are needed.

Constraints: preserve G1.1 and its tests, gravity, velocity, flip speed, input locks, scroll speed, game over and restart, the neon style and Visual node structure; keep visual and collision size synchronised; keep obstacles inside the playable area; maximum about two-thirds of playable height; no new mechanics; do not weaken tests; no unnecessary abstractions or full spawner rewrite; do not commit or push.

Fairness: account for ground and ceiling obstacles, player size and movement, distance between consecutive obstacles, whether a flip can finish in time, large obstacles making a route impossible, and resize. Do not claim safety from visual inspection; separate what can be tested automatically from what needs playtesting.

Report: verified description of spawning and recycling; file paths and functions; size-selection and spacing strategy; definition of playable height and maximum size; fairness strategy; smallest implementation; tests; risks and open decisions; commands. Distinguish verified findings from assumptions. Stop and wait for approval.
