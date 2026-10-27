extends SceneTree

# Headless checks for the scrolling loop (fixed player, scrolling hazards, flip, hazards,
# game over, restart, input, resize).
#   godot --headless --path <project> --script res://tests/m3_check.gd
# Exits 0 when every check passes, 1 otherwise.
#
# Taps call Main._unhandled_input directly: headless script mode does not dispatch
# pushed or parsed input events to the scene, so engine input dispatch is untested.
# Physics (CharacterBody2D, Area2D overlap) runs for real via physics frames.

const HALF := 16.0
const EMPTY := [[]]
const START_X := 40.0

var _failures := 0
var _main: Node
var _p
var _rect: Rect2


func _check(ok: bool, what: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + what)
	if not ok:
		_failures += 1


func _tap_mouse(device: int = 0) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	e.device = device
	_main._unhandled_input(e)


func _tap_touch() -> void:
	var e := InputEventScreenTouch.new()
	e.pressed = true
	_main._unhandled_input(e)


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _set_window(size: Vector2i) -> void:
	root.size = size
	await process_frame
	root.size = size
	await process_frame


# Fresh Main, optionally with a replacement pattern list (EMPTY = no hazards).
func _new_main(patterns = null) -> void:
	if _main:
		root.remove_child(_main)
		_main.queue_free()
		await process_frame
	_main = load("res://scenes/main.tscn").instantiate()
	if patterns != null:
		_main.patterns = patterns
	root.add_child(_main)
	await _frames(2)
	_p = _main.get_node("Player")
	_rect = root.get_visible_rect()


func _hazards() -> Array:
	return _main.get_node("Hazards").get_children()


func _label_visible() -> bool:
	return _main.get_node("GameOverLabel").visible


func _floor_y() -> float:
	return _main.get_node("Ground").position.y - 20.0 - HALF


func _ceil_y() -> float:
	return _main.get_node("Ceiling").position.y + 20.0 + HALF


# Waits out the tap lock (real physics time, in ticks) so the next tap counts.
func _wait_unlocked() -> void:
	await _frames(40)


func _px_per_tick() -> float:
	return _main.SCROLL_SPEED / Engine.physics_ticks_per_second


func _test_movement_and_surfaces() -> void:
	print("-- fixed player, scroll, flip, safe surfaces (no hazards)")
	await _new_main(EMPTY)
	_check(_p.running and _p.gravity_dir == 1.0, "run starts running with gravity down")
	var x0: float = _p.position.x
	_check(absf(x0 - (_rect.position.x + START_X)) < 0.01, "player starts at START_MARGIN")
	await _frames(40)
	_check(_p.position.x == x0 and _p.velocity.x == 0.0, "player does not move horizontally")
	await _frames(60)
	_check(absf(_p.position.y - _floor_y()) < 1.5, "rests on ground (y=%.2f, expected %.2f)" % [_p.position.y, _floor_y()])
	_check(_p.running and not _label_visible(), "ground contact is safe")
	var sa: float = _main._scroll
	await _frames(30)
	_check(absf((_main._scroll - sa) - _px_per_tick() * 30.0) < 0.001, "world scrolls at constant SCROLL_SPEED")

	_tap_mouse()
	_check(_p.gravity_dir == -1.0, "mouse click flips gravity up")
	var min_y := INF
	for i in 120:
		await physics_frame
		min_y = minf(min_y, _p.position.y)
	_check(min_y >= _ceil_y() - 1.0, "never above ceiling (min y=%.2f, limit %.2f)" % [min_y, _ceil_y()])
	_check(absf(_p.position.y - _ceil_y()) < 1.5, "rests on ceiling")
	_check(_p.running and not _label_visible(), "ceiling contact is safe")

	var laps_ok := true
	var s0: float = _main._scroll
	for i in 2:
		for j in 900:
			await physics_frame
			laps_ok = laps_ok and _p.running and _p.position.x == x0
		_tap_mouse()
	_check(laps_ok and not _label_visible() and _main._scroll - s0 > 2.0 * _rect.size.x,
			"multiple laps on ceiling and ground never end the run")


