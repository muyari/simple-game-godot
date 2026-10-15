@tool
extends Control
class_name TouchLayoutMarker

## Placeholder in touch_controls.tscn. On touch devices the HUD node with the
## same name (HealthOrb, SkillSlotQ, ...) takes this marker's anchors and
## offsets. Markers only draw in the editor; the game removes them.

@export var round := false:
	set(value):
		round = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not Engine.is_editor_hint():
		hide()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var fill := Color(0.91, 0.78, 0.49, 0.18)
	var outline := Color(0.91, 0.78, 0.49, 0.9)
	if round:
		var radius := minf(size.x, size.y) / 2.0
		draw_circle(size / 2.0, radius, fill)
		draw_arc(size / 2.0, radius - 1.0, 0.0, TAU, 48, outline, 2.0, true)
	else:
		draw_rect(Rect2(Vector2.ZERO, size), fill, true)
		draw_rect(Rect2(Vector2.ZERO, size), outline, false, 2.0)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(0.0, size.y / 2.0 + 5.0),
		name,
		HORIZONTAL_ALIGNMENT_CENTER,
		size.x,
		12,
		Color.WHITE
	)
