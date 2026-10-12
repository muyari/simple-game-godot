extends Node2D
class_name WitchFamiliar

const FOLLOW_RADIUS = 46.0
const ORBIT_HEIGHT = 26.0
const ATTACK_RANGE = 340.0
const ATTACK_INTERVAL = 1.8
const WISP_BOLT_SCENE = preload("res://wisp_bolt.tscn")

var owner_player: Player
var duration := 9.0
var damage := 2.0
var duration_remaining := 0.0
var attack_timer := 0.0
var animation_time := 0.0


func _ready() -> void:
	duration_remaining = duration
	z_index = 2


func _process(delta: float) -> void:
	if not is_instance_valid(owner_player):
		queue_free()
		return

	duration_remaining = maxf(duration_remaining - delta, 0.0)
	if duration_remaining == 0.0:
		queue_free()
		return

	animation_time += delta
	attack_timer -= delta
	global_position = owner_player.global_position + Vector2(
		cos(animation_time * 2.2) * FOLLOW_RADIUS,
		sin(animation_time * 2.2) * 14.0 - ORBIT_HEIGHT
	)
	if attack_timer <= 0.0:
		var enemy := _find_nearest_enemy()
		if enemy != null:
			var bolt := WISP_BOLT_SCENE.instantiate() as WispBolt
			if bolt == null:
				push_error("The Wisp bolt scene root must use the WispBolt script.")
			else:
				bolt.target = enemy
				bolt.damage = damage
				bolt.global_position = global_position
				get_tree().current_scene.add_child(bolt)
				attack_timer = ATTACK_INTERVAL
	queue_redraw()


func _find_nearest_enemy() -> Node2D:
	var nearest_enemy: Node2D
	var nearest_distance := ATTACK_RANGE
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if not candidate is Node2D or not candidate.has_method("take_damage"):
			continue
		var enemy := candidate as Node2D
		var distance := global_position.distance_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_enemy = enemy
			nearest_distance = distance
	return nearest_enemy


func _draw() -> void:
	var pulse := sin(animation_time * 8.0) * 2.0
	draw_circle(Vector2.ZERO, 12.0 + pulse, Color(0.3, 0.85, 1.0, 0.18))
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(0.0, -10.0 - pulse),
			Vector2(8.0, 0.0),
			Vector2(0.0, 10.0 + pulse),
			Vector2(-8.0, 0.0)
		]),
		Color("#7de8e0")
	)
	draw_circle(Vector2.ZERO, 3.5, Color("#e5ffff"))