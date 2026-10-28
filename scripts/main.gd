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
const JumboScene := preload("res://scenes/jumbo.tscn")

# Jumbo obstacles (G1.3 stage 1): a solid circular core inside a non-solid attraction field that
# pulls the player vertically toward the core. They live in their own node and schedule, apart
# from the rectangular hazards and PATTERNS. Sizes are fractions of the playable height.
const JUMBO_CORE_FRAC := 0.12
const JUMBO_FIELD_FRAC := 0.30
# Peak attraction in px/s^2 at and inside the core radius (provisional; compare 2700, 4000, 6000).
const JUMBO_STRENGTH := 4000.0
# Jumbos are OFF in normal play until stage 2 adds a dedicated, clearance-checked encounter
# segment. A schedule is a sorted list of {x, y_frac}: x is the core centre in pixels from the
# start of the run, y_frac its height as a fraction of the playable height from the ceiling.
const JUMBO_SCHEDULE := []
# Stage 1 prototype placement for development and tests (set Main.jumbo_schedule to it). It is
# NOT validated as fair: a player who flips to the far lane at every hazard hits the core.
const JUMBO_PROTOTYPE_SCHEDULE := [
	{"x": 2760.0, "y_frac": 0.5},
]

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
# Jumbo encounters; an empty list disables them. Tests that expect only PATTERNS set it to [].
var jumbo_schedule: Array = JUMBO_SCHEDULE
var jumbo_strength := JUMBO_STRENGTH
# Distance the world has scrolled left since the run started.
var _scroll := 0.0
# Next hazard to spawn: spec _spawn_spec of pattern number _spawn_index, which starts
# _spawn_origin pixels from the start of the run.
var _spawn_index := 0
var _spawn_origin := 0.0
var _spawn_spec := 0
# Next entry of jumbo_schedule to spawn.
var _next_jumbo := 0
var _tap_lock := 0.0

@onready var _player = $Player
@onready var _ground: StaticBody2D = $Ground
@onready var _ceiling: StaticBody2D = $Ceiling
@onready var _hazards: Node2D = $Hazards
@onready var _jumbos: Node2D = $Jumbos
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
	# Main's physics step runs before the Player's, so this value is used in the same tick.
	_player.attract_accel = _jumbo_attraction()


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
	_next_jumbo = 0
	while _hazards.get_child_count() > 0:
		var old := _hazards.get_child(0)
		_hazards.remove_child(old)
		old.queue_free()
	while _jumbos.get_child_count() > 0:
		var old_jumbo := _jumbos.get_child(0)
		_jumbos.remove_child(old_jumbo)
		old_jumbo.queue_free()
	_spawn_hazards()
	_spawn_jumbos()
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
	for jumbo in _jumbos.get_children():
		jumbo.position.x = jumbo.world_x - _scroll
		# Free only once the whole field (not just the core) has left the screen.
		if jumbo.position.x + jumbo.size.x / 2.0 < rect.position.x:
			_jumbos.remove_child(jumbo)
			jumbo.queue_free()
	_spawn_jumbos()


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


# Spawns scheduled jumbos once their field's left edge is within SPAWN_AHEAD of the right edge,
# so the field scrolls into view before the core arrives.
func _spawn_jumbos() -> void:
	var rect := get_viewport().get_visible_rect()
	var limit := rect.end.x + SPAWN_AHEAD
	var field_radius := JUMBO_FIELD_FRAC * (rect.size.y - 2.0 * SURFACE_THICKNESS)
	while _next_jumbo < jumbo_schedule.size():
		var spec: Dictionary = jumbo_schedule[_next_jumbo]
		if rect.position.x + spec["x"] - field_radius - _scroll > limit:
			return
		var jumbo := JumboScene.instantiate()
		jumbo.body_entered.connect(_on_hazard_body_entered)
		_jumbos.add_child(jumbo)
		jumbo.place(rect, SURFACE_THICKNESS, spec["x"], spec["y_frac"], JUMBO_CORE_FRAC, JUMBO_FIELD_FRAC, jumbo_strength)
		jumbo.position.x = jumbo.world_x - _scroll
		_next_jumbo += 1


# Total vertical attraction (px/s^2, positive = down) from the active jumbo fields. Stateless:
# recomputed every tick from positions, so entering, leaving and re-entering need no events.
func _jumbo_attraction() -> float:
	var total := 0.0
	for jumbo in _jumbos.get_children():
		total += jumbo.attraction_at(_player.position).y
	return total


# Re-places existing jumbos for the current visible rect, keeping the scroll.
func _place_jumbos() -> void:
	var rect := get_viewport().get_visible_rect()
	for jumbo in _jumbos.get_children():
		jumbo.place(rect, SURFACE_THICKNESS, jumbo.x_px, jumbo.y_frac, jumbo.core_frac, jumbo.field_frac, jumbo.strength)
		jumbo.position.x = jumbo.world_x - _scroll


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
	_place_jumbos()
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
