extends Node2D
class_name IceFloor
## Ground detail for one ice cave region, drawn flat under everything: patches of frozen-over ice with
## cracks and glints, soft drifts of shadowed and wind-polished snow that break up the ripple tiling,
## stones poking through the snow and trails of animal tracks. Fully determined by `seed_value`.

const PIXEL := 2.0
const SHADED_SNOW := Color(0.45, 0.62, 0.85, 0.035)
const BRIGHT_SNOW := Color(1.0, 1.0, 1.0, 0.05)
const PATCH_LAYERS := 6
const ICE_RIM := Color("#9fcbe8")
const ICE := Color("#bfe2f6")
const ICE_DEEP := Color("#a6d3ef")
const ICE_CRACK := Color("#7fb3da")
const ICE_GLINT := Color("#f4fbff")
const STONE_COLORS: Array[Color] = [Color("#7d8796"), Color("#6a7383"), Color("#939cab")]
const STONE_SNOW := Color("#f2f8fc")
const TRACK := Color(0.5, 0.64, 0.82, 0.55)

var seed_value := 0
var half_extents := Vector2(576, 324)


func _draw() -> void:
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	for _patch in random.randi_range(4, 7):
		var color := SHADED_SNOW if random.randf() < 0.6 else BRIGHT_SNOW
		var size := Vector2(random.randf_range(180, 360), random.randf_range(80, 160))
		_draw_soft_patch(_random_point(random), size, color)
	for _pond in random.randi_range(0, 2):
		_draw_ice_patch(_random_point(random) * 0.8, random)
	for _cluster in random.randi_range(3, 6):
		var center := _random_point(random)
		for _stone in random.randi_range(1, 4):
			_draw_stone(_snap(center + Vector2(random.randfn(0, 16), random.randfn(0, 8))), random)
	if random.randf() < 0.6:
		_draw_tracks(_random_point(random), random)


func _random_point(random: RandomNumberGenerator) -> Vector2:
	return Vector2(
		random.randf_range(-half_extents.x, half_extents.x),
		random.randf_range(-half_extents.y, half_extents.y)
	)


func _snap(point: Vector2) -> Vector2:
	return (point / PIXEL).floor() * PIXEL


func _draw_soft_patch(center: Vector2, size: Vector2, color: Color) -> void:
	# Faint stacked ellipses, each smaller one deepening the middle, so the edge fades smoothly;
	# stretched along the wind.
	for layer in PATCH_LAYERS:
		var layer_scale := 1.0 - float(layer) / (PATCH_LAYERS + 1)
		draw_colored_polygon(_blob(center, size * layer_scale, 0.14, center.x), color)


func _blob(center: Vector2, size: Vector2, wobble_amount: float, phase: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for step in 24:
		var angle := TAU * step / 24.0
		var wobble := 1.0 + sin(angle * 3.0 + phase) * wobble_amount + sin(angle * 5.0 + phase * 1.7) * wobble_amount * 0.5
		var point := Vector2(cos(angle) * size.x, sin(angle) * size.y) * 0.5 * wobble
		points.append(center + point.rotated(-0.3))
	return points


## A frozen puddle: a rim, clear ice with a deeper middle, a few cracks and a glint of light.
func _draw_ice_patch(center: Vector2, random: RandomNumberGenerator) -> void:
	var size := Vector2(random.randf_range(140, 260), random.randf_range(60, 110))
	var phase := random.randf() * TAU
	draw_colored_polygon(_blob(center, size + Vector2(10, 6), 0.12, phase), ICE_RIM)
	draw_colored_polygon(_blob(center, size, 0.12, phase), ICE)
	draw_colored_polygon(_blob(center + Vector2(size.x * 0.06, size.y * 0.08), size * 0.55, 0.18, phase + 1.0), ICE_DEEP)
	for _crack in random.randi_range(2, 4):
		var point := center + Vector2(random.randf_range(-0.3, 0.3) * size.x, random.randf_range(-0.25, 0.25) * size.y)
		var heading := random.randf() * TAU
		for _segment in random.randi_range(3, 5):
			heading += random.randf_range(-0.7, 0.7)
			var next := point + Vector2(cos(heading), sin(heading) * 0.5) * random.randf_range(10, 22)
			draw_line(point, next, ICE_CRACK, PIXEL)
			point = next
	var glint := center + Vector2(-size.x * 0.22, -size.y * 0.18)
	draw_line(glint, glint + Vector2(26, -6), ICE_GLINT, PIXEL * 1.5)
	draw_line(glint + Vector2(8, 6), glint + Vector2(22, 3), ICE_GLINT, PIXEL)


func _draw_stone(origin: Vector2, random: RandomNumberGenerator) -> void:
	var color: Color = STONE_COLORS[random.randi() % STONE_COLORS.size()]
	var width := random.randi_range(2, 4)
	draw_rect(Rect2(origin + Vector2(-PIXEL, PIXEL * 2), Vector2(width + 1, 1) * PIXEL), Color(0.3, 0.42, 0.6, 0.22))
	draw_rect(Rect2(origin + Vector2(0, PIXEL), Vector2(width, 1) * PIXEL), color.darkened(0.2))
	draw_rect(Rect2(origin, Vector2(width, 1) * PIXEL), color)
	# A cap of snow on top.
	draw_rect(Rect2(origin + Vector2(PIXEL * 0.5, -PIXEL), Vector2(maxf(width - 1, 1), 1) * PIXEL), STONE_SNOW)


## A meandering line of paw prints, left in pairs.
func _draw_tracks(start: Vector2, random: RandomNumberGenerator) -> void:
	var heading := random.randf() * TAU
	var point := start
	for step in random.randi_range(10, 18):
		heading += random.randf_range(-0.25, 0.25)
		var direction := Vector2(cos(heading), sin(heading) * 0.6)
		var side := Vector2(-direction.y, direction.x) * (5.0 if step % 2 == 0 else -5.0)
		var paw := _snap(point + side)
		draw_rect(Rect2(paw, Vector2(2, 2) * PIXEL), TRACK)
		draw_rect(Rect2(paw + Vector2(0, -PIXEL * 1.5), Vector2(PIXEL, PIXEL)), TRACK)
		point += direction * 18.0
