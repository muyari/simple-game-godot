extends Control
class_name HudMenu

## Top-right "Menu" button that drops down every major command (character,
## inventory, skills, quests, town portal...), so each one can be reached by
## mouse or touch in every scene. PC shows each entry's hotkey; touch devices
## hide them since there is no keyboard.

const BUTTON_SIZE := Vector2(116.0, 40.0)
const TOUCH_BUTTON_SIZE := Vector2(132.0, 54.0)
const ENTRY_WIDTH := 250.0
const ENTRY_HEIGHT := 40.0
const TOUCH_ENTRY_HEIGHT := 56.0
const MARGIN := 16.0

## Returns true while the HUD is free to take commands (no modal menu open).
var is_available: Callable = func() -> bool: return true

var _show_hotkeys := not TouchControls.is_supported()
var _menu_button: TouchButton
var _outside_catcher: Control
var _dropdown: PanelContainer
var _entries: VBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = MenuStyle.get_theme()
	_build()


## Adds a dropdown entry that calls `action` when chosen. `hotkey` is only
## shown on PC.
func add_command(label_text: String, hotkey: String, action: Callable) -> void:
	var entry := TouchButton.new()
	entry.text = label_text
	entry.alignment = HORIZONTAL_ALIGNMENT_LEFT
	entry.focus_mode = Control.FOCUS_NONE
	entry.custom_minimum_size = Vector2(
		ENTRY_WIDTH,
		ENTRY_HEIGHT if _show_hotkeys else TOUCH_ENTRY_HEIGHT
	)
	entry.add_theme_font_size_override("font_size", 17 if _show_hotkeys else 20)
	entry.activated.connect(_on_entry_activated.bind(action))
	_entries.add_child(entry)

	if _show_hotkeys and not hotkey.is_empty():
		var hotkey_label := Label.new()
		hotkey_label.text = hotkey
		hotkey_label.theme_type_variation = &"HintLabel"
		hotkey_label.add_theme_font_size_override("font_size", 15)
		hotkey_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hotkey_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hotkey_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hotkey_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		hotkey_label.offset_right = -16.0
		entry.add_child(hotkey_label)


func is_open() -> bool:
	return _dropdown.visible


func open_dropdown() -> void:
	_dropdown.show()
	_outside_catcher.show()


func close_dropdown() -> void:
	_dropdown.hide()
	_outside_catcher.hide()


func _process(_delta: float) -> void:
	var available := bool(is_available.call()) and not get_tree().paused
	_menu_button.visible = available
	if not available and is_open():
		close_dropdown()


func _input(event: InputEvent) -> void:
	if not is_open() or not event is InputEventKey or not event.pressed or event.echo:
		return
	# Any key closes the dropdown; Esc stops there instead of opening the pause menu.
	close_dropdown()
	if event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()


func _build() -> void:
	var touch := not _show_hotkeys

	# Clicking or tapping anywhere outside the dropdown closes it.
	_outside_catcher = Control.new()
	_outside_catcher.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_outside_catcher.mouse_filter = Control.MOUSE_FILTER_STOP
	_outside_catcher.gui_input.connect(_on_outside_input)
	_outside_catcher.hide()
	add_child(_outside_catcher)

	var button_size := TOUCH_BUTTON_SIZE if touch else BUTTON_SIZE
	_menu_button = TouchButton.new()
	_menu_button.text = "Menu"
	_menu_button.focus_mode = Control.FOCUS_NONE
	_menu_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_menu_button.add_theme_font_size_override("font_size", 20 if touch else 18)
	_menu_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_menu_button.offset_left = -MARGIN - button_size.x
	_menu_button.offset_top = MARGIN
	_menu_button.offset_right = -MARGIN
	_menu_button.offset_bottom = MARGIN + button_size.y
	_menu_button.activated.connect(_on_menu_button_activated)
	add_child(_menu_button)

	_dropdown = PanelContainer.new()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = MenuStyle.PANEL_BG
	panel_style.border_color = MenuStyle.GOLD_DIM
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(6)
	panel_style.set_content_margin_all(8.0)
	panel_style.shadow_color = Color(0, 0, 0, 0.45)
	panel_style.shadow_size = 12
	_dropdown.add_theme_stylebox_override("panel", panel_style)
	_dropdown.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	# Grows leftwards and down from just under the Menu button.
	_dropdown.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_dropdown.offset_left = -MARGIN
	_dropdown.offset_right = -MARGIN
	_dropdown.offset_top = MARGIN + button_size.y + 6.0
	_dropdown.offset_bottom = _dropdown.offset_top
	_dropdown.mouse_filter = Control.MOUSE_FILTER_STOP
	_dropdown.hide()
	add_child(_dropdown)

	_entries = VBoxContainer.new()
	_entries.add_theme_constant_override("separation", 4)
	_dropdown.add_child(_entries)


func _on_menu_button_activated() -> void:
	if is_open():
		close_dropdown()
	else:
		open_dropdown()


func _on_entry_activated(action: Callable) -> void:
	close_dropdown()
	action.call()


func _on_outside_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
		close_dropdown()
		_outside_catcher.accept_event()
