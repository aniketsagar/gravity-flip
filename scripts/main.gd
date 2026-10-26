extends Node2D

const SURFACE_THICKNESS := 40.0

@onready var _player: CharacterBody2D = $Player
@onready var _ground: StaticBody2D = $Ground
@onready var _ceiling: StaticBody2D = $Ceiling


func _ready() -> void:
	get_viewport().size_changed.connect(_layout)
	_layout()


# With stretch aspect "expand" the visible area can be larger than 480x854,
# so place the surfaces from the actual visible rect.
func _layout() -> void:
	var rect := get_viewport().get_visible_rect()
	_place_surface(_ceiling, rect, rect.position.y + SURFACE_THICKNESS / 2.0)
	_place_surface(_ground, rect, rect.end.y - SURFACE_THICKNESS / 2.0)
	_player.position = rect.get_center()


func _place_surface(body: StaticBody2D, rect: Rect2, center_y: float) -> void:
	var size := Vector2(rect.size.x, SURFACE_THICKNESS)
	body.position = Vector2(rect.get_center().x, center_y)
	(body.get_node("CollisionShape2D").shape as RectangleShape2D).size = size
	var visual: ColorRect = body.get_node("Visual")
	visual.size = size
	visual.position = -size / 2.0
