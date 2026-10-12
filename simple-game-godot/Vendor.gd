extends Area2D
class_name Vendor

signal shop_requested

@onready var prompt: Label = $Prompt

var player_nearby := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	prompt.hide()


func _unhandled_input(event: InputEvent) -> void:
	if player_nearby and event is InputEventKey and event.pressed \
			and not event.echo and event.keycode == KEY_E:
		shop_requested.emit()
		get_viewport().set_input_as_handled()


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player_nearby = true
		prompt.show()


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		player_nearby = false
		prompt.hide()
