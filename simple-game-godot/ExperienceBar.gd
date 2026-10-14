extends ProgressBar
class_name ExperienceBar

# Palette shared with the globe and potion artwork.
const OUTLINE_COLOR := Color8(8, 9, 13)
const RIM_COLOR := Color8(112, 178, 214)
const GLASS_COLOR := Color8(22, 27, 38)
const GLASS_SHINE := Color(1, 1, 1, 0.08)
const LIQUID_COLOR := Color8(222, 158, 34)
const LIQUID_SHADE := Color8(150, 92, 16)
const LIQUID_HIGHLIGHT := Color8(255, 226, 140)
const SEGMENTS := 10


func _init() -> void:
	show_percentage = false
	for style_name in ["background", "fill"]:
		add_theme_stylebox_override(style_name, StyleBoxEmpty.new())


func _draw() -> void:
	var outer := Rect2(Vector2.ZERO, size)
	draw_rect(outer, OUTLINE_COLOR)
	draw_rect(outer.grow(-1.0), RIM_COLOR)
	var inner := outer.grow(-2.0)
	draw_rect(inner, GLASS_COLOR)

	var fraction := clampf((value - min_value) / (max_value - min_value), 0.0, 1.0) if max_value > min_value else 0.0
	var fill_width := roundf(inner.size.x * fraction)
	if fill_width > 0.0:
		var liquid := Rect2(inner.position, Vector2(fill_width, inner.size.y))
		draw_rect(liquid, LIQUID_COLOR)
		var shade_height := maxf(roundf(inner.size.y * 0.35), 1.0)
		draw_rect(Rect2(liquid.position.x, liquid.end.y - shade_height, fill_width, shade_height), LIQUID_SHADE)
		draw_rect(Rect2(liquid.position, Vector2(fill_width, 1.0)), LIQUID_HIGHLIGHT)
		draw_rect(Rect2(liquid.end.x - 1.0, liquid.position.y, 1.0, liquid.size.y), LIQUID_HIGHLIGHT)

	# Segment notches and a faint glass reflection along the top.
	for index in range(1, SEGMENTS):
		var notch_x := roundf(inner.position.x + inner.size.x * index / SEGMENTS)
		draw_rect(Rect2(notch_x, inner.position.y, 1.0, inner.size.y), Color(OUTLINE_COLOR, 0.55))
	draw_rect(Rect2(inner.position.x + 2.0, inner.position.y + 1.0, inner.size.x - 4.0, 1.0), GLASS_SHINE)
