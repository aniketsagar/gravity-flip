extends CharacterBody2D

signal crashed

const SPEED := 200.0
const GRAVITY := 1800.0
const MAX_FALL_SPEED := 900.0

# Horizontal limits of the play area; set by Main from the visible rect.
var play_rect := Rect2(0, 0, 480, 854)
var running := false
var gravity_dir := 1.0


func start(at: Vector2) -> void:
	position = at
	velocity = Vector2.ZERO
	gravity_dir = 1.0
	running = true


func flip() -> void:
	gravity_dir = -gravity_dir


func _physics_process(delta: float) -> void:
	if not running:
		return
	velocity.x = SPEED
	velocity.y = clampf(velocity.y + gravity_dir * GRAVITY * delta, -MAX_FALL_SPEED, MAX_FALL_SPEED)
	move_and_slide()
	# Wrap from the right edge to the left edge, carrying over any overshoot so
	# horizontal movement stays continuous. Vertical position and gravity are kept.
	if position.x >= play_rect.end.x:
		position.x -= play_rect.size.x
