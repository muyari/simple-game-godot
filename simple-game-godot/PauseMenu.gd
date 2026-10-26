extends CanvasLayer
class_name PauseMenu

signal return_to_character_selection_requested
signal close_game_requested

var backdrop: ColorRect
var panel: PanelContainer
var resume_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_menu()
	hide()


func open_menu() -> void:
	if visible:
		return
	show()
	get_tree().paused = true
	Audio.play_sfx("ui_open")
	backdrop.modulate.a = 0.0
	panel.modulate.a = 0.0
	panel.pivot_offset = panel.size * 0.5
	panel.scale = Vector2(0.96, 0.96)
	var tween := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(backdrop, "modulate:a", 1.0, 0.16)
	tween.tween_property(panel, "modulate:a", 1.0, 0.18)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.18)
	resume_button.grab_focus()


func close_menu() -> void:
	hide()
	Audio.play_sfx("ui_close")
	get_tree().paused = false


func _build_menu() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = MenuStyle.get_theme()
	add_child(root)

	backdrop = ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.015, 0.02, 0.018, 0.72)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)

	panel = PanelContainer.new()
	panel.theme_type_variation = &"MenuPanel"
	panel.custom_minimum_size = Vector2(460.0, 0.0)
	center.add_child(panel)

	var contents := VBoxContainer.new()
	contents.add_theme_constant_override("separation", 12)
	panel.add_child(contents)

	var eyebrow := Label.new()
	eyebrow.text = "THE JOURNEY WAITS"
	eyebrow.theme_type_variation = &"EyebrowLabel"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	contents.add_child(eyebrow)

	var title := Label.new()
	title.text = "Paused"
	title.theme_type_variation = &"TitleLabel"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	contents.add_child(title)

	contents.add_child(HSeparator.new())

	resume_button = _create_button("Resume")
	resume_button.pressed.connect(close_menu)
	contents.add_child(resume_button)

	contents.add_child(AudioSettings.new())

	var character_button := _create_button("Return to Character Selection")
	character_button.pressed.connect(_on_return_to_character_selection_pressed)
	contents.add_child(character_button)

	var close_button := _create_button("Close Game")
	close_button.theme_type_variation = &"DangerButton"
	close_button.pressed.connect(_on_close_game_pressed)
	contents.add_child(close_button)

	var hint := Label.new()
	hint.text = "Press Esc to resume"
	hint.theme_type_variation = &"HintLabel"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.visible = not TouchControls.is_supported()
	contents.add_child(hint)


func _create_button(button_text: String) -> Button:
	var button := Button.new()
	button.text = button_text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.y = 50.0
	return button


func _on_return_to_character_selection_pressed() -> void:
	return_to_character_selection_requested.emit()


func _on_close_game_pressed() -> void:
	close_game_requested.emit()
