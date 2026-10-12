extends Area2D
class_name Portal

@export_file("*.tscn") var destination_scene := ""
@export var destination_position := Vector2.ZERO

var pulse_time := 0.0
var is_transitioning := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	pulse_time += delta
	queue_redraw()


func _draw() -> void:
	var center := Vector2.ZERO
	var pulse := sin(pulse_time * 3.0) * 2.0
	draw_circle(center, 31.0 + pulse, Color(0.15, 0.62, 0.92, 0.16))
	draw_arc(center, 27.0 + pulse, 0.0, TAU, 64, Color(0.28, 0.83, 1.0, 0.95), 4.0, true)
	draw_arc(center, 20.0 - pulse * 0.4, 0.0, TAU, 64, Color(0.62, 0.91, 1.0, 0.8), 2.0, true)
	draw_circle(center, 17.0, Color(0.08, 0.24, 0.48, 0.88))
	draw_circle(center, 11.0, Color(0.2, 0.58, 0.86, 0.75))


func _on_body_entered(body: Node2D) -> void:
	if is_transitioning or not body is Player:
		return
	if destination_scene.is_empty() or not ResourceLoader.exists(destination_scene):
		push_error("Portal destination scene does not exist: %s" % destination_scene)
		return

	is_transitioning = true
	call_deferred("_change_scene", body as Player)


func _change_scene(player: Player) -> void:
	if not is_inside_tree():
		return
	if not is_instance_valid(player):
		is_transitioning = false
		push_error("Could not travel through portal: player no longer exists.")
		return

	get_tree().set_meta("portal_spawn_position", destination_position)
	get_tree().set_meta("portal_player_vitals", {
		"health": player.health,
		"mana": player.mana
	})
	var error := get_tree().change_scene_to_file(destination_scene)
	if error != OK:
		get_tree().remove_meta("portal_spawn_position")
		get_tree().remove_meta("portal_player_vitals")
		is_transitioning = false
		push_error("Could not travel through portal: %s" % error_string(error))
