extends CharacterBody2D

signal wrapped

const SPEED := 200.0
# Tuning values.
const GRAVITY := 2700.0
const MAX_VERTICAL_SPEED := 1000.0
# Vertical speed given to the player the moment gravity is flipped, so a flip
# reverses direction at once instead of waiting for gravity to turn the old velocity.
const FLIP_SPEED := 600.0

# Horizontal limits of the play area; set by Main from the visible rect.
var play_rect := Rect2(0, 0, 480, 854)
var running := false
var gravity_dir := 1.0


func start(at: Vector2) -> void:
	position = at
	velocity = Vector2.ZERO
	gravity_dir = 1.0
	running = true


func stop() -> void:
	running = false
	velocity = Vector2.ZERO


func flip() -> void:
	if not running:
		return
	gravity_dir = -gravity_dir
	velocity.y = gravity_dir * FLIP_SPEED


func _physics_process(delta: float) -> void:
	if not running:
		return
	velocity.x = SPEED
	velocity.y = clampf(velocity.y + gravity_dir * GRAVITY * delta, -MAX_VERTICAL_SPEED, MAX_VERTICAL_SPEED)
	move_and_slide()
	# Wrap from the right edge to the left edge, carrying over any overshoot so
	# horizontal movement stays continuous. Vertical position and gravity are kept.
	if position.x >= play_rect.end.x:
		position.x -= play_rect.size.x
		wrapped.emit()