func _test_snappy_flip() -> void:
	print("-- snappy flip")
	await _new_main(EMPTY)
	var mid_y: float = _rect.get_center().y
	var speed: float = _p.FLIP_SPEED
	# Downward-moving player flips to upward velocity at once, without teleporting.
	await _wait_unlocked()
	_p.position.y = mid_y
	await _frames(5)
	_check(_p.velocity.y > 0.0 and _p.gravity_dir == 1.0, "player is moving down before the flip (vy=%.1f)" % _p.velocity.y)
	var pos_before: Vector2 = _p.position
	var x_before: float = _p.position.x
	_tap_touch()
	_check(_p.velocity.y == -speed, "flip while falling: vy becomes -FLIP_SPEED immediately (%.1f)" % _p.velocity.y)
	_check(_p.position == pos_before, "flip does not teleport the player")
	_check(_p.velocity.x == 0.0, "flip adds no horizontal speed")
	await physics_frame
	_check(_p.position.y < pos_before.y, "player moves up on the very next physics tick")
	_check(_p.position.x == x_before and _p.velocity.x == 0.0, "player x still fixed after flip")
	# Upward-moving player flips to downward velocity at once.
	await _frames(5)
	_check(_p.velocity.y < 0.0 and _p.gravity_dir == -1.0, "player is moving up before the second flip (vy=%.1f)" % _p.velocity.y)
	pos_before = _p.position
	_tap_mouse()
	_check(_p.velocity.y == speed and _p.gravity_dir == 1.0, "flip while rising: vy becomes +FLIP_SPEED immediately (%.1f)" % _p.velocity.y)
	_check(_p.position == pos_before, "no teleport on the upward flip either")
	await physics_frame
	_check(_p.position.y > pos_before.y, "player moves down on the very next physics tick")

	# Flip while touching the ground moves away from it right away.
	await _new_main(EMPTY)
	await _frames(40)
	_check(absf(_p.position.y - _floor_y()) < 1.5 and _p.is_on_floor(), "resting on ground before flip")
	await _wait_unlocked()
	_tap_mouse()
	await _frames(3)
	_check(_p.position.y < _floor_y() - 3.0 and _p.velocity.y < 0.0, "flip from the ground leaves the ground (y=%.2f)" % _p.position.y)
	# Flip while touching the ceiling moves away from it right away.
	await _frames(60)
	_check(absf(_p.position.y - _ceil_y()) < 1.5, "resting on ceiling before flip")
	_tap_mouse()
	await _frames(3)
	_check(_p.position.y > _ceil_y() + 3.0 and _p.velocity.y > 0.0, "flip from the ceiling leaves the ceiling (y=%.2f)" % _p.position.y)
	# Vertical speed never exceeds the maximum.
	var vmax := 0.0
	for i in 120:
		await physics_frame
		vmax = maxf(vmax, absf(_p.velocity.y))
	_check(vmax <= _p.MAX_VERTICAL_SPEED + 0.01, "vertical speed capped (max %.1f)" % vmax)
	# Several rapid flips stay bounded between the surfaces.
	var bounded := true
	for i in 12:
		await _frames(7)
		_p.flip()
		bounded = bounded and _p.position.y >= _ceil_y() - 1.0 and _p.position.y <= _floor_y() + 1.0
	_check(bounded and _p.running, "rapid flipping never leaves the corridor")

	# No flips after game over, by tap or by direct call.
	await _new_main()
	_p.position = _hazards()[0].position
	await _frames(3)
	await _wait_unlocked()
	var gd: float = _p.gravity_dir
	_p.flip()
	_check(not _p.running and _p.gravity_dir == gd and _p.velocity == Vector2.ZERO, "flip() after game over is ignored")


