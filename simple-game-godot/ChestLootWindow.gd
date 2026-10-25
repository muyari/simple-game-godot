extends PanelContainer
class_name ChestLootWindow
## A compact version of the inventory panel listing a chest's loot.

signal take_requested(index: int)
signal take_all_requested
signal close_requested

const SLOT_COUNT = 5
const EMPTY_SLOT_COLOR := Color(0.52, 0.53, 0.49, 1)

var slots: Array[Button] = []
var selected_index := -1
var items: Array[ItemData] = []
var selected_item_label: Label
var status_label: Label
var take_button: Button
var take_all_button: Button


func _ready() -> void:
	custom_minimum_size = Vector2(460, 0)
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	var panel_style := StyleBoxFlat.new()
	panel_style.content_margin_left = 24.0
	panel_style.content_margin_top = 20.0
	panel_style.content_margin_right = 24.0
	panel_style.content_margin_bottom = 20.0
	panel_style.bg_color = Color(0.075, 0.09, 0.075, 0.98)
	panel_style.set_border_width_all(3)
	panel_style.border_color = Color(0.62, 0.49, 0.29, 1)
	panel_style.set_corner_radius_all(8)
	add_theme_stylebox_override("panel", panel_style)

	var contents := VBoxContainer.new()
	contents.add_theme_constant_override("separation", 10)
	add_child(contents)

	var title := Label.new()
	title.text = "Treasure Chest"
	title.add_theme_color_override("font_color", Color(0.91, 0.78, 0.52, 1))
	title.add_theme_font_size_override("font_size", 24)
	contents.add_child(title)

	selected_item_label = Label.new()
	selected_item_label.custom_minimum_size = Vector2(0, 42)
	selected_item_label.add_theme_color_override("font_color", Color(0.88, 0.83, 0.72, 1))
	contents.add_child(selected_item_label)

	var grid := GridContainer.new()
	grid.columns = SLOT_COUNT
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	contents.add_child(grid)
	for slot_index in SLOT_COUNT:
		var slot := Button.new()
		slot.custom_minimum_size = Vector2(76, 54)
		slot.alignment = HORIZONTAL_ALIGNMENT_LEFT
		slot.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		slot.add_theme_font_size_override("font_size", 11)
		var slot_style := StyleBoxFlat.new()
		slot_style.bg_color = Color(0.13, 0.15, 0.14, 1)
		slot_style.set_border_width_all(2)
		slot_style.border_color = Color(0.48, 0.4, 0.29, 1)
		slot_style.set_corner_radius_all(5)
		slot.add_theme_stylebox_override("normal", slot_style)
		slot.add_theme_stylebox_override("disabled", slot_style)
		var selected_style := slot_style.duplicate() as StyleBoxFlat
		selected_style.border_color = Color(0.91, 0.78, 0.52, 1)
		slot.set_meta("normal_style", slot_style)
		slot.set_meta("selected_style", selected_style)
		slot.pressed.connect(_on_slot_pressed.bind(slot_index))
		grid.add_child(slot)
		slots.append(slot)

	status_label = Label.new()
	status_label.add_theme_color_override("font_color", Color(1, 0.55, 0.45, 1))
	status_label.hide()
	contents.add_child(status_label)

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 8)
	contents.add_child(button_row)
	take_button = _make_button("Take Selected", button_row)
	take_button.pressed.connect(func(): take_requested.emit(selected_index))
	take_all_button = _make_button("Take All", button_row)
	take_all_button.pressed.connect(func(): take_all_requested.emit())
	var close_button := _make_button("Close" + MenuStyle.key_hint("Esc"), contents)
	close_button.pressed.connect(func(): close_requested.emit())
	hide()


func open(loot: Array[ItemData]) -> void:
	selected_index = 0 if not loot.is_empty() else -1
	status_label.hide()
	refresh(loot)
	show()


func refresh(loot: Array[ItemData]) -> void:
	items = loot
	if selected_index >= items.size():
		selected_index = items.size() - 1
	for index in slots.size():
		var slot := slots[index]
		if index < items.size():
			slot.text = items[index].display_name
			slot.tooltip_text = "%s (%s)" % [items[index].display_name, items[index].equipment_slot]
			slot.add_theme_color_override("font_color", items[index].icon_color)
			slot.disabled = false
		else:
			slot.text = "-"
			slot.tooltip_text = "Empty"
			slot.add_theme_color_override("font_color", EMPTY_SLOT_COLOR)
			slot.disabled = true
		var style_key := "selected_style" if index == selected_index else "normal_style"
		slot.add_theme_stylebox_override("normal", slot.get_meta(style_key))
	_update_selected_item()


func show_status(message: String) -> void:
	status_label.text = message
	status_label.show()


func _on_slot_pressed(slot_index: int) -> void:
	if slot_index >= items.size():
		return
	selected_index = slot_index
	status_label.hide()
	refresh(items)


func _update_selected_item() -> void:
	take_all_button.disabled = items.is_empty()
	if selected_index < 0:
		selected_item_label.text = "The chest is empty." if items.is_empty() else "Select an item to inspect it."
		take_button.disabled = true
		return
	var item := items[selected_index]
	take_button.disabled = false
	if not item.quest_id.is_empty():
		selected_item_label.text = "%s  |  Quest Item\nTaking this will update your quest. It won't use an inventory slot." % item.display_name
		return
	var stats: Array[String] = []
	if item.damage_bonus > 0:
		stats.append("+%d damage" % item.damage_bonus)
	if item.damage_reduction > 0:
		stats.append("-%d damage taken" % item.damage_reduction)
	selected_item_label.text = "%s  |  %s\n%s" % [
		item.display_name,
		item.equipment_slot,
		", ".join(stats) if not stats.is_empty() else "No combat bonus"
	]
	take_button.disabled = false


func _make_button(label: String, parent: Control) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(0, 38)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 16)
	parent.add_child(button)
	return button
