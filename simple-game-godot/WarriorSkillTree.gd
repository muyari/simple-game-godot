extends Control
class_name WarriorSkillTree

signal closed
signal loadout_changed
signal passive_tree_requested

const BRANCHES: Array[String] = ["All", "Single Target", "Area", "Support"]
const SKILL_SLOTS: Array[String] = ["Q", "W", "E", "R"]
const SKILL_ICONS := {
	"heavy_strike": preload("res://textures/warrior_skills/heavy_strike.svg"),
	"shield_bash": preload("res://textures/warrior_skills/shield_bash.svg"),
	"cleave": preload("res://textures/warrior_skills/cleave.svg"),
	"leap_slam": preload("res://textures/warrior_skills/leap_slam.svg"),
	"war_cry": preload("res://textures/warrior_skills/war_cry.svg"),
	"iron_resolve": preload("res://textures/warrior_skills/iron_resolve.svg")
}

var selected_branch := "All"
var selected_skill_id := "heavy_strike"
var branch_buttons: Dictionary = {}
var skill_buttons: Dictionary = {}
var skill_icons: Dictionary = {}
var skill_name_labels: Dictionary = {}
var skill_summary_labels: Dictionary = {}
var points_label: Label
var details_label: Label
var status_label: Label
var purchase_button: Button
var slot_picker: OptionButton
var assign_button: Button
var passive_tree_button: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	_refresh()


func open_tree() -> void:
	show()
	_refresh()


func _build_ui() -> void:
	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.015, 0.02, 0.03, 0.92)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 8.0
	panel.offset_top = 8.0
	panel.offset_right = -8.0
	panel.offset_bottom = -8.0
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#0d1216")
	panel_style.set_border_width_all(2)
	panel_style.border_color = Color("#4fb8c7")
	panel_style.set_corner_radius_all(6)
	panel_style.content_margin_left = 14.0
	panel_style.content_margin_right = 14.0
	panel_style.content_margin_top = 9.0
	panel_style.content_margin_bottom = 9.0
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	var contents := VBoxContainer.new()
	contents.add_theme_constant_override("separation", 7)
	panel.add_child(contents)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	contents.add_child(header)

	var active_tab := Button.new()
	active_tab.text = "Active Skills"
	active_tab.custom_minimum_size = Vector2(130.0, 36.0)
	active_tab.disabled = true
	_style_tab_button(active_tab, true)
	header.add_child(active_tab)

	passive_tree_button = Button.new()
	passive_tree_button.text = "Passive Tree"
	passive_tree_button.custom_minimum_size = Vector2(130.0, 36.0)
	passive_tree_button.pressed.connect(func(): passive_tree_requested.emit())
	header.add_child(passive_tree_button)

	var title := Label.new()
	title.text = "Warrior"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color("#d5e5df"))
	header.add_child(title)

	points_label = Label.new()
	points_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	points_label.add_theme_font_size_override("font_size", 15)
	points_label.add_theme_color_override("font_color", Color("#aee8dd"))
	header.add_child(points_label)

	var close_button := Button.new()
	close_button.text = "Close (Esc)"
	close_button.custom_minimum_size = Vector2(96.0, 36.0)
	close_button.pressed.connect(_on_close_pressed)
	header.add_child(close_button)

	var branch_row := HBoxContainer.new()
	branch_row.add_theme_constant_override("separation", 8)
	contents.add_child(branch_row)
	for branch in BRANCHES:
		var branch_button := Button.new()
		branch_button.text = branch
		branch_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		branch_button.custom_minimum_size.y = 32.0
		branch_button.add_theme_font_size_override("font_size", 13)
		branch_button.pressed.connect(_select_branch.bind(branch))
		branch_row.add_child(branch_button)
		branch_buttons[branch] = branch_button

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 178.0
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	contents.add_child(scroll)

	var skill_grid := GridContainer.new()
	skill_grid.columns = 3
	skill_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skill_grid.add_theme_constant_override("h_separation", 10)
	skill_grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(skill_grid)
	_build_skill_cards(skill_grid)

	details_label = Label.new()
	details_label.custom_minimum_size.y = 66.0
	details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details_label.add_theme_font_size_override("font_size", 14)
	details_label.add_theme_color_override("font_color", Color("#d5e5df"))
	contents.add_child(details_label)

	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 8)
	contents.add_child(action_row)

	purchase_button = Button.new()
	purchase_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	purchase_button.custom_minimum_size.y = 40.0
	purchase_button.add_theme_font_size_override("font_size", 15)
	purchase_button.pressed.connect(_purchase_selected_skill)
	action_row.add_child(purchase_button)

	slot_picker = OptionButton.new()
	slot_picker.custom_minimum_size.x = 96.0
	for slot in SKILL_SLOTS:
		slot_picker.add_item("Slot %s" % slot)
	action_row.add_child(slot_picker)

	assign_button = Button.new()
	assign_button.text = "Assign to Slot"
	assign_button.custom_minimum_size.y = 40.0
	assign_button.add_theme_font_size_override("font_size", 14)
	assign_button.pressed.connect(_assign_selected_skill)
	action_row.add_child(assign_button)

	status_label = Label.new()
	status_label.custom_minimum_size.y = 18.0
	status_label.add_theme_color_override("font_color", Color("#b6d9a0"))
	contents.add_child(status_label)


