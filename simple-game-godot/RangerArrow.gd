extends Node2D
class_name RangerArrow

const BASE_SPEED := 560.0
const BASE_HIT_RADIUS := 25.0
const BASE_MAX_RANGE := 620.0

var direction := Vector2.RIGHT
var speed := BASE_SPEED
var hit_radius := BASE_HIT_RADIUS
var max_range := BASE_MAX_RANGE
var damage := 1.0
var pierce_count := 0
var explosion_radius := 0.0
var explosion_damage := 0.0
var distance_travelled := 0.0
var hit_targets: Dictionary = {}


func _ready() -> void:
	direction = direction.normalized()
	rotation = direction.angle()


func _process(delta: float) -> void:
	var step_distance := speed * delta
	var hit_target := _find_hit_target(step_distance)
	if hit_target != null:
		var target_id := hit_target.get_instance_id()
		var impact_position := hit_target.global_position
		hit_targets[target_id] = true
		hit_target.call("take_damage", damage)
		if explosion_radius > 0.0:
			_explode(impact_position, target_id)
			queue_free()
			return
		if pierce_count > 0:
			pierce_count -= 1
		else:
			queue_free()
			return

	global_position += direction * step_distance
	distance_travelled += step_distance
	if distance_travelled >= max_range:
		queue_free()


func _find_hit_target(step_distance: float) -> Node2D:
	var nearest_target: Node2D
	var nearest_projection := INF
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy is Node2D or not enemy.has_method("take_damage") \
				or hit_targets.has(enemy.get_instance_id()):
			continue

		var enemy_node := enemy as Node2D
		var to_enemy := enemy_node.global_position - global_position
		var projection := to_enemy.dot(direction)
		if projection < -hit_radius or projection > step_distance + hit_radius:
			continue

		var closest_point := direction * clampf(projection, 0.0, step_distance)
		if (to_enemy - closest_point).length_squared() <= hit_radius * hit_radius \
				and projection < nearest_projection:
			nearest_target = enemy_node
			nearest_projection = projection
	return nearest_target


func _explode(impact_position: Vector2, direct_hit_id: int) -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy is Node2D or not enemy.has_method("take_damage"):
			continue
		var enemy_node := enemy as Node2D
		var in_range := enemy_node.global_position.distance_to(impact_position) <= explosion_radius
		if in_range and enemy_node.get_instance_id() != direct_hit_id:
			enemy.call("take_damage", explosion_damage)
		if in_range and enemy_node.has_method("apply_stun"):
			enemy.call("apply_stun", 0.2)


func _draw() -> void:
	draw_line(Vector2(-10.0, 0.0), Vector2(12.0, 0.0), Color("#e9d4a0"), 3.0, true)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(15.0, 0.0),
			Vector2(7.0, -4.0),
			Vector2(7.0, 4.0)
		]),
		Color("#bf7042")
	)
	draw_line(Vector2(-8.0, -3.0), Vector2(-13.0, 0.0), Color("#a87a45"), 2.0, true)
	draw_line(Vector2(-8.0, 3.0), Vector2(-13.0, 0.0), Color("#a87a45"), 2.0, true)
