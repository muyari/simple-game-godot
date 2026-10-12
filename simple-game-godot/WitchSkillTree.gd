extends Control
class_name WitchSkillTree

signal closed
signal loadout_changed

const BRANCHES = ["Elemental", "Summoner", "Support"]
const SKILL_SLOTS = ["Q", "W", "E", "R"]

var selected_branch := "Elemental"
var selected_skill_id := "firebolt"
var branch_buttons: Dictionary = {}
var skill_list: VBoxContainer
var points_label: Label
var details_label: Label
var status_label: Label
var purchase_button: Button
var slot_picker: OptionButton
var assign_button: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	_refresh()


func open_tree() -> void:
	visible = true
	_refresh()


func _build_ui() -> void:
	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.015, 0.025, 0.035, 0.88)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 18.0
	panel.offset_top = 18.0
	panel.offset_right = -18.0
	panel.offset_bottom = -18.0
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.055, 0.09, 0.105, 0.98)
	panel_style.set_border_width_all(2)
	panel_style.border_color = Color("#66cfc8")
	panel_style.set_corner_radius_all(6)
	panel_style.content_margin_left = 18.0
	panel_style.content_margin_right = 18.0
	panel_style.content_margin_top = 12.0
	panel_style.content_margin_bottom = 12.0
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	var contents := VBoxContainer.new()
	contents.add_theme_constant_override("separation", 6)
	panel.add_child(contents)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	contents.add_child(header)

	var title := Label.new()
	title.text = "Witch Skill Tree"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("#e9cb83"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	points_label = Label.new()
	points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	points_label.add_theme_color_override("font_color", Color("#aee8dd"))
	header.add_child(points_label)

	var close_button := Button.new()
	close_button.text = "Close"
	_style_button(close_button, 42.0)
	close_button.pressed.connect(_on_close_pressed)
	header.add_child(close_button)

	var branch_row := HBoxContainer.new()
	branch_row.add_theme_constant_override("separation", 8)
	contents.add_child(branch_row)
	for branch in BRANCHES:
		var branch_button := Button.new()
		branch_button.text = branch
		branch_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_button(branch_button, 40.0)
		branch_button.pressed.connect(_select_branch.bind(branch))
		branch_row.add_child(branch_button)
		branch_buttons[branch] = branch_button

	var list_scroll := ScrollContainer.new()
	list_scroll.custom_minimum_size.y = 84.0
	list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	contents.add_child(list_scroll)

	skill_list = VBoxContainer.new()
	skill_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skill_list.add_theme_constant_override("separation", 5)
	list_scroll.add_child(skill_list)

	details_label = Label.new()
	details_label.custom_minimum_size.y = 72.0
	details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details_label.add_theme_color_override("font_color", Color("#d5e5df"))
	contents.add_child(details_label)

	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 8)
	contents.add_child(action_row)

	purchase_button = Button.new()
	purchase_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(purchase_button, 44.0)
	purchase_button.pressed.connect(_purchase_selected_skill)
	action_row.add_child(purchase_button)

	slot_picker = OptionButton.new()
	slot_picker.custom_minimum_size.x = 92.0
	for slot in SKILL_SLOTS:
		slot_picker.add_item("Slot %s" % slot)
	action_row.add_child(slot_picker)

	assign_button = Button.new()
	assign_button.text = "Assign"
	_style_button(assign_button, 44.0)
	assign_button.pressed.connect(_assign_selected_skill)
	action_row.add_child(assign_button)

	status_label = Label.new()
	status_label.custom_minimum_size.y = 18.0
	status_label.add_theme_color_override("font_color", Color("#b6d9a0"))
	contents.add_child(status_label)


func _style_button(button: Button, height: float) -> void:
	button.custom_minimum_size.y = height
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", 16)


func _select_branch(branch: String) -> void:
	selected_branch = branch
	var definitions := GameState.get_witch_skill_definitions()
	for definition in definitions:
		if definition["branch"] == branch:
			selected_skill_id = definition["id"]
			break
	_refresh()


func _select_skill(skill_id: String) -> void:
	selected_skill_id = skill_id
	_refresh()


