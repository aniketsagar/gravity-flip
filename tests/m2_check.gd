extends SceneTree

# Headless check for the M2 loop. Run:
#   godot --headless --path <project> --script res://tests/m2_check.gd
# Taps call Main._unhandled_input directly: headless script mode does not dispatch
# pushed or parsed input events to the scene, so engine dispatch itself is untested.
# Exits 0 when every check passes, 1 otherwise.

var _failures := 0
var _main: Node


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


func _initialize() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	_main = main
	root.add_child(main)
	await _frames(2)
	var p = main.get_node("Player")
	var ground: StaticBody2D = main.get_node("Ground")
	var ceiling: StaticBody2D = main.get_node("Ceiling")
	var rect := root.get_visible_rect()
	var half := 16.0
	var floor_y: float = ground.position.y - 20.0 - half
	var ceil_y: float = ceiling.position.y + 20.0 + half

	_check(p.running, "run starts running")
	_check(p.gravity_dir == 1.0, "gravity starts downward")

	# Fall to the ground without passing through, while moving right at constant speed.
	var x0: float = p.position.x
	var min_y := INF
	await _frames(40)
	_check(p.position.x > x0, "moves right")
	await _frames(20)
	_check(absf(p.position.y - floor_y) < 1.5, "rests on ground (y=%.2f, expected %.2f)" % [p.position.y, floor_y])

	# Tap flips gravity (mouse), then the player rises to the ceiling without passing it.
	_tap_mouse()
	_check(p.gravity_dir == -1.0, "mouse click flips gravity up")
	for i in 120:
		await physics_frame
		min_y = minf(min_y, p.position.y)
	_check(min_y >= ceil_y - 1.0, "never above ceiling (min y=%.2f, limit %.2f)" % [min_y, ceil_y])

	# Touch flips; emulated mouse copy of a touch is ignored.
	var before: float = p.gravity_dir
	_tap_mouse(InputEvent.DEVICE_ID_EMULATION)
	_check(p.gravity_dir == before, "emulated mouse event ignored")
	_tap_touch()
	_check(p.gravity_dir == -before, "screen touch flips gravity")

	# Constant horizontal speed: 30 physics ticks advance SPEED * 30 / tick rate.
	var expected: float = p.SPEED * 30.0 / Engine.physics_ticks_per_second
	var xa: float = p.position.x
	await _frames(30)
	_check(absf(fposmod(p.position.x - xa, rect.size.x) - expected) < 0.5, "constant horizontal speed")

	# Wrap: let the player settle on a surface, then park it just left of the right edge.
	await _frames(120)
	var gdir: float = p.gravity_dir
	var y_before: float = p.position.y
	p.position.x = rect.end.x - 1.0
	await physics_frame
	_check(p.position.x < rect.position.x + p.SPEED / 30.0, "wraps to left edge (x=%.2f)" % p.position.x)
	_check(absf(p.position.y - y_before) < 1.5, "vertical position kept on wrap (%.2f -> %.2f)" % [y_before, p.position.y])
	_check(p.gravity_dir == gdir, "gravity direction kept on wrap")
	var xw: float = p.position.x
	await _frames(10)
	_check(p.position.x > xw, "keeps moving right after wrap")

	# Overshoot is carried across the wrap (continuous movement).
	p.position.x = rect.end.x - 1.0
	await physics_frame
	var step: float = p.SPEED / Engine.physics_ticks_per_second
	_check(absf(p.position.x - (rect.position.x + step - 1.0)) < 0.01, "overshoot carried over wrap (x=%.3f)" % p.position.x)

	# Ground and ceiling are safe: several full laps on each surface, no game over.
	var laps_ok := true
	for dir_flip in 2:
		for i in 900:
			await physics_frame
			laps_ok = laps_ok and p.running and p.position.x >= rect.position.x and p.position.x < rect.end.x
		_tap_mouse()
	_check(laps_ok, "multiple laps on ground and ceiling never end the run")
	_check(not main.get_node("GameOverLabel").visible, "game over label never shown")

	# Restart path (kept for later game-over conditions): a tap while stopped restarts.
	p.running = false
	main.get_node("GameOverLabel").visible = true
	_tap_mouse()
	_check(p.running, "tap restarts a stopped run")
	_check(p.gravity_dir == 1.0 and absf(p.position.x - (rect.position.x + 40.0)) < 1.0, "restart resets player")
	_check(not main.get_node("GameOverLabel").visible, "game over label hidden after restart")

	print("physics tick rate=", Engine.physics_ticks_per_second, " visible_rect=", rect)
	print("RESULT: ", "ALL PASSED" if _failures == 0 else "%d FAILED" % _failures)
	quit(1 if _failures else 0)
