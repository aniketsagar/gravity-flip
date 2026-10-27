# Report 014 — G1.2 final plan (2026-10-27)

Prompt: `../prompts/014-g1-2-final-plan.md`. Planning only; no project file modified, nothing committed or pushed. Evidence: scratch scripts in the session scratchpad (outside the repo) ran the real `Main`, `Player` and `Hazard` code headless at 60 ticks/s: `measure.gd` (flip travel), `verify_rule.gd` and `dbg3.gd` (clearance sweeps). Working tree at the time: uncommitted `MAX_VERTICAL_SPEED = 3000.0` in `player.gd` (confirmed intentional by the user), plus `README.md` and editor-added node ids in `main.tscn`.

## 1. Clearance rule, verified
`gap >= W_p + v * (T(next) + R)` holds for a consecutive pair. W_p = 32 (the `RectangleShape2D` in `main.tscn`), v = 200 px/s, R = 0.3 s, T = measured flip-to-clear time of the next hazard's height from rest on the opposite surface (identical from ground and ceiling). The gap is edge to edge (previous right edge to next left edge); centre distance = gap + (w_prev + w_next)/2. Reason: at the flip moment the player's left edge is at the previous hazard's right edge, so the player's right edge has gap - 32 px to cover.

Empirical check (P = 986; a bot flips down a set delay after the player's left edge passes the first hazard; smallest surviving gap, 2 px sweep):

| Fraction | Formula, no margin / measured | Formula + 0.3 s / measured |
|---|---|---|
| 0.20 | 75.3 / 77 | 135.3 / 137 |
| 0.38 | 102.0 / 104 | 162.0 / 164 |
| 0.50 | 118.7 / 117 | 178.7 / 177 |
| 0.60 | 128.7 / 131 | 188.7 / 191 |
| 0.66 | 135.3 / 137 | 195.3 / 197 |

Measured thresholds equal the formula within about 2 px (sweep resolution). It is not the global physical optimum (an earlier flip might save distance; not established).

Corrections:
- First obstacle: no previous hazard, so no W_p term. Condition: `left edge - 56 >= v * (t_flip + T)` (56 = player right edge). The 0.15 s restart tap lock belongs to the physical minimum (measured with a flip at the lock end: 75 px at 0.20 against 73.3 predicted); with the 0.3 s margin it is absorbed (measured 107 against 103.3 predicted at 0.20; 167 against 163.3 at 0.66).
- Cycle boundary (last hazard of the last pattern to the first of pattern 0) follows the pair rule; the first-obstacle rule applies only at run start.
- Not covered by the formula, forbidden by a test: same-side consecutive hazards and horizontally overlapping hazards.

Levels: (1) geometric `32 + 200*T`; (2) with margin: plus 60 px; (3) recommended for first playtest: (2) plus one tick (3.3 px), rounded up to 10 px: 140 / 150 / 160 / 170 / 180 / 190 / 190 / 200 for fractions 0.20 / 0.25 / 0.30 / 0.38 / 0.45 / 0.50 / 0.55 / 0.66 at P = 986 (0.15 also 140, 0.60 is 200). Needs playtest: M52 touch latency, whether 0.3 s feels fair.

## 2. Derived pattern lengths (authored candidate; positions are centres in px from the pattern start)
| Pattern | Hazards | Length |
|---|---|---|
| P0 | ground 0.15 w30 @216, ceiling 0.20 w30 @446 | 480 |
| P1 | ground 0.30 w40 @216, ceiling 0.38 w40 @446 | 480 |
| P2 | ground 0.50 w40 @216, ceiling 0.45 w30 @446 | 480 |
| P3 | ground 0.25 w50 @216, ceiling 0.55 w40 @466 | 500 |
| P4 | ground 0.66 w40 @216, ceiling 0.20 w30 @446 | 480 |

Consecutive pairs incl. both boundaries (available gap / recommended minimum / slack): P0 ground to ceiling 200/140/60; P0 to P1 215/160/55; P1 internal 190/170/20; P1 to P2 210/190/20; P2 internal 195/180/15; P2 to P3 210/150/60; P3 internal 205/190/15; P3 to P4 (0.55 to 0.66) 210/200/10; P4 internal 195/140/55; P4 to P0 (cycle) 220/140/80. P3 needs 500 px: at 480 the 0.55 to 0.66 pair would have zero slack. P = 774 needs smaller gaps, so it holds. First hazard (0.15): 145 px approach against 96.7 needed. Final values are validated by the tests.

## 3. Files and functions
- `scripts/main.gd`: new `PATTERNS` format (`{"len", "hazards": [...]}`, x in px, `h_frac`), `_playable_height()`, `_spawn_origin` (reset in `_restart`), `_spawn_hazards`, `_place_hazards`; `_restart` ordering open (see risk 1).
- `scripts/hazard.gd`: store `x_px` and `h_frac`; `place()` takes pixel x; height = round(h_frac * P).
- `tests/m3_check.gd`: adapt checks that read fractional x, pixel h, `x_frac` or the lap count; no assertion removed or loosened.
- Unchanged: `player.gd` (MAX_VERTICAL_SPEED = 3000 stays), scenes, scroll speed, visuals.

## 4. Tests to add
Category bounds and the 0.66 maximum at 480x854, 480x1066 and 1281x854; hazards inside the playable area; collision/Visual/Outline/Halo synchronisation; clearance for every cyclic consecutive pair with required gaps measured by running the real Player; strict alternation across boundaries; first hazard Small and first approach rule; a 0.3 s-delay bot survives several cycles at all sizes, with a too-tight pair as negative control; resize rescales heights and keeps positions valid; restart restores origin, sizes and sequence; existing scroll, collision and G1.1 tests kept.

## 5. Risks and playtests
1. New finding (verified in scratch): `_restart()` spawns hazards before moving the player, which still sits at its scene-file position (240, 427) on first launch; a tall hazard over x 224-256 at that height registers a hit on frame 1 (ground hazard h >= 583 at P = 986, ceiling hazard h >= 371). The authored first patterns avoid it. Candidate fixes: place the player before spawning (not verified for the first frame) or move the scene position to x = 40; a test decides. Also observed in scratch only: a restart in the same frame as such an overlap can be stopped again by a stale queued overlap event.
2. Playtest on the M52: margin comfort, slack of 5-20 px, readability of tall obstacles, difficulty progression, touch latency.
3. Assumptions: M52 layout 480x1066; taller viewports make the same fractions harder.

## Status
Waiting for explicit approval. Implementation: NOT STARTED. The measurements above are real-game headless results at 60 ticks/s without touch latency.
