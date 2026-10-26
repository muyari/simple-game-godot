extends RefCounted
class_name HitFeedback
## Combat feedback shared by everything that lands a hit: floating damage numbers, a burst of impact
## sparks and hit-stop (a split-second freeze that gives melee blows weight).

## Seconds of game time frozen on a melee hit, and on a heavy one.
const HIT_STOP := 0.045
const HEAVY_HIT_STOP := 0.08
const HIT_STOP_SCALE := 0.05

## Bumped by every hit-stop; only the most recent one's timer restores normal speed.
static var _stop_token := 0


## Freezes the game for `duration` real seconds. A new hit-stop replaces one already running.
static func hit_stop(tree: SceneTree, duration: float) -> void:
	_stop_token += 1
	var token := _stop_token
	Engine.time_scale = HIT_STOP_SCALE
	tree.create_timer(duration, true, false, true).timeout.connect(func() -> void:
		if token == _stop_token:
			Engine.time_scale = 1.0
	)


## A number rising from where a hit landed. `heavy` hits are larger and gold; amount <= 0 shows "Miss".
static func number(parent: Node, world_position: Vector2, amount: float, heavy := false) -> void:
	if parent == null:
		return
	var label := DamageNumber.new()
	if amount <= 0.0:
		label.text = "Miss"
		label.color = Color(0.82, 0.82, 0.78)
	else:
		label.text = str(roundi(amount)) if absf(amount - roundf(amount)) < 0.05 or amount >= 10.0 else "%.1f" % amount
		label.color = Color("#ffd75e") if heavy else Color(1.0, 0.97, 0.9)
	label.big = heavy
	label.position = world_position + Vector2(randf_range(-8.0, 8.0), 0.0)
	parent.add_child(label)


static func sparks(parent: Node, world_position: Vector2, direction: Vector2, heavy := false) -> void:
	if parent == null:
		return
	var spark := HitSpark.new()
	spark.position = world_position
	spark.direction = direction
	spark.heavy = heavy
	parent.add_child(spark)


class DamageNumber extends Node2D:
	const LIFETIME := 0.75
	const RISE := 34.0
	var text := ""
	var color := Color.WHITE
	var big := false
	var time := 0.0
	var drift := 0.0

	func _ready() -> void:
		z_index = 40
		z_as_relative = false
		drift = randf_range(-10.0, 10.0)

	func _process(delta: float) -> void:
		time += delta
		if time >= LIFETIME:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var t := time / LIFETIME
		var font := ThemeDB.fallback_font
		var size := 22 if big else 16
		# Pops in, then eases up and fades out.
		var pop := 1.0 + 0.45 * maxf(0.0, 1.0 - t * 6.0)
		var offset := Vector2(drift * t, -RISE * (1.0 - pow(1.0 - t, 2.0)))
		var alpha := 1.0 - smoothstep(0.55, 1.0, t)
		draw_set_transform(offset, 0.0, Vector2.ONE * pop)
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		var origin := Vector2(-width * 0.5, 0.0)
		draw_string_outline(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 5, Color(0.1, 0.05, 0.03, alpha))
		draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(color, alpha))
		draw_set_transform(Vector2.ZERO)


class HitSpark extends Node2D:
	const LIFETIME := 0.16
	var direction := Vector2.RIGHT
	var heavy := false
	var time := 0.0
	var rays: Array[Vector2] = []

	func _ready() -> void:
		z_index = 30
		z_as_relative = false
		var base_angle := direction.angle() if not direction.is_zero_approx() else randf() * TAU
		for index in (9 if heavy else 6):
			# Sprayed mostly along the blow, a few going wide.
			var spread := randf_range(-1.1, 1.1) if index % 3 != 0 else randf_range(-PI, PI)
			rays.append(Vector2.from_angle(base_angle + spread) * randf_range(0.6, 1.0))

	func _process(delta: float) -> void:
		time += delta
		if time >= LIFETIME:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var t := time / LIFETIME
		var reach := (26.0 if heavy else 18.0) * (0.35 + t)
		var alpha := 1.0 - t
		draw_circle(Vector2.ZERO, (9.0 if heavy else 6.0) * (1.0 - t), Color(1.0, 0.98, 0.9, alpha), true, -1.0, true)
		for ray in rays:
			var from := ray * reach * 0.35
			var to := ray * reach
			draw_line(from, to, Color(1.0, 0.86, 0.5, alpha), 2.5 if heavy else 2.0, true)