func _style_tab_button(button: Button, is_active: bool) -> void:
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(6)
	style.set_border_width_all(2)
	if is_active:
		style.bg_color = Color("#17363b")
		style.border_color = Color("#66cfc8")
		button.add_theme_color_override("font_color", Color("#ffd559"))
		button.add_theme_color_override("font_disabled_color", Color("#ffd559"))
	else:
		style.bg_color = Color("#11181c")
		style.border_color = Color("#3d5158")
		button.add_theme_color_override("font_color", Color("#9aacab"))
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("disabled", style)


func _build_skill_cards(parent: GridContainer) -> void:
	for definition in GameState.get_warrior_skill_definitions():
		var skill_id := str(definition["id"])
		var button := Button.new()
		button.name = "Card_%s" % skill_id
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0.0, 70.0)
		button.pressed.connect(_select_skill.bind(skill_id))
		parent.add_child(button)
		skill_buttons[skill_id] = button

		var row := HBoxContainer.new()
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.offset_left = 8.0
		row.offset_top = 4.0
		row.offset_right = -8.0
		row.offset_bottom = -4.0
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 10)
		button.add_child(row)

		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(48.0, 48.0)
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.texture = SKILL_ICONS[skill_id]
		row.add_child(icon)
		skill_icons[skill_id] = icon

		var text_column := VBoxContainer.new()
		text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_column.alignment = BoxContainer.ALIGNMENT_CENTER
		text_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(text_column)

		var name_label := Label.new()
		name_label.add_theme_font_size_override("font_size", 15)
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_column.add_child(name_label)
		skill_name_labels[skill_id] = name_label

		var summary_label := Label.new()
		summary_label.add_theme_font_size_override("font_size", 13)
		summary_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_column.add_child(summary_label)
		skill_summary_labels[skill_id] = summary_label


func _select_branch(branch: String) -> void:
	selected_branch = branch
	for definition in GameState.get_warrior_skill_definitions():
		if branch == "All" or str(definition["branch"]) == branch:
			selected_skill_id = str(definition["id"])
			break
	_refresh()


func _select_skill(skill_id: String) -> void:
	selected_skill_id = skill_id
	_refresh()


