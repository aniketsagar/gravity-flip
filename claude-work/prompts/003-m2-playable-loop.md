# Prompt 003 — M2 first playable loop (2026-10-26)

Summary of the user's prompt:

Implement M2 in `E:\dev\projects\gravity-flip` (Godot 4.7.2). Inspect the project and M1 first; preserve scene structure/conventions.

Requirements:
1. Player moves horizontally at constant speed through the play area.
2. Mouse click / screen tap flips vertical gravity.
3. Correct CharacterBody2D movement/collision; never pass through ceiling or ground.
4. Stay within the horizontal play area; simple predictable edge behavior.
5. Minimal game-over state for a failed run + tap/click-to-restart.
6. Mouse works in desktop editor; touch works on Android.
7. Simple visuals consistent with M1; no obstacles, scoring, menus, sound, external deps.
8. Frame-rate independent movement and gravity.
9. Input and physics in the appropriate callbacks; no unnecessary nodes/abstractions.

Verification: headless validation with the installed 4.7.2 exe; focused checks where practical; inspect final diff; do not commit, push, change remotes, or install Android tooling; write an M2 report in `claude-work/reports` (changed files, controls, mechanics, verification commands/results, limitations, manual-test items); do not claim touch or visual gameplay verified unless tested.

Final answer: what changed; how to run/test; exact verification commands and results; remaining risks/decisions.
