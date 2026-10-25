extends Control
class_name HealthBarFrame
## The ornate frame around TargetHealthBar: a dark rim, a bevelled gold band with a glint sweeping along
## its top, and a gem stud at each end. Fill its parent bar; it draws a little outside it.

const RIM := Color("#140803")
const GOLD := Color("#c99a3c")
const GOLD_LIGHT := Color("#f6e3a1")
const GOLD_DARK := Color("#6e4a17")
const GEM := Color("#c8202a")
const DANGER := Color("#ff4a3a")
const STUD_SIZE := 7.0
## Seconds between glints.
const GLINT_PERIOD := 2.8
const GLINT_LENGTH := 60.0

## 0..1: how far the gold glows toward red (the bar sets this while the monster is low on health).
var danger := 0.0
var time := 0.0
var rim_style := _ring(RIM, 2, 5.0)
var gold_style := _ring(GOLD, 3, 3.0)
var bevel_style := _ring(Color(GOLD_LIGHT, 0.55), 1, 1.0)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _process(delta: float) -> void:
	time += delta
	queue_redraw()


func _draw() -> void:
	var radius := size.y * 0.5
	var gold := GOLD.lerp(DANGER, danger)
	var area := Rect2(Vector2.ZERO, size)
	for style in [rim_style, gold_style, bevel_style]:
		style.set_corner_radius_all(ceili(radius + style.expand_margin_left))
	gold_style.border_color = gold
	draw_style_box(rim_style, area)
	draw_style_box(gold_style, area)
	draw_style_box(bevel_style, area)
	_draw_glint(radius)
	for x in [-STUD_SIZE * 0.6, size.x + STUD_SIZE * 0.6]:
		_draw_stud(Vector2(x, radius), gold)


## A bright streak running left to right along the straight top edge, fading in and out at the ends.
func _draw_glint(radius: float) -> void:
	var run := size.x - radius * 2.0
	if run <= 0.0:
		return
	var progress := fposmod(time / GLINT_PERIOD, 1.0) * 1.6
	if progress > 1.0:
		return
	var center_x := radius + progress * run
	var fade := sin(progress * PI)
	var y := -1.5
	var half := GLINT_LENGTH * 0.5
	var points := PackedVector2Array([
		Vector2(maxf(center_x - half, radius), y),
		Vector2(center_x, y),
		Vector2(minf(center_x + half, size.x - radius), y)
	])
	var colors := PackedColorArray([
		Color(Color.WHITE, 0.0),
		Color(Color.WHITE, 0.9 * fade),
		Color(Color.WHITE, 0.0)
	])
	draw_polyline_colors(points, colors, 2.0)


func _draw_stud(center: Vector2, gold: Color) -> void:
	var outer := _diamond(center, STUD_SIZE + 2.0)
	draw_colored_polygon(outer, RIM)
	draw_colored_polygon(_diamond(center, STUD_SIZE), gold)
	draw_colored_polygon(_diamond(center + Vector2(0.0, 1.0), STUD_SIZE * 0.45), GOLD_DARK)
	draw_colored_polygon(_diamond(center, STUD_SIZE * 0.45), GEM.lerp(DANGER, danger))
	draw_line(center + Vector2(-STUD_SIZE * 0.55, -1.0), center + Vector2(0.0, -STUD_SIZE * 0.55), Color(GOLD_LIGHT, 0.9), 1.0)


static func _diamond(center: Vector2, half_size: float) -> PackedVector2Array:
	return PackedVector2Array([
		center + Vector2(0.0, -half_size),
		center + Vector2(half_size, 0.0),
		center + Vector2(0.0, half_size),
		center + Vector2(-half_size, 0.0)
	])


static func _ring(color: Color, width: int, expand: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.draw_center = false
	style.border_color = color
	style.set_border_width_all(width)
	style.set_expand_margin_all(expand)
	style.anti_aliasing = true
	return style
