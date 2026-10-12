extends Control

@export var key_label := "Q"
@export var skill_label := ""


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#17191d"), true)
	draw_rect(Rect2(Vector2(3, 3), size - Vector2(6, 6)), Color("#42454a"), true)
	draw_rect(Rect2(Vector2(6, 6), size - Vector2(12, 12)), Color("#25282d"), true)
	draw_rect(Rect2(Vector2(2, 2), size - Vector2(4, 4)), Color("#b99b68"), false, 2.0)

	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(10, 20), key_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#f4e6c8"))
	if skill_label.is_empty():
		draw_string(font, size / 2.0 + Vector2(-5, 7), "-", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#82858b"))
	else:
		draw_colored_polygon(
			PackedVector2Array([
				Vector2(size.x * 0.5, 17.0),
				Vector2(size.x * 0.73, size.y * 0.53),
				Vector2(size.x * 0.5, size.y * 0.43),
				Vector2(size.x * 0.28, size.y * 0.53)
			]),
			Color("#ff6b24")
		)
		draw_string(font, Vector2(7, size.y - 8), skill_label, HORIZONTAL_ALIGNMENT_CENTER, size.x - 14, 10, Color("#f4e6c8"))
