# Prompt 002 — M1 runnable scene skeleton (2026-10-26)

Summary of the user's prompt (decisions + requirements):

Decisions: keep `scenes/`; main scene `res://scenes/main.tscn`; root renamed `Main`; project renamed `Gravity Flip`; Godot 4.7.2; GL Compatibility; viewport 480x854 portrait; stretch canvas_items / aspect expand.

Requirements:
1. `project.godot`: name `Gravity Flip`, `run/main_scene="res://scenes/main.tscn"`.
2. `scenes/main.tscn`: Main (Node2D) with Player (CharacterBody2D), Ground and Ceiling (StaticBody2D), CollisionShape2D children (Rectangle/Capsule), minimal visible shapes.
3. Ground/ceiling placed sensibly for portrait; account for `expand` (don't assume exactly 480x854).
4. Keep simple: no obstacles, scoring, game over, gravity switching, audio, menus, Android deps, external assets.
5. Don't change remotes, re-init git, or commit.

Verification asked: run the 4.7.2 console exe headlessly (`E:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`); confirm main scene loads with no missing-main-scene error; report warnings/errors; check `git diff` and `git status`; don't claim untested passes.

Final report must cover: files changed, scene tree, config changes, verification commands + actual results, remaining limitations. No commit; leave ready for review.
