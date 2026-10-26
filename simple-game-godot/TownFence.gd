@tool
extends Node2D
class_name TownFence
## Draws a run of Oblath's wooden fence round `fence_rect` (world pixels), smooth and softly lit, with
## closed double gates between stone pillars where streets meet it. Each side can be switched off, so the
## south run can live on its own node and y-sort in front of the player while the rest sits behind.

const WOOD := Color("#8a5d33")
const WOOD_DARK := Color("#5e3d22")
const STONE := Color("#a0988b")
const STONE_CAP := Color("#c4bcae")
const IRON := Color("#3d3936")
const GROUND_SHADOW := Color(0.02, 0.08, 0.02, 0.22)

const POST_SPACING := 48.0
const POST_WIDTH := 8.0
const POST_HEIGHT := 28.0
const CORNER_POST_WIDTH := 12.0
const CORNER_POST_HEIGHT := 34.0
const RAIL_THICKNESS := 5.0
const UPPER_RAIL_HEIGHT := 18.0
const LOWER_RAIL_HEIGHT := 7.0
const GATE_WIDTH := 104.0
const GATE_PILLAR := Vector2(18.0, 46.0)

@export var fence_rect := Rect2(-560, -420, 2272, 1600):
	set(value):
		fence_rect = value
		queue_redraw()
@export var draw_top := true
@export var draw_bottom := true
@export var draw_sides := true
## Gate centres: x along the top/bottom runs, y along the left/right runs.
@export var top_gates: Array[float] = []
@export var bottom_gates: Array[float] = []
@export var left_gates: Array[float] = []
@export var right_gates: Array[float] = []


func _draw() -> void:
	# Draw in world coordinates whatever this node's position is (it only sets the sort depth).
	draw_set_transform(-position)
	var left := fence_rect.position.x
	var right := fence_rect.end.x
	var top := fence_rect.position.y
	var bottom := fence_rect.end.y
	if draw_sides:
		_draw_vertical_side(left, top, bottom, left_gates)
		_draw_vertical_side(right, top, bottom, right_gates)
	if draw_top:
		_draw_horizontal_side(top, left, right, top_gates)
	if draw_bottom:
		_draw_horizontal_side(bottom, left, right, bottom_gates)
	var corners: Array[Vector2] = []
	if draw_top:
		corners.append_array([Vector2(left, top), Vector2(right, top)])
	if draw_bottom:
		corners.append_array([Vector2(left, bottom), Vector2(right, bottom)])
	for corner in corners:
		_draw_post(corner, CORNER_POST_WIDTH, CORNER_POST_HEIGHT, 0)


## A side broken into runs around its gates.
func _draw_horizontal_side(ground_y: float, start_x: float, end_x: float, gates: Array[float]) -> void:
	var cursor := start_x
	var sorted := gates.duplicate()
	sorted.sort()
	for gate_x in sorted:
		_draw_horizontal_run(ground_y, cursor, gate_x - GATE_WIDTH * 0.5)
		_draw_gate(Vector2(gate_x, ground_y))
		cursor = gate_x + GATE_WIDTH * 0.5
	_draw_horizontal_run(ground_y, cursor, end_x)


func _draw_vertical_side(x: float, start_y: float, end_y: float, gates: Array[float]) -> void:
	var cursor := start_y
	var sorted := gates.duplicate()
	sorted.sort()
	for gate_y in sorted:
		_draw_vertical_run(x, cursor, gate_y - GATE_WIDTH * 0.35)
		_draw_side_gate(Vector2(x, gate_y))
		cursor = gate_y + GATE_WIDTH * 0.35
	_draw_vertical_run(x, cursor, end_y)


func _draw_horizontal_run(ground_y: float, start_x: float, end_x: float) -> void:
	if end_x - start_x < 4.0:
		return
	SmoothDraw.flat(self, Rect2(start_x, ground_y, end_x - start_x, 6.0), GROUND_SHADOW, 3.0)
	_draw_rail(Rect2(start_x, ground_y - UPPER_RAIL_HEIGHT - RAIL_THICKNESS * 0.5, end_x - start_x, RAIL_THICKNESS))
	_draw_rail(Rect2(start_x, ground_y - LOWER_RAIL_HEIGHT - RAIL_THICKNESS * 0.5, end_x - start_x, RAIL_THICKNESS))
	var x := start_x + POST_SPACING
	while x < end_x - 1.0:
		_draw_post(Vector2(x, ground_y), POST_WIDTH, POST_HEIGHT, int(x))
		x += POST_SPACING