func _refresh() -> void:
	if not is_inside_tree() or skill_list == null:
		return
	points_label.text = "Skill points: %d" % GameState.skill_tree_points
	for branch in BRANCHES:
		var branch_button: Button = branch_buttons[branch]
		branch_button.disabled = branch == selected_branch

	for child in skill_list.get_children():
		skill_list.remove_child(child)
		child.queue_free()

	for definition in GameState.get_witch_skill_definitions():
		if definition["branch"] != selected_branch:
			continue
		var skill_id := str(definition["id"])
		var rank := GameState.get_witch_skill_rank(skill_id)
		var skill_button := Button.new()
		var node_state := "Locked" if rank == 0 else "Rank %d/%d" % [rank, definition["max_rank"]]
		skill_button.text = "%s  -  %s" % [definition["name"], node_state]
		skill_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_button(skill_button, 40.0)
		if skill_id == selected_skill_id:
			skill_button.add_theme_color_override("font_color", Color("#e9cb83"))
		skill_button.pressed.connect(_select_skill.bind(skill_id))
		skill_list.add_child(skill_button)

	_refresh_details()


func _refresh_details() -> void:
	var definition := GameState.get_witch_skill_definition(selected_skill_id)
	if definition.is_empty():
		details_label.text = "Select a skill node."
		purchase_button.disabled = true
		assign_button.disabled = true
		return

	var rank := GameState.get_witch_skill_rank(selected_skill_id)
	var prerequisite_names: Array[String] = []
	for prerequisite_id in definition["prerequisites"]:
		var prerequisite := GameState.get_witch_skill_definition(prerequisite_id)
		prerequisite_names.append(str(prerequisite.get("name", prerequisite_id)))
	var prerequisites_text := ", ".join(prerequisite_names) if not prerequisite_names.is_empty() else "None"
	var equipped_slots: Array[String] = []
	for slot in SKILL_SLOTS:
		if GameState.get_witch_equipped_skill(slot) == selected_skill_id:
			equipped_slots.append(slot)
	var equipped_text := ", ".join(equipped_slots) if not equipped_slots.is_empty() else "Not equipped"
	details_label.text = "%s | %s\n%s\nRank %d/%d  |  Level %d  |  %d mana  |  %.1f sec cooldown  |  Requires: %s  |  %s" % [
		definition["branch"],
		definition["name"],
		definition["description"],
		rank,
		definition["max_rank"],
		definition["required_level"],
		definition["mana_cost"],
		definition["cooldown"],
		prerequisites_text,
		equipped_text
	]

	var can_purchase := GameState.can_unlock_witch_skill(selected_skill_id)
	purchase_button.disabled = not can_purchase
	if rank >= int(definition["max_rank"]):
		purchase_button.text = "Maximum rank"
	elif rank == 0:
		purchase_button.text = "Unlock  -  %d SP" % definition["point_cost"]
	else:
		purchase_button.text = "Upgrade  -  %d SP" % definition["point_cost"]
	assign_button.disabled = rank == 0


func _purchase_selected_skill() -> void:
	if GameState.unlock_or_upgrade_witch_skill(selected_skill_id):
		status_label.text = "%s upgraded." % GameState.get_witch_skill_definition(selected_skill_id).get("name", "Skill")
	else:
		status_label.text = "Level, prerequisites, or skill points required."
	_refresh()


func _assign_selected_skill() -> void:
	if slot_picker.selected < 0 or slot_picker.selected >= SKILL_SLOTS.size():
		return
	var slot: String = SKILL_SLOTS[slot_picker.selected]
	if GameState.assign_witch_skill(selected_skill_id, slot):
		status_label.text = "%s assigned to %s." % [
			GameState.get_witch_skill_definition(selected_skill_id).get("name", "Skill"),
			slot
		]
		loadout_changed.emit()
	else:
		status_label.text = "Unlock this skill before assigning it."
	_refresh()


func _on_close_pressed() -> void:
	hide()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo \
			and event.keycode == KEY_ESCAPE:
		_on_close_pressed()
		get_viewport().set_input_as_handled()