func _test_scroll() -> void:
	print("-- hazard scrolling")
	await _new_main()
	var hs := _hazards()
	var spec0: Dictionary = _main.PATTERNS[0][0]
	_check(_main._scroll < 2.0 * _px_per_tick() + 0.001 and hs.size() == 2, "run starts with scroll ~0 and pattern 0's 2 hazards")
	_check(absf(hs[0].position.x - (_rect.position.x + _rect.size.x * spec0["x"] - _main._scroll)) < 0.01, "pattern 0 hazards at their start positions")
	var xs := [hs[0].position.x, hs[1].position.x]
	await _frames(30)
	var moved: float = _px_per_tick() * 30.0
	_check(absf(hs[0].position.x - (xs[0] - moved)) < 0.001 and absf(hs[1].position.x - (xs[1] - moved)) < 0.001,
			"hazards move left at SCROLL_SPEED")
	_check(not _label_visible(), "still running")

	# Scroll to the next lap: pattern 1 hazards come in from beyond the right edge.
	await _new_main()
	var spec1: Dictionary = _main.PATTERNS[1][0]
	# Put pattern 1's first hazard ~50px beyond the right edge, inside the spawn window.
	_main._scroll = _rect.size.x * spec1["x"] - spec1["w"] / 2.0 - 50.0
	await physics_frame
	var entering = null
	for h in _hazards():
		if h.x_frac >= 1.0:
			entering = h
	_check(entering != null and entering.position.x - entering.size.x / 2.0 > _rect.end.x,
			"next lap's hazard spawns beyond the right edge")
	_check(entering != null and absf(entering.x_frac - (1.0 + spec1["x"])) < 0.0001 and entering.size == Vector2(spec1["w"], spec1["h"]),
			"...with pattern 1's first spec")

	# Hazards that have left the screen are removed.
	await _new_main()
	_main._scroll = _rect.size.x
	await physics_frame
	var gone := true
	for h in _hazards():
		gone = gone and h.position.x + h.size.x / 2.0 >= _rect.position.x
	_check(gone and _hazards().size() <= 3, "hazards left of the screen are removed (%d alive)" % _hazards().size())

	# Empty pattern list never hangs spawning and creates no hazards.
	await _new_main(EMPTY)
	await _frames(30)
	_check(_hazards().size() == 0 and _p.running, "empty pattern list: no hazards, no hang")


func _test_layout() -> void:
	print("-- hazard layout")
	await _new_main()
	var hs := _hazards()
	_check(hs.size() == 2 and not hs[0].ceiling_side and hs[1].ceiling_side, "pattern 0 alternates ground then ceiling")
	var ground_top: float = _main.get_node("Ground").position.y - 20.0
	var ceiling_bottom: float = _main.get_node("Ceiling").position.y + 20.0
	_check(absf(hs[0].position.y + hs[0].size.y / 2.0 - ground_top) < 0.01, "ground hazard sits on the ground")
	_check(absf(hs[1].position.y - hs[1].size.y / 2.0 - ceiling_bottom) < 0.01, "ceiling hazard hangs from the ceiling")
	var far_from_spawn := true
	for pat in _main.PATTERNS:
		var prev_ceiling = null
		for spec in pat:
			far_from_spawn = far_from_spawn and spec["x"] >= 0.4
			if prev_ceiling != null:
				far_from_spawn = far_from_spawn and spec["ceiling"] != prev_ceiling
			prev_ceiling = spec["ceiling"]
	_check(far_from_spawn, "all patterns alternate sides and start well after the spawn point")
	var distinct := true
	var hz_color: Color = hs[0].get_node("Visual").color
	for surf in ["Ground", "Ceiling"]:
		var c: Color = _main.get_node(surf + "/Visual").color
		distinct = distinct and (absf(c.r - hz_color.r) + absf(c.g - hz_color.g) + absf(c.b - hz_color.b)) > 0.8
	var pc: Color = _p.get_node("Visual").color
	distinct = distinct and (absf(pc.r - hz_color.r) + absf(pc.g - hz_color.g) + absf(pc.b - hz_color.b)) > 0.8
	_check(distinct, "hazard colour differs clearly from ground, ceiling and player")


