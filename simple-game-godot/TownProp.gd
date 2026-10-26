extends Node2D
class_name TownProp
## Small pieces of village life, drawn smooth and softly lit like the HUD, standing on their node origin
## so they y-sort with everything else: lamp posts, benches, a well, a signpost, a scarecrow, hay bales and
## the notice board.

enum Kind { LAMP, BENCH, WELL, SIGNPOST, SCARECROW, HAY, NOTICE_BOARD }

const WOOD := Color("#8a5d33")
const WOOD_LIGHT := Color("#b48452")
const IRON := Color("#3d3936")
const GLASS := Color("#ffe3a3")
const STONE := Color("#a0988b")
const STONE_LIGHT := Color("#c8c0b2")
const WATER := Color("#2f6596")
const STRAW := Color("#ddb75e")
const STRAW_DARK := Color("#a8823a")
const CLOTH := Color("#9b4231")
const SACK := Color("#cdb88f")
const HAT := Color("#5e4932")
const OUTLINE := Color(0.13, 0.08, 0.05)

var kind := Kind.LAMP
## For signposts: which way the top arm points.
var flip := false
var time := 0.0
var phase := 0.0


func _ready() -> void:
	phase = randf() * TAU
	if kind == Kind.LAMP:
		FireGlow.attach(self, Vector2(9.0, -36.0), 80.0, Color("#ffcf7a"), 0.25)
	set_process(kind in [Kind.SCARECROW, Kind.LAMP])


func _process(delta: float) -> void:
	time += delta
	queue_redraw()


func _draw() -> void:
	match kind:
		Kind.LAMP:
			_draw_lamp()
		Kind.BENCH:
			_draw_bench()
		Kind.WELL:
			_draw_well()
		Kind.SIGNPOST:
			_draw_signpost()
		Kind.SCARECROW:
			_draw_scarecrow()
		Kind.HAY:
			_draw_hay()
		Kind.NOTICE_BOARD:
			_draw_notice_board()


func _draw_notice_board() -> void:
	SmoothDraw.shadow(self, Vector2(-3, 1), Vector2(54, 9))
	for post_x in [-23.0, 19.0]:
		SmoothDraw.box(self, Rect2(post_x, -58, 4, 58), WOOD.darkened(0.2), 2.0)
	# Board, a little shingled roof, and the notices pinned to it.
	SmoothDraw.box(self, Rect2(-26, -52, 52, 32), WOOD_LIGHT, 3.0)
	SmoothDraw.flat(self, Rect2(-23, -49, 46, 26), WOOD.lightened(0.05), 2.0)
	SmoothDraw.polygon(self, PackedVector2Array([Vector2(-31, -54), Vector2(-24, -64), Vector2(24, -64), Vector2(31, -54)]), CLOTH.darkened(0.15), OUTLINE, 2.0)
	draw_line(Vector2(-25, -62), Vector2(25, -62), Color(CLOTH.lightened(0.3), 0.6), 1.5, true)
	var papers := [Rect2(-20, -47, 13, 15), Rect2(-4, -48, 12, 11), Rect2(10, -46, 11, 17), Rect2(-3, -35, 10, 10)]
	for index in papers.size():
		var paper: Rect2 = papers[index]
		SmoothDraw.box(self, paper, SACK.lightened(0.25 if index % 2 == 0 else 0.1), 1.0, Color(OUTLINE, 0.7))
		for line in int(paper.size.y / 4.0) - 1:
			var y := paper.position.y + 3.5 + line * 3.5
			draw_line(Vector2(paper.position.x + 2, y), Vector2(paper.end.x - 2.5, y), Color(OUTLINE, 0.35), 1.0, true)
		draw_circle(Vector2(paper.get_center().x, paper.position.y + 1.5), 1.3, CLOTH, true, -1.0, true)


