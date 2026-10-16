extends Node2D
class_name IceShockwave
## A ring of frost spreading over the ground and a spray of ice chips, for slams and eruptions.
## Purely cosmetic; frees itself when done.

const DURATION := 0.5
const CHIP_COUNT := 10
const RING_COLOR := Color(0.85, 0.96, 1.0, 0.85)
const FROST_COLOR := Color(0.62, 0.84, 0.98, 0.35)
const CHIP_COLORS: Array[Color] = [Color("#f2fbff"), Color("#bfe6fa"), Color("#8cc8ec")]

var radius := 100.0
var time := 0.0
var chips: Array[Vector2] = []


static func spawn(parent: Node, world_position: Vector2, ring_radius: float) -> IceShockwave:
	var wave := IceShockwave.new()
	wave.radius = ring_radius
	wave.position = world_position
	# Flat on the ground, under characters.
	wave.z_index = -3
	parent.add_child(wave)
	return wave


func _ready() -> void:
	for _chip in CHIP_COUNT:
		chips.append(Vector2.RIGHT.rotated(randf() * TAU) * randf_range(0.4, 1.0))


func _process(delta: float) -> void:
	time += delta
	if time >= DURATION:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var progress := time / DURATION
	var spread := radius * (0.25 + 0.75 * sqrt(progress))
	var fade := 1.0 - progress
	# Flattened for the top-down view.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5))
	draw_circle(Vector2.ZERO, spread, Color(FROST_COLOR, FROST_COLOR.a * fade))
	draw_arc(Vector2.ZERO, spread, 0.0, TAU, 40, Color(RING_COLOR, RING_COLOR.a * fade), 4.0 * fade + 1.0)
	draw_set_transform(Vector2.ZERO)
	for index in chips.size():
		var chip := chips[index]
		var lift := sin(progress * PI) * 26.0 * chip.length()
		var spot := Vector2(chip.x, chip.y * 0.5) * spread - Vector2(0.0, lift)
		var color := CHIP_COLORS[index % CHIP_COLORS.size()]
		draw_rect(Rect2(spot.round(), Vector2(4, 4)), Color(color, fade))
