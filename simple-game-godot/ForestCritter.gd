extends Node2D
class_name ForestCritter
## Small ambient forest life drawn as pixel art: butterflies that flutter around a spot and
## rabbits that nibble, hop about and bolt when the player comes close. Purely cosmetic.

enum Kind { BUTTERFLY, RABBIT }

const PIXEL := 2.0
const OUTLINE := Color("#2b1d14")
const SHADOW := Color(0, 0, 0, 0.16)
const BUTTERFLY_COLORS: Array[Color] = [Color("#f0a030"), Color("#7cc6f2"), Color("#f4efe0"), Color("#e9d24a")]
const RABBIT_BODY := Color("#9b7650")
const RABBIT_LIGHT := Color("#d8c19c")
const RABBIT_TAIL := Color("#f3ede1")
const RABBIT_EAR := Color("#d99a92")
const RABBIT_EYE := Color("#140c08")
## Side view facing right. o outline, b body, l belly, w tail, p inner ear, e eye, n nose.
const RABBIT := [
	".......oo.....",
	"......opbo....",
	"......opbooo..",
	".......obbbbo.",
	"...oooobbbebo.",
	".oobbbbbbbbbno",
	"owbbbbbbbbbbo.",
	"owbbbbbbbllo..",
	"obbbbbbbblo...",
	".obbbbbbbbo...",
	"..oooooo.oo...",
]
const FLEE_DISTANCE := 130.0
const HOP_DURATION := 0.32
const HOP_HEIGHT := 9.0

var kind := Kind.BUTTERFLY
var player: Node2D
var time := 0.0
var home := Vector2.ZERO
var phase := 0.0
var wing_color := Color.WHITE

var hop_from := Vector2.ZERO
var hop_to := Vector2.ZERO
var hop_progress := 1.0
var hops_left := 0
var idle_timer := 0.0
var facing_right := true
var lift := 0.0


func _ready() -> void:
	phase = randf() * TAU
	home = position
	if kind == Kind.BUTTERFLY:
		wing_color = BUTTERFLY_COLORS[randi() % BUTTERFLY_COLORS.size()]
		# Butterflies fly above the undergrowth and tree trunks.
		z_index = 3
	else:
		idle_timer = randf_range(1.0, 3.0)
		facing_right = randf() < 0.5


func _process(delta: float) -> void:
	time += delta
	if kind == Kind.BUTTERFLY:
		_update_butterfly(delta)
	else:
		_update_rabbit(delta)
	queue_redraw()


func _update_butterfly(delta: float) -> void:
	# Wander a looping path around a slowly drifting home point.
	home += Vector2(cos(phase + time * 0.11), sin(phase * 1.7 + time * 0.07)) * 9.0 * delta
	position = home + Vector2(sin(time * 0.8 + phase) * 46.0, sin(time * 1.3 + phase * 2.0) * 22.0)
	lift = 22.0 + sin(time * 2.1 + phase) * 5.0


func _update_rabbit(delta: float) -> void:
	if hop_progress < 1.0:
		hop_progress = minf(1.0, hop_progress + delta / HOP_DURATION)
		position = hop_from.lerp(hop_to, hop_progress)
		lift = sin(hop_progress * PI) * HOP_HEIGHT
		if hop_progress >= 1.0:
			lift = 0.0
			if hops_left > 0:
				hops_left -= 1
				_start_hop(hop_to - hop_from)
		return
	if player != null and player.global_position.distance_to(global_position) < FLEE_DISTANCE:
		var away := (global_position - player.global_position).normalized().rotated(randf_range(-0.6, 0.6))
		hops_left = 5
		_start_hop(away * 34.0)
		return
	idle_timer -= delta
	if idle_timer <= 0.0:
		idle_timer = randf_range(1.5, 4.0)
		var toward_home := (home - position).limit_length(30.0)
		hops_left = randi_range(0, 2)
		_start_hop(Vector2.from_angle(randf() * TAU) * 22.0 + toward_home * 0.5)


func _start_hop(step: Vector2) -> void:
	hop_from = position
	hop_to = position + step
	hop_progress = 0.0
	if absf(step.x) > 2.0:
		facing_right = step.x > 0.0


func _draw() -> void:
	if kind == Kind.BUTTERFLY:
		_draw_butterfly()
	else:
		_draw_rabbit()


func _draw_butterfly() -> void:
	draw_rect(Rect2(-3, -1, 6, 2), SHADOW)
	var body := Vector2(0, -lift).round()
	# Wing span shrinks and grows to fake the flap.
	var flap := absf(sin(time * 16.0 + phase))
	var span := 1 + int(round(flap * 2.0))
	var shade := wing_color.darkened(0.3)
	for side in [-1, 1]:
		for column in span:
			var x: float = body.x + PIXEL * 0.5 + column * PIXEL if side > 0 else body.x - PIXEL * 0.5 - (column + 1) * PIXEL
			draw_rect(Rect2(x, body.y - PIXEL * 2, PIXEL, PIXEL * 2), wing_color if column < span - 1 else shade)
			if column < maxi(1, span - 1):
				draw_rect(Rect2(x, body.y, PIXEL, PIXEL), shade)
	draw_rect(Rect2(body.x - PIXEL * 0.5, body.y - PIXEL * 2, PIXEL, PIXEL * 3), OUTLINE)


func _draw_rabbit() -> void:
	var width: int = RABBIT[0].length()
	var height := RABBIT.size()
	# Contact shadow shrinks while airborne.
	var shadow_scale := 1.0 - lift / (HOP_HEIGHT * 2.5)
	draw_set_transform(Vector2(0, -1), 0.0, Vector2(shadow_scale, 0.4))
	draw_circle(Vector2.ZERO, width * PIXEL * 0.42, SHADOW)
	draw_set_transform(Vector2.ZERO)
	var origin := Vector2(-width * PIXEL / 2.0, -height * PIXEL - roundf(lift))
	for row in height:
		var line: String = RABBIT[row]
		for column in width:
			var color: Color
			match line[column]:
				"o": color = OUTLINE
				"b": color = RABBIT_BODY
				"l": color = RABBIT_LIGHT
				"w": color = RABBIT_TAIL
				"p", "n": color = RABBIT_EAR
				"e": color = RABBIT_EYE
				_: continue
			var x := column if facing_right else width - 1 - column
			draw_rect(Rect2(origin + Vector2(x, row) * PIXEL, Vector2.ONE * PIXEL), color)
