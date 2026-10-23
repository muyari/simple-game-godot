extends Node2D
class_name UnderworldFloor
## Ground detail for one underworld region, drawn flat under everything: drifts of grey ash, soot
## scorches, glowing ember seams cracking through the cobbles and scattered bone chips. Fully determined
## by `seed_value`.

const PIXEL := 2.0
const ASH := Color(0.55, 0.5, 0.5, 0.06)
const SOOT := Color(0.02, 0.0, 0.0, 0.16)
const SEAM_DARK := Color("#3a0f0c")
const SEAM := Color("#c2361a")
const SEAM_HOT := Color("#ff8a2a")
const BONE := Color("#cfc2a6")
const BONE_SHADE := Color("#8a7e6a")
const PATCH_LAYERS := 5

var seed_value := 0
var half_extents := Vector2(576, 324)


func _draw() -> void:
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	for _patch in random.randi_range(3, 5):
		var color := ASH if random.randf() < 0.55 else SOOT
		var size := Vector2(random.randf_range(160, 320), random.randf_range(70, 140))
		_draw_soft_patch(_random_point(random), size, color, random.randf() * TAU)
	for _seam in random.randi_range(2, 4):
		_draw_seam(_random_point(random), random)
	for _scatter in random.randi_range(3, 6):
		var center := _random_point(random)
		for _chip in random.randi_range(1, 3):
			_draw_bone_chip(_snap(center + Vector2(random.randfn(0, 14), random.randfn(0, 7))), random)


func _random_point(random: RandomNumberGenerator) -> Vector2:
	return Vector2(
		random.randf_range(-half_extents.x, half_extents.x),
		random.randf_range(-half_extents.y, half_extents.y)
	)


func _snap(point: Vector2) -> Vector2:
	return (point / PIXEL).floor() * PIXEL


func _draw_soft_patch(center: Vector2, size: Vector2, color: Color, phase: float) -> void:
	# Faint stacked blobs, each smaller one deepening the middle, so the edge fades smoothly.
	for layer in PATCH_LAYERS:
		var layer_scale := 1.0 - float(layer) / (PATCH_LAYERS + 1)
		var points := PackedVector2Array()
		for step in 24:
			var angle := TAU * step / 24.0
			var wobble := 1.0 + sin(angle * 3.0 + phase) * 0.15 + sin(angle * 5.0 + phase * 1.7) * 0.07
			points.append(center + Vector2(cos(angle) * size.x, sin(angle) * size.y) * 0.5 * layer_scale * wobble)
		draw_colored_polygon(points, color)


## A crack in the cobbles with fire showing through: a dark scorched edge, a red seam and hot spots.
func _draw_seam(start: Vector2, random: RandomNumberGenerator) -> void:
	var points := PackedVector2Array([_snap(start)])
	var heading := random.randf() * TAU
	for _segment in random.randi_range(5, 9):
		heading += random.randf_range(-0.6, 0.6)
		points.append(_snap(points[-1] + Vector2(cos(heading), sin(heading) * 0.55) * random.randf_range(14, 30)))
	draw_polyline(points, SEAM_DARK, PIXEL * 3.0)
	draw_polyline(points, SEAM, PIXEL)
	for index in range(1, points.size() - 1, 2):
		draw_rect(Rect2(points[index] - Vector2.ONE * PIXEL * 0.5, Vector2.ONE * PIXEL), SEAM_HOT)
	# A short branch off the middle.
	var branch_start := points[points.size() / 2]
	var branch_heading := heading + (1.2 if random.randf() < 0.5 else -1.2)
	var branch_end := _snap(branch_start + Vector2(cos(branch_heading), sin(branch_heading) * 0.55) * random.randf_range(12, 22))
	draw_line(branch_start, branch_end, SEAM_DARK, PIXEL * 2.0)
	draw_line(branch_start, branch_end, SEAM, PIXEL)


func _draw_bone_chip(origin: Vector2, random: RandomNumberGenerator) -> void:
	var length := random.randi_range(2, 4)
	var vertical := random.randf() < 0.3
	var size := Vector2(1, length) if vertical else Vector2(length, 1)
	draw_rect(Rect2(origin + Vector2(0, PIXEL), size * PIXEL), BONE_SHADE)
	draw_rect(Rect2(origin, size * PIXEL), BONE)
