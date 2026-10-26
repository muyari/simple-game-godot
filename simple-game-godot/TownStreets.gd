@tool
extends Node2D
class_name TownStreets
## Draws Oblath's streets smoothly at any resolution: paved streets merged into one network and painted by
## town_ground.gdshader as bricks, a round cobbled plaza, dirt lanes with soft grassy edges, and rounded
## kerb stones running round the true outline of the paving. Shapes are rectangles in world pixels.

const GROUND_SHADER = preload("res://town_ground.gdshader")
const KERB_OUTLINE := Color("#3a332d")
const KERB_STONE := Color("#a29a8d")
const KERB_STONE_ALT := Color("#b1a99b")
const KERB_LIGHT := Color("#d6cfc2")
const KERB_SHADE := Color("#7a7166")
const ROAD_SHADOW := Color(0.0, 0.05, 0.0, 0.16)
const DIRT_FRINGE := Color(0.33, 0.42, 0.18, 0.75)
const STONE_LENGTH := 20.0
const KERB_WIDTH := 9.0

@export var paved_rects: Array[Rect2] = []:
	set(value):
		paved_rects = value
		_rebuild()
@export var dirt_rects: Array[Rect2] = []:
	set(value):
		dirt_rects = value
		_rebuild()
@export var plaza_center := Vector2(576, 400):
	set(value):
		plaza_center = value
		_rebuild()
@export var plaza_radius := 175.0:
	set(value):
		plaza_radius = value
		_rebuild()
## Kept for scenes made before the streets were shader-painted; unused.
@export var road_texture: Texture2D
@export var plaza_texture: Texture2D
@export var wear_seed := 7

var _paved_outlines: Array = []
var _dirt_outlines: Array = []
var _layers: Node2D


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	if not is_inside_tree():
		return
	_paved_outlines = _merge(_rect_polygons(paved_rects) + [_circle(plaza_center, plaza_radius + KERB_WIDTH, 96)])
	_dirt_outlines = _merge(_rect_polygons(dirt_rects))
	if _layers != null:
		_layers.queue_free()
	_layers = Node2D.new()
	add_child(_layers, false, Node.INTERNAL_MODE_FRONT)
	for outline in _dirt_outlines:
		_layers.add_child(_painted(outline, 3))
	for outline in _paved_outlines:
		_layers.add_child(_painted(outline, 1))
	_layers.add_child(_painted(_circle(plaza_center, plaza_radius, 128), 2))
	var kerbs := Node2D.new()
	kerbs.draw.connect(_draw_kerbs.bind(kerbs))
	_layers.add_child(kerbs)
	queue_redraw()


func _painted(outline: PackedVector2Array, mode: int) -> Polygon2D:
	var polygon := Polygon2D.new()
	polygon.polygon = outline
	polygon.antialiased = true
	var material := ShaderMaterial.new()
	material.shader = GROUND_SHADER
	material.set_shader_parameter("mode", mode)
	material.set_shader_parameter("noise_texture", TownStreets.noise())
	polygon.material = material
	return polygon


static var _noise: NoiseTexture2D


## Seamless noise shared by the ground and street shaders.
static func noise() -> NoiseTexture2D:
	if _noise == null:
		var source := FastNoiseLite.new()
		source.seed = 12
		source.frequency = 0.02
		source.fractal_octaves = 3
		_noise = NoiseTexture2D.new()
		_noise.width = 256
		_noise.height = 256
		_noise.seamless = true
		_noise.noise = source
	return _noise


## Under the paving and dirt: a soft shadow below the kerbs and a grassy fringe round the lanes.
func _draw() -> void:
	for outline in _paved_outlines:
		var shifted := PackedVector2Array()
		for point in outline:
			shifted.append(point + Vector2(0, 5))
		draw_colored_polygon(shifted, ROAD_SHADOW)
	for outline in _dirt_outlines:
		var closed: PackedVector2Array = outline.duplicate()
		closed.append(outline[0])
		draw_polyline(closed, DIRT_FRINGE, 7.0, true)


func _draw_kerbs(canvas: Node2D) -> void:
	for outline in _paved_outlines:
		_draw_kerb_loop(canvas, outline)
	_draw_kerb_loop(canvas, _circle(plaza_center, plaza_radius + KERB_WIDTH * 0.5, 128))
	# A ring of pale stones round the fountain.
	canvas.draw_arc(plaza_center, plaza_radius * 0.48, 0.0, TAU, 96, Color(KERB_LIGHT, 0.7), 7.0, true)
	canvas.draw_arc(plaza_center, plaza_radius * 0.48 + 4.0, 0.0, TAU, 96, Color(KERB_SHADE, 0.6), 2.0, true)


## Rounded kerb stones laid along an outline, alternating shades, lit from above.
func _draw_kerb_loop(canvas: Node2D, points: PackedVector2Array) -> void:
	var closed := points.duplicate()
	closed.append(points[0])
	canvas.draw_polyline(closed, KERB_OUTLINE, KERB_WIDTH + 3.0, true)
	var stone_index := 0
	var carry := 0.0
	for index in points.size():
		var from: Vector2 = points[index]
		var to: Vector2 = points[(index + 1) % points.size()]
		var length := from.distance_to(to)
		if length < 0.5:
			continue
		var direction := (to - from) / length
		var travelled := -carry
		while travelled < length:
			var a := from + direction * maxf(travelled, 0.0)
			var b := from + direction * minf(travelled + STONE_LENGTH - 2.0, length)
			if a.distance_to(b) > 1.0:
				var stone := KERB_STONE if stone_index % 2 == 0 else KERB_STONE_ALT
				canvas.draw_line(a, b, stone, KERB_WIDTH - 1.0, true)
				canvas.draw_line(a + Vector2(0, -KERB_WIDTH * 0.28), b + Vector2(0, -KERB_WIDTH * 0.28), Color(KERB_LIGHT, 0.6), 2.0, true)
				canvas.draw_line(a + Vector2(0, KERB_WIDTH * 0.32), b + Vector2(0, KERB_WIDTH * 0.32), Color(KERB_SHADE, 0.6), 1.5, true)
			travelled += STONE_LENGTH
			stone_index += 1
		carry = travelled - length


func _rect_polygons(rects: Array[Rect2]) -> Array:
	var polygons := []
	for rect in rects:
		polygons.append(PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]))
	return polygons


## Unions a list of polygons into separate outlines (holes are dropped; streets don't enclose any).
func _merge(polygons: Array) -> Array:
	var merged: Array = []
	for polygon in polygons:
		var current: PackedVector2Array = polygon
		var index := 0
		while index < merged.size():
			if Geometry2D.intersect_polygons(current, merged[index]).is_empty():
				index += 1
				continue
			# Overlapping shapes merge into one outline (the largest result; any others are holes).
			var best: PackedVector2Array = current
			var best_area := 0.0
			for outline in Geometry2D.merge_polygons(current, merged[index]):
				var area := absf(_area(outline))
				if area > best_area:
					best_area = area
					best = outline
			current = best
			merged.remove_at(index)
			index = 0
		merged.append(current)
	return merged


func _area(points: PackedVector2Array) -> float:
	var total := 0.0
	for index in points.size():
		var a := points[index]
		var b := points[(index + 1) % points.size()]
		total += a.x * b.y - b.x * a.y
	return total * 0.5


func _circle(center: Vector2, radius: float, steps: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for step in steps:
		var angle := TAU * step / steps
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points
