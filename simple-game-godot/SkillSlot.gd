extends Control
class_name SkillSlot

signal skill_activated(slot: String)

@export var key_label := "Q"
@export var skill_label := ""
@export var skill_icon: Texture2D
@export_multiline var skill_tooltip := ""
@export_range(0.0, 1.0, 0.01) var cooldown_progress := 0.0
## Round thumb button without the keyboard key, used by the touch controls.
var touch_style := false:
	set(value):
		touch_style = value
		queue_redraw()

const FIREBOLT_ICON = preload("res://textures/skills/firebolt.svg")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if key_label == "Q" and skill_icon == null:
		skill_icon = FIREBOLT_ICON
	if key_label == "Q" and skill_tooltip.is_empty():
		skill_tooltip = "Fireball\nDamage: 50% of target maximum health"
	tooltip_text = skill_tooltip


func _gui_input(event: InputEvent) -> void:
	# Touch is handled directly so a slot works while another finger is on a
	# joystick; the mouse event Godot emulates from that touch is skipped.
	if event is InputEventScreenTouch and event.pressed:
		skill_activated.emit(key_label)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed and event.device != InputEvent.DEVICE_ID_EMULATION:
		skill_activated.emit(key_label)
		accept_event()


func _draw() -> void:
	if touch_style:
		_draw_round()
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color("#17191d"), true)
	draw_rect(Rect2(Vector2(3, 3), size - Vector2(6, 6)), Color("#42454a"), true)
	draw_rect(Rect2(Vector2(6, 6), size - Vector2(12, 12)), Color("#25282d"), true)
	draw_rect(Rect2(Vector2(2, 2), size - Vector2(4, 4)), Color("#b99b68"), false, 2.0)
	if cooldown_progress > 0.0:
		var overlay_height := (size.y - 12.0) * clampf(cooldown_progress, 0.0, 1.0)
		draw_rect(
			Rect2(Vector2(6.0, 6.0), Vector2(size.x - 12.0, overlay_height)),
			Color(1.0, 1.0, 1.0, 0.38),
			true
		)

	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(10, 20), key_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#f4e6c8"))
	if skill_label.is_empty():
		draw_string(font, size / 2.0 + Vector2(-5, 7), "-", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#82858b"))
	elif skill_icon != null:
		draw_texture_rect(skill_icon, Rect2(Vector2(size.x - 36.0, 6.0), Vector2(28.0, 28.0)), false)
		draw_string(font, Vector2(5, size.y - 8), skill_label, HORIZONTAL_ALIGNMENT_LEFT, size.x - 10, 10, Color("#f4e6c8"))
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


func _has_point(point: Vector2) -> bool:
	if not touch_style:
		return Rect2(Vector2.ZERO, size).has_point(point)
	return point.distance_to(size / 2.0) <= minf(size.x, size.y) / 2.0


func _draw_round() -> void:
	var center := size / 2.0
	var radius := minf(size.x, size.y) / 2.0
	draw_circle(center, radius, Color("#17191d"))
	draw_circle(center, radius - 3.0, Color("#42454a"))
	draw_circle(center, radius - 6.0, Color("#25282d"))
	draw_arc(center, radius - 2.0, 0.0, TAU, 48, Color("#b99b68"), 2.0, true)
	if cooldown_progress > 0.0:
		# Cooldown sweeps clockwise from the top.
		var sweep := TAU * clampf(cooldown_progress, 0.0, 1.0)
		var points := PackedVector2Array([center])
		var steps := maxi(ceili(32.0 * cooldown_progress), 1)
		for step in steps + 1:
			var angle := -PI / 2.0 + sweep * float(step) / float(steps)
			points.append(center + Vector2.from_angle(angle) * (radius - 6.0))
		draw_colored_polygon(points, Color(1.0, 1.0, 1.0, 0.38))

	var font := ThemeDB.fallback_font
	if skill_label.is_empty():
		draw_string(font, center + Vector2(-5, 7), "-", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#82858b"))
		return
	var label_baseline := center.y + radius * 0.62
	if skill_icon != null:
		var icon_size := radius * 0.95
		draw_texture_rect(
			skill_icon,
			Rect2(center - Vector2(icon_size, icon_size) * 0.5 - Vector2(0.0, radius * 0.12), Vector2(icon_size, icon_size)),
			false
		)
	else:
		draw_colored_polygon(
			PackedVector2Array([
				center + Vector2(0.0, -radius * 0.55),
				center + Vector2(radius * 0.32, radius * 0.08),
				center + Vector2(0.0, -radius * 0.08),
				center + Vector2(-radius * 0.32, radius * 0.08)
			]),
			Color("#ff6b24")
		)
	draw_string(font, Vector2(0.0, label_baseline), skill_label, HORIZONTAL_ALIGNMENT_CENTER, size.x, 10, Color("#f4e6c8"))
