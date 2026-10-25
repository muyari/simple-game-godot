extends Node2D
class_name PickupBurst
## The flash left behind when a drop is collected: a ring of light, sparks flying outward and the loot's
## name floating up. Frees itself when done.

const DURATION := 0.8
const SPARK_COUNT := 8
const TEXT_RISE := 30.0
const FONT_SIZE := 13

var color := Color.WHITE
var text := ""
var spark_count := SPARK_COUNT
var age := 0.0


static func spawn(parent: Node, world_position: Vector2, burst_color: Color, burst_text: String, sparks := SPARK_COUNT) -> void:
	if parent == null:
		return
	var burst := PickupBurst.new()
	burst.color = burst_color
	burst.text = burst_text
	burst.spark_count = sparks
	# Above the world so the text is never hidden behind props.
	burst.z_index = 50
	parent.add_child(burst)
	burst.global_position = world_position


func _process(delta: float) -> void:
	age += delta
	if age >= DURATION:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var progress := age / DURATION
	var fade := 1.0 - progress
	var center := Vector2(0.0, -14.0)

	var ring_radius := 6.0 + ease(progress, 0.4) * 26.0
	draw_arc(center, ring_radius, 0.0, TAU, 24, Color(color, fade * 0.8), 2.0)
	draw_circle(center, 10.0 * fade, Color(color.lightened(0.5), fade * 0.5))

	for index in spark_count:
		var angle := TAU * index / spark_count + 0.3
		var direction := Vector2.RIGHT.rotated(angle)
		var distance := 6.0 + ease(progress, 0.35) * 30.0
		LootFx.draw_sparkle(self, center + direction * distance, 3.0 * fade + 0.5, Color(color.lightened(0.3), fade))

	if text.is_empty():
		return
	var font := ThemeDB.fallback_font
	var text_width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	var text_position := Vector2(-text_width * 0.5, -30.0 - ease(progress, 0.5) * TEXT_RISE)
	var text_alpha := clampf(fade * 1.6, 0.0, 1.0)
	draw_string_outline(font, text_position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, 4, Color(0.08, 0.08, 0.07, text_alpha))
	draw_string(font, text_position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color(color, text_alpha))
