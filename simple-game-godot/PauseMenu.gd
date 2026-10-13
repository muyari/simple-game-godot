extends CanvasLayer
class_name PauseMenu

signal return_to_character_selection_requested
signal close_game_requested

var backdrop: ColorRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_menu()
	hide()


func open_menu() -> void:
	if visible:
		return
	show()
	get_tree().paused = true


func close_menu() -> void:
	hide()
	get_tree().paused = false


func _build_menu() -> void:
	backdrop = ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.015, 0.02, 0.018, 0.78)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(420.0, 0.0)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -210.0
	panel.offset_top = -180.0
	panel.offset_right = 210.0
	panel.offset_bottom = 180.0
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#131a17")
	panel_style.set_border_width_all(3)
	panel_style.border_color = Color("#9e7d4a")
	panel_style.set_corner_radius_all(8)
	panel_style.content_margin_left = 28.0
	panel_style.content_margin_right = 28.0
	panel_style.content_margin_top = 24.0
	panel_style.content_margin_bottom = 24.0
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	var contents := VBoxContainer.new()
	contents.add_theme_constant_override("separation", 12)
	panel.add_child(contents)

	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color("#e8c77e"))
	contents.add_child(title)

	var resume_button := _create_button("Resume")
	resume_button.pressed.connect(close_menu)
	contents.add_child(resume_button)

	var character_button := _create_button("Return to Character Selection")
	character_button.pressed.connect(_on_return_to_character_selection_pressed)
	contents.add_child(character_button)

	var close_button := _create_button("Close Game")
	close_button.pressed.connect(_on_close_game_pressed)
	contents.add_child(close_button)

	var hint := Label.new()
	hint.text = "Press Esc to resume"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color("#c4c9c0"))
	contents.add_child(hint)


func _create_button(button_text: String) -> Button:
	var button := Button.new()
	button.text = button_text
	button.custom_minimum_size.y = 48.0
	button.add_theme_font_size_override("font_size", 18)
	return button


func _on_return_to_character_selection_pressed() -> void:
	return_to_character_selection_requested.emit()


func _on_close_game_pressed() -> void:
	close_game_requested.emit()
