extends Node2D
class_name LavaPool
## A pool of molten rock set into the ground: a dark crust rim, glowing lava with slowly drifting bright
## veins and the odd bubble. Burns the player while they stand in it; monsters don't mind.

const TICK := 0.5
const TICK_DAMAGE := 5
const CRUST := Color("#2a1416")
const CRUST_EDGE := Color("#5c2414")
const LAVA := Color("#a82612")
const LAVA_HOT := Color("#e2541c")
const LAVA_CORE := Color("#ffb347")

var seed_value := 0
## Half width and half height of the pool, in world pixels.
var half_size := Vector2(70.0, 34.0)
var time := 0.0
var burn_timer := 0.0
var shape: PackedVector2Array
var veins: Array[PackedVector2Array] = []
var bubbles: Array[Vector3] = []


func _ready() -> void:
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	shape = _blob(Vector2.ONE, random.randf() * TAU, 0.16)
	for _vein in random.randi_range(2, 4):
		var line := PackedVector2Array()
		var point := Vector2(random.randf_range(-0.5, 0.5) * half_size.x, random.randf_range(-0.4, 0.4) * half_size.y)
		var heading := random.randf() * TAU
		for _segment in random.randi_range(3, 5):
			line.append(point)
			heading += random.randf_range(-0.8, 0.8)
			point += Vector2(cos(heading), sin(heading) * 0.5) * random.randf_range(8.0, 18.0)
		veins.append(line)
	for _bubble in random.randi_range(2, 4):
		bubbles.append(Vector3(
			random.randf_range(-0.55, 0.55) * half_size.x,
			random.randf_range(-0.45, 0.45) * half_size.y,
			random.randf() * 3.0
		))
	FireGlow.attach(self, Vector2.ZERO, half_size.x * 2.6, Color("#ff4e12"), 0.55)


func _blob(scale_factor: Vector2, phase: float, wobble: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for step in 28:
		var angle := TAU * step / 28.0
		var bump := 1.0 + sin(angle * 3.0 + phase) * wobble + sin(angle * 5.0 + phase * 1.6) * wobble * 0.5
		points.append(Vector2(cos(angle) * half_size.x, sin(angle) * half_size.y) * scale_factor * bump)
	return points


func _process(delta: float) -> void:
	time += delta
	_burn_player(delta)
	queue_redraw()


func _burn_player(delta: float) -> void:
	burn_timer = maxf(burn_timer - delta, 0.0)
	if burn_timer > 0.0:
		return
	var player := get_tree().current_scene.get_node_or_null("Player") as Player
	if player == null or player.health <= 0:
		return
	var offset := player.global_position - global_position
	# Only the molten middle burns; the crust rim is safe to step on.
	if Vector2(offset.x / (half_size.x * 0.82), offset.y / (half_size.y * 0.82)).length() > 1.0:
		return
	burn_timer = TICK
	player.take_damage(TICK_DAMAGE)
	FireShockwave.spawn(get_parent(), player.global_position, 18.0)


func _draw() -> void:
	var outer := PackedVector2Array()
	for point in shape:
		outer.append(point * 1.14)
	draw_colored_polygon(outer, CRUST)
	var rim := PackedVector2Array()
	for point in shape:
		rim.append(point * 1.04)
	draw_colored_polygon(rim, CRUST_EDGE)
	draw_colored_polygon(shape, LAVA)
	var inner := PackedVector2Array()
	var pulse := 0.55 + sin(time * 1.7) * 0.05
	for point in shape:
		inner.append(point * pulse + Vector2(4.0, 2.0))
	draw_colored_polygon(inner, LAVA_HOT)
	# Bright veins drifting across the surface.
	var drift := Vector2(sin(time * 0.4) * 3.0, cos(time * 0.3) * 1.5)
	for vein in veins:
		var moved := PackedVector2Array()
		for point in vein:
			moved.append(point + drift)
		draw_polyline(moved, LAVA_CORE, 2.0)
	for bubble in bubbles:
		var cycle := fmod(time + bubble.z, 3.0) / 3.0
		if cycle < 0.7:
			continue
		var grow := (cycle - 0.7) / 0.3
		draw_arc(Vector2(bubble.x, bubble.y), 2.0 + grow * 4.0, 0.0, TAU, 12, Color(LAVA_CORE, 1.0 - grow), 2.0)
