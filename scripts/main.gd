extends Node2D

const SURFACE_THICKNESS := 40.0
const START_MARGIN := 40.0

@onready var _player = $Player
@onready var _ground: StaticBody2D = $Ground
@onready var _ceiling: StaticBody2D = $Ceiling
@onready var _game_over: Label = $GameOverLabel


func _ready() -> void:
	get_viewport().size_changed.connect(_layout)
	_player.crashed.connect(_on_player_crashed)
	_layout()
	_restart()


func _unhandled_input(event: InputEvent) -> void:
	if not _is_tap(event):
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
	var rect := get_viewport().get_visible_rect()
	_player.start(Vector2(rect.position.x + START_MARGIN, rect.get_center().y))


func _on_player_crashed() -> void:
	_game_over.visible = true


# With stretch aspect "expand" the visible area can be larger than 480x854,
# so place the surfaces from the actual visible rect.
func _layout() -> void:
	var rect := get_viewport().get_visible_rect()
	_player.play_rect = rect
	_place_surface(_ceiling, rect, rect.position.y + SURFACE_THICKNESS / 2.0)
	_place_surface(_ground, rect, rect.end.y - SURFACE_THICKNESS / 2.0)
	_game_over.position = Vector2(rect.position.x, rect.get_center().y - _game_over.size.y / 2.0)
	_game_over.size.x = rect.size.x


func _place_surface(body: StaticBody2D, rect: Rect2, center_y: float) -> void:
	var size := Vector2(rect.size.x, SURFACE_THICKNESS)
	body.position = Vector2(rect.get_center().x, center_y)
	(body.get_node("CollisionShape2D").shape as RectangleShape2D).size = size
	var visual: ColorRect = body.get_node("Visual")
	visual.size = size
	visual.position = -size / 2.0
