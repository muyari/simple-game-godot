extends Node2D

const MAP_SIZE := Vector2(1152.0, 768.0)
const FENCE_INSET := 30.0
const POST_SPACING := 48.0


func _draw() -> void:
	var fence_rect := Rect2(
		Vector2(FENCE_INSET, FENCE_INSET),
		MAP_SIZE - Vector2(FENCE_INSET * 2.0, FENCE_INSET * 2.0)
	)
	var rail_color := Color("#573e28")
	var rail_highlight := Color("#a37a49")
	var post_color := Color("#795632")
	var post_highlight := Color("#bd9560")
	var post_size := 9.0
	var rail_height := 7.0

	_draw_horizontal_rail(fence_rect.position.x, fence_rect.end.x, fence_rect.position.y, rail_color, rail_highlight, rail_height)
	_draw_horizontal_rail(fence_rect.position.x, fence_rect.end.x, fence_rect.end.y, rail_color, rail_highlight, rail_height)
	_draw_vertical_rail(fence_rect.position.y, fence_rect.end.y, fence_rect.position.x, rail_color, rail_highlight, rail_height)
	_draw_vertical_rail(fence_rect.position.y, fence_rect.end.y, fence_rect.end.x, rail_color, rail_highlight, rail_height)

	var x := fence_rect.position.x
	while x <= fence_rect.end.x:
		_draw_post(Vector2(x, fence_rect.position.y), post_size, post_color, post_highlight)
		_draw_post(Vector2(x, fence_rect.end.y), post_size, post_color, post_highlight)
		x += POST_SPACING

	var y := fence_rect.position.y + POST_SPACING
	while y < fence_rect.end.y:
		_draw_post(Vector2(fence_rect.position.x, y), post_size, post_color, post_highlight)
		_draw_post(Vector2(fence_rect.end.x, y), post_size, post_color, post_highlight)
		y += POST_SPACING


func _draw_horizontal_rail(
	start_x: float,
	end_x: float,
	y: float,
	rail_color: Color,
	highlight_color: Color,
	rail_height: float
) -> void:
	draw_rect(Rect2(start_x, y - rail_height * 0.5, end_x - start_x, rail_height), rail_color)
	draw_line(Vector2(start_x, y - rail_height * 0.5 + 1.0), Vector2(end_x, y - rail_height * 0.5 + 1.0), highlight_color, 1.5)


func _draw_vertical_rail(
	start_y: float,
	end_y: float,
	x: float,
	rail_color: Color,
	highlight_color: Color,
	rail_height: float
) -> void:
	draw_rect(Rect2(x - rail_height * 0.5, start_y, rail_height, end_y - start_y), rail_color)
	draw_line(Vector2(x - rail_height * 0.5 + 1.0, start_y), Vector2(x - rail_height * 0.5 + 1.0, end_y), highlight_color, 1.5)


func _draw_post(post_position: Vector2, post_size: float, post_color: Color, highlight_color: Color) -> void:
	draw_rect(Rect2(post_position - Vector2(post_size * 0.5, 15.0), Vector2(post_size, 30.0)), post_color)
	draw_rect(Rect2(post_position - Vector2(post_size * 0.5, 15.0), Vector2(2.0, 30.0)), highlight_color)
	draw_rect(Rect2(post_position - Vector2(post_size * 0.5 + 1.0, 15.0), Vector2(post_size + 2.0, 4.0)), highlight_color)
