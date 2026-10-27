extends Node2D
class_name Fireworks
## Fireworks over Ashgate's walls once the last watchfire is lit (Quests.LAST_WATCHFIRE): a rocket climbs
## from the yard, then bursts into a ring of sparks that fall and fade. Drawn smooth, high above the world.

const COLORS: Array[Color] = [Color("#ffb347"), Color("#ffd34d"), Color("#ff6a4a"), Color("#9fd3ee"), Color("#c99bff"), Color("#a9d98a")]
const RISE_TIME := 0.7
const BURST_TIME := 1.8
const SPARKS := 28
const GRAVITY := 70.0

## Where the bursts go off, in world pixels, when there's no camera to follow; otherwise they go off in the
## upper part of whatever the camera shows, so they're seen from anywhere in the hub.
var sky := Rect2(0, -260, 1160, 420)
var bursts: Array[Dictionary] = []
var next_launch := 0.4
var random := RandomNumberGenerator.new()


func _ready() -> void:
	z_index = 60
	z_as_relative = false
	random.randomize()


func _process(delta: float) -> void:
	if not Quests.is_completed(Quests.LAST_WATCHFIRE):
		return
	next_launch -= delta
	if next_launch <= 0.0:
		next_launch = random.randf_range(0.35, 1.1)
		var area := _launch_area()
		var target := Vector2(random.randf_range(area.position.x, area.end.x), random.randf_range(area.position.y, area.end.y))
		bursts.append({
			"from": Vector2(target.x + random.randf_range(-60, 60), area.end.y + 260.0), "to": target, "age": 0.0,
			"color": COLORS[random.randi() % COLORS.size()], "radius": random.randf_range(70.0, 130.0), "spin": random.randf() * TAU,
		})
	for burst in bursts:
		burst["age"] += delta
	bursts = bursts.filter(func(burst: Dictionary) -> bool: return burst["age"] < RISE_TIME + BURST_TIME)
	queue_redraw()


func _launch_area() -> Rect2:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return sky
	var view := get_viewport_rect().size / camera.zoom
	var top_left := camera.get_screen_center_position() - view * 0.5
	return Rect2(top_left + Vector2(view.x * 0.1, view.y * 0.08), Vector2(view.x * 0.8, view.y * 0.35))


func _draw() -> void:
	for burst in bursts:
		var age: float = burst["age"]
		var color: Color = burst["color"]
		if age < RISE_TIME:
			# The rocket climbing, with a short fading tail.
			var t := age / RISE_TIME
			var head: Vector2 = burst["from"].lerp(burst["to"], 1.0 - pow(1.0 - t, 2.0))
			var tail: Vector2 = burst["from"].lerp(burst["to"], maxf(1.0 - pow(1.0 - maxf(t - 0.12, 0.0), 2.0), 0.0))
			draw_line(tail, head, Color(1.0, 0.9, 0.7, 0.6), 2.0, true)
			SmoothDraw.disc(self, head, 2.5, Color(1.0, 0.95, 0.8))
			continue
		var t := (age - RISE_TIME) / BURST_TIME
		var fade := 1.0 - t
		var spread: float = burst["radius"] * (1.0 - pow(1.0 - t, 3.0))
		var drop := GRAVITY * t * t
		if t < 0.15:
			SmoothDraw.disc(self, burst["to"], 40.0 * (1.0 - t / 0.15), Color(1.0, 1.0, 0.9, 0.5))
		for spark in SPARKS:
			var direction := Vector2.from_angle(burst["spin"] + TAU * spark / SPARKS)
			var tip: Vector2 = burst["to"] + direction * spread + Vector2(0, drop)
			var trail: Vector2 = burst["to"] + direction * spread * 0.82 + Vector2(0, drop * 0.8)
			draw_line(trail, tip, Color(color, 0.7 * fade), 2.0, true)
			SmoothDraw.disc(self, tip, 2.2, Color(color.lightened(0.3), fade))
