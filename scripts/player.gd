extends CharacterBody2D

# Tuning values.
const GRAVITY := 2700.0
const MAX_VERTICAL_SPEED := 3000.0
# Vertical speed given to the player the moment gravity is flipped, so a flip
# reverses direction at once instead of waiting for gravity to turn the old velocity.
const FLIP_SPEED := 600.0
# Visual-only: how long the 90 degree spin on a flip takes. The collision shape never rotates.
const SPIN_TIME := 0.12

var running := false
var gravity_dir := 1.0
# Extra vertical acceleration (px/s^2, positive = down) from a jumbo's attraction field. Main
# sets it every physics tick, before this node integrates (parents run first). It is added to
# gravity inside the speed clamp, so MAX_VERTICAL_SPEED still holds. Always 0 when not running.
var attract_accel := 0.0
var _spin_turns := 0
var _spin_tween: Tween

# The visuals are Controls, which rotate around their top-left corner by default;
# _ready moves each pivot to its centre. They are all centred on the body origin.
@onready var _visuals: Array[Control] = [$Halo, $Visual, $Outline]


func _ready() -> void:
	for visual in _visuals:
		visual.pivot_offset = visual.size / 2.0


func start(at: Vector2) -> void:
	position = at
	velocity = Vector2.ZERO
	attract_accel = 0.0
	gravity_dir = 1.0
	running = true
	_reset_spin()


func stop() -> void:
	running = false
	velocity = Vector2.ZERO
	attract_accel = 0.0


func flip() -> void:
	if not running:
		return
	gravity_dir = -gravity_dir
	velocity.y = gravity_dir * FLIP_SPEED
	_spin()


# Turns the visuals a further 90 degrees clockwise. The target is always a whole number
# of quarter turns, so rapid flips retarget from the current angle and end exactly aligned.
func _spin() -> void:
	_spin_turns += 1
	if _spin_tween:
		_spin_tween.kill()
	_spin_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	for visual in _visuals:
		_spin_tween.tween_property(visual, "rotation", _spin_turns * PI / 2.0, SPIN_TIME)


func _reset_spin() -> void:
	_spin_turns = 0
	if _spin_tween:
		_spin_tween.kill()
	for visual in _visuals:
		visual.rotation = 0.0


func _physics_process(delta: float) -> void:
	if not running:
		return
	velocity.y = clampf(velocity.y + (gravity_dir * GRAVITY + attract_accel) * delta, -MAX_VERTICAL_SPEED, MAX_VERTICAL_SPEED)
	move_and_slide()
