extends Node2D
class_name DesertLizard
## Small ambient desert life drawn as pixel art: a lizard that basks in the sun, darts off in short bursts
## and bolts away when the player comes close. Purely cosmetic.

const PIXEL := 2.0
const OUTLINE := Color("#3a2414")
const BODY := Color("#a9682c")
const BODY_DARK := Color("#74431d")
const BELLY := Color("#dcb173")
const EYE := Color("#140c08")
const SHADOW := Color(0.38, 0.2, 0.06, 0.3)
## Seen from above, facing right. o outline, b body, d back pattern, l light flank, e eye.
## The two frames step the legs in a diagonal gait.
const FRAMES := [
	[
		"......o.....o.....",
		".....ob....ob.....",
		"oo..obbbbbbbbbboo.",
		"oboobddbddbdbbbbo.",
		".oobllbbbbbbbbbebo",
		"...oobddbddbdbbbo.",
		".....obbbbbbbbboo.",
		"........ob....ob..",
		".........o.....o..",
	],
	[
		"........o.....o...",
		".......ob....ob...",
		"oo..obbbbbbbbbboo.",
		"oboobddbddbdbbbbo.",
		".oobllbbbbbbbbbebo",
		"...oobddbddbdbbbo.",
		".....obbbbbbbbboo.",
		"......ob....ob....",
		".....o.....o......",
	],
]
const FLEE_DISTANCE := 150.0
const DART_SPEED := 150.0
const FLEE_SPEED := 280.0

var player: Node2D
var home := Vector2.ZERO
var time := 0.0
var velocity := Vector2.ZERO
var dart_time := 0.0
var rest_time := 0.0
var facing_right := true


func _ready() -> void:
	home = position
	rest_time = randf_range(0.5, 3.0)
	facing_right = randf() < 0.5


func _process(delta: float) -> void:
	time += delta
	if dart_time > 0.0:
		dart_time -= delta
		position += velocity * delta
		if dart_time <= 0.0:
			velocity = Vector2.ZERO
			rest_time = randf_range(1.0, 4.0)
	elif player != null and player.global_position.distance_to(global_position) < FLEE_DISTANCE:
		var away := (global_position - player.global_position).normalized().rotated(randf_range(-0.5, 0.5))
		_dart(away * FLEE_SPEED, randf_range(0.5, 0.8))
	else:
		rest_time -= delta
		if rest_time <= 0.0:
			var toward_home := (home - position).limit_length(60.0) / 60.0
			var direction := (Vector2.from_angle(randf() * TAU) + toward_home).normalized()
			_dart(direction * DART_SPEED, randf_range(0.2, 0.45))
	queue_redraw()


func _dart(dart_velocity: Vector2, duration: float) -> void:
	velocity = dart_velocity
	dart_time = duration
	if absf(dart_velocity.x) > 1.0:
		facing_right = dart_velocity.x > 0.0


func _draw() -> void:
	var frame: Array = FRAMES[int(time * 18.0) % 2 if dart_time > 0.0 else 0]
	var width: int = frame[0].length()
	draw_set_transform(Vector2(0, -1), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, width * PIXEL * 0.45, SHADOW)
	draw_set_transform(Vector2.ZERO)
	# Legs scurry while darting, otherwise rest in one pose.
	var rows: Array = frame
	var origin := Vector2(-width * PIXEL / 2.0, -rows.size() * PIXEL)
	for row in rows.size():
		var line: String = rows[row]
		for column in line.length():
			var color: Color
			match line[column]:
				"o": color = OUTLINE
				"b": color = BODY
				"d": color = BODY_DARK
				"l": color = BELLY
				"e": color = EYE
				_: continue
			var x := column if facing_right else width - 1 - column
			draw_rect(Rect2(origin + Vector2(x, row) * PIXEL, Vector2.ONE * PIXEL), color)
