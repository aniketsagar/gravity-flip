extends Area2D

const GROUND_COLOR := Color("ff2bd6")
const CEILING_COLOR := Color("9d4dff")
# The halo is the core colour at low alpha, a few pixels larger on every side.
const HALO_PAD := 4.0
const HALO_ALPHA := 0.25

var size := Vector2.ZERO
var ceiling_side := false
# Placement inputs kept so Main can re-place the hazard after a viewport resize.
# x_frac may exceed 1.0: the integer part is the lap, the fraction the position within it.
var x_frac := 0.0
# Unscrolled x; Main sets position.x = world_x - scroll each physics tick.
var world_x := 0.0


# Attaches the hazard to the ceiling or ground edge of the visible rect.
# at_frac is the hazard's centre as a fraction of the rect width (lap + fraction).
func place(rect: Rect2, surface_thickness: float, on_ceiling: bool, at_frac: float, hazard_size: Vector2) -> void:
	size = hazard_size
	ceiling_side = on_ceiling
	x_frac = at_frac
	world_x = rect.position.x + rect.size.x * at_frac
	var y := rect.end.y - surface_thickness - size.y / 2.0
	if on_ceiling:
		y = rect.position.y + surface_thickness + size.y / 2.0
	position = Vector2(world_x, y)
	var shape := RectangleShape2D.new()
	shape.size = size
	$CollisionShape2D.shape = shape
	var visual: ColorRect = $Visual
	visual.size = size
	visual.position = -size / 2.0
	var core := CEILING_COLOR if on_ceiling else GROUND_COLOR
	visual.color = core
	var halo: ColorRect = $Halo
	halo.color = Color(core, HALO_ALPHA)
	halo.size = size + Vector2.ONE * HALO_PAD * 2.0
	halo.position = -halo.size / 2.0
	var outline: ReferenceRect = $Outline
	outline.border_color = core.lightened(0.6)
	outline.size = size
	outline.position = -size / 2.0
