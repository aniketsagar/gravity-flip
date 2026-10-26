extends Node2D

const SURFACE_THICKNESS := 40.0
const START_MARGIN := 40.0
const PLAYER_HALF := 16.0
# Taps are ignored briefly after a crash (so frantic taps don't skip the game-over
# screen) and after a restart (so the restart tap can never also flip gravity).
const GAME_OVER_TAP_DELAY := 0.4
const RESTART_TAP_DELAY := 0.15

const HazardScene := preload("res://scenes/hazard.tscn")

# One pattern per lap; the next one is shown each time the player wraps.
# x is the hazard centre as a fraction of the play-area width, w/h are pixels.
# Hazards alternate ground, ceiling, so the player must keep flipping gravity.
const PATTERNS := [
	[
		{"ceiling": false, "x": 0.50, "w": 30.0, "h": 120.0},
		{"ceiling": true, "x": 0.90, "w": 30.0, "h": 120.0},
	],
	[
		{"ceiling": false, "x": 0.50, "w": 40.0, "h": 160.0},
		{"ceiling": true, "x": 0.90, "w": 40.0, "h": 160.0},
	],
	[
		{"ceiling": false, "x": 0.55, "w": 30.0, "h": 180.0},
		{"ceiling": true, "x": 0.92, "w": 50.0, "h": 160.0},
	],
]

var patterns: Array = PATTERNS
var _pattern_index := 0
var _tap_lock := 0.0

@onready var _player = $Player
@onready var _ground: StaticBody2D = $Ground
@onready var _ceiling: StaticBody2D = $Ceiling
@onready var _hazards: Node2D = $Hazards
@onready var _game_over: Label = $GameOverLabel


func _ready() -> void:
	get_viewport().size_changed.connect(_layout)
	_player.wrapped.connect(_on_player_wrapped)
	_layout()
	_restart()


func _physics_process(delta: float) -> void:
	_tap_lock = maxf(_tap_lock - delta, 0.0)


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
	_show_pattern(0)
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


func _on_player_wrapped() -> void:
	_show_pattern(_pattern_index + 1)


func _show_pattern(index: int) -> void:
	_pattern_index = index % patterns.size()
	var count: int = patterns[_pattern_index].size()
	while _hazards.get_child_count() > count:
		var extra := _hazards.get_child(_hazards.get_child_count() - 1)
		_hazards.remove_child(extra)
		extra.queue_free()
	while _hazards.get_child_count() < count:
		var hazard := HazardScene.instantiate()
		hazard.body_entered.connect(_on_hazard_body_entered)
		_hazards.add_child(hazard)
	_place_hazards()


func _place_hazards() -> void:
	var rect := get_viewport().get_visible_rect()
	var pattern: Array = patterns[_pattern_index]
	# _layout can run before the first pattern is shown, when there are no hazards yet.
	for i in mini(pattern.size(), _hazards.get_child_count()):
		var spec: Dictionary = pattern[i]
		_hazards.get_child(i).place(rect, SURFACE_THICKNESS, spec["ceiling"], spec["x"],
				Vector2(spec["w"], spec["h"]))


# With stretch aspect "expand" the visible area can be larger than 480x854,
# so place everything from the actual visible rect.
func _layout() -> void:
	var rect := get_viewport().get_visible_rect()
	_player.play_rect = rect
	_place_surface(_ceiling, rect, rect.position.y + SURFACE_THICKNESS / 2.0)
	_place_surface(_ground, rect, rect.end.y - SURFACE_THICKNESS / 2.0)
	_place_hazards()
	_game_over.position = Vector2(rect.position.x, rect.get_center().y - _game_over.size.y / 2.0)
	_game_over.size.x = rect.size.x


func _place_surface(body: StaticBody2D, rect: Rect2, center_y: float) -> void:
	var size := Vector2(rect.size.x, SURFACE_THICKNESS)
	body.position = Vector2(rect.get_center().x, center_y)
	(body.get_node("CollisionShape2D").shape as RectangleShape2D).size = size
	var visual: ColorRect = body.get_node("Visual")
	visual.size = size
	visual.position = -size / 2.0
