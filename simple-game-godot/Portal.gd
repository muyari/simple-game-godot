extends Area2D
class_name Portal

@export_file("*.tscn") var destination_scene := ""
@export var destination_position := Vector2.ZERO

@onready var interaction_prompt: Label = $InteractionPrompt

var nearby_player: Player
var is_transitioning := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	interaction_prompt.hide()


func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(nearby_player) and not is_transitioning \
			and event is InputEventKey and event.pressed \
			and not event.echo and event.keycode == KEY_E:
		if destination_scene.is_empty() or not ResourceLoader.exists(destination_scene):
			push_error("Portal destination scene does not exist: %s" % destination_scene)
			return

		is_transitioning = true
		call_deferred("_change_scene", nearby_player)
		get_viewport().set_input_as_handled()


func _on_body_entered(body: Node2D) -> void:
	if body is Player and not is_instance_valid(nearby_player):
		nearby_player = body as Player
		interaction_prompt.show()


func _on_body_exited(body: Node2D) -> void:
	if body == nearby_player:
		nearby_player = null
		interaction_prompt.hide()


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
