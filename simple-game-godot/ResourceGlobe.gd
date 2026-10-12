extends Control
class_name ResourceGlobe

@export var fill_color := Color(0.82, 0.12, 0.13)
@export var highlight_color := Color(1.0, 0.55, 0.48, 0.55)

var value := 100.0:
	set(new_value):
		value = new_value
		queue_redraw()

var maximum := 100.0:
	set(new_maximum):
		maximum = new_maximum
		queue_redraw()


func _draw() -> void:
	var center := size / 2.0
	var radius := minf(size.x, size.y) * 0.43
	var fraction := clampf(value / maximum, 0.0, 1.0) if maximum > 0.0 else 0.0

	draw_circle(center, radius + 7.0, Color("#171b20"))
	draw_arc(center, radius + 6.0, 0.0, TAU, 96, Color("#b99b68"), 3.0, true)
	draw_circle(center, radius, Color("#292d32"))

	if fraction > 0.0:
		if fraction >= 1.0:
			draw_circle(center, radius - 2.0, fill_color)
		else:
			var level := radius - 2.0 * radius * fraction
			var start_angle := asin(clampf(level / radius, -1.0, 1.0))
			var end_angle := PI - start_angle
			var points := PackedVector2Array()
			for step in range(33):
				var angle := lerpf(start_angle, end_angle, float(step) / 32.0)
				points.append(center + Vector2(cos(angle), sin(angle)) * radius)
			draw_colored_polygon(points, fill_color)

	draw_circle(center, radius - 3.0, Color(0, 0, 0, 0), false, 2.0, true)
	draw_arc(center + Vector2(-radius * 0.12, -radius * 0.12), radius * 0.66, PI * 1.08, PI * 1.78, 24, highlight_color, 4.0, true)
	draw_arc(center, radius + 3.0, 0.0, TAU, 96, Color("#e1c68d"), 2.0, true)
	var font := ThemeDB.fallback_font
	var amount := str(roundi(value))
	draw_string(font, center + Vector2(-size.x / 2.0, 6.0), amount, HORIZONTAL_ALIGNMENT_CENTER, size.x, 16, Color.WHITE)
