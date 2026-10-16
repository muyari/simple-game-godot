extends Node2D
class_name FrostShard

const SPEED = 290.0
const HIT_RADIUS = 18.0
const MAX_RANGE = 520.0

@export var damage := 8
@export var chill_duration := 1.25
## Drawn pointing along the flight path instead of the default glowing shard.
@export var texture: Texture2D

var direction := Vector2.DOWN
## Monster that fired this, told about hits so on-hit modifiers like Vampiric work.
var source_monster: Wolf
var distance_travelled := 0.0
var animation_time := 0.0


func _process(delta: float) -> void:
	animation_time += delta
	var step_distance := SPEED * delta
	var player := _find_hit_player(step_distance)
	if player != null:
		_report_hit(player.take_damage(damage))
		player.apply_chill(chill_duration, 0.58)
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
	if texture != null:
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		draw_texture(texture, -texture.get_size() * 0.5)
		return
	var pulse := sin(animation_time * 18.0) * 1.5
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-20.0, -5.0),
			Vector2(0.0, -9.0 - pulse),
			Vector2(13.0, 0.0),
			Vector2(0.0, 9.0 + pulse),
			Vector2(-20.0, 5.0)
		]),
		Color("#7acfe9", 0.65)
	)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-8.0, -4.0),
			Vector2(2.0, -6.0 - pulse * 0.4),
			Vector2(10.0, 0.0),
			Vector2(2.0, 6.0 + pulse * 0.4),
			Vector2(-8.0, 4.0)
		]),
		Color("#e4fbff")
	)