# Scrolls the world so the hazard's left edge is `gap` px ahead of the player's right edge.
func _scroll_to_gap(h, gap: float) -> void:
	_main._scroll += (h.position.x - h.size.x / 2.0) - (_p.position.x + HALF) - gap
	_main._refresh_hazards()


func _test_collisions() -> void:
	print("-- hazard collisions and game over")
	for ceiling_hazard in [false, true]:
		await _new_main()
		var h = _hazards()[1 if ceiling_hazard else 0]
		_p.position = h.position
		await _frames(3)
		_check(not _p.running and _label_visible(), "%s hazard hit stops the run and shows game over" % ("ceiling" if ceiling_hazard else "ground"))
		_check(_p.velocity == Vector2.ZERO, "player stopped")
		var lock_before: float = _main._tap_lock
		var pos_before: Vector2 = _p.position
		_main._on_hazard_body_entered(_p)
		await _frames(5)
		_check(_main._tap_lock <= lock_before and _p.position == pos_before and not _p.running, "repeated hit does not re-trigger or move the player")

	# Hit by actually driving into the hazard: with no input the run ends at the first ground hazard.
	await _new_main()
	var h0 = _hazards()[0]
	for i in 600:
		if not _p.running:
			break
		await physics_frame
	_check(not _p.running and _main._scroll < _rect.size.x, "no input: run ends at a hazard in lap 1")
	_check(not h0.ceiling_side and absf(h0.position.x - h0.size.x / 2.0 - (_p.position.x + HALF)) < 8.0,
			"...scrolling into the first ground hazard (gap=%.1f)" % (h0.position.x - h0.size.x / 2.0 - (_p.position.x + HALF)))

	# Sitting on the ceiling is also deadly: ceiling hazard ends that run.
	await _new_main()
	var h1 = _hazards()[1]
	await _wait_unlocked()
	_tap_touch()
	for i in 600:
		if not _p.running:
			break
		await physics_frame
	_check(not _p.running and _p.gravity_dir == -1.0 and h1.ceiling_side
			and absf(h1.position.x - h1.size.x / 2.0 - (_p.position.x + HALF)) < 8.0,
			"staying on the ceiling ends the run at the ceiling hazard")

	# Safe surfaces next to hazards do not trigger game over.
	await _new_main()
	var g = _hazards()[0]
	_scroll_to_gap(g, 50.0)
	await _frames(5)
	_check(_p.running and not _label_visible(), "resting on ground just before a ground hazard is safe")
	await _new_main()
	var c = _hazards()[1]
	_p.flip()
	_p.position.y = _ceil_y()
	_scroll_to_gap(c, 50.0)
	await _frames(5)
	_check(_p.running and not _label_visible(), "resting on ceiling just before a ceiling hazard is safe")
	await _new_main()
	g = _hazards()[0]
	# Get the player up to the ceiling first, then let the ground hazard pass underneath.
	_p.position.y = _ceil_y() + 5.0
	_p.flip()
	await _frames(3)
	_scroll_to_gap(g, -g.size.x / 2.0 - HALF)
	await _frames(3)
	_check(_p.running and not _label_visible(), "passing over a ground hazard near the ceiling is safe (p=%s g=%s scroll=%.1f)" % [_p.position, g.position, _main._scroll])


