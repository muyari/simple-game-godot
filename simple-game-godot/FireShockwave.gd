extends Node2D
class_name FireShockwave
## A ring of fire rolling over the ground with a spray of embers, for slams, bursts and deaths.
## Purely cosmetic; frees itself when done.

const DURATION := 0.55
const EMBER_COUNT := 12
const RING_COLOR := Color(1.0, 0.62, 0.22, 0.9)
const SCORCH_COLOR := Color(0.95, 0.3, 0.08, 0.32)
const EMBER_COLORS: Array[Color] = [Color("#fff1a8"), Color("#ffb347"), Color("#ff6a1f")]

var radius := 100.0
var time := 0.0
var embers: Array[Vector2] = []


static func spawn(parent: Node, world_position: Vector2, ring_radius: float) -> FireShockwave:
	Audio.play_sfx_at("eruption", world_position, -3.0)
	var wave := FireShockwave.new()
	wave.radius = ring_radius
	wave.position = world_position
	# Flat on the ground, under characters.
	wave.z_index = -3
	parent.add_child(wave)
	return wave


func _ready() -> void:
	for _index in EMBER_COUNT:
		var angle := randf() * TAU
		embers.append(Vector2(cos(angle), sin(angle) * 0.55) * randf_range(0.35, 1.0))


func _process(delta: float) -> void:
	time += delta
	if time >= DURATION:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var progress := time / DURATION
	var fade := 1.0 - progress
	var reach := radius * (0.3 + 0.7 * sqrt(progress))
	# Flattened for the top-down view.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.55))
	draw_circle(Vector2.ZERO, reach, Color(SCORCH_COLOR, SCORCH_COLOR.a * fade))
	draw_arc(Vector2.ZERO, reach, 0.0, TAU, 40, Color(RING_COLOR, RING_COLOR.a * fade), 4.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for index in embers.size():
		var ember := embers[index] * reach
		# Embers fly out and float up as they cool.
		var rise := Vector2(0.0, -26.0 * progress)
		draw_rect(Rect2(ember + rise - Vector2.ONE * 1.5, Vector2.ONE * 3.0), Color(EMBER_COLORS[index % 3], fade))
