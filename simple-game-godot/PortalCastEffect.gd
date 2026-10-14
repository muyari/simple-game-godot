extends Node2D

const BAR_SIZE := Vector2(44.0, 5.0)
const BAR_OFFSET_Y := -52.0

var animation_time := 0.0
var progress := 0.0:
	set(new_progress):
		progress = clampf(new_progress, 0.0, 1.0)
		queue_redraw()


func _process(delta: float) -> void:
	if not visible:
		return

	animation_time += delta
	queue_redraw()


func _draw() -> void:
	var pulse := sin(animation_time * 8.0) * 3.0
	var spin := animation_time * 3.5
	for ring_index in range(3):
		var start_angle := spin + ring_index * TAU / 3.0
		draw_arc(
			Vector2(0.0, -5.0),
			24.0 + ring_index * 6.0 + pulse,
			start_angle,
			start_angle + 1.55,
			24,
			Color(0.35, 0.8, 1.0, 0.8 - ring_index * 0.16),
			2.5,
			true
		)

	for mote_index in range(6):
		var angle := spin * 1.7 + mote_index * TAU / 6.0
		var radius := 30.0 + sin(animation_time * 5.0 + mote_index) * 5.0
		var mote_position := Vector2.from_angle(angle) * radius + Vector2(0.0, -5.0)
		draw_circle(mote_position, 2.5, Color(0.74, 0.94, 1.0, 0.9))

	_draw_channel_bar()


func play() -> void:
	animation_time = 0.0
	progress = 0.0
	show()
	queue_redraw()


func stop() -> void:
	hide()
	queue_redraw()


func _draw_channel_bar() -> void:
	var bar_rect := Rect2(Vector2(-BAR_SIZE.x / 2.0, BAR_OFFSET_Y), BAR_SIZE)
	draw_rect(bar_rect.grow(1.0), Color(0.04, 0.07, 0.12, 0.9))
	if progress > 0.0:
		var fill_rect := Rect2(bar_rect.position, Vector2(BAR_SIZE.x * progress, BAR_SIZE.y))
		draw_rect(fill_rect, Color(0.25, 0.68, 1.0))
		draw_rect(Rect2(fill_rect.position, Vector2(fill_rect.size.x, 1.0)), Color(0.74, 0.94, 1.0))
	draw_rect(bar_rect.grow(1.0), Color(0.35, 0.8, 1.0, 0.9), false, 1.0)
