extends Node2D

const SCROLL_SPEED := 200.0
const SURFACE_THICKNESS := 40.0
const ACCENT_THICKNESS := 3.0
const START_MARGIN := 40.0
const PLAYER_HALF := 16.0
# Taps are ignored briefly after a crash (so frantic taps don't skip the game-over
# screen) and after a restart (so the restart tap can never also flip gravity).
const GAME_OVER_TAP_DELAY := 0.4
const RESTART_TAP_DELAY := 0.15
# Hazards are spawned this far beyond the right edge, so they scroll into view
# instead of appearing on screen.
const SPAWN_AHEAD := 100.0

const HazardScene := preload("res://scenes/hazard.tscn")

# Patterns repeat in order. Each has a length in pixels (the next pattern starts that far
# further right) and hazards placed by x, their centre in pixels from the pattern start,
# w in pixels and h_frac, the height as a fraction of the playable height.
# Small is 0.15-0.25, medium 0.30-0.45, large 0.50-0.66 (never taller than 0.66).
# Hazards alternate ground, ceiling, so the player must keep flipping gravity. Lengths and
# positions leave each hazard enough room to be cleared after the previous one:
# gap >= 32 + SCROLL_SPEED * (clear time of the next hazard + 0.3 s), checked by the tests.
const PATTERNS := [
	{"len": 480.0, "hazards": [
		{"ceiling": false, "x": 216.0, "w": 30.0, "h_frac": 0.15},
		{"ceiling": true, "x": 446.0, "w": 30.0, "h_frac": 0.20},
	]},
	{"len": 480.0, "hazards": [
		{"ceiling": false, "x": 216.0, "w": 40.0, "h_frac": 0.30},
		{"ceiling": true, "x": 446.0, "w": 40.0, "h_frac": 0.38},
	]},
	{"len": 480.0, "hazards": [
		{"ceiling": false, "x": 216.0, "w": 40.0, "h_frac": 0.50},
		{"ceiling": true, "x": 446.0, "w": 30.0, "h_frac": 0.45},
	]},
	{"len": 500.0, "hazards": [
		{"ceiling": false, "x": 216.0, "w": 50.0, "h_frac": 0.25},
		{"ceiling": true, "x": 466.0, "w": 40.0, "h_frac": 0.55},
	]},
	{"len": 480.0, "hazards": [
		{"ceiling": false, "x": 216.0, "w": 40.0, "h_frac": 0.66},
		{"ceiling": true, "x": 446.0, "w": 30.0, "h_frac": 0.20},
	]},
]

var patterns: Array = PATTERNS
# Distance the world has scrolled left since the run started.
var _scroll := 0.0
# Next hazard to spawn: spec _spawn_spec of pattern number _spawn_index, which starts
# _spawn_origin pixels from the start of the run.
var _spawn_index := 0
var _spawn_origin := 0.0
var _spawn_spec := 0
var _tap_lock := 0.0

@onready var _player = $Player
@onready var _ground: StaticBody2D = $Ground
@onready var _ceiling: StaticBody2D = $Ceiling
@onready var _hazards: Node2D = $Hazards
@onready var _game_over: Label = $GameOverLabel


func _ready() -> void:
	get_viewport().size_changed.connect(_layout)
	_layout()
	_restart()


func _physics_process(delta: float) -> void:
	_tap_lock = maxf(_tap_lock - delta, 0.0)
	if not _player.running:
		return
	_scroll += SCROLL_SPEED * delta
	_refresh_hazards()


func _unhandled_input(event: InputEvent) -> void:
	if not _is_tap(event) or _tap_lock > 0.0:
		return
	if _player.running:
		_player.flip()
	else:
		_restart()


