extends Control

@onready var title_screen: VBoxContainer = $CenterContainer/MenuPanel/TitleScreen
@onready var character_screen: VBoxContainer = $CenterContainer/MenuPanel/CharacterScreen
@onready var level_screen: VBoxContainer = $CenterContainer/MenuPanel/LevelScreen
@onready var character_status: Label = $CenterContainer/MenuPanel/CharacterScreen/CharacterStatus
@onready var level_subtitle: Label = $CenterContainer/MenuPanel/LevelScreen/Subtitle
@onready var level_status: Label = $CenterContainer/MenuPanel/LevelScreen/LevelStatus

var selected_character := ""


func _ready() -> void:
	$CenterContainer/MenuPanel/TitleScreen/StartButton.pressed.connect(_on_start_pressed)
	$CenterContainer/MenuPanel/TitleScreen/QuitButton.pressed.connect(_on_quit_pressed)

	if get_tree().has_meta("return_to_level_select"):
		get_tree().remove_meta("return_to_level_select")
		selected_character = str(get_tree().get_meta("selected_character", "Warrior"))
		level_subtitle.text = "Your selected hero: %s" % selected_character
		_show_screen(level_screen)
	else:
		_show_screen(title_screen)


func _on_start_pressed() -> void:
	_show_screen(character_screen)


func _show_screen(screen_to_show: Control) -> void:
	title_screen.hide()
	character_screen.hide()
	level_screen.hide()
	screen_to_show.show()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_warrior_selected() -> void:
	selected_character = "Warrior"
	character_status.text = "Warrior selected"


func _on_witch_selected() -> void:
	selected_character = "Witch"
	character_status.text = "Witch selected"


func _on_character_continue() -> void:
	if selected_character.is_empty():
		character_status.text = "Select a character first."
		return

	level_subtitle.text = "Your selected hero: %s" % selected_character
	_show_screen(level_screen)


func _on_level_1_selected() -> void:
	_load_level("res://main.tscn", "Forest Level 1")


func _on_level_2_selected() -> void:
	_load_level("res://desert.tscn", "Sunscorch Sands")


func _load_level(scene_path: String, level_name: String) -> void:
	if selected_character.is_empty():
		level_status.text = "Select a character before entering a level."
		return

	get_tree().set_meta("selected_character", selected_character)
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("Could not load %s: %s" % [level_name, error_string(error)])


func _on_back_to_characters() -> void:
	_show_screen(character_screen)