func _test_restart_and_input() -> void:
	print("-- restart and input")
	await _new_main()
	# scroll on to a later pattern, crash, then restart
	_main._scroll = _rect.size.x * 1.2
	_p.position.y = _ceil_y() + 200.0
	await _frames(3)
	var h = _hazards()[0]
	_check(int(floorf(h.x_frac)) == 1, "scrolled into pattern 1's hazards")
	_p.position = h.position
	await _frames(3)
	_check(not _p.running and _main._scroll > _rect.size.x, "crashed in pattern 1")
	var frozen: float = _main._scroll
	await _frames(10)
	_check(_main._scroll == frozen, "scroll stops at game over")

	_tap_mouse()
	_check(not _p.running and _label_visible(), "tap right after game over is ignored (anti-skip delay)")
	await _wait_unlocked()
	_tap_mouse()
	_check(_p.running and not _label_visible(), "tap after the delay restarts the run")
	_check(_p.gravity_dir == 1.0, "restart tap did not flip gravity")
	_check(_p.velocity == Vector2.ZERO, "player velocity reset")
	_check(absf(_p.position.x - (_rect.position.x + START_X)) < 0.01 and absf(_p.position.y - _floor_y()) < 0.01, "player position reset (on the ground)")
	_check(_main._scroll == 0.0 and _main._spawn_lap <= 1, "scroll reset to 0 and spawning restarted at pattern 0")
	var first = _hazards()[0]
	_check(absf(first.position.x - (_rect.position.x + _rect.size.x * _main.PATTERNS[0][0]["x"])) < 0.01 and _hazards().size() == 2, "hazards back at pattern 0 positions")

	# Input immediately after restart must not flip; later taps flip exactly once.
	_tap_mouse()
	_tap_touch()
	_check(_p.gravity_dir == 1.0, "taps in the post-restart delay do not flip")
	await _wait_unlocked()
	_tap_mouse()
	_check(_p.gravity_dir == -1.0, "tap after the delay flips once")
	_tap_mouse(InputEvent.DEVICE_ID_EMULATION)
	_check(_p.gravity_dir == -1.0, "emulated mouse copy of a touch is ignored")
	var e := InputEventScreenTouch.new()
	e.pressed = false
	_main._unhandled_input(e)
	var m := InputEventMouseButton.new()
	m.button_index = MOUSE_BUTTON_RIGHT
	m.pressed = true
	_main._unhandled_input(m)
	_check(_p.gravity_dir == -1.0, "touch release and right click do not flip")
	_tap_touch()
	_check(_p.gravity_dir == 1.0, "screen touch flips once")

	# After the run restarts, the second crash path works the same (state not corrupted).
	_p.position = _hazards()[0].position
	await _frames(3)
	_check(not _p.running and _label_visible(), "second crash after restart triggers game over again")


# Simple bot: flip when the next hazard ahead is within a lead distance (px) and on our side.
# Flipping away from a ceiling hazard starts earlier because the player carries upward speed.
func _bot_tap(ground_lead: float, ceiling_lead: float) -> void:
	var next = null
	var best := INF
	for h in _hazards():
		var gap: float = h.position.x - h.size.x / 2.0 - (_p.position.x + HALF)
		if gap >= 0.0 and gap < best:
			best = gap
			next = h
	var lead := ceiling_lead if next != null and next.ceiling_side else ground_lead
	if next != null and best <= lead and next.ceiling_side == (_p.gravity_dir < 0.0):
		_tap_touch()


