@tool
extends Node2D
class_name GroundShadows
## Soft ellipse shadows under static props. Each Rect2 is a shadow: position = centre, size = width/height.

const SHADOW_COLOR := Color(0.03, 0.06, 0.02, 0.13)
const LAYERS := 3

@export var shadows: Array[Rect2] = []:
	set(value):
		shadows = value
		queue_redraw()


func _draw() -> void:
	for shadow in shadows:
		draw_soft_ellipse(self, shadow.position, shadow.size)


static func draw_soft_ellipse(canvas: CanvasItem, center: Vector2, size: Vector2) -> void:
	# Stacked ellipses, each smaller one darkening the middle a little more.
	for layer in LAYERS:
		var layer_scale := 1.0 - float(layer) / (LAYERS + 1)
		var points := PackedVector2Array()
		for step in 24:
			var angle := TAU * step / 24.0
			points.append(center + Vector2(cos(angle) * size.x, sin(angle) * size.y) * 0.5 * layer_scale)
		canvas.draw_colored_polygon(points, SHADOW_COLOR)
