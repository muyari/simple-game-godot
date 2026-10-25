extends Control
class_name QuestDialogue
## Paged NPC dialogue box, styled like the vendor's. The last page can offer Accept / Decline.

signal accepted
signal declined
signal closed

var pages: Array[String] = []
var page_index := 0
var offers_choice := false
var speaker_label: Label
var quest_title_label: Label
var text_label: Label
var primary_button: Button
var secondary_button: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	hide()

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(620, 0)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel.offset_left = -310.0
	panel.offset_right = 310.0
	panel.offset_bottom = -40.0
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.075, 0.09, 0.075, 0.98)
	panel_style.set_border_width_all(3)
	panel_style.border_color = Color(0.62, 0.49, 0.29, 1)
	panel_style.set_corner_radius_all(8)
	panel_style.content_margin_left = 20.0
	panel_style.content_margin_right = 20.0
	panel_style.content_margin_top = 12.0
	panel_style.content_margin_bottom = 12.0
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	var contents := VBoxContainer.new()
	contents.add_theme_constant_override("separation", 8)
	panel.add_child(contents)

	var header := HBoxContainer.new()
	contents.add_child(header)
	speaker_label = Label.new()
	speaker_label.add_theme_color_override("font_color", Color(0.91, 0.78, 0.52, 1))
	speaker_label.add_theme_font_size_override("font_size", 22)
	speaker_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(speaker_label)
	quest_title_label = Label.new()
	quest_title_label.add_theme_color_override("font_color", Color("#ffd34d"))
	quest_title_label.add_theme_font_size_override("font_size", 14)
	header.add_child(quest_title_label)

	text_label = Label.new()
	text_label.custom_minimum_size = Vector2(0, 72)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.add_theme_color_override("font_color", Color("#e8ca86"))
	text_label.add_theme_font_size_override("font_size", 18)
	contents.add_child(text_label)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	contents.add_child(buttons)
	primary_button = _make_button(buttons)
	primary_button.pressed.connect(press_primary)
	secondary_button = _make_button(buttons)
	secondary_button.pressed.connect(press_secondary)


## Shows the given pages. If offer_choice is true, the last page asks the player to accept or decline.
func start(speaker: String, quest_title: String, dialogue_pages: Array[String], offer_choice: bool) -> void:
	speaker_label.text = speaker
	quest_title_label.text = quest_title
	pages = dialogue_pages
	offers_choice = offer_choice
	page_index = 0
	_show_page()
	show()


## E key / left button: continue, or accept on the final choice page.
func press_primary() -> void:
	if page_index < pages.size() - 1:
		page_index += 1
		_show_page()
	elif offers_choice:
		accepted.emit()
	else:
		_close()


## Esc key / right button: decline on the choice page, otherwise leave the conversation.
func press_secondary() -> void:
	if _is_choice_page():
		declined.emit()
	else:
		_close()


func _close() -> void:
	hide()
	closed.emit()


func _is_choice_page() -> bool:
	return offers_choice and page_index == pages.size() - 1


func _show_page() -> void:
	text_label.text = pages[page_index]
	if _is_choice_page():
		primary_button.text = "Accept" + MenuStyle.key_hint("E")
		secondary_button.text = "Decline" + MenuStyle.key_hint("Esc")
	elif page_index < pages.size() - 1:
		primary_button.text = "Continue" + MenuStyle.key_hint("E")
		secondary_button.text = "Leave" + MenuStyle.key_hint("Esc")
	else:
		primary_button.text = "Farewell" + MenuStyle.key_hint("E")
		secondary_button.text = "Close" + MenuStyle.key_hint("Esc")
	secondary_button.visible = _is_choice_page() or page_index < pages.size() - 1


func _make_button(parent: Control) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 42)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 18)
	parent.add_child(button)
	return button
