# Report 016 — G1.2 implementation audit (2026-10-27)

Prompt: `../prompts/016-g1-2-audit.md`. Read-only audit; the only things run were `git` queries and the headless suite. This report was written afterwards at the user's request; the only file edited besides it is Report 015 (errata, below).

## Errata to Report 015 (found by this audit)
- "29 consecutive pairs" was wrong: the clearance test checks **19** pairs (20 hazards over two cycles; index 0 gets the first-obstacle rule).
- "Four tests" changed tap timing: it was **three**.

## 1. Test changes
- Window 480x854 (first line of `_initialize`): the headless default is 854x854 (verified: 4 hazards alive at start). Patterns are now pixels, so hazards-at-once depends on width; "pattern 0's 2 hazards" holds only at 480 px. Wide windows remain covered by the 1200x800 bot test and the 1281x854 G1.2 tests.
- Three `_wait_unlocked()` (40 ticks = 0.67 s) became `_frames(10)`: the "staying on the ceiling" collision test, the "After game over" spin block, the "flip right before a crash" spin block. The first hazard now arrives after 145 px / 200 = 0.725 s, so the old wait put the tap on the hazard. Lock is 0.15 s = 9 ticks.
- Bot ground lead 100 to 140 px: run 1 failed `bot dodges all patterns for 6 laps at (540, 1200)` (laps 4.33) with 100; a 0.66 hazard at P = 986 needs 31 ticks, about 103 px. 140 passes at all windows (verified by run, no isolated analysis).
- No assertion removed or weakened by the diff; every deleted line was rewritten for the new data format with the same message. Coverage differences: legacy tests no longer run at 854 px width incidentally; the legacy bot is a slightly different harness.

## 2. G1.1 spin regression
- Failing test: `restart during/after a spin starts at zero rotation and stays there` (`tests/m3_check.gd:646`). Fixed by changing the tap before it (`:637`) from `_wait_unlocked()` to `_frames(10)`.
- Probable mechanism (NOT verified): the old wait put the "flip" tap about 1.17 s after the restart, after the first hazard had ended the run, so it was likely a restart rather than a flip. Why the final assertion then failed was not established; the deferred restart issues were not investigated.
- The test still verifies reset to zero (flip, crash, restart, running, angle 0, turns 0 after 30 ticks). Gap: it does not assert the spin is mid-animation at crash time (pre-existing; the earlier blocks `:623` and `:634` cover reset after a completed spin).

## 3. Clearance evidence
- `_flat_hazards(patterns, 2)` = 20 hazards; pairs i = 1..19: 10 within a pattern, 8 between patterns (P0-P1, P1-P2, P2-P3, P3-P4 in each cycle), 1 cycle boundary (P4-P0). Same loop at 480x854, 540x1200 (visible 480x1066) and 1281x854, T measured per viewport.
- Output prints one aggregate result per viewport plus the tightest pair, not one line per pair:
  - 480x854: approach 145.0 >= 90.0; all pairs pass, tightest `#7->#8` (h 511, 26 ticks) slack 31.3 px.
  - 540x1200: approach 145.0 >= 96.7; all pairs pass, tightest `#7->#8` (h 651, 31 ticks) slack 14.7 px.
  - 1281x854: same as 480x854 (same playable height).
- Limit: T is measured only for the ceiling-to-ground direction in the suite; symmetry was shown in earlier scratch measurements.

## 4. Test results
`godot --headless --path . --script res://tests/m3_check.gd` (console exe): exit 0, 154 PASS, 0 FAIL, `RESULT: ALL PASSED`, re-run after the final changes (scratchpad `run5.txt`).

## 5. Diff audit
- `git diff --check`: exit 0 (CRLF to LF warnings for `main.gd` and `m3_check.gd` only).
- Modified: `scripts/main.gd`, `scripts/hazard.gd`, `tests/m3_check.gd` (G1.2); `README.md`, `scenes/main.tscn`, `scripts/player.gd` (not mine). Untracked: `.claude/`, `claude-work/`, `image/`, `screenshots/`.
- `player.gd` diff is only `MAX_VERTICAL_SPEED` 1000 to 3000 (the user's edit); `GRAVITY` 2700, `FLIP_SPEED` 600, `SPIN_TIME` 0.12 and the spin code are unchanged. `SCROLL_SPEED := 200.0` unchanged.

## Status
Audit complete; no code changed. Pending: M52 playtest, then the user's decision on commit.
