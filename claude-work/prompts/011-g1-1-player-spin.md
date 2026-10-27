# Prompt 011 — G1.1 implementation: player spin on flip (2026-10-27)

Summary of the user's approval and decisions (follows prompt 010's inspection).

1. On each successful gravity flip, smoothly rotate the player visuals exactly 90 degrees clockwise.
2. Keep the `CollisionShape2D` axis-aligned and unchanged at 32x32 throughout the animation. Do not rotate the `Player` root if that would rotate the collision shape.
3. Gravity and vertical velocity changes stay immediate; the animation is visual feedback only.
4. Reset the visual rotation to zero when a new run starts.
5. No rotation for ignored flips after game over.
6. Preserve gravity, velocity and flip-speed constants, input locks, scrolling, hazards, game over and restart.
7. Avoid unnecessary scene-tree changes; handle the pivot so the player rotates about its centre. Do not assume `Control` nodes rotate about their centre.
8. Add targeted tests for rotation, collision-shape invariance, ignored flips, restart and rapid flips; do not weaken existing assertions.

Before implementing: inspect the visual node types and choose the simplest safe way to rotate all visuals around their shared centre.

After: run `godot --headless --path . --script res://tests/m3_check.gd` and `git diff --check`, review the complete diff, report actual results and the limits of headless animation testing, confirm only the intended player script and test files changed, do not commit or push. Stop after reporting.
