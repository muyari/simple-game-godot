extends Node2D
class_name VenomBall

const SPEED = 230.0
const HIT_RADIUS = 14.0
const MAX_RANGE = 600.0

@export var damage := 20

var direction := Vector2.DOWN
## Monster that fired this, told about hits so on-hit modifiers like Vampiric work.
var source_monster: Wolf
var distance_travelled := 0.0
var animation_time := 0.0


func _ready() -> void:
	# Deferred: the monster that fired it places it after adding it.
	(func() -> void: Audio.play_sfx_at("enemy_spell", global_position)).call_deferred()


func _process(delta: float) -> void:
	animation_time += delta
	var step_distance := SPEED * delta
	var to_player := _find_hit_player(step_distance)
	if to_player != null:
		_report_hit(to_player.take_damage(damage))
		queue_free()
		return

	global_position += direction * step_distance
	distance_travelled += step_distance
	if distance_travelled >= MAX_RANGE:
		queue_free()
		return

	rotation = direction.angle()
	queue_redraw()


func _report_hit(damage_dealt: int) -> void:
	if is_instance_valid(source_monster):
		source_monster.register_hit(damage_dealt)


func _find_hit_player(step_distance: float) -> Player:
	var player := get_tree().current_scene.get_node_or_null("Player") as Player
	if player == null or player.health <= 0:
		return null

	var to_player := player.global_position - global_position
	var projection := to_player.dot(direction)
	if projection < -HIT_RADIUS or projection > step_distance + HIT_RADIUS:
		return null

	var closest_point := direction * clampf(projection, 0.0, step_distance)
	if (to_player - closest_point).length_squared() <= HIT_RADIUS * HIT_RADIUS:
		return player
	return null


func _draw() -> void:
	var pulse := sin(animation_time * 18.0) * 1.5
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-8.0, -5.0),
			Vector2(-20.0, -2.0),
			Vector2(-25.0, 0.0),
			Vector2(-20.0, 2.0),
			Vector2(-8.0, 5.0)
		]),
		Color("#69a92d", 0.62)
	)
	draw_circle(Vector2.ZERO, 9.0 + pulse, Color("#398b27"))
	draw_circle(Vector2(1.5, -1.5), 6.0 + pulse * 0.45, Color("#75d83b"))
	draw_circle(Vector2(3.0, -3.0), 2.5, Color("#c8ff78"))
