extends Node2D
class_name DesertFloor
## Ground detail for one desert region, drawn flat under everything: drifts of darker wind-packed and paler
## smooth sand that break up the ripple tiling, pebbles, dry grass tufts and sun-bleached bones.
## Fully determined by `seed_value`.

const PIXEL := 2.0
const PACKED_SAND := Color(0.55, 0.3, 0.08, 0.025)
const SMOOTH_SAND := Color(1.0, 0.93, 0.72, 0.035)
const PATCH_LAYERS := 7
const PEBBLE_COLORS: Array[Color] = [Color("#a7774a"), Color("#8f6a4a"), Color("#c49a66"), Color("#7d5a3c")]
const PEBBLE_SHADE := Color("#5e3f24")
const GRASS_COLORS: Array[Color] = [Color("#a89a4e"), Color("#8c8040"), Color("#c2b065")]
const BONE := Color("#efe6cf")
const BONE_SHADE := Color("#c9bb98")
const OUTLINE := Color("#4a3220")
## Bleached remains. o outline, b bone, s shade, e eye socket.
const SKULL := [
	".ooooo.",
	"obbbbbo",
	"obebebo",
	"obbbbbo",
	".osbso.",
	"..ooo..",
]
const RIBS := [
	"o.o.o.o.",
	"bobobobo",
	"bsbsbsbs",
	"ooooooo.",
]

var seed_value := 0
var half_extents := Vector2(576, 324)


func _draw() -> void:
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	for _patch in random.randi_range(4, 7):
		var color := PACKED_SAND if random.randf() < 0.55 else SMOOTH_SAND
		var size := Vector2(random.randf_range(160, 340), random.randf_range(70, 150))
		_draw_soft_patch(_random_point(random), size, color)
	for _cluster in random.randi_range(5, 9):
		var center := _random_point(random)
		for _pebble in random.randi_range(2, 6):
			_draw_pebble(_snap(center + Vector2(random.randfn(0, 14), random.randfn(0, 7))), random)
	for _tuft in random.randi_range(5, 9):
		_draw_grass_tuft(_snap(_random_point(random)), random)
	if random.randf() < 0.55:
		_draw_pixels(SKULL, _snap(_random_point(random)), random.randf() < 0.5)
	if random.randf() < 0.45:
		_draw_pixels(RIBS, _snap(_random_point(random)), random.randf() < 0.5)


func _random_point(random: RandomNumberGenerator) -> Vector2:
	return Vector2(
		random.randf_range(-half_extents.x, half_extents.x),
		random.randf_range(-half_extents.y, half_extents.y)
	)


func _snap(point: Vector2) -> Vector2:
	return (point / PIXEL).floor() * PIXEL


func _draw_soft_patch(center: Vector2, size: Vector2, color: Color) -> void:
	# Many faint stacked ellipses, each smaller one deepening the middle, so the edge fades smoothly;
	# stretched along the wind.
	for layer in PATCH_LAYERS:
		var layer_scale := 1.0 - float(layer) / (PATCH_LAYERS + 1)
		var points := PackedVector2Array()
		for step in 20:
			var angle := TAU * step / 20.0
			var wobble := 1.0 + sin(angle * 3.0 + center.x) * 0.14
			var point := Vector2(cos(angle) * size.x, sin(angle) * size.y) * 0.5 * layer_scale * wobble
			points.append(center + point.rotated(-0.35))
		draw_colored_polygon(points, color)


func _draw_pebble(origin: Vector2, random: RandomNumberGenerator) -> void:
	var color: Color = PEBBLE_COLORS[random.randi() % PEBBLE_COLORS.size()]
	var width := random.randi_range(1, 3)
	draw_rect(Rect2(origin + Vector2(-PIXEL, PIXEL), Vector2(width + 1, 1) * PIXEL), Color(0.35, 0.18, 0.05, 0.22))
	draw_rect(Rect2(origin, Vector2(width, 1) * PIXEL), color)
	draw_rect(Rect2(origin + Vector2(0, PIXEL), Vector2(width, 1) * PIXEL), PEBBLE_SHADE)


func _draw_grass_tuft(origin: Vector2, random: RandomNumberGenerator) -> void:
	# A few dry blades fanning up from one point.
	var color: Color = GRASS_COLORS[random.randi() % GRASS_COLORS.size()]
	for blade in random.randi_range(3, 5):
		var lean := blade - 2
		var height := random.randi_range(2, 4)
		for step in height:
			var pixel := origin + Vector2(roundf(lean * step * 0.5), -step) * PIXEL
			draw_rect(Rect2(pixel, Vector2.ONE * PIXEL), color if step < height - 1 else color.lightened(0.2))


func _draw_pixels(pattern: Array, origin: Vector2, mirrored: bool) -> void:
	var width: int = pattern[0].length()
	draw_rect(Rect2(origin + Vector2(-PIXEL, (pattern.size() - 1) * PIXEL), Vector2(width + 2, 1.5) * PIXEL), Color(0.35, 0.18, 0.05, 0.2))
	for row in pattern.size():
		var line: String = pattern[row]
		for column in line.length():
			var color: Color
			match line[column]:
				"o": color = OUTLINE
				"b": color = BONE
				"s": color = BONE_SHADE
				"e": color = OUTLINE
				_: continue
			var x := width - 1 - column if mirrored else column
			draw_rect(Rect2(origin + Vector2(x, row) * PIXEL, Vector2.ONE * PIXEL), color)
