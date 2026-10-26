extends Node2D
class_name SiegeFire
## The Underworld's bombardment of Ashgate Outpost: every few seconds a ball of hellfire arcs down out of
## the dark beyond the walls and bursts in a flash of embers, leaving a scorch that slowly fades. Purely
## cosmetic, and it never lands inside `safe_area`.

const INTERVAL := Vector2(2.5, 6.0)
const FLIGHT_TIME := 1.1
const SCORCH_TIME := 6.0

## Where shots land, in world pixels.
var target_area := Rect2(-300, -320, 1800, 260)
var safe_area := Rect2()
var timer := 1.5
var shots: Array[Dictionary] = []
var scorches: Array[Dictionary] = []


func _ready() -> void:
	z_index = 8


func _process(delta: float) -> void:
	timer -= delta
	if timer <= 0.0:
		timer = randf_range(INTERVAL.x, INTERVAL.y)
		_launch()
	for shot in shots:
		shot["t"] += delta / FLIGHT_TIME
		if shot["t"] >= 1.0 and not shot["landed"]:
			shot["landed"] = true
			_burst(shot["to"])
	shots = shots.filter(func(shot: Dictionary) -> bool: return not shot["landed"])
	for scorch in scorches:
		scorch["age"] += delta
	scorches = scorches.filter(func(scorch: Dictionary) -> bool: return scorch["age"] < SCORCH_TIME)
	queue_redraw()


func _launch() -> void:
	var to := Vector2.ZERO
	for _attempt in 6:
		to = Vector2(randf_range(target_area.position.x, target_area.end.x), randf_range(target_area.position.y, target_area.end.y))
		if not safe_area.has_point(to):
			break
	var from := to + Vector2(randf_range(-260.0, 260.0), -520.0)
	shots.append({"from": from, "to": to, "t": 0.0, "landed": false})


func _burst(at: Vector2) -> void:
	scorches.append({"at": at, "age": 0.0, "size": randf_range(18.0, 30.0)})
	var flash := FireGlow.attach(self, at, 160.0, Color("#ff7a2a"), 0.9)
	var fade := flash.create_tween()
	fade.tween_property(flash, "strength", 0.0, 0.9)
	fade.tween_callback(flash.queue_free)
	var embers := CPUParticles2D.new()
	embers.position = at
	embers.one_shot = true
	embers.emitting = true
	embers.amount = 28
	embers.lifetime = 1.1
	embers.explosiveness = 0.95
	embers.direction = Vector2.UP
	embers.spread = 70.0
	embers.gravity = Vector2(0.0, 160.0)
	embers.initial_velocity_min = 60.0
	embers.initial_velocity_max = 150.0
	embers.scale_amount_min = 1.5
	embers.scale_amount_max = 3.0
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.4, 1.0])
	ramp.colors = PackedColorArray([Color("#fff1a8"), Color("#ff8a2a"), Color(0.6, 0.1, 0.02, 0.0)])
	embers.color_ramp = ramp
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	embers.material = additive
	add_child(embers)
	embers.finished.connect(embers.queue_free)


func _draw() -> void:
	for scorch in scorches:
		var fade: float = 1.0 - scorch["age"] / SCORCH_TIME
		var at: Vector2 = scorch["at"]
		var size: float = scorch["size"]
		draw_set_transform(at, 0.0, Vector2(1.0, 0.45))
		draw_circle(Vector2.ZERO, size, Color(0.05, 0.02, 0.02, 0.55 * fade), true, -1.0, true)
		draw_circle(Vector2.ZERO, size * 0.45, Color(1.0, 0.4, 0.08, 0.6 * fade * fade), true, -1.0, true)
		draw_set_transform(Vector2.ZERO)
	for shot in shots:
		var t: float = shot["t"]
		var from: Vector2 = shot["from"]
		var to: Vector2 = shot["to"]
		# A falling arc: drifts sideways while it drops, speeding up toward the ground.
		var point := from.lerp(to, t) + Vector2(0.0, -sin(t * PI) * 60.0)
		var tail := from.lerp(to, maxf(t - 0.12, 0.0)) + Vector2(0.0, -sin(maxf(t - 0.12, 0.0) * PI) * 60.0)
		draw_line(tail, point, Color(1.0, 0.45, 0.1, 0.35), 7.0, true)
		draw_line(tail.lerp(point, 0.5), point, Color(1.0, 0.75, 0.3, 0.6), 4.0, true)
		draw_circle(point, 6.0, Color("#ff6a1f"), true, -1.0, true)
		draw_circle(point, 3.5, Color("#fff1a8"), true, -1.0, true)
