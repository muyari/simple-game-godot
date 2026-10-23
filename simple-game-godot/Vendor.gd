extends Area2D
class_name Vendor

signal shop_requested

@onready var prompt: Label = $Prompt

var player_nearby := false


func _ready() -> void:
	add_to_group("interactables")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	prompt.hide()
	prompt.text = MenuStyle.interact_prompt(prompt.text.trim_prefix("E  "))


func can_interact(_player: Player) -> bool:
	return player_nearby


func interact(_player: Player) -> void:
	if player_nearby:
		shop_requested.emit()


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player_nearby = true
		prompt.show()


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		player_nearby = false
		prompt.hide()
