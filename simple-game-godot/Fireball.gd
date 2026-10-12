extends Node2D
class_name Fireball

const SPEED = 420.0
const HIT_RADIUS = 30.0
const MAX_RANGE = 600.0

var direction := Vector2.DOWN
var distance_travelled := 0.0
var animation_time := 0.0


func _process(delta: float) -> void:
	animation_time += delta
	var step_distance := SPEED * delta
	var step_end := global_position + direction * step_distance
	var hit_target := _find_hit_target(step_distance)
	if hit_target != null:
		hit_target.call("take_percentage_damage", 0.5)
		queue_free()
		return

	global_position = step_end
	distance_travelled += step_distance
	if distance_travelled >= MAX_RANGE:
		queue_free()
		return

	rotation = direction.angle()
	queue_redraw()


func _find_hit_target(step_distance: float) -> Node2D:
	var hit_target: Node2D
	var nearest_projection := INF

	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy is Node2D or not enemy.has_method("take_percentage_damage"):
			continue

		var enemy_node := enemy as Node2D
		var to_enemy := enemy_node.global_position - global_position
		var projection := to_enemy.dot(direction)
		if projection < -HIT_RADIUS or projection > step_distance + HIT_RADIUS:
			continue

		var closest_point := direction * clampf(projection, 0.0, step_distance)
		if (to_enemy - closest_point).length_squared() <= HIT_RADIUS * HIT_RADIUS and projection < nearest_projection:
			hit_target = enemy_node
			nearest_projection = projection

	return hit_target


func _draw() -> void:
	var pulse := sin(animation_time * 24.0) * 1.5
	draw_circle(Vector2.ZERO, 10.0 + pulse, Color("#bc321c"))
	draw_circle(Vector2(1.0, 0.0), 7.0 + pulse * 0.5, Color("#f47722"))
	draw_circle(Vector2(3.0, 0.0), 4.0, Color("#ffe58a"))
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-6.0, -4.0),
			Vector2(-19.0, 0.0),
			Vector2(-6.0, 4.0)
		]),
		Color("#ee5422", 0.72)
	)