# Real taps arrive as InputEventScreenTouch. Android also emulates a mouse click
# from each touch (device id -1); ignore that copy so one tap flips only once.
func _is_tap(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return event.pressed
	if event is InputEventMouseButton:
		return event.pressed and event.button_index == MOUSE_BUTTON_LEFT \
				and event.device != InputEvent.DEVICE_ID_EMULATION
	return false


func _restart() -> void:
	_game_over.visible = false
	_tap_lock = RESTART_TAP_DELAY
	_scroll = 0.0
	_spawn_index = 0
	_spawn_origin = 0.0
	_spawn_spec = 0
	while _hazards.get_child_count() > 0:
		var old := _hazards.get_child(0)
		_hazards.remove_child(old)
		old.queue_free()
	_spawn_hazards()
	var rect := get_viewport().get_visible_rect()
	# Start resting on the ground so the first hazard gives a full, fair reaction time.
	_player.start(Vector2(rect.position.x + START_MARGIN, rect.end.y - SURFACE_THICKNESS - PLAYER_HALF))


func _on_hazard_body_entered(body: Node2D) -> void:
	# Only the first hit counts; later overlaps while stopped are ignored.
	if body != _player or not _player.running:
		return
	_player.stop()
	_game_over.visible = true
	_tap_lock = GAME_OVER_TAP_DELAY


# Moves hazards with the scroll, drops those that left the screen and spawns new
# ones that are about to enter from the right.
func _refresh_hazards() -> void:
	var rect := get_viewport().get_visible_rect()
	for hazard in _hazards.get_children():
		hazard.position.x = hazard.world_x - _scroll
		if hazard.position.x + hazard.size.x / 2.0 < rect.position.x:
			_hazards.remove_child(hazard)
			hazard.queue_free()
	_spawn_hazards()


# Spawns hazards, in pattern order, until the next one is further than
# SPAWN_AHEAD beyond the right edge. Each pattern starts its length after the previous one.
func _spawn_hazards() -> void:
	var rect := get_viewport().get_visible_rect()
	var limit := rect.end.x + SPAWN_AHEAD
	while true:
		var pattern: Dictionary = patterns[_spawn_index % patterns.size()]
		var specs: Array = pattern["hazards"]
		if _spawn_spec >= specs.size():
			# Pattern finished; stop if the next one starts beyond the spawn limit.
			if rect.position.x + _spawn_origin + pattern["len"] - _scroll > limit:
				return
			_spawn_origin += pattern["len"]
			_spawn_index += 1
			_spawn_spec = 0
			continue
		var spec: Dictionary = specs[_spawn_spec]
		var left: float = rect.position.x + _spawn_origin + spec["x"] - _scroll - spec["w"] / 2.0
		if left > limit:
			return
		var hazard := HazardScene.instantiate()
		hazard.body_entered.connect(_on_hazard_body_entered)
		_hazards.add_child(hazard)
		hazard.place(rect, SURFACE_THICKNESS, spec["ceiling"], _spawn_origin + spec["x"],
				spec["w"], spec["h_frac"])
		hazard.position.x = hazard.world_x - _scroll
		_spawn_spec += 1


# Re-places existing hazards for the current visible rect, keeping the scroll.
func _place_hazards() -> void:
	var rect := get_viewport().get_visible_rect()
	for hazard in _hazards.get_children():
		hazard.place(rect, SURFACE_THICKNESS, hazard.ceiling_side, hazard.x_px, hazard.size.x, hazard.h_frac)
		hazard.position.x = hazard.world_x - _scroll


# With stretch aspect "expand" the visible area can be larger than 480x854,
# so place everything from the actual visible rect.
func _layout() -> void:
	var rect := get_viewport().get_visible_rect()
	_place_surface(_ceiling, rect, rect.position.y + SURFACE_THICKNESS / 2.0, false)
	_place_surface(_ground, rect, rect.end.y - SURFACE_THICKNESS / 2.0, true)
	_place_hazards()
	_refresh_hazards()
	_game_over.position = Vector2(rect.position.x, rect.get_center().y - _game_over.size.y / 2.0)
	_game_over.size.x = rect.size.x


# accent_on_top puts the thin accent line on the top edge (ground) instead of the bottom (ceiling),
# so it always runs along the edge facing the play area.
func _place_surface(body: StaticBody2D, rect: Rect2, center_y: float, accent_on_top: bool) -> void:
	var size := Vector2(rect.size.x, SURFACE_THICKNESS)
	body.position = Vector2(rect.get_center().x, center_y)
	(body.get_node("CollisionShape2D").shape as RectangleShape2D).size = size
	var visual: ColorRect = body.get_node("Visual")
	visual.size = size
	visual.position = -size / 2.0
	var accent: ColorRect = body.get_node("Accent")
	accent.size = Vector2(size.x, ACCENT_THICKNESS)
	accent.position = Vector2(-size.x / 2.0, -size.y / 2.0 if accent_on_top else size.y / 2.0 - ACCENT_THICKNESS)