func _draw_lamp() -> void:
	SmoothDraw.shadow(self, Vector2(-3, 1), Vector2(18, 6))
	SmoothDraw.box(self, Rect2(-5, -5, 10, 5), STONE, 2.0)
	SmoothDraw.box(self, Rect2(-2, -42, 4, 38), IRON, 2.0)
	SmoothDraw.box(self, Rect2(-2, -45, 14, 3), IRON, 1.5)
	# The lantern sways a touch, its flame flickering.
	var sway := sin(time * 1.4 + phase) * 0.7
	var lantern := Rect2(5.0 + sway, -41.0, 9.0, 11.0)
	SmoothDraw.box(self, lantern, IRON, 2.0)
	var flicker := 0.85 + 0.15 * sin(time * 11.0 + phase)
	SmoothDraw.flat(self, lantern.grow(-1.8), GLASS * Color(1, 1, 1, flicker), 1.5)
	draw_circle(lantern.get_center(), 2.0, Color(1.0, 0.97, 0.85, flicker), true, -1.0, true)
	draw_colored_polygon(PackedVector2Array([lantern.position + Vector2(-1, 0), Vector2(lantern.get_center().x, lantern.position.y - 4.0), Vector2(lantern.end.x + 1, lantern.position.y)]), IRON)


func _draw_bench() -> void:
	SmoothDraw.shadow(self, Vector2(-2, 1), Vector2(50, 8))
	for leg_x in [-18.0, 15.0]:
		SmoothDraw.box(self, Rect2(leg_x, -11, 3, 11), WOOD.darkened(0.2), 1.0)
	SmoothDraw.box(self, Rect2(-21, -26, 42, 5), WOOD, 2.0)
	for post_x in [-19.0, 16.0]:
		SmoothDraw.box(self, Rect2(post_x, -26, 3, 14), WOOD.darkened(0.2), 1.0)
	SmoothDraw.box(self, Rect2(-22, -14, 44, 6), WOOD_LIGHT, 2.0)


func _draw_well() -> void:
	SmoothDraw.shadow(self, Vector2(-4, 2), Vector2(66, 16))
	# Stone drum with courses of blocks.
	var drum := Rect2(-24, -24, 48, 24)
	SmoothDraw.box(self, drum, STONE, 5.0)
	for row in [-16.0, -8.0]:
		draw_line(Vector2(drum.position.x + 3, row), Vector2(drum.end.x - 3, row), Color(STONE.darkened(0.3), 0.6), 1.0, true)
	for column in [-14.0, -2.0, 10.0]:
		var offset := 6.0 if column == -2.0 else 0.0
		draw_line(Vector2(column + offset, -24), Vector2(column + offset, -16), Color(STONE.darkened(0.3), 0.6), 1.0, true)
	# The rim and dark water seen from above.
	draw_set_transform(Vector2(0, -24), 0.0, Vector2(1.0, 0.36))
	draw_circle(Vector2.ZERO, 25.0, OUTLINE, true, -1.0, true)
	draw_circle(Vector2.ZERO, 23.5, STONE_LIGHT, true, -1.0, true)
	draw_circle(Vector2.ZERO, 17.0, WATER.darkened(0.45), true, -1.0, true)
	draw_circle(Vector2(-5, -4), 6.0, Color(WATER.lightened(0.3), 0.35), true, -1.0, true)
	draw_set_transform(Vector2.ZERO)
	# Posts, roof and bucket on its rope.
	for post_x in [-22.0, 18.0]:
		SmoothDraw.box(self, Rect2(post_x, -60, 4, 38), WOOD, 2.0)
	SmoothDraw.box(self, Rect2(-24, -62, 48, 4), WOOD.darkened(0.15), 2.0)
	SmoothDraw.polygon(self, PackedVector2Array([Vector2(-31, -59), Vector2(0, -80), Vector2(31, -59)]), CLOTH, OUTLINE, 2.0)
	draw_line(Vector2(-27, -61), Vector2(0, -77), Color(CLOTH.lightened(0.3), 0.7), 2.0, true)
	draw_line(Vector2(0, -58), Vector2(0, -42), OUTLINE, 1.0, true)
	SmoothDraw.box(self, Rect2(-4, -42, 8, 7), WOOD.darkened(0.2), 2.0)


