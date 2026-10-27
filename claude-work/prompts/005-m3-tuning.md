# Prompt 005 — M3 tuning after hands-on feedback (2026-10-26)

Summary of the user's prompt:

Feedback: playable; first obstacle visible early enough; gap between the two hazards too short; player feels rushed when flipping; flipping feels laggy/boaty and should be snappy; game over and restart correct.

Inspect `scripts/player.gd`, `scripts/main.gd`, `scenes/hazard.tscn`, `tests/m3_check.gd` first.

1. Snappy flip: on a valid tap reverse gravity and immediately set vertical velocity toward the new surface; no teleporting; keep normal collision and frame-rate independence; horizontal speed unchanged; a flip from either safe surface moves away from it; no flips after game over; keep the restart/input-lock behaviour.
2. Physics: gravity 2400 px/s^2, max vertical speed 1000 px/s, horizontal 200 px/s; values centralized; no extra abstractions.
3. Spacing: increase the gap between successive hazards by about 20-25%; keep the first obstacle at about its current position; keep three patterns and alternation; each pattern survivable with the real physics; not trivial.
4. Tests: falling->up velocity, rising->down velocity, flip from ground/ceiling moves away, hazards still end the run, safe surfaces safe, restart and locks, wrap and all three patterns, survivability. Run headless validation and the full M3 test. Do not claim it feels better without manual playtesting.
5. Report: update the M3 report (physics values, spacing, test results, limitations). No commit/push/remote changes/new features; review the final diff and summarize.
