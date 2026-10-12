extends Node2D
class_name WispBolt

const SPEED = 360.0
const TURN_RATE = 5.0
const HIT_RADIUS = 18.0
const MAX_RANGE = 1200.0
const IMPACT_DURATION = 0.16

var target: Node2D
var damage := 2.0
var direction := Vector2.RIGHT
var distance_travelled := 0.0
var animation_time := 0.0
var impact_time_remaining := 0.0
var has_hit := false
var last_known_target_position := Vector2.ZERO


func _ready() -> void:
	z_index = 3
	if not is_instance_valid(target):
		queue_free()
		return
	last_known_target_position = target.global_position
	direction = (last_known_target_position - global_position).normalized()
	if target.has_method("take_damage"):
		target.call("take_damage", damage)


func _process(delta: float) -> void:
	animation_time += delta
	if has_hit:
		impact_time_remaining = maxf(impact_time_remaining - delta, 0.0)
		if impact_time_remaining == 0.0:
			queue_free()
			return
		queue_redraw()
		return

	if is_instance_valid(target) and target.is_inside_tree():
		last_known_target_position = target.global_position
	var to_target := last_known_target_position - global_position
	if not to_target.is_zero_approx():
		direction = direction.lerp(to_target.normalized(), clampf(TURN_RATE * delta, 0.0, 1.0)).normalized()
	var step_distance := SPEED * delta
	if to_target.length() <= step_distance + HIT_RADIUS:
		global_position = last_known_target_position
		has_hit = true
		impact_time_remaining = IMPACT_DURATION
		queue_redraw()
		return

	global_position += direction * step_distance
	distance_travelled += step_distance
	if distance_travelled >= MAX_RANGE:
		queue_free()
		return
	rotation = direction.angle()
	queue_redraw()


func _draw() -> void:
	var pulse := sin(animation_time * 24.0) * 1.5
	if has_hit:
		var impact_progress := 1.0 - impact_time_remaining / IMPACT_DURATION
		var impact_radius := 5.0 + impact_progress * 18.0
		draw_arc(Vector2.ZERO, impact_radius, 0.0, TAU, 20, Color(0.67, 1.0, 0.95, 1.0 - impact_progress), 2.0)
		return

	draw_line(Vector2(-20.0, 0.0), Vector2(-5.0, 0.0), Color(0.35, 0.95, 0.88, 0.72), 4.0)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(11.0 + pulse, 0.0),
			Vector2(0.0, 7.0),
			Vector2(-8.0, 0.0),
			Vector2(0.0, -7.0)
		]),
		Color("#70e9dd")
	)
	draw_circle(Vector2.ZERO, 3.0, Color("#e5fff6"))