# Runs the bot for `laps` laps of scrolling while recording what happens to hazards.
func _run_bot(size: Vector2i, laps: float) -> Dictionary:
	await _set_window(size)
	await _new_main()
	var r := {"frames": 0, "spawned": [], "continuous": true, "entered_offscreen": true,
			"pruned_offscreen": true, "max_alive": 0}
	var last_x := {}   # hazard instance id -> last observed position.x
	var last_w := {}   # hazard instance id -> width
	for h in _hazards():
		last_x[h.get_instance_id()] = h.position.x
		last_w[h.get_instance_id()] = h.size.x
	var step := _px_per_tick()
	while _p.running and _main._scroll < laps * _rect.size.x and r["frames"] < 6000:
		_bot_tap(100.0, 200.0)
		await physics_frame
		r["frames"] += 1
		var alive := {}
		for h in _hazards():
			var id: int = h.get_instance_id()
			alive[id] = true
			if last_x.has(id):
				r["continuous"] = r["continuous"] and absf((last_x[id] - h.position.x) - step) < 0.001
			else:
				r["entered_offscreen"] = r["entered_offscreen"] and h.position.x - h.size.x / 2.0 >= _rect.end.x
				r["spawned"].append({"x": h.x_frac, "w": h.size.x, "h": h.size.y, "ceiling": h.ceiling_side})
				last_w[id] = h.size.x
			last_x[id] = h.position.x
		for id in last_x.keys():
			if not alive.has(id):
				# Removed: its right edge must have just crossed the left edge.
				r["pruned_offscreen"] = r["pruned_offscreen"] and last_x[id] + last_w[id] / 2.0 < _rect.position.x + step + 0.001
				last_x.erase(id)
		r["max_alive"] = maxi(r["max_alive"], alive.size())
	r["running"] = _p.running
	r["laps"] = _main._scroll / _rect.size.x
	return r


func _test_bot(size: Vector2i) -> void:
	var r := await _run_bot(size, 6.0)
	_check(r["running"] and r["laps"] >= 6.0 and not _label_visible(),
			"bot dodges all patterns for 6 laps at %s (visible %s, %d ticks, running=%s, laps=%.2f, pos=%s)" % [size, _rect.size, r["frames"], r["running"], r["laps"], _p.position])


func _test_scroll_lifecycle() -> void:
	print("-- scroll continuity and pattern sequence (bot run, 540x960)")
	var r := await _run_bot(Vector2i(540, 960), 6.0)
	_check(r["running"], "bot survives the run used for lifecycle checks")
	_check(r["continuous"], "every hazard moves exactly SCROLL_SPEED per tick (no pops or jumps)")
	_check(r["entered_offscreen"], "every new hazard spawns fully beyond the right edge")
	_check(r["pruned_offscreen"], "every hazard is removed only after fully leaving the left edge")
	_check(r["max_alive"] <= 4, "at most a few hazards alive at once (max %d)" % r["max_alive"])
	var expected := []
	var lap := 0
	while expected.size() < r["spawned"].size() + 2:
		for spec in _main.PATTERNS[lap % _main.PATTERNS.size()]:
			expected.append({"x": lap + spec["x"], "w": spec["w"], "h": spec["h"], "ceiling": spec["ceiling"]})
		lap += 1
	var seq_ok: bool = r["spawned"].size() >= 6
	for i in r["spawned"].size():
		var a: Dictionary = r["spawned"][i]
		var e: Dictionary = expected[i + 2]  # the first 2 hazards exist at run start, before observation
		seq_ok = seq_ok and absf(a["x"] - e["x"]) < 0.0001 and a["w"] == e["w"] and a["h"] == e["h"] and a["ceiling"] == e["ceiling"]
	_check(seq_ok, "spawned hazards follow the pattern sequence with consistent spacing (%d spawned)" % r["spawned"].size())


func _test_resize() -> void:
	print("-- viewport resize")
	await _set_window(Vector2i(480, 854))
	await _new_main()
	await _frames(10)
	await _set_window(Vector2i(540, 1200))
	_rect = root.get_visible_rect()
	await _frames(2)
	var ok := true
	for h in _hazards():
		var y: float = _rect.end.y - 40.0 - h.size.y / 2.0
		if h.ceiling_side:
			y = _rect.position.y + 40.0 + h.size.y / 2.0
		ok = ok and absf(h.world_x - (_rect.position.x + _rect.size.x * h.x_frac)) < 0.01
		ok = ok and absf(h.position.x - (h.world_x - _main._scroll)) <= _px_per_tick() + 0.01
		ok = ok and absf(h.position.y - y) < 0.01
	_check(ok and _hazards().size() >= 2, "hazards re-placed for the new visible rect, scroll kept")
	_check(_p.running and not _label_visible(), "resize does not end the run")
	await _set_window(Vector2i(480, 854))


