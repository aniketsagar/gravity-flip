# Report 001 — Project inspection (2026-10-26)

> **Historical snapshot (2026-10-26).** This report records the initial project state, before the M1 skeleton and everything after it (gameplay loop, obstacles, scrolling, neon visuals, G1.x, Android setup). Its findings are preserved unchanged and may no longer match the current code.

Prompt: `../prompts/001-inspection.md`. Read-only inspection. The only files created are those in `claude-work/`.

## Environment
- Repo: `E:\dev\projects\gravity-flip`, branch `main`, working tree clean before and after inspection.
- Remote `origin` = `https://github.com/aniketsagar/gravity-flip.git` (untouched).
- Tracked files: `.editorconfig .gitattributes .gitignore README.md icon.svg icon.svg.import project.godot scenes/main.tscn`.

## Godot executable (headless)
`E:\Godot_v4.7.2-stable_win64.exe` is a **directory**, not the exe. It contains:
- `E:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe` (editor, GUI subsystem)
- `E:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe` (console build, use this for CLI/headless)

Not on PATH. `--version` -> `4.7.2.stable.official.ed1daf0bf` (matches the target).

Headless invocation pattern (PowerShell):
```
$godot = 'E:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe'
& $godot --headless --path E:\dev\projects\gravity-flip --quit-after 2
```
Verified: it starts, then fails with `Can't run project: no main scene defined in the project.` (exit 1). Running does not dirty git (`.godot/` is ignored).

## Findings

### 1. Scene path mismatch
- Actual file: `res://scenes/main.tscn` (folder is `scenes`). The brief says `res://scene/main.tscn`. No `scene/` folder exists.
- Recommendation: keep `scenes/` (already tracked, conventional) and treat the brief's path as a typo.

### 2. Scene tree is a stub
`scenes/main.tscn` (whole file):
```
[gd_scene format=3 uid="uid://cqow47bch5ocs"]
[node name="main" type="Node2D" unique_id=546288906]
```
- Only one node: `main` (Node2D), lowercase name (intended: `Main`).
- Missing entirely: Player (CharacterBody2D), Ground (StaticBody2D), Ceiling (StaticBody2D), and their CollisionShape2D / visuals (each body needs a shape to function).

### 3. No main scene configured
`project.godot` has no `run/main_scene` under `[application]`. Headless/play fails (confirmed above).

### 4. Project name
`config/name="New Game Project"` -> should be "Gravity Flip".

### 5. Display settings (portrait 2D) — mostly good
| Setting | Value | Assessment |
|---|---|---|
| viewport 480x854 | portrait ~9:16 | OK |
| window override 480x854 | desktop test window matches | OK |
| stretch mode `canvas_items` | good for 2D | OK |
| stretch aspect `expand` | handles taller phones; gameplay must anchor to the top/bottom edges rather than assume 854 tall (ceiling/ground placed from the viewport rect) | OK, design note |
| `window/handheld/orientation=1` | Portrait | OK (1 = portrait) |
| renderer `gl_compatibility` (+ `.mobile`) | right for Android | OK |

### 6. Physics settings
- `3d/physics_engine="Jolt Physics"` is irrelevant for a 2D game (harmless).
- No 2D gravity or layer names set. Gravity flip will be implemented in script (the player sets its own gravity sign), so the project default gravity is a non-issue.
- No collision layer names defined (optional).

### 7. Missing / not yet set up
- No scripts, no `.gd` files, no input mapping (a tap/touch action is needed; touch can emulate mouse by default, so `_input` with `InputEventScreenTouch`/mouse works, or define an `flip` action).
- No `export_presets.cfg` (gitignored by `.gitignore`, so it can never be committed; fine, but Android export is local only).
- `.gitignore` ignores `/android/`, `.godot/`, `export_presets.cfg`, keystores. Fine.
- `README.md` is a 2-line stub (leave as is; no docs requested).
- Icon is the default `icon.svg` (cosmetic).

### 8. Android toolchain (not needed for gameplay milestones; relevant later)
- Godot editor settings point `android_sdk_path` to `C:\Users\<WINDOWS_USER>\AppData\Local\Android\Sdk`, but that directory **does not exist**; `adb` is not on PATH.
- `export/android/java_sdk_path` is empty; `java` on PATH is Java 16.0.2 (Godot 4.x Android export needs JDK 17).
- `%APPDATA%\Godot\export_templates` is empty -> no Android export templates installed.
- Consequence: an APK cannot be exported yet. Does not block gameplay development, which can be verified on desktop/headless. No software installed per instructions.

## Recommended minimal changes before gameplay
1. `project.godot`: set `config/name="Gravity Flip"` and `run/main_scene="res://scenes/main.tscn"`.
2. `scenes/main.tscn`: rename root to `Main`; add `Player` (CharacterBody2D), `Ground` (StaticBody2D), `Ceiling` (StaticBody2D), each with a CollisionShape2D (RectangleShape2D / CapsuleShape2D). Place Ground/Ceiling by script from the viewport size, or at fixed positions inside the 480x854 base while keeping `expand` in mind.
3. Optional: add an input action `flip` in `project.godot`; remove the Jolt 3D line only if unwanted (harmless).
4. Defer Android SDK/JDK 17/export templates until a milestone needs a device build.

## Proposed milestones
1. M1 scene skeleton + main scene config (headless run exits 0).
2. M2 player gravity and flip on tap, constrained between Ground and Ceiling.
3. M3 obstacles/scoring/game over/restart.
4. M4 polish and Android export setup.

Each is headless-testable with a small test script, committed separately.

## Open points for the user
- Confirm `scenes/` (existing) over `scene/` (brief).
- Confirm root node name `Main` (rename from `main`).
