extends Area2D

var size := Vector2.ZERO
var ceiling_side := false


# Attaches the hazard to the ceiling or ground edge of the visible rect.
# x_frac is the hazard's centre as a fraction of the rect width.
func place(rect: Rect2, surface_thickness: float, on_ceiling: bool, x_frac: float, hazard_size: Vector2) -> void:
	size = hazard_size
	ceiling_side = on_ceiling
	var y := rect.end.y - surface_thickness - size.y / 2.0
	if on_ceiling:
		y = rect.position.y + surface_thickness + size.y / 2.0
	position = Vector2(rect.position.x + rect.size.x * x_frac, y)
	var shape := RectangleShape2D.new()
	shape.size = size
	$CollisionShape2D.shape = shape
	var visual: ColorRect = $Visual
	visual.size = size
	visual.position = -size / 2.0
