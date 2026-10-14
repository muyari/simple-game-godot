@tool
extends Node2D
## Draws the town's main road, its stone kerb, wear details and the fountain plaza.

const KERB_OUTLINE := Color("#36302b")
const KERB_STONE := Color("#8f877c")
const KERB_STONE_ALT := Color("#9b9286")
const KERB_LIGHT := Color("#bcb3a4")
const KERB_SHADE := Color("#6a6259")
const ROAD_SHADOW := Color(0.0, 0.0, 0.0, 0.18)
const GRIME := Color(0.18, 0.13, 0.09, 0.12)
const WORN_LIGHT := Color(1.18, 1.14, 1.08, 0.55)
const WORN_DARK := Color(0.8, 0.76, 0.72, 0.5)
const STONE_LENGTH := 18.0
const CORNER_SEGMENTS := 10

@export var road_rect := Rect2(48, 284, 1056, 232):
	set(value):
		road_rect = value
		queue_redraw()
@export var corner_radius := 36.0:
	set(value):
		corner_radius = value
		queue_redraw()
@export var kerb_width := 10.0:
	set(value):
		kerb_width = value
		queue_redraw()
@export var plaza_center := Vector2(576, 400):
	set(value):
		plaza_center = value
		queue_redraw()
@export var plaza_radius := 95.0:
	set(value):
		plaza_radius = value
		queue_redraw()
@export var road_texture: Texture2D:
	set(value):
		road_texture = value
		queue_redraw()
@export var plaza_texture: Texture2D:
	set(value):
		plaza_texture = value
		queue_redraw()
@export var wear_seed := 7:
	set(value):
		wear_seed = value
		queue_redraw()


func _draw() -> void:
	var road_outline := _rounded_rect(road_rect, corner_radius)
	_draw_textured(road_outline, road_texture)
	_draw_wear()
	_draw_kerb(road_rect.grow(-kerb_width * 0.5), corner_radius - kerb_width * 0.5, true)

	var plaza_outline := _circle(plaza_center, plaza_radius, 48)
	_draw_textured(plaza_outline, plaza_texture)
	_draw_kerb_loop(_circle(plaza_center, plaza_radius + kerb_width * 0.5, 64), true)


func _draw_textured(points: PackedVector2Array, texture: Texture2D) -> void:
	if texture == null:
		draw_colored_polygon(points, Color("#7b7067"))
		return
	var uvs := PackedVector2Array()
	for point in points:
		uvs.append(point / texture.get_size())
	draw_colored_polygon(points, Color.WHITE, uvs, texture)


func _draw_wear() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = wear_seed
	var inner := road_rect.grow(-kerb_width - 14.0)
	for index in 9:
		var center := Vector2(
			rng.randf_range(inner.position.x, inner.end.x),
			rng.randf_range(inner.position.y, inner.end.y)
		)
		# Keep the plaza clear; it already has its own paving.
		if center.distance_to(plaza_center) < plaza_radius + 40.0:
			continue
		var blob := _blob(center, Vector2(rng.randf_range(28.0, 52.0), rng.randf_range(14.0, 24.0)), rng)
		if index % 3 == 0 or road_texture == null:
			draw_colored_polygon(blob, GRIME)
		else:
			# Faded or darkened bricks, re-using the road texture so the pattern lines up.
			var uvs := PackedVector2Array()
			for point in blob:
				uvs.append(point / road_texture.get_size())
			draw_colored_polygon(blob, WORN_LIGHT if index % 2 == 0 else WORN_DARK, uvs, road_texture)


func _draw_kerb(rect: Rect2, radius: float, shadow_inside: bool) -> void:
	_draw_kerb_loop(_rounded_rect(rect, radius), shadow_inside)


func _draw_kerb_loop(centerline: PackedVector2Array, shadow_inside: bool) -> void:
	var closed := centerline.duplicate()
	closed.append(centerline[0])
	var half := kerb_width * 0.5
	if shadow_inside:
		draw_polyline(_offset(closed, -half - 2.0), ROAD_SHADOW, 4.0)
	draw_polyline(closed, KERB_OUTLINE, kerb_width + 2.0)

	# Individual stones, alternating tint, separated by dark joints.
	var stones := _resample(closed, STONE_LENGTH)
	for index in stones.size() - 1:
		var tint := KERB_STONE if index % 2 == 0 else KERB_STONE_ALT
		draw_line(stones[index], stones[index + 1], tint, kerb_width - 2.0)
	draw_polyline(_offset(closed, half - 2.0), KERB_LIGHT, 2.0)
	draw_polyline(_offset(closed, -half + 2.0), KERB_SHADE, 2.0)
	for index in stones.size() - 1:
		var direction := (stones[index + 1] - stones[index]).normalized()
		var normal := Vector2(-direction.y, direction.x)
		draw_line(stones[index] - normal * (half - 1.0), stones[index] + normal * (half - 1.0), KERB_OUTLINE, 1.0)


func _rounded_rect(rect: Rect2, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var corners := [
		[Vector2(rect.end.x - radius, rect.position.y + radius), -PI / 2.0],
		[Vector2(rect.end.x - radius, rect.end.y - radius), 0.0],
		[Vector2(rect.position.x + radius, rect.end.y - radius), PI / 2.0],
		[Vector2(rect.position.x + radius, rect.position.y + radius), PI],
	]
	for corner in corners:
		for step in CORNER_SEGMENTS + 1:
			var angle: float = corner[1] + PI / 2.0 * step / CORNER_SEGMENTS
			points.append(corner[0] + Vector2.from_angle(angle) * radius)
	return points


func _circle(center: Vector2, radius: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for step in segments:
		points.append(center + Vector2.from_angle(TAU * step / segments) * radius)
	return points


func _blob(center: Vector2, radii: Vector2, rng: RandomNumberGenerator) -> PackedVector2Array:
	var points := PackedVector2Array()
	for step in 10:
		var angle := TAU * step / 10.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y) * rng.randf_range(0.75, 1.0))
	return points


## Shifts a clockwise closed polyline outward (positive) or inward (negative).
func _offset(points: PackedVector2Array, distance: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	var count := points.size() - 1
	for index in count:
		var previous := points[(index - 1 + count) % count]
		var next := points[(index + 1) % count]
		var tangent := (next - previous).normalized()
		result.append(points[index] + Vector2(-tangent.y, tangent.x) * -distance)
	result.append(result[0])
	return result


func _resample(points: PackedVector2Array, spacing: float) -> PackedVector2Array:
	var result := PackedVector2Array([points[0]])
	var carried := 0.0
	for index in points.size() - 1:
		var start := points[index]
		var segment := points[index + 1] - start
		var length := segment.length()
		var travelled := spacing - carried
		while travelled <= length:
			result.append(start + segment * (travelled / length))
			travelled += spacing
		carried = length - (travelled - spacing)
	result.append(points[points.size() - 1])
	return result