func _draw_signpost() -> void:
	var direction := -1.0 if flip else 1.0
	SmoothDraw.shadow(self, Vector2(-2, 1), Vector2(16, 6))
	SmoothDraw.box(self, Rect2(-2, -48, 4, 48), WOOD.darkened(0.15), 2.0)
	for row in 2:
		var y := -45.0 + row * 14.0
		var arm := direction if row == 0 else -direction
		var points := PackedVector2Array([
			Vector2(-arm * 5.0, y), Vector2(arm * 20.0, y), Vector2(arm * 27.0, y + 4.5),
			Vector2(arm * 20.0, y + 9.0), Vector2(-arm * 5.0, y + 9.0),
		])
		SmoothDraw.polygon(self, points, WOOD_LIGHT, OUTLINE, 1.5)
		draw_line(Vector2(-arm * 3.0, y + 1.5), Vector2(arm * 19.0, y + 1.5), Color(WOOD_LIGHT.lightened(0.3), 0.7), 1.5, true)
		for mark in 3:
			var x := arm * (2.0 + mark * 5.0)
			draw_line(Vector2(x, y + 4.5), Vector2(x + arm * 3.0, y + 4.5), Color(OUTLINE, 0.6), 1.0, true)


func _draw_scarecrow() -> void:
	var sway := sin(time * 1.1 + phase) * 1.5
	SmoothDraw.shadow(self, Vector2(-3, 1), Vector2(26, 7))
	SmoothDraw.box(self, Rect2(-1.5, -50, 3, 50), WOOD.darkened(0.2), 1.5)
	SmoothDraw.box(self, Rect2(-23 + sway * 0.3, -41, 46, 3), WOOD.darkened(0.2), 1.5)
	for side in [-1.0, 1.0]:
		draw_circle(Vector2(side * 23.0 + sway * 0.3, -39.5), 3.5, STRAW, true, -1.0, true)
	SmoothDraw.box(self, Rect2(-9 + sway * 0.4, -43, 18, 21), CLOTH, 3.0)
	draw_line(Vector2(-9 + sway * 0.4, -30), Vector2(9 + sway * 0.4, -30), CLOTH.darkened(0.35), 2.0, true)
	draw_circle(Vector2(sway * 0.5, -19), 3.0, STRAW, true, -1.0, true)
	SmoothDraw.dome(self, Vector2(sway * 0.5, -48), 6.5, SACK)
	draw_circle(Vector2(-2.5 + sway * 0.5, -48), 1.1, OUTLINE, true, -1.0, true)
	draw_circle(Vector2(2.5 + sway * 0.5, -48), 1.1, OUTLINE, true, -1.0, true)
	SmoothDraw.box(self, Rect2(-10 + sway * 0.5, -55, 20, 3), HAT, 1.5)
	SmoothDraw.box(self, Rect2(-5 + sway * 0.5, -62, 10, 8), HAT, 2.5)


func _draw_hay() -> void:
	SmoothDraw.shadow(self, Vector2(-3, 1), Vector2(40, 8))
	SmoothDraw.box(self, Rect2(-16, -19, 32, 19), STRAW, 4.0)
	for row in [-13.0, -7.0]:
		draw_line(Vector2(-14, row), Vector2(14, row), Color(STRAW_DARK, 0.6), 1.0, true)
	for column in [-8.0, 7.0]:
		SmoothDraw.flat(self, Rect2(column, -19, 2, 19), Color("#7a5a2a"), 1.0)
	for index in 5:
		var x := -12.0 + index * 6.0
		draw_line(Vector2(x, -19), Vector2(x - 1.5, -22), Color(STRAW.lightened(0.15), 0.9), 1.0, true)
