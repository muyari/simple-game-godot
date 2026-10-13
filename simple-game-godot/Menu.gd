extends Control

@onready var title_screen: VBoxContainer = $CenterContainer/MenuPanel/TitleScreen
@onready var roster_screen: VBoxContainer = $CenterContainer/MenuPanel/RosterScreen
@onready var character_screen: VBoxContainer = $CenterContainer/MenuPanel/CharacterScreen
@onready var level_screen: VBoxContainer = $CenterContainer/MenuPanel/LevelScreen
@onready var character_list: VBoxContainer = $CenterContainer/MenuPanel/RosterScreen/CharacterScroll/CharacterList
@onready var roster_status: Label = $CenterContainer/MenuPanel/RosterScreen/RosterStatus
@onready var roster_continue_button: Button = $CenterContainer/MenuPanel/RosterScreen/RosterActions/ContinueButton
@onready var roster_delete_button: Button = $CenterContainer/MenuPanel/RosterScreen/RosterActions/DeleteButton
@onready var character_name_input: LineEdit = $CenterContainer/MenuPanel/CharacterScreen/CharacterNameInput
@onready var character_status: Label = $CenterContainer/MenuPanel/CharacterScreen/CharacterStatus
@onready var level_subtitle: Label = $CenterContainer/MenuPanel/LevelScreen/Subtitle
@onready var level_status: Label = $CenterContainer/MenuPanel/LevelScreen/LevelStatus
@onready var level2_button: Button = $CenterContainer/MenuPanel/LevelScreen/Level2Button
@onready var level3_button: Button = $CenterContainer/MenuPanel/LevelScreen/Level3Button
@onready var level4_button: Button = $CenterContainer/MenuPanel/LevelScreen/Level4Button
@onready var start_in_town_button: Button = $CenterContainer/MenuPanel/LevelScreen/LevelHeader/TownButton
@onready var delete_confirmation: ConfirmationDialog = $DeleteConfirmation

var selected_character_id := ""
var selected_character_name := ""
var selected_character_class := ""
var new_character_class := "Warrior"
var pending_delete_id := ""


func _ready() -> void:
	$CenterContainer/MenuPanel/TitleScreen/StartButton.pressed.connect(_on_start_pressed)
	$CenterContainer/MenuPanel/TitleScreen/QuitButton.pressed.connect(_on_quit_pressed)
	start_in_town_button.pressed.connect(_on_start_in_town_pressed)
	delete_confirmation.confirmed.connect(_on_delete_confirmed)

	if get_tree().has_meta("return_to_character_select"):
		get_tree().remove_meta("return_to_character_select")
		selected_character_id = str(get_tree().get_meta("selected_character_id", ""))
		get_tree().remove_meta("selected_character_id")
		_refresh_character_roster()
		_show_screen(roster_screen)
	elif get_tree().has_meta("return_to_level_select"):
		get_tree().remove_meta("return_to_level_select")
		selected_character_id = str(get_tree().get_meta("selected_character_id", ""))
		if not selected_character_id.is_empty() and GameState.select_character(selected_character_id):
			var character := GameState.get_character(selected_character_id)
			selected_character_name = str(character.get("name", "Adventurer"))
			selected_character_class = str(character.get("class", "Warrior"))
			_show_level_screen()
		else:
			_refresh_character_roster()
			_show_screen(roster_screen)
	else:
		_refresh_character_roster()
		_show_screen(title_screen)


func _on_start_pressed() -> void:
	_refresh_character_roster()
	_show_screen(roster_screen)


func _show_screen(screen_to_show: Control) -> void:
	title_screen.hide()
	roster_screen.hide()
	character_screen.hide()
	level_screen.hide()
	screen_to_show.show()


func _refresh_character_roster() -> void:
	for child in character_list.get_children():
		character_list.remove_child(child)
		child.queue_free()

	var characters := GameState.get_characters()
	var selected_character_exists := false
	for character in characters:
		var character_id := str(character.get("id", ""))
		var character_name := str(character.get("name", "Adventurer"))
		var character_class := str(character.get("class", "Warrior"))
		var character_button := Button.new()
		character_button.custom_minimum_size = Vector2(0, 52)
		character_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		character_button.add_theme_font_size_override("font_size", 18)
		character_button.text = "%s  -  %s" % [character_name, character_class]
		character_button.pressed.connect(_on_roster_character_selected.bind(character_id))
		if character_id == selected_character_id:
			character_button.add_theme_color_override("font_color", Color(0.91, 0.78, 0.52, 1))
			selected_character_exists = true
		character_list.add_child(character_button)

	if not selected_character_exists:
		selected_character_id = ""
		roster_continue_button.disabled = true
		roster_delete_button.disabled = true
		roster_status.text = "No character selected."
	else:
		roster_continue_button.disabled = false
		roster_delete_button.disabled = false
	if characters.is_empty():
		roster_status.text = "No characters yet. Create one to begin."


func _on_roster_character_selected(character_id: String) -> void:
	var character := GameState.get_character(character_id)
	if character.is_empty():
		return

	selected_character_id = character_id
	selected_character_name = str(character.get("name", "Adventurer"))
	selected_character_class = str(character.get("class", "Warrior"))
	roster_status.text = "Selected: %s (%s)" % [selected_character_name, selected_character_class]
	_refresh_character_roster()


