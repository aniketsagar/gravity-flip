extends SceneTree

# Headless checks for the M3 loop (movement, flip, wrap, hazards, game over, restart, input).
#   godot --headless --path <project> --script res://tests/m3_check.gd
# Exits 0 when every check passes, 1 otherwise.
#
# Taps call Main._unhandled_input directly: headless script mode does not dispatch
# pushed or parsed input events to the scene, so engine input dispatch is untested.
# Physics (CharacterBody2D, Area2D overlap) runs for real via physics frames.

const HALF := 16.0
const EMPTY := [[]]

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


func _test_movement_and_surfaces() -> void:
	print("-- movement, flip, safe surfaces (no hazards)")
	await _new_main(EMPTY)
	_check(_p.running and _p.gravity_dir == 1.0, "run starts running with gravity down")
	var x0: float = _p.position.x
	await _frames(40)
	_check(_p.position.x > x0, "moves right")
	await _frames(60)
	_check(absf(_p.position.y - _floor_y()) < 1.5, "rests on ground (y=%.2f, expected %.2f)" % [_p.position.y, _floor_y()])
	_check(_p.running and not _label_visible(), "ground contact is safe")
	var xa: float = _p.position.x
	await _frames(30)
	var expected: float = _p.SPEED * 30.0 / Engine.physics_ticks_per_second
	_check(absf(fposmod(_p.position.x - xa, _rect.size.x) - expected) < 0.5, "constant horizontal speed")

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
	for i in 2:
		for j in 900:
			await physics_frame
			laps_ok = laps_ok and _p.running and _p.position.x >= _rect.position.x and _p.position.x < _rect.end.x
		_tap_mouse()
	_check(laps_ok and not _label_visible(), "multiple laps on ceiling and ground never end the run")


func _test_wrap() -> void:
	print("-- horizontal wrap")
	await _new_main(EMPTY)
	await _frames(120)
	var gdir: float = _p.gravity_dir
	var y_before: float = _p.position.y
	_p.position.x = _rect.end.x - 1.0
	await physics_frame
	_check(_p.position.x < _rect.position.x + _p.SPEED / 30.0, "wraps to left edge (x=%.2f)" % _p.position.x)
	_check(absf(_p.position.y - y_before) < 1.5, "vertical position kept on wrap")
	_check(_p.gravity_dir == gdir, "gravity direction kept on wrap")
	var step: float = _p.SPEED / Engine.physics_ticks_per_second
	_check(absf(_p.position.x - (_rect.position.x + step - 1.0)) < 0.01, "overshoot carried over wrap (x=%.3f)" % _p.position.x)
	var xw: float = _p.position.x
	await _frames(10)
	_check(_p.position.x > xw, "keeps moving right after wrap")

	await _new_main()
	_check(_main._pattern_index == 0 and _hazards().size() == 2, "real patterns: starts on pattern 0 with 2 hazards")
	_p.position.x = _rect.end.x - 1.0
	_p.position.y = _ceil_y() + 200.0
	await physics_frame
	_check(_main._pattern_index == 1, "wrap advances to pattern 1")
	await process_frame
	_check(_hazards().size() == 2 and absf(_hazards()[0].position.x - (_rect.position.x + _rect.size.x * _main.PATTERNS[1][0]["x"])) < 0.01,
			"hazards re-placed for pattern 1")


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
			far_from_spawn = far_from_spawn and spec["x"] >= 0.5
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
	for i in 600:
		if not _p.running:
			break
		await physics_frame
	_check(not _p.running and _main._pattern_index == 0, "no input: run ends at a hazard in lap 1")
	var h0 = _hazards()[0]
	_check(absf(_p.position.x - (h0.position.x - h0.size.x / 2.0 - HALF)) < 8.0, "...driving into the first ground hazard (x=%.1f)" % _p.position.x)

	# Sitting on the ceiling is also deadly: ceiling hazard ends that run.
	await _new_main()
	await _wait_unlocked()
	_tap_touch()
	for i in 600:
		if not _p.running:
			break
		await physics_frame
	var h1 = _hazards()[1]
	_check(not _p.running and _p.gravity_dir == -1.0 and _p.position.x > h1.position.x - h1.size.x - HALF,
			"staying on the ceiling ends the run at the ceiling hazard")

	# Safe surfaces next to hazards do not trigger game over.
	await _new_main()
	var g = _hazards()[0]
	_p.position = Vector2(g.position.x - g.size.x / 2.0 - HALF - 50.0, _floor_y())
	await _frames(5)
	_check(_p.running and not _label_visible(), "resting on ground just before a ground hazard is safe")
	await _new_main()
	var c = _hazards()[1]
	_p.flip()
	_p.position = Vector2(c.position.x - c.size.x / 2.0 - HALF - 50.0, _ceil_y())
	await _frames(5)
	_check(_p.running and not _label_visible(), "resting on ceiling just before a ceiling hazard is safe")
	await _new_main()
	g = _hazards()[0]
	_p.position = Vector2(g.position.x, _ceil_y() + 5.0)
	_p.flip()
	await _frames(3)
	_check(_p.running and not _label_visible(), "passing over a ground hazard near the ceiling is safe")


func _test_restart_and_input() -> void:
	print("-- restart and input")
	await _new_main()
	# advance to a later pattern, crash, then restart
	_p.position.x = _rect.end.x - 1.0
	_p.position.y = _ceil_y() + 200.0
	await _frames(3)
	var h = _hazards()[0]
	_p.position = h.position
	await _frames(3)
	_check(not _p.running and _main._pattern_index == 1, "crashed in pattern 1")

	_tap_mouse()
	_check(not _p.running and _label_visible(), "tap right after game over is ignored (anti-skip delay)")
	await _wait_unlocked()
	_tap_mouse()
	_check(_p.running and not _label_visible(), "tap after the delay restarts the run")
	_check(_p.gravity_dir == 1.0, "restart tap did not flip gravity")
	_check(_p.velocity == Vector2.ZERO, "player velocity reset")
	_check(absf(_p.position.x - (_rect.position.x + 40.0)) < 0.01 and absf(_p.position.y - _floor_y()) < 0.01, "player position reset (on the ground)")
	_check(_main._pattern_index == 0, "pattern reset to 0")
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


func _test_bot(size: Vector2i) -> void:
	await _set_window(size)
	await _new_main()
	var laps := [0]
	_p.wrapped.connect(func(): laps[0] += 1)
	var frames := 0
	while _p.running and laps[0] < 6 and frames < 4000:
		_bot_tap(100.0, 200.0)
		await physics_frame
		frames += 1
	_check(_p.running and laps[0] >= 6 and not _label_visible(),
			"bot dodges all patterns for 6 laps at %s (visible %s, %d ticks, running=%s, laps=%d, pattern=%d, pos=%s)" % [size, _rect.size, frames, _p.running, laps[0], _main._pattern_index, _p.position])


func _initialize() -> void:
	await _test_movement_and_surfaces()
	await _test_wrap()
	await _test_layout()
	await _test_collisions()
	await _test_restart_and_input()
	print("-- solvability: patterns survivable with flips")
	await _test_bot(Vector2i(540, 960))
	await _test_bot(Vector2i(540, 1200))
	await _test_bot(Vector2i(1200, 800))
	print("physics tick rate=", Engine.physics_ticks_per_second)
	print("RESULT: ", "ALL PASSED" if _failures == 0 else "%d FAILED" % _failures)
	quit(1 if _failures else 0)
