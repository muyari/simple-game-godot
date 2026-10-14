extends Node2D
class_name ForestFloor
## Ground detail for one forest region, drawn flat under everything: moss and dirt patches that break up the
## grass tiling, leaf litter, twigs, pebbles and tiny mushrooms. Fully determined by `seed_value`.

const PIXEL := 2.0
const MOSS_COLOR := Color(0.1, 0.2, 0.06, 0.08)
const DIRT_COLOR := Color(0.36, 0.27, 0.13, 0.09)
const LEAF_COLORS: Array[Color] = [
	Color("#c46d2b"), Color("#d99a3a"), Color("#8c4a22"), Color("#a8892f"), Color("#6c7f2a"),
]
const TWIG_COLOR := Color("#5a3b22")
const TWIG_LIGHT := Color("#7d5833")
const PEBBLE_COLOR := Color("#8d8a7f")
const PEBBLE_SHADE := Color("#5b5a52")
const OUTLINE := Color("#2a1c12")
const MUSHROOM_CAPS: Array[Color] = [Color("#c8322b"), Color("#b0703a"), Color("#d9b36a")]
const MUSHROOM_STEM := Color("#efe3c8")
## Cap pixels: c = cap, s = spot, t = stem, o = outline.
const MUSHROOM := [
	".ooo.",
	"ocsco",
	"occco",
	".oto.",
	".oto.",
]

var seed_value := 0
var half_extents := Vector2(576, 324)


func _draw() -> void:
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	for _patch in random.randi_range(5, 8):
		var color := MOSS_COLOR if random.randf() < 0.6 else DIRT_COLOR
		var size := Vector2(random.randf_range(120, 260), random.randf_range(60, 130))
		_draw_soft_patch(_random_point(random), size, color)
	for _cluster in random.randi_range(6, 10):
		var center := _random_point(random)
		for _leaf in random.randi_range(5, 12):
			var leaf_position := _snap(center + Vector2(random.randfn(0, 16), random.randfn(0, 9)))
			var leaf_color: Color = LEAF_COLORS[random.randi() % LEAF_COLORS.size()]
			var leaf_size := Vector2(PIXEL * random.randi_range(1, 2), PIXEL)
			draw_rect(Rect2(leaf_position, leaf_size), leaf_color.darkened(random.randf_range(0.0, 0.2)))
	for _twig in random.randi_range(4, 8):
		var start := _snap(_random_point(random))
		var length := random.randi_range(4, 8)
		var slope := random.randi_range(-1, 1)
		for step in length:
			var pixel := start + Vector2(step * PIXEL, floorf(step * slope / 3.0) * PIXEL)
			draw_rect(Rect2(pixel, Vector2.ONE * PIXEL), TWIG_COLOR if step % 3 else TWIG_LIGHT)
	for _pebble in random.randi_range(4, 9):
		var pebble := _snap(_random_point(random))
		var width := random.randi_range(1, 2)
		draw_rect(Rect2(pebble, Vector2(width + 1, 1) * PIXEL), PEBBLE_COLOR)
		draw_rect(Rect2(pebble + Vector2(0, PIXEL), Vector2(width + 1, 1) * PIXEL), PEBBLE_SHADE)
	for _group in random.randi_range(1, 3):
		var center := _random_point(random)
		var cap: Color = MUSHROOM_CAPS[random.randi() % MUSHROOM_CAPS.size()]
		for _mushroom in random.randi_range(1, 3):
			_draw_mushroom(_snap(center + Vector2(random.randf_range(-18, 18), random.randf_range(-8, 8))), cap)


func _random_point(random: RandomNumberGenerator) -> Vector2:
	return Vector2(
		random.randf_range(-half_extents.x, half_extents.x),
		random.randf_range(-half_extents.y, half_extents.y)
	)


func _snap(point: Vector2) -> Vector2:
	return (point / PIXEL).floor() * PIXEL


func _draw_soft_patch(center: Vector2, size: Vector2, color: Color) -> void:
	# Stacked ellipses, each smaller one deepening the middle, like GroundShadows.
	for layer in 3:
		var layer_scale := 1.0 - float(layer) / 4.0
		var points := PackedVector2Array()
		for step in 20:
			var angle := TAU * step / 20.0
			var wobble := 1.0 + sin(angle * 3.0 + center.x) * 0.12
			points.append(center + Vector2(cos(angle) * size.x, sin(angle) * size.y) * 0.5 * layer_scale * wobble)
		draw_colored_polygon(points, color)


func _draw_mushroom(origin: Vector2, cap: Color) -> void:
	draw_rect(Rect2(origin + Vector2(0, MUSHROOM.size() * PIXEL - PIXEL), Vector2(5, 1.5) * PIXEL), Color(0, 0, 0, 0.18))
	for row in MUSHROOM.size():
		var line: String = MUSHROOM[row]
		for column in line.length():
			var color: Color
			match line[column]:
				"o": color = OUTLINE
				"c": color = cap
				"s": color = MUSHROOM_STEM
				"t": color = MUSHROOM_STEM.darkened(0.08)
				_: continue
			draw_rect(Rect2(origin + Vector2(column, row) * PIXEL, Vector2.ONE * PIXEL), color)
