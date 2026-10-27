# Prompt 010 — G1.1: player rotation and collision (2026-10-27)

Summary of the user's prompt (inspection only; no implementation yet).

Goal: the player rotates exactly 90 degrees with every successful gravity flip. The visual and the collision shape must rotate together. The player is currently square; implement it in a way that respects the existing scene structure and avoids unnecessary coupling.

Task: inspection only. Do not modify any files, run formatters that modify files, or commit or push. Inspect `scripts/player.gd`, `scripts/main.gd`, `scenes/main.tscn` and the tests covering flip, collision, game over and restart.

Questions: which node owns position and physics; where the collision shape is defined and positioned; how a successful flip is detected; whether the flip starts in `player.gd`, `main.gd` or both; whether flips are immediate or animated; how input locks and game over are handled; whether rotating the body affects collision or other gameplay; the smallest safe implementation; existing tests and targeted tests to add; concerns about collision, restart state and repeated flips.

Constraints for the eventual implementation: keep gravity direction behaviour, gravity, velocity and flip-speed constants, the input locks, scrolling, obstacle placement and collision (apart from the player rotation), obstacle sizes and spacing, and the G1 neon visuals; no new mechanics, dependencies or unnecessary abstractions; do not weaken test assertions; do not commit or push.

Report: existing architecture; exact files and functions to change; the rotation approach and why it is safe; risks and unresolved questions; tests to add or update; commands to run after implementation. Distinguish verified findings from assumptions. Stop after the report and wait for approval.