func _on_roster_continue_pressed() -> void:
	if selected_character_id.is_empty():
		roster_status.text = "Select a character first."
		return
	if not GameState.select_character(selected_character_id):
		roster_status.text = "Could not load that character."
		return

	var character := GameState.get_character(selected_character_id)
	selected_character_name = str(character.get("name", "Adventurer"))
	selected_character_class = str(character.get("class", "Warrior"))
	_show_level_screen()


func _show_level_screen() -> void:
	level_subtitle.text = "%s  -  %s" % [selected_character_name, selected_character_class]
	_refresh_level_buttons()
	_show_screen(level_screen)


func _refresh_level_buttons() -> void:
	level2_button.disabled = not GameState.is_level_unlocked(2)
	level3_button.disabled = not GameState.is_level_unlocked(3)
	level4_button.disabled = not GameState.is_level_unlocked(4)
	level2_button.text = "Level 2  -  Sunscorch Sands" if not level2_button.disabled else "Level 2  -  Sunscorch Sands (Locked)"
	level3_button.text = "Level 3  -  The Ice Caves" if not level3_button.disabled else "Level 3  -  The Ice Caves (Locked)"
	level4_button.text = "Level 4  -  The Futuristic AI Zone" if not level4_button.disabled else "Level 4  -  The Futuristic AI Zone (Locked)"


func _on_roster_create_pressed() -> void:
	character_name_input.text = ""
	new_character_class = "Warrior"
	character_status.text = "Choose a class for your character."
	_show_screen(character_screen)
	character_name_input.grab_focus()


func _on_roster_delete_pressed() -> void:
	if selected_character_id.is_empty():
		roster_status.text = "Select a character to delete."
		return

	pending_delete_id = selected_character_id
	delete_confirmation.dialog_text = "Delete %s? This cannot be undone." % selected_character_name
	delete_confirmation.popup_centered()


func _on_delete_confirmed() -> void:
	if pending_delete_id.is_empty():
		return
	if not GameState.delete_character(pending_delete_id):
		roster_status.text = "Could not delete that character."
		return

	if pending_delete_id == selected_character_id:
		selected_character_id = ""
		selected_character_name = ""
		selected_character_class = ""
	pending_delete_id = ""
	_refresh_character_roster()
	_show_screen(roster_screen)


func _on_creation_cancel_pressed() -> void:
	_refresh_character_roster()
	_show_screen(roster_screen)


func _on_roster_back_pressed() -> void:
	_show_screen(title_screen)


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_warrior_selected() -> void:
	new_character_class = "Warrior"
	character_status.text = "Warrior selected"


func _on_witch_selected() -> void:
	new_character_class = "Witch"
	character_status.text = "Witch selected"


func _on_ranger_selected() -> void:
	new_character_class = "Ranger"
	character_status.text = "Ranger selected"


func _on_character_continue() -> void:
	var character_id := GameState.create_character(character_name_input.text, new_character_class)
	if character_id.is_empty():
		character_status.text = "Enter a name to create your character."
		return

	selected_character_id = character_id
	var character := GameState.get_character(character_id)
	selected_character_name = str(character.get("name", "Adventurer"))
	selected_character_class = str(character.get("class", "Warrior"))
	_refresh_character_roster()
	roster_status.text = "%s joined your roster." % selected_character_name
	_show_screen(roster_screen)


func _on_level_1_selected() -> void:
	_load_level("res://main.tscn", "Forest Level 1")


func _on_level_2_selected() -> void:
	_load_level("res://desert.tscn", "Sunscorch Sands")


func _on_level_3_selected() -> void:
	_load_level("res://ice_caves.tscn", "The Ice Caves")


func _on_level_4_selected() -> void:
	_load_level("res://futuristic_ai_zone.tscn", "The Futuristic AI Zone")


func _load_level(scene_path: String, level_name: String) -> void:
	if selected_character_id.is_empty():
		level_status.text = "Select a character before entering a level."
		return
	var level_id := GameState.get_level_id(scene_path)
	if not GameState.is_level_unlocked(level_id):
		level_status.text = "Complete the earlier levels to unlock this area."
		return

	get_tree().set_meta("selected_character", selected_character_class)
	get_tree().set_meta("selected_character_id", selected_character_id)
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("Could not load %s: %s" % [level_name, error_string(error)])


func _on_start_in_town_pressed() -> void:
	if selected_character_id.is_empty():
		level_status.text = "Select a character before entering town."
		return
	if not GameState.save_character(GameState.get_inventory(), GameState.get_equipment()):
		level_status.text = "Could not save your character before entering town."
		return

	get_tree().set_meta("selected_character", selected_character_class)
	get_tree().set_meta("selected_character_id", selected_character_id)
	var error := get_tree().change_scene_to_file("res://town.tscn")
	if error != OK:
		push_error("Could not load town: %s" % error_string(error))


func _on_back_to_characters() -> void:
	_refresh_character_roster()
	_show_screen(roster_screen)
