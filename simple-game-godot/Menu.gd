extends Control

@onready var character_screen: VBoxContainer = $CenterContainer/MenuPanel/CharacterScreen
@onready var level_screen: VBoxContainer = $CenterContainer/MenuPanel/LevelScreen
@onready var character_status: Label = $CenterContainer/MenuPanel/CharacterScreen/CharacterStatus
@onready var level_status: Label = $CenterContainer/MenuPanel/LevelScreen/LevelStatus

var warrior_selected := false


func _ready() -> void:
	if get_tree().has_meta("return_to_level_select"):
		get_tree().remove_meta("return_to_level_select")
		warrior_selected = true
		character_screen.hide()
		level_screen.show()
	else:
		character_screen.show()
		level_screen.hide()


func _on_warrior_selected() -> void:
	warrior_selected = true
	character_status.text = "Warrior selected"


func _on_character_continue() -> void:
	if not warrior_selected:
		character_status.text = "Select a character first."
		return

	character_screen.hide()
	level_screen.show()


func _on_level_1_selected() -> void:
	_load_level("res://main.tscn", "Forest Level 1")


func _on_level_2_selected() -> void:
	_load_level("res://desert.tscn", "Sunscorch Sands")


func _load_level(scene_path: String, level_name: String) -> void:
	if not warrior_selected:
		level_status.text = "Select a character before entering a level."
		return

	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("Could not load %s: %s" % [level_name, error_string(error)])


func _on_back_to_characters() -> void:
	level_screen.hide()
	character_screen.show()
