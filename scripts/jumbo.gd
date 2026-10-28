extends Area2D

# A jumbo obstacle: a solid circular core (this Area2D's only collision shape, lethal like a
# hazard) inside a larger, non-solid attraction field. The field is only maths and drawing:
# it has no collision shape and never ends the run.

const CORE_COLOR := Color("ff2bd6")
const FIELD_COLOR := Color("9d4dff")
const FIELD_FILL_ALPHA := 0.12
const FIELD_LINE_WIDTH := 2.0
const CORE_OUTLINE_WIDTH := 2.0
# Distances below this count as "centres coincide": no direction, so no attraction.
const MIN_DISTANCE := 0.0001

# Pixels; the field centre is the core centre is this node's position.
var core_radius := 0.0
var field_radius := 0.0
# Peak strength in px/s^2, reached at and inside the core radius.
var strength := 0.0
# Size of the field's bounding box, so Main can free it like a hazard (by its right edge).
var size := Vector2.ZERO
# Placement inputs kept so Main can re-place the jumbo after a viewport resize.
var x_px := 0.0
var y_frac := 0.0
var core_frac := 0.0
var field_frac := 0.0
# Unscrolled x; Main sets position.x = world_x - scroll each physics tick.
var world_x := 0.0


# Attraction on a body at player_pos, as a vector toward the core:
#   a = strength * f(d) * (core_pos - player_pos) / d,  f(d) = clamp((R - d) / (R - r), 0, 1)
# Zero at and beyond the field edge (d >= R) and when the centres coincide. Main applies only
# the vertical component.
static func attraction(player_pos: Vector2, core_pos: Vector2, core_r: float, field_r: float, peak: float) -> Vector2:
	var to_core := core_pos - player_pos
	var d := to_core.length()
	if d < MIN_DISTANCE or d >= field_r:
		return Vector2.ZERO
	var f := clampf((field_r - d) / maxf(field_r - core_r, MIN_DISTANCE), 0.0, 1.0)
	return to_core / d * (peak * f)


func attraction_at(player_pos: Vector2) -> Vector2:
	return attraction(player_pos, position, core_radius, field_radius, strength)


# Sizes derive from the playable height (between the inner faces of ceiling and ground), like
# the hazards. x_at is the core centre in pixels from the start of the run; y_at the centre
# height as a fraction of the playable height, measured down from the ceiling.
func place(rect: Rect2, surface_thickness: float, x_at: float, y_at: float, core_fraction: float,
		field_fraction: float, peak: float) -> void:
	var playable := rect.size.y - 2.0 * surface_thickness
	x_px = x_at
	y_frac = y_at
	core_frac = core_fraction
	field_frac = field_fraction
	core_radius = core_fraction * playable
	field_radius = field_fraction * playable
	strength = peak
	size = Vector2.ONE * field_radius * 2.0
	world_x = rect.position.x + x_px
	position = Vector2(world_x, rect.position.y + surface_thickness + y_frac * playable)
	var shape := CircleShape2D.new()
	shape.radius = core_radius
	$CollisionShape2D.shape = shape
	queue_redraw()


# Debug geometry for the physics prototype: a faint violet disc with a violet boundary for the
# field, a solid magenta disc with a lighter outline for the core.
func _draw() -> void:
	draw_circle(Vector2.ZERO, field_radius, Color(FIELD_COLOR, FIELD_FILL_ALPHA))
	draw_arc(Vector2.ZERO, field_radius, 0.0, TAU, 96, Color(FIELD_COLOR, 0.8), FIELD_LINE_WIDTH, true)
	draw_circle(Vector2.ZERO, core_radius, CORE_COLOR)
	draw_arc(Vector2.ZERO, core_radius, 0.0, TAU, 64, CORE_COLOR.lightened(0.6), CORE_OUTLINE_WIDTH, true)
