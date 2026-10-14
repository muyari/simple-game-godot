extends Node2D
class_name HomingPulse

const SPEED = 245.0
const TURN_RATE = 4.2
const HIT_RADIUS = 18.0
const MAX_RANGE = 720.0
const WINDUP_DURATION = 0.42
const TRACK_DURATION = 1.25

var target: Player
var damage := 13
var initial_direction := Vector2.DOWN
## Monster that fired this, told about hits so on-hit modifiers like Vampiric work.
var source_monster: Wolf
var direction := Vector2.DOWN
var last_known_position := Vector2.ZERO
var windup_remaining := WINDUP_DURATION
var track_remaining := TRACK_DURATION
var distance_travelled := 0.0
var animation_time := 0.0


func _ready() -> void:
	direction = initial_direction.normalized()
	if direction.is_zero_approx():
		direction = Vector2.DOWN
	if is_instance_valid(target):
		last_known_position = target.global_position + target.velocity * 0.45
	else:
		last_known_position = global_position + direction * 240.0


func _process(delta: float) -> void:
	animation_time += delta
	if windup_remaining > 0.0:
		windup_remaining = maxf(windup_remaining - delta, 0.0)
		if is_instance_valid(target):
			last_known_position = target.global_position + target.velocity * 0.45
		queue_redraw()
		return

	if track_remaining > 0.0 and is_instance_valid(target):
		track_remaining = maxf(track_remaining - delta, 0.0)
		last_known_position = target.global_position + target.velocity * 0.32

	var to_last_position := last_known_position - global_position
	if not to_last_position.is_zero_approx():
		var desired_direction := to_last_position.normalized()
		direction = direction.lerp(desired_direction, clampf(TURN_RATE * delta, 0.0, 1.0)).normalized()
	var step_distance := SPEED * delta
	var hit_player := _find_hit_player(step_distance)
	if hit_player != null:
		_report_hit(hit_player.take_damage(damage))
		hit_player.apply_chill(0.7, 0.78)
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
	var pulse := 1.5 + sin(animation_time * 16.0) * 1.0
	if windup_remaining > 0.0:
		draw_arc(Vector2.ZERO, 13.0 + pulse, 0.0, TAU, 24, Color(0.42, 0.92, 1.0, 0.7), 2.0)
	else:
		draw_colored_polygon(
			PackedVector2Array([
				Vector2(12.0 + pulse, 0.0),
				Vector2(0.0, 8.0),
				Vector2(-11.0, 0.0),
				Vector2(0.0, -8.0)
			]),
			Color("#45d9dc")
		)
		draw_circle(Vector2.ZERO, 4.0, Color("#e2ffff"))