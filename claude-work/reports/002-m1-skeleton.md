# Report 002 — M1 runnable scene skeleton (2026-10-26)

Prompt: `../prompts/002-m1-skeleton.md`. Not committed; left for review.

## Files changed
- `project.godot` (modified): `config/name="Gravity Flip"`, added `run/main_scene="res://scenes/main.tscn"`.
- `scenes/main.tscn` (modified): full M1 scene.
- `scripts/main.gd` (new): lays out Ground/Ceiling/Player from the visible rect.
- `claude-work/` (new, untracked): prompts and reports.

## Scene tree
```
Main (Node2D, script scripts/main.gd)
├─ Player (CharacterBody2D)  ─ CollisionShape2D (RectangleShape2D 32x32), Visual (ColorRect, yellow)
├─ Ground (StaticBody2D)     ─ CollisionShape2D (RectangleShape2D), Visual (ColorRect, green)
└─ Ceiling (StaticBody2D)    ─ CollisionShape2D (RectangleShape2D), Visual (ColorRect, pink)
```
Root name kept its existing uid/unique_id. No external assets.

## Layout approach (expand aspect)
`main.gd` computes `get_viewport().get_visible_rect()` in `_ready()` and on `size_changed`. Ceiling = top edge, Ground = bottom edge (both 40 px thick, full visible width, shape and ColorRect resized to match), Player = rect centre. The values stored in the .tscn (480-wide, y=20 / 834) are only editor-time defaults that the script overrides at runtime.

## Verification (actually run)
Godot = `E:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`.

1. `--headless --path E:\dev\projects\gravity-flip --quit-after 5` -> prints only the version banner, **exit 0**, no errors/warnings, and no missing-main-scene error (previously failed with exit 1).
2. Scratch script (`--headless --script <scratchpad>\check.gd`, outside the repo) loaded `res://scenes/main.tscn`, instantiated it, waited one frame, printed the tree and shapes. Output matched the tree above; Player/Ground/Ceiling classes were CharacterBody2D/StaticBody2D/StaticBody2D with RectangleShape2D shapes; **exit 0**, no warnings/errors.
3. `git status --short`: ` M project.godot`, ` M scenes/main.tscn`, `?? claude-work/`, `?? scripts/`. `git diff --stat`: 2 files, +54/-2. Remotes untouched, no commit.

## Limitations / caveats
- Step 1 proves the project starts with the configured main scene without errors, but it prints nothing from the scene itself; scene loading was confirmed explicitly by step 2.
- In the headless `--script` run the visible rect was 854x854 (a headless-window artifact), giving surfaces 854 wide at x=427. This shows the layout follows the visible rect but is NOT a check of a real portrait device or the 480x854 desktop window. Not visually verified: no screenshot or windowed run was done.
- No Player movement/gravity yet (CharacterBody2D is static), by M1 design.
- `main.tscn` was hand-written; the editor may re-save it with extra uids/formatting on first open.
- Android toolchain gaps from report 001 still stand.