func _draw_vertical_run(x: float, start_y: float, end_y: float) -> void:
	if end_y - start_y < 4.0:
		return
	SmoothDraw.flat(self, Rect2(x + 2.0, start_y, 5.0, end_y - start_y), GROUND_SHADOW, 2.5)
	_draw_rail(Rect2(x - RAIL_THICKNESS * 0.5, start_y - UPPER_RAIL_HEIGHT, RAIL_THICKNESS, end_y - start_y))
	var y := start_y + POST_SPACING
	while y < end_y - 1.0:
		_draw_post(Vector2(x, y), POST_WIDTH, POST_HEIGHT, int(y) * 7)
		y += POST_SPACING


func _draw_post(base: Vector2, width: float, height: float, seed_value: int) -> void:
	# Small deterministic variation so the fence doesn't look stamped.
	var variation := posmod(seed_value * 2654435761, 97)
	var post_height := height - float(variation % 3)
	var tint := 0.94 + float(variation % 5) * 0.03
	SmoothDraw.shadow(self, base + Vector2(-2.0, 1.0), Vector2(width * 2.2, 6.0), 0.5)
	SmoothDraw.box(self, Rect2(base.x - width * 0.5, base.y - post_height, width, post_height), WOOD * tint, 2.5)
	# A rounded cap.
	draw_circle(Vector2(base.x, base.y - post_height + 1.0), width * 0.5, (WOOD * tint).lightened(0.2), true, -1.0, true)


func _draw_rail(rect: Rect2) -> void:
	SmoothDraw.box(self, rect, WOOD, 2.5)


## Stone pillars either side of a pair of closed plank doors, seen from the front.
func _draw_gate(base: Vector2) -> void:
	var half := GATE_WIDTH * 0.5
	var door_width := half - GATE_PILLAR.x
	for side in [-1.0, 1.0]:
		var door := Rect2(base.x + (0.5 if side > 0.0 else -door_width - 0.5), base.y - 40.0, door_width, 38.0)
		SmoothDraw.shadow(self, Vector2(door.get_center().x, base.y), Vector2(door_width + 6.0, 7.0), 0.4)
		SmoothDraw.box(self, door, WOOD, 2.0)
		var plank := door.position.x + 7.0
		while plank < door.end.x - 3.0:
			draw_line(Vector2(plank, door.position.y + 2.0), Vector2(plank, door.end.y - 2.0), Color(WOOD_DARK, 0.7), 1.0, true)
			plank += 7.0
		for strap_y in [door.position.y + 8.0, door.end.y - 10.0]:
			SmoothDraw.flat(self, Rect2(door.position.x + 1.0, strap_y, door.size.x - 2.0, 3.0), IRON, 1.0)
		draw_arc(Vector2(base.x + side * 7.0, base.y - 20.0), 3.0, 0.0, TAU, 16, IRON, 1.5, true)
	for side in [-1.0, 1.0]:
		_draw_pillar(base + Vector2(side * (half - GATE_PILLAR.x * 0.5), 0.0))


## A gate seen side-on on the east and west runs: two pillars and the edge of the doors between them.
func _draw_side_gate(base: Vector2) -> void:
	var half := GATE_WIDTH * 0.35
	_draw_pillar(base + Vector2(0.0, -half))
	SmoothDraw.box(self, Rect2(base.x - 3.0, base.y - half - 30.0, 6.0, half * 2.0), WOOD, 2.0)
	_draw_pillar(base + Vector2(0.0, half))


func _draw_pillar(base: Vector2) -> void:
	SmoothDraw.shadow(self, base + Vector2(-3.0, 1.0), Vector2(GATE_PILLAR.x * 2.0, 9.0), 0.55)
	var body := Rect2(base.x - GATE_PILLAR.x * 0.5, base.y - GATE_PILLAR.y, GATE_PILLAR.x, GATE_PILLAR.y)
	SmoothDraw.box(self, body, STONE, 3.0)
	for row in range(1, 4):
		var y := body.position.y + row * 11.0
		draw_line(Vector2(body.position.x + 2.0, y), Vector2(body.end.x - 2.0, y), Color(STONE.darkened(0.3), 0.7), 1.0, true)
	SmoothDraw.box(self, Rect2(body.position.x - 3.0, body.position.y - 7.0, body.size.x + 6.0, 8.0), STONE_CAP, 3.0)