func _refresh() -> void:
	if not is_inside_tree() or points_label == null:
		return

	points_label.text = "Skill Points: %d  |  Level %d" % [
		GameState.skill_tree_points,
		GameState.player_level
	]
	for branch in BRANCHES:
		var button: Button = branch_buttons[branch]
		var is_selected_branch := branch == selected_branch
		button.disabled = is_selected_branch
		var branch_style := StyleBoxFlat.new()
		branch_style.set_corner_radius_all(4)
		branch_style.set_border_width_all(1)
		branch_style.bg_color = Color("#19383a") if is_selected_branch else Color("#13181b")
		branch_style.border_color = Color("#5bc7c4") if is_selected_branch \
			else Color("#20272b")
		button.add_theme_stylebox_override("normal", branch_style)
		button.add_theme_stylebox_override("hover", branch_style)
		button.add_theme_stylebox_override("disabled", branch_style)
		button.add_theme_color_override(
			"font_color",
			Color("#d6f1e7") if is_selected_branch else Color("#cbd2d1")
		)
		button.add_theme_color_override("font_disabled_color", Color("#d6f1e7"))

	for definition in GameState.get_warrior_skill_definitions():
		var skill_id := str(definition["id"])
		var button: Button = skill_buttons[skill_id]
		var rank := GameState.get_warrior_skill_rank(skill_id)
		var can_unlock := GameState.can_unlock_warrior_skill(skill_id)
		var is_selected := skill_id == selected_skill_id
		var matches_branch := selected_branch == "All" \
			or str(definition["branch"]) == selected_branch
		button.visible = matches_branch
		skill_name_labels[skill_id].text = "%s  [%d/%d]" % [
			definition["name"],
			rank,
			definition["max_rank"]
		]
		skill_summary_labels[skill_id].text = "%s  ·  Lv %d" % [
			definition["branch"],
			definition["required_level"]
		]
		skill_icons[skill_id].modulate = Color.WHITE if rank > 0 or can_unlock \
			else Color(0.62, 0.68, 0.72, 1.0)

		var style := StyleBoxFlat.new()
		style.set_corner_radius_all(6)
		style.set_border_width_all(3 if is_selected else 2)
		style.content_margin_left = 8.0
		style.content_margin_right = 8.0
		style.content_margin_top = 6.0
		style.content_margin_bottom = 6.0
		if rank >= int(definition["max_rank"]):
			style.bg_color = Color("#27352c")
			style.border_color = Color("#ffd559") if is_selected else Color("#c99b52")
		elif rank > 0:
			style.bg_color = Color("#15443b")
			style.border_color = Color.WHITE if is_selected else Color("#55e6c7")
		elif can_unlock:
			style.bg_color = Color("#202e39")
			style.border_color = Color.WHITE if is_selected else Color("#86c9e3")
		else:
			style.bg_color = Color("#11181c")
			style.border_color = Color.WHITE if is_selected else Color("#3d5158")
		button.add_theme_stylebox_override("normal", style)
		button.add_theme_stylebox_override("hover", style)
		button.add_theme_stylebox_override("pressed", style)
		button.add_theme_color_override(
			"font_color",
			Color("#ffd559") if is_selected else Color("#d6e0df")
		)
		skill_name_labels[skill_id].add_theme_color_override(
			"font_color",
			Color("#ffd559") if is_selected else Color("#d6e0df")
		)
		skill_summary_labels[skill_id].add_theme_color_override(
			"font_color",
			Color("#aee8dd") if rank > 0 else Color("#aebdc0")
		)

	_refresh_details()


func _refresh_details() -> void:
	var definition := GameState.get_warrior_skill_definition(selected_skill_id)
	if definition.is_empty():
		details_label.text = "Select a skill to view its details."
		purchase_button.disabled = true
		assign_button.disabled = true
		return

	var prerequisites: Array[String] = []
	for prerequisite_id in definition["prerequisites"]:
		var prerequisite := GameState.get_warrior_skill_definition(str(prerequisite_id))
		prerequisites.append(str(prerequisite.get("name", prerequisite_id)))
	var prerequisite_text := ", ".join(prerequisites) if not prerequisites.is_empty() else "None"
	var rank := GameState.get_warrior_skill_rank(selected_skill_id)
	details_label.text = "%s  |  %s\n%s\nRank %d/%d  |  Level %d  |  %d mana  |  %.1f sec cooldown  |  Requires: %s" % [
		definition["branch"],
		definition["name"],
		definition["description"],
		rank,
		definition["max_rank"],
		definition["required_level"],
		definition["mana_cost"],
		definition["cooldown"],
		prerequisite_text
	]

	purchase_button.disabled = not GameState.can_unlock_warrior_skill(selected_skill_id)
	if rank >= int(definition["max_rank"]):
		purchase_button.text = "Maximum rank"
	elif rank == 0:
		purchase_button.text = "Unlock  -  %d SP" % definition["point_cost"]
	else:
		purchase_button.text = "Upgrade  -  %d SP" % definition["point_cost"]
	assign_button.disabled = rank <= 0


func _purchase_selected_skill() -> void:
	if GameState.unlock_or_upgrade_warrior_skill(selected_skill_id):
		status_label.text = "%s upgraded." % GameState.get_warrior_skill_definition(
			selected_skill_id
		).get("name", "Skill")
		loadout_changed.emit()
	else:
		status_label.text = "Level, prerequisites, or skill points required."
	_refresh()


func _assign_selected_skill() -> void:
	if slot_picker.selected < 0 or slot_picker.selected >= SKILL_SLOTS.size():
		return
	var slot := SKILL_SLOTS[slot_picker.selected]
	if GameState.assign_warrior_skill(selected_skill_id, slot):
		status_label.text = "%s assigned to %s." % [
			GameState.get_warrior_skill_definition(selected_skill_id).get("name", "Skill"),
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
