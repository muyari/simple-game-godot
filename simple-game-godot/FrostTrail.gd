extends Node2D
class_name FrostTrail

const DURATION = 4.0
const CHILL_RADIUS = 48.0
const CHILL_TICK = 0.3

var time_remaining := DURATION
var chill_tick_remaining := 0.0


func _ready() -> void:
	z_index = -2


func _process(delta: float) -> void:
	time_remaining = maxf(time_remaining - delta, 0.0)
	chill_tick_remaining -= delta
	if time_remaining <= 0.0:
		queue_free()
		return

	if chill_tick_remaining <= 0.0:
		chill_tick_remaining = CHILL_TICK
		var player := get_tree().current_scene.get_node_or_null("Player") as Player
		if player != null and player.health > 0 \
				and global_position.distance_to(player.global_position) <= CHILL_RADIUS:
			player.apply_chill(0.45, 0.62)
	queue_redraw()


func _draw() -> void:
	var alpha := clampf(time_remaining / DURATION, 0.0, 1.0) * 0.42
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-48.0, -8.0),
			Vector2(-34.0, -15.0),
			Vector2(-18.0, -9.0),
			Vector2(-2.0, -16.0),
			Vector2(15.0, -8.0),
			Vector2(36.0, -13.0),
			Vector2(48.0, -4.0),
			Vector2(35.0, 12.0),
			Vector2(13.0, 8.0),
			Vector2(-8.0, 16.0),
			Vector2(-27.0, 8.0),
			Vector2(-45.0, 13.0)
		]),
		Color(0.38, 0.78, 0.9, alpha)
	)
	draw_polyline(
		PackedVector2Array([
			Vector2(-40.0, -2.0),
			Vector2(-22.0, 1.0),
			Vector2(-6.0, -5.0),
			Vector2(13.0, 2.0),
			Vector2(35.0, -3.0)
		]),
		Color(0.82, 0.96, 1.0, alpha),
		2.0
	)