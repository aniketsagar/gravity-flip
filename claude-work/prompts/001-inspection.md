# Prompt 001 — Project inspection (2026-10-26)

Verbatim from the user:

> We're building Gravity Flip, a minimalist 2D arcade game for Android using Godot 4.7.2 Stable and GDScript.
>
> The project has an initial Git commit and a GitHub remote. Do not initialize Git or change the remote configuration.
>
> The main scene is `res://scene/main.tscn`. The intended scene tree is:
>
> * Main (Node2D)
>   * Player (CharacterBody2D)
>   * Ground (StaticBody2D)
>   * Ceiling (StaticBody2D)
>
> First, inspect the existing project without modifying any files.
>
> 1. Read `project.godot` and `scene/main.tscn`.
> 2. Verify the actual scene tree and node types.
> 3. Check the display settings for a portrait-oriented 2D game.
> 4. Identify any missing configuration or structural issues.
> 5. Determine how to run Godot headlessly from this Windows environment, using the installed executable rather than assuming it is on PATH.
> 6. Report the findings and recommend the smallest set of changes needed before implementing gameplay.
>
> Do not modify files during this inspection. Do not install additional software. Do not create a README or other documentation unless requested.
>
> We'll implement the game in small, testable milestones and commit each verified milestone separately.

Follow-up instruction (same message):

> also make a folder in the current directory where you write reports and your prompts, maintain detailed reports and prompts for working context

Interpretation: the `claude-work/` folder is an explicit user-requested exception to "no file changes"; it holds `prompts/` and `reports/`. Nothing else was modified.