# --- G1.1: visual-only spin on flip ---

func _spin_nodes() -> Array:
	return [_p.get_node("Halo"), _p.get_node("Visual"), _p.get_node("Outline")]


func _spin_angle() -> float:
	return _p.get_node("Visual").rotation


# True when all three visuals share one angle.
func _spin_in_sync() -> bool:
	var a: float = _spin_angle()
	for v in _spin_nodes():
		if absf(v.rotation - a) > 0.0001:
			return false
	return true


# The collision shape and the body itself must never rotate, at any moment.
func _collision_untouched() -> bool:
	var cs: CollisionShape2D = _p.get_node("CollisionShape2D")
	return cs.rotation == 0.0 and cs.global_rotation == 0.0 and _p.rotation == 0.0 \
			and (cs.shape as RectangleShape2D).size == Vector2(32, 32)


# Each visual's pivot must stay on the body centre, so the spin is about the centre.
func _pivots_centred() -> bool:
	for v in _spin_nodes():
		if ((v.get_global_transform() * v.pivot_offset) - _p.global_position).length() > 0.01:
			return false
	return true


func _test_rotation() -> void:
	print("-- player spin (visual only)")
	await _new_main(EMPTY)
	_check(_spin_angle() == 0.0 and _spin_in_sync() and _collision_untouched(), "starts unrotated")
	_check(_p.get_node("Visual").pivot_offset == Vector2(16, 16) and _p.get_node("Outline").pivot_offset == Vector2(16, 16)
			and _p.get_node("Halo").pivot_offset == Vector2(20, 20), "visual pivots are at each node's centre")
	_check(_pivots_centred(), "visual pivots coincide with the body centre")
	await _wait_unlocked()

	# One flip: gravity is immediate, the spin is animated and ends at exactly 90 degrees clockwise.
	_tap_touch()
	_check(_p.gravity_dir == -1.0 and _p.velocity.y == -_p.FLIP_SPEED, "flip is immediate (gravity and velocity change at once)")
	_check(_spin_angle() == 0.0, "spin has not jumped on the flip tick (it animates)")
	var prev := 0.0
	var smooth := true
	var collision_ok := true
	var centred := true
	var in_sync := true
	var saw_mid := false
	for i in 30:
		await physics_frame
		var a := _spin_angle()
		smooth = smooth and a >= prev - 0.0001 and a <= PI / 2.0 + 0.0001
		saw_mid = saw_mid or (a > 0.01 and a < PI / 2.0 - 0.01)
		collision_ok = collision_ok and _collision_untouched()
		centred = centred and _pivots_centred()
		in_sync = in_sync and _spin_in_sync()
		prev = a
	_check(smooth and saw_mid, "spin increases smoothly toward 90 degrees (saw intermediate angles)")
	_check(absf(_spin_angle() - PI / 2.0) < 0.0001, "ends at exactly +90 degrees (clockwise)")
	_check(collision_ok, "collision shape stays axis-aligned 32x32 and the body never rotates during the spin")
	_check(centred and in_sync, "the visuals spin around the centre and stay in sync")

	# Four flips make a full turn; each adds exactly 90 degrees.
	var step_ok := true
	for k in 3:
		await _wait_unlocked()
		_p.flip()
		await _frames(30)
		step_ok = step_ok and absf(_spin_angle() - (k + 2) * PI / 2.0) < 0.0001
	_check(step_ok and _p._spin_turns == 4, "every flip adds exactly 90 degrees (4 flips = %.4f rad)" % _spin_angle())
	_check(absf(fposmod(_spin_angle(), TAU)) < 0.0001 or absf(fposmod(_spin_angle(), TAU) - TAU) < 0.0001, "four flips are a full turn")
	_check(_collision_untouched() and _p.running, "collision still untouched after several flips")

	# Rapid flips retarget from the current angle and still end aligned.
	await _new_main(EMPTY)
	await _wait_unlocked()
	var bounded := true
	for i in 12:
		_p.flip()
		await _frames(3)
		bounded = bounded and _collision_untouched() and _p.position.y >= _ceil_y() - 1.0 and _p.position.y <= _floor_y() + 1.0
	await _frames(30)
	_check(_p._spin_turns == 12 and absf(_spin_angle() - 12.0 * PI / 2.0) < 0.0001 and _spin_in_sync(),
			"rapid flips end exactly on 12 quarter turns (%.4f rad)" % _spin_angle())
	_check(bounded and _p.running, "rapid flips keep the collision shape fixed and the player inside the corridor")

	# Ignored flips do not spin.
	await _new_main(EMPTY)
	_tap_mouse()
	_tap_touch()
	await _frames(20)
	_check(_p._spin_turns == 0 and _spin_angle() == 0.0, "taps during the post-restart lock do not spin")
	await _wait_unlocked()
	_tap_mouse(InputEvent.DEVICE_ID_EMULATION)
	var e := InputEventScreenTouch.new()
	e.pressed = false
	_main._unhandled_input(e)
	var m := InputEventMouseButton.new()
	m.button_index = MOUSE_BUTTON_RIGHT
	m.pressed = true
	_main._unhandled_input(m)
	await _frames(20)
	_check(_p._spin_turns == 0 and _spin_angle() == 0.0, "emulated mouse, touch release and right click do not spin")

	# After game over: no spin from taps, direct flips or the tap lock.
	await _new_main()
	await _wait_unlocked()
	_tap_touch()
	await _frames(30)
	_check(absf(_spin_angle() - PI / 2.0) < 0.0001, "one real flip spun the player before the crash")
	_p.position = _hazards()[0].position
	await _frames(3)
	_check(not _p.running, "crashed")
	var turns_at_crash: int = _p._spin_turns
	_tap_mouse()
	_p.flip()
	await _wait_unlocked()
	_p.flip()
	await _frames(30)
	_check(_p._spin_turns == turns_at_crash and absf(_spin_angle() - PI / 2.0) < 0.0001,
			"flips after game over (tap lock and direct calls) do not spin")

	# Restart resets the spin immediately and leaves no animation running.
	_tap_mouse()
	_check(_p.running and _spin_angle() == 0.0 and _spin_in_sync() and _p._spin_turns == 0, "restart resets the visual rotation to zero")
	await _frames(30)
	_check(_spin_angle() == 0.0 and _spin_in_sync() and _collision_untouched(), "no stale animation after restart")

	# A flip right before a crash, then restart: the old tween must not keep turning the new run.
	await _wait_unlocked()
	_tap_mouse()
	await _frames(2)
	_p.position = _hazards()[0].position
	await _frames(3)
	_check(not _p.running, "crashed again mid-spin")
	await _wait_unlocked()
	_tap_mouse()
	await _frames(30)
	_check(_p.running and _spin_angle() == 0.0 and _p._spin_turns == 0, "restart during/after a spin starts at zero rotation and stays there")


func _initialize() -> void:
	await _test_movement_and_surfaces()
	await _test_snappy_flip()
	await _test_scroll()
	await _test_layout()
	await _test_collisions()
	await _test_restart_and_input()
	await _test_rotation()
	await _test_resize()
	await _test_scroll_lifecycle()
	print("-- solvability: patterns survivable with flips")
	await _test_bot(Vector2i(540, 960))
	await _test_bot(Vector2i(540, 1200))
	await _test_bot(Vector2i(1200, 800))
	print("physics tick rate=", Engine.physics_ticks_per_second)
	print("RESULT: ", "ALL PASSED" if _failures == 0 else "%d FAILED" % _failures)
	quit(1 if _failures else 0)
