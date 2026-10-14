extends Node2D

const MAP_SIZE := Vector2(1152.0, 768.0)
const FENCE_INSET := 30.0
const POST_SPACING := 48.0

const OUTLINE := Color("#2a1a10")
const WOOD_DARK := Color("#5c3b22")
const WOOD := Color("#84582f")
const WOOD_LIGHT := Color("#b07d48")
const WOOD_HIGHLIGHT := Color("#d6a96a")
const GROUND_SHADOW := Color(0.0, 0.0, 0.0, 0.2)

const POST_WIDTH := 8.0
const POST_HEIGHT := 28.0
const CORNER_POST_WIDTH := 12.0
const CORNER_POST_HEIGHT := 34.0
const RAIL_THICKNESS := 5.0
const UPPER_RAIL_HEIGHT := 18.0
const LOWER_RAIL_HEIGHT := 7.0


func _draw() -> void:
	var fence_rect := Rect2(
		Vector2(FENCE_INSET, FENCE_INSET),
		MAP_SIZE - Vector2(FENCE_INSET * 2.0, FENCE_INSET * 2.0)
	)
	var left := fence_rect.position.x
	var right := fence_rect.end.x
	var top := fence_rect.position.y
	var bottom := fence_rect.end.y

	# Side runs first so the top and bottom runs overlap them at the corners.
	_draw_vertical_run(left, top, bottom)
	_draw_vertical_run(right, top, bottom)
	_draw_horizontal_run(top, left, right)
	_draw_horizontal_run(bottom, left, right)

	for corner in [Vector2(left, top), Vector2(right, top), Vector2(left, bottom), Vector2(right, bottom)]:
		_draw_post(corner, CORNER_POST_WIDTH, CORNER_POST_HEIGHT, 0)


func _draw_horizontal_run(ground_y: float, start_x: float, end_x: float) -> void:
	draw_rect(Rect2(start_x, ground_y + 2.0, end_x - start_x, 5.0), GROUND_SHADOW)

	var x := start_x + POST_SPACING
	while x < end_x - 1.0:
		_draw_post(Vector2(x, ground_y), POST_WIDTH, POST_HEIGHT, int(x))
		x += POST_SPACING

	_draw_horizontal_rail(start_x, end_x, ground_y - UPPER_RAIL_HEIGHT)
	_draw_horizontal_rail(start_x, end_x, ground_y - LOWER_RAIL_HEIGHT)


func _draw_vertical_run(x: float, start_y: float, end_y: float) -> void:
	draw_rect(Rect2(x + 4.0, start_y, 4.0, end_y - start_y), GROUND_SHADOW)
	_draw_vertical_rail(x, start_y - UPPER_RAIL_HEIGHT, end_y - UPPER_RAIL_HEIGHT)

	var y := start_y + POST_SPACING
	while y < end_y - 1.0:
		_draw_post(Vector2(x, y), POST_WIDTH, POST_HEIGHT, int(y) * 7)
		y += POST_SPACING


func _draw_post(base: Vector2, width: float, height: float, seed_value: int) -> void:
	# Small deterministic variation so the fence doesn't look stamped.
	var variation := posmod(seed_value * 2654435761, 97)
	var post_height := height - float(variation % 3)
	var tint := 0.94 + float(variation % 5) * 0.03
	var body := Rect2(roundf(base.x - width * 0.5), base.y - post_height, width, post_height)

	draw_rect(Rect2(body.position.x - 1.0, body.end.y - 1.0, width + 4.0, 3.0), GROUND_SHADOW)
	draw_rect(body.grow(1.0), OUTLINE)
	draw_rect(body, WOOD * tint)
	draw_rect(Rect2(body.position, Vector2(2.0, body.size.y)), WOOD_LIGHT * tint)
	draw_rect(Rect2(body.end.x - 2.0, body.position.y, 2.0, body.size.y), WOOD_DARK)
	# Bevelled cap.
	draw_rect(Rect2(body.position, Vector2(width, 3.0)), WOOD_HIGHLIGHT * tint)
	draw_rect(Rect2(body.position.x, body.position.y + 3.0, width, 1.0), WOOD_DARK)
	# Grain and the odd knot.
	draw_rect(Rect2(body.position.x + 3.0, body.position.y + 8.0 + float(variation % 6), 1.0, 6.0), WOOD_DARK)
	if variation % 4 == 0:
		draw_rect(Rect2(body.position.x + 4.0, body.end.y - 9.0, 2.0, 2.0), WOOD_DARK)


func _draw_horizontal_rail(start_x: float, end_x: float, center_y: float) -> void:
	var rail := Rect2(start_x, roundf(center_y - RAIL_THICKNESS * 0.5), end_x - start_x, RAIL_THICKNESS)
	draw_rect(rail.grow(1.0), OUTLINE)
	draw_rect(rail, WOOD)
	draw_rect(Rect2(rail.position, Vector2(rail.size.x, 1.0)), WOOD_HIGHLIGHT)
	draw_rect(Rect2(rail.position.x, rail.end.y - 1.0, rail.size.x, 1.0), WOOD_DARK)
	var grain_x := start_x + 11.0
	while grain_x < end_x - 8.0:
		draw_rect(Rect2(grain_x, rail.position.y + 2.0, 5.0, 1.0), WOOD_DARK)
		grain_x += 29.0


func _draw_vertical_rail(x: float, start_y: float, end_y: float) -> void:
	var rail := Rect2(roundf(x - RAIL_THICKNESS * 0.5), start_y, RAIL_THICKNESS, end_y - start_y)
	draw_rect(rail.grow(1.0), OUTLINE)
	draw_rect(rail, WOOD)
	draw_rect(Rect2(rail.position, Vector2(1.0, rail.size.y)), WOOD_HIGHLIGHT)
	draw_rect(Rect2(rail.end.x - 1.0, rail.position.y, 1.0, rail.size.y), WOOD_DARK)
	var grain_y := start_y + 13.0
	while grain_y < end_y - 8.0:
		draw_rect(Rect2(rail.position.x + 2.0, grain_y, 1.0, 5.0), WOOD_DARK)
		grain_y += 31.0
