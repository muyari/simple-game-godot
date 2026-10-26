extends Control

const LEVEL_NUMERALS = {1: "I", 2: "II", 3: "III", 4: "IV"}

@onready var backdrop: TextureRect = $Backdrop
@onready var campfire: TitleCampfire = %Campfire
@onready var title_screen: VBoxContainer = %TitleScreen
@onready var roster_screen: VBoxContainer = %RosterScreen
@onready var character_screen: VBoxContainer = %CharacterScreen
@onready var level_screen: VBoxContainer = %LevelScreen
@onready var character_list: VBoxContainer = %CharacterList
@onready var roster_status: Label = %RosterStatus
@onready var roster_continue_button: Button = %ContinueButton
@onready var roster_delete_button: Button = %DeleteButton
@onready var character_name_input: LineEdit = %CharacterNameInput
@onready var character_status: Label = %CharacterStatus
@onready var warrior_button: Button = %WarriorButton
@onready var witch_button: Button = %WitchButton
@onready var ranger_button: Button = %RangerButton
@onready var level_subtitle: Label = %LevelSubtitle
@onready var level_status: Label = %LevelStatus
@onready var level1_button: Button = %Level1Button
@onready var level2_button: Button = %Level2Button
@onready var level3_button: Button = %Level3Button
@onready var level4_button: Button = %Level4Button
@onready var delete_confirmation: ConfirmationDialog = %DeleteConfirmation

var settings_screen: VBoxContainer

var selected_character_id := ""
var selected_character_name := ""
var selected_character_class := ""
var new_character_class := "Warrior"
var pending_delete_id := ""


func _ready() -> void:
	theme = MenuStyle.get_theme()
	resized.connect(_fit_campfire)
	_fit_campfire()
	delete_confirmation.confirmed.connect(_on_delete_confirmed)
	_setup_class_buttons()
	_build_settings_screen()

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


func _fit_campfire() -> void:
	campfire.fit_to_backdrop(backdrop.size)


## A Settings button on the title screen (above Quit) and the screen it opens, with the volume sliders.
func _build_settings_screen() -> void:
	var settings_button := Button.new()
	settings_button.text = "Settings"
	settings_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	settings_button.custom_minimum_size.y = 54.0
	title_screen.add_child(settings_button)
	title_screen.move_child(settings_button, title_screen.get_node("QuitButton").get_index())

	settings_screen = VBoxContainer.new()
	settings_screen.add_theme_constant_override("separation", 12)
	settings_screen.hide()
	title_screen.get_parent().add_child(settings_screen)

	var eyebrow := Label.new()
	eyebrow.text = "BY THE FIRE"
	eyebrow.theme_type_variation = &"EyebrowLabel"
	settings_screen.add_child(eyebrow)
	var title := Label.new()
	title.text = "Settings"
	title.theme_type_variation = &"TitleLabel"
	settings_screen.add_child(title)
	settings_screen.add_child(HSeparator.new())
	settings_screen.add_child(AudioSettings.new())
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	settings_screen.add_child(spacer)
	var back_button := Button.new()
	back_button.text = "Back"
	back_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	back_button.custom_minimum_size.y = 54.0
	settings_screen.add_child(back_button)

	settings_button.pressed.connect(_show_screen.bind(settings_screen))
	back_button.pressed.connect(_show_screen.bind(title_screen))


func _setup_class_buttons() -> void:
	var class_group := ButtonGroup.new()
	for entry in [[warrior_button, "Warrior"], [witch_button, "Witch"], [ranger_button, "Ranger"]]:
		var button: Button = entry[0]
		button.button_group = class_group
		button.icon = MenuStyle.class_portrait(entry[1])
		button.expand_icon = false


func _show_screen(screen_to_show: Control) -> void:
	title_screen.hide()
	roster_screen.hide()
	character_screen.hide()
	level_screen.hide()
	settings_screen.hide()
	screen_to_show.show()
	screen_to_show.modulate.a = 0.0
	create_tween().tween_property(screen_to_show, "modulate:a", 1.0, 0.18)


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
		character_button.theme_type_variation = &"ChoiceButton"
		character_button.custom_minimum_size = Vector2(0, 56)
		character_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		character_button.toggle_mode = true
		character_button.icon = MenuStyle.class_portrait(character_class)
		character_button.text = "%s\n%s" % [character_name, character_class]
		character_button.pressed.connect(_on_roster_character_selected.bind(character_id))
		if character_id == selected_character_id:
			character_button.set_pressed_no_signal(true)
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
	for entry in [[level1_button, 1], [level2_button, 2], [level3_button, 3], [level4_button, 4]]:
		var button: Button = entry[0]
		var level_id: int = entry[1]
		button.disabled = not GameState.is_level_unlocked(level_id)
		button.text = "%s.   %s" % [LEVEL_NUMERALS[level_id], GameState.LEVEL_NAMES[level_id]]
		if button.disabled:
			button.text += "   (Locked)"


func _on_roster_create_pressed() -> void:
	character_name_input.text = ""
	new_character_class = "Warrior"
	warrior_button.button_pressed = true
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


func go_back() -> void:
	if delete_confirmation.visible:
		delete_confirmation.hide()
	elif character_screen.visible:
		_on_creation_cancel_pressed()
	elif level_screen.visible:
		_on_back_to_characters()
	elif roster_screen.visible:
		_on_roster_back_pressed()
	elif settings_screen.visible:
		_show_screen(title_screen)
	else:
		_on_quit_pressed()


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
	_load_level("res://main.tscn", GameState.LEVEL_NAMES[1])


func _on_level_2_selected() -> void:
	_load_level("res://desert.tscn", GameState.LEVEL_NAMES[2])


func _on_level_3_selected() -> void:
	_load_level("res://ice_caves.tscn", GameState.LEVEL_NAMES[3])


func _on_level_4_selected() -> void:
	_load_level("res://underworld.tscn", GameState.LEVEL_NAMES[4])


func _load_level(scene_path: String, level_name: String) -> void:
	if selected_character_id.is_empty():
		level_status.text = "Select a character before entering a level."
		return
	var level_id := GameState.get_level_id(scene_path)
	if not GameState.is_level_unlocked(level_id):
		level_status.text = "Complete the earlier levels to unlock this area."
		return

	if not GameState.save_character(GameState.get_inventory(), GameState.get_equipment()):
		level_status.text = "Could not save your character before setting out."
		return

	# Every region is entered from its hub, so that's where the journey starts.
	get_tree().set_meta("selected_character", selected_character_class)
	get_tree().set_meta("selected_character_id", selected_character_id)
	get_tree().set_meta("portal_spawn_position", GameState.get_hub_arrival(level_id))
	var error := GameState.change_scene(GameState.get_hub_scene(level_id))
	if error != OK:
		get_tree().remove_meta("portal_spawn_position")
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
	var error := GameState.change_scene("res://town.tscn")
	if error != OK:
		push_error("Could not load town: %s" % error_string(error))


func _on_back_to_characters() -> void:
	_refresh_character_roster()
	_show_screen(roster_screen)
