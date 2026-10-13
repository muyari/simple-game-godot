extends Control
class_name WitchSkillTree

signal closed
signal loadout_changed
signal passives_changed

const BRANCHES_SKILLS = ["All", "Elemental", "Summoner", "Support"]
const SKILL_SLOTS = ["Q", "W", "E", "R"]

const BRANCHES_PASSIVES = [
	"All",
	"Spire of Arcana",
	"Shadow & Siphon",
	"Aegis of Phantoms",
	"Mystic Wellspring",
	"Astral Convergence"
]

const GRID_CELL_W = 180.0
const GRID_CELL_H = 110.0
const PADDING_X = 60.0
const PADDING_Y = 50.0
const STANDARD_NODE_SIZE = Vector2(150.0, 68.0)
const SUPER_NODE_SIZE = Vector2(174.0, 92.0)

var active_tab: String = "passives"

# Active Skills variables
var selected_skill_branch := "All"
var selected_skill_id := "firebolt"
var skill_branch_buttons: Dictionary = {}
var skill_grid: GridContainer
var skill_tile_buttons: Dictionary = {}
var skill_details_label: Label
var skill_status_label: Label
var skill_purchase_button: Button
var skill_slot_picker: OptionButton
var skill_assign_button: Button

# Passive Tree variables
var selected_passive_branch := "All"
var selected_passive_id := "arcane_spark"
var passive_branch_buttons: Dictionary = {}
var passive_node_buttons: Dictionary = {}
var node_container: Control
var passive_scroll_container: ScrollContainer
var stats_summary_label: Label
var passive_details_label: Label
var passive_status_label: Label
var unlock_passive_button: Button

# Common controls
var tab_skills_button: Button
var tab_passives_button: Button
var points_label: Label
var skills_container: VBoxContainer
var passives_container: VBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	_refresh()


func open_tree(initial_tab: Variant = "") -> void:
	visible = true
	var tab_str := str(initial_tab) if initial_tab != null else ""
	if tab_str == "skills" or tab_str == "passives":
		switch_tab(tab_str)
	elif active_tab == "skills" or active_tab == "passives":
		switch_tab(active_tab)
	else:
		switch_tab("passives")


func switch_tab(tab_name: Variant = "passives") -> void:
	var clean_tab := str(tab_name) if tab_name != null else "passives"
	if clean_tab != "skills" and clean_tab != "passives":
		clean_tab = "passives"
	active_tab = clean_tab
	if skills_container != null and passives_container != null:
		skills_container.visible = (active_tab == "skills")
		passives_container.visible = (active_tab == "passives")
		_style_tab_button(tab_skills_button, active_tab == "skills")
		_style_tab_button(tab_passives_button, active_tab == "passives")
	_refresh()


func _build_ui() -> void:
	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.015, 0.02, 0.03, 0.92)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 16.0
	panel.offset_top = 16.0
	panel.offset_right = -16.0
	panel.offset_bottom = -16.0
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.07, 0.09, 0.98)
	panel_style.set_border_width_all(2)
	panel_style.border_color = Color("#4fb8c7")
	panel_style.set_corner_radius_all(6)
	panel_style.content_margin_left = 16.0
	panel_style.content_margin_right = 16.0
	panel_style.content_margin_top = 10.0
	panel_style.content_margin_bottom = 10.0
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	var contents := VBoxContainer.new()
	contents.add_theme_constant_override("separation", 6)
	panel.add_child(contents)

	# --- Header with Tab Switchers ---
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	contents.add_child(header)

	var tab_bar := HBoxContainer.new()
	tab_bar.add_theme_constant_override("separation", 6)
	header.add_child(tab_bar)

	tab_skills_button = Button.new()
	tab_skills_button.text = "Active Skills"
	tab_skills_button.pressed.connect(switch_tab.bind("skills"))
	tab_bar.add_child(tab_skills_button)

	tab_passives_button = Button.new()
	tab_passives_button.text = "Passive Tree"
	tab_passives_button.pressed.connect(switch_tab.bind("passives"))
	tab_bar.add_child(tab_passives_button)

	_style_tab_button(tab_skills_button, active_tab == "skills")
	_style_tab_button(tab_passives_button, active_tab == "passives")

	points_label = Label.new()
	points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	points_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	points_label.add_theme_font_size_override("font_size", 15)
	points_label.add_theme_color_override("font_color", Color("#aee8dd"))
	header.add_child(points_label)

	var close_button := Button.new()
	close_button.text = "Close (Esc)"
	close_button.custom_minimum_size = Vector2(96.0, 36.0)
	close_button.pressed.connect(_on_close_pressed)
	header.add_child(close_button)

	# --- Tab 1: Active Skills ---
	_build_skills_tab(contents)

	# --- Tab 2: Passive Tree ---
	_build_passives_tab(contents)

	skills_container.visible = (active_tab == "skills")
	passives_container.visible = (active_tab == "passives")


func _style_tab_button(button: Button, is_active: bool) -> void:
	button.custom_minimum_size = Vector2(130.0, 36.0)
	button.add_theme_font_size_override("font_size", 15)
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(6)
	style.set_border_width_all(2)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	if is_active:
		style.bg_color = Color(0.1, 0.22, 0.25, 0.95)
		style.border_color = Color("#66cfc8")
		button.add_theme_color_override("font_color", Color("#ffd559"))
	else:
		style.bg_color = Color(0.04, 0.06, 0.08, 0.8)
		style.border_color = Color(0.24, 0.32, 0.36, 0.6)
		button.add_theme_color_override("font_color", Color("#8ea2a0"))
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("disabled", style)


# ==============================================================================
# ACTIVE SKILLS TAB
# ==============================================================================
func _build_skills_tab(parent: Control) -> void:
	skills_container = VBoxContainer.new()
	skills_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	skills_container.add_theme_constant_override("separation", 6)
	parent.add_child(skills_container)

	var branch_row := HBoxContainer.new()
	branch_row.add_theme_constant_override("separation", 8)
	skills_container.add_child(branch_row)
	for branch in BRANCHES_SKILLS:
		var branch_button := Button.new()
		branch_button.text = branch
		branch_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_skill_button(branch_button, 32.0)
		branch_button.pressed.connect(_select_skill_branch.bind(branch))
		branch_row.add_child(branch_button)
		skill_branch_buttons[branch] = branch_button

	var list_scroll := ScrollContainer.new()
	list_scroll.custom_minimum_size.y = 175.0
	list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	skills_container.add_child(list_scroll)

	skill_grid = GridContainer.new()
	skill_grid.columns = 3
	skill_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skill_grid.add_theme_constant_override("h_separation", 12)
	skill_grid.add_theme_constant_override("v_separation", 12)
	list_scroll.add_child(skill_grid)

	_build_skill_tiles()

	skill_details_label = Label.new()
	skill_details_label.custom_minimum_size.y = 66.0
	skill_details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	skill_details_label.add_theme_font_size_override("font_size", 14)
	skill_details_label.add_theme_color_override("font_color", Color("#d5e5df"))
	skills_container.add_child(skill_details_label)

	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 8)
	skills_container.add_child(action_row)

	skill_purchase_button = Button.new()
	skill_purchase_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_skill_button(skill_purchase_button, 40.0)
	skill_purchase_button.pressed.connect(_purchase_selected_skill)
	action_row.add_child(skill_purchase_button)

	skill_slot_picker = OptionButton.new()
	skill_slot_picker.custom_minimum_size.x = 96.0
	for slot in SKILL_SLOTS:
		skill_slot_picker.add_item("Slot %s" % slot)
	action_row.add_child(skill_slot_picker)

	skill_assign_button = Button.new()
	skill_assign_button.text = "Assign to Slot"
	_style_skill_button(skill_assign_button, 40.0)
	skill_assign_button.pressed.connect(_assign_selected_skill)
	action_row.add_child(skill_assign_button)

	skill_status_label = Label.new()
	skill_status_label.custom_minimum_size.y = 18.0
	skill_status_label.add_theme_color_override("font_color", Color("#b6d9a0"))
	skills_container.add_child(skill_status_label)


func _build_skill_tiles() -> void:
	for definition in GameState.get_witch_skill_definitions():
		var skill_id := str(definition["id"])
		var tile := Button.new()
		tile.name = "Tile_%s" % skill_id
		tile.custom_minimum_size = Vector2(230.0, 76.0)
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tile.clip_text = false
		tile.alignment = HORIZONTAL_ALIGNMENT_LEFT
		tile.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT

		var icon_path := str(definition.get("icon_path", ""))
		if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
			tile.icon = load(icon_path)
			tile.expand_icon = true

		tile.pressed.connect(_select_skill.bind(skill_id))
		skill_grid.add_child(tile)
		skill_tile_buttons[skill_id] = tile


func _style_skill_button(button: Button, height: float) -> void:
	button.custom_minimum_size.y = height
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.add_theme_font_size_override("font_size", 14)


func _select_skill_branch(branch: String) -> void:
	selected_skill_branch = branch
	if branch != "All":
		var definitions := GameState.get_witch_skill_definitions()
		for definition in definitions:
			if definition["branch"] == branch:
				selected_skill_id = definition["id"]
				break
	_refresh_skills()


func _select_skill(skill_id: String) -> void:
	if selected_skill_id == skill_id:
		# If user clicks the already selected skill tile again, allot point if possible
		if GameState.can_unlock_witch_skill(skill_id):
			_purchase_selected_skill()
			return
	selected_skill_id = skill_id
	_refresh_skills()


func _refresh_skills() -> void:
	if not is_inside_tree() or skill_tile_buttons.is_empty():
		return

	for branch in BRANCHES_SKILLS:
		var branch_button: Button = skill_branch_buttons[branch]
		branch_button.disabled = branch == selected_skill_branch

	for definition in GameState.get_witch_skill_definitions():
		var skill_id := str(definition["id"])
		if not skill_tile_buttons.has(skill_id):
			continue
		var tile: Button = skill_tile_buttons[skill_id]
		var rank := GameState.get_witch_skill_rank(skill_id)
		var max_rank := int(definition["max_rank"])
		var can_upgrade := GameState.can_unlock_witch_skill(skill_id)
		var is_selected := (skill_id == selected_skill_id)

		var matches_branch: bool = (selected_skill_branch == "All" or str(definition.get("branch", "")) == selected_skill_branch)
		tile.modulate = Color(1.0, 1.0, 1.0, 1.0 if matches_branch else 0.35)

		# Passive-tree style container styling
		var style := StyleBoxFlat.new()
		style.set_corner_radius_all(6)
		style.set_border_width_all(3 if is_selected else 2)
		style.content_margin_left = 10.0
		style.content_margin_right = 10.0
		style.content_margin_top = 8.0
		style.content_margin_bottom = 8.0

		if rank >= max_rank:
			style.bg_color = Color(0.35, 0.24, 0.05, 0.95)
			style.border_color = Color("#ffffff") if is_selected else Color("#ffd559")
		elif rank > 0:
			style.bg_color = Color(0.08, 0.28, 0.24, 0.95)
			style.border_color = Color("#ffffff") if is_selected else Color("#55e6c7")
		elif can_upgrade:
			style.bg_color = Color(0.12, 0.18, 0.24, 0.92)
			style.border_color = Color("#ffffff") if is_selected else Color("#86cbe6")
		else:
			style.bg_color = Color(0.05, 0.07, 0.09, 0.85)
			style.border_color = Color("#ffffff") if is_selected else Color(0.28, 0.34, 0.4, 0.8)

		tile.add_theme_stylebox_override("normal", style)
		tile.add_theme_stylebox_override("hover", style)
		tile.add_theme_stylebox_override("pressed", style)

		# Multi-line formatted label on the tile with 1/3, 2/3, 3/3 counter
		var counter_text := "%d/%d" % [rank, max_rank]
		var branch_name := str(definition.get("branch", ""))
		var skill_name := str(definition["name"])
		tile.text = "   %s  [%s]\n   %s  •  Lv %d" % [
			skill_name,
			counter_text,
			branch_name,
			int(definition["required_level"])
		]

		var font_col := Color("#ffd559") if is_selected else (Color("#b6f0e2") if rank > 0 else Color("#d6e0df"))
		tile.add_theme_color_override("font_color", font_col)

	_refresh_skill_details()


func _refresh_skill_details() -> void:
	var definition := GameState.get_witch_skill_definition(selected_skill_id)
	if definition.is_empty():
		skill_details_label.text = "Select a skill node."
		skill_purchase_button.disabled = true
		skill_assign_button.disabled = true
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
	skill_details_label.text = "%s | %s\n%s\nRank %d/%d  |  Level %d  |  %d mana  |  %.1f sec cooldown  |  Requires: %s  |  %s" % [
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
	skill_purchase_button.disabled = not can_purchase
	if rank >= int(definition["max_rank"]):
		skill_purchase_button.text = "Maximum rank"
	elif rank == 0:
		skill_purchase_button.text = "Unlock  -  %d SP" % definition["point_cost"]
	else:
		skill_purchase_button.text = "Upgrade  -  %d SP" % definition["point_cost"]
	skill_assign_button.disabled = rank == 0


func _purchase_selected_skill() -> void:
	if GameState.unlock_or_upgrade_witch_skill(selected_skill_id):
		skill_status_label.text = "%s upgraded." % GameState.get_witch_skill_definition(selected_skill_id).get("name", "Skill")
		loadout_changed.emit()
	else:
		skill_status_label.text = "Level, prerequisites, or skill points required."
	_refresh()


func _assign_selected_skill() -> void:
	if skill_slot_picker.selected < 0 or skill_slot_picker.selected >= SKILL_SLOTS.size():
		return
	var slot: String = SKILL_SLOTS[skill_slot_picker.selected]
	if GameState.assign_witch_skill(selected_skill_id, slot):
		skill_status_label.text = "%s assigned to %s." % [
			GameState.get_witch_skill_definition(selected_skill_id).get("name", "Skill"),
			slot
		]
		loadout_changed.emit()
	else:
		skill_status_label.text = "Unlock this skill before assigning it."
	_refresh()


# ==============================================================================
# PASSIVE TREE TAB
# ==============================================================================
func _build_passives_tab(parent: Control) -> void:
	passives_container = VBoxContainer.new()
	passives_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	passives_container.add_theme_constant_override("separation", 6)
	parent.add_child(passives_container)

	# Branch filter row
	var branch_row := HBoxContainer.new()
	branch_row.add_theme_constant_override("separation", 6)
	passives_container.add_child(branch_row)
	for branch in BRANCHES_PASSIVES:
		var branch_btn := Button.new()
		branch_btn.text = branch
		branch_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		branch_btn.custom_minimum_size.y = 30.0
		branch_btn.add_theme_font_size_override("font_size", 12)
		branch_btn.pressed.connect(_select_passive_branch.bind(branch))
		branch_row.add_child(branch_btn)
		passive_branch_buttons[branch] = branch_btn

	# Main Interactive Passive Canvas
	passive_scroll_container = ScrollContainer.new()
	passive_scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	passive_scroll_container.custom_minimum_size.y = 260.0
	passives_container.add_child(passive_scroll_container)

	node_container = Control.new()
	node_container.custom_minimum_size = Vector2(
		PADDING_X * 2.0 + GRID_CELL_W * 5.0,
		PADDING_Y * 2.0 + GRID_CELL_H * 15.0
	)
	node_container.draw.connect(_on_node_container_draw)
	passive_scroll_container.add_child(node_container)

	_build_passive_nodes()

	# Passive Stats Summary Bar
	stats_summary_label = Label.new()
	stats_summary_label.custom_minimum_size.y = 22.0
	stats_summary_label.add_theme_font_size_override("font_size", 13)
	stats_summary_label.add_theme_color_override("font_color", Color("#9be8c9"))
	passives_container.add_child(stats_summary_label)

	# Node Details Card
	passive_details_label = Label.new()
	passive_details_label.custom_minimum_size.y = 64.0
	passive_details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	passive_details_label.add_theme_font_size_override("font_size", 13)
	passive_details_label.add_theme_color_override("font_color", Color("#e4eee9"))
	passives_container.add_child(passive_details_label)

	# Action Row
	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 8)
	passives_container.add_child(action_row)

	unlock_passive_button = Button.new()
	unlock_passive_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	unlock_passive_button.custom_minimum_size.y = 38.0
	unlock_passive_button.add_theme_font_size_override("font_size", 15)
	unlock_passive_button.pressed.connect(_unlock_selected_passive)
	action_row.add_child(unlock_passive_button)

	passive_status_label = Label.new()
	passive_status_label.custom_minimum_size.y = 18.0
	passive_status_label.add_theme_color_override("font_color", Color("#b6d9a0"))
	passives_container.add_child(passive_status_label)


func _get_node_center(passive_id: String) -> Vector2:
	var def := GameState.get_witch_passive_definition(passive_id)
	if def.is_empty():
		return Vector2.ZERO
	var gx := float(def.get("x", 0))
	var gy := float(def.get("y", 0))
	return Vector2(
		PADDING_X + gx * GRID_CELL_W + GRID_CELL_W * 0.5,
		PADDING_Y + gy * GRID_CELL_H + GRID_CELL_H * 0.5
	)


func _build_passive_nodes() -> void:
	for passive_id in GameState.WITCH_PASSIVE_ORDER:
		var def: Dictionary = GameState.get_witch_passive_definition(passive_id)
		var is_super := bool(def.get("is_super", false))
		var center := _get_node_center(passive_id)
		var node_size := SUPER_NODE_SIZE if is_super else STANDARD_NODE_SIZE

		var node_btn := Button.new()
		node_btn.name = "Node_%s" % passive_id
		node_btn.custom_minimum_size = node_size
		node_btn.size = node_size
		node_btn.position = center - node_size * 0.5
		node_btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		node_btn.pressed.connect(_select_passive.bind(passive_id))
		node_container.add_child(node_btn)
		passive_node_buttons[passive_id] = node_btn


func _on_node_container_draw() -> void:
	for passive_id in GameState.WITCH_PASSIVE_ORDER:
		var def: Dictionary = GameState.get_witch_passive_definition(passive_id)
		var p_center := _get_node_center(passive_id)
		var is_unlocked: bool = GameState.is_witch_passive_unlocked(passive_id)
		var prereqs: Array = def.get("prerequisites", [])

		for prereq_id in prereqs:
			var req_center := _get_node_center(str(prereq_id))
			var prereq_unlocked: bool = GameState.is_witch_passive_unlocked(str(prereq_id))
			var line_color := Color("#73f4e1") if (is_unlocked and prereq_unlocked) else Color(0.24, 0.32, 0.38, 0.7)
			var line_width := 4.0 if (is_unlocked and prereq_unlocked) else 2.0
			node_container.draw_line(req_center, p_center, line_color, line_width, true)


func _select_passive_branch(branch: String) -> void:
	selected_passive_branch = branch
	if branch != "All":
		for passive_id in GameState.WITCH_PASSIVE_ORDER:
			var def: Dictionary = GameState.get_witch_passive_definition(passive_id)
			if def.get("branch", "") == branch:
				selected_passive_id = passive_id
				break
	_refresh_passives()


func _select_passive(passive_id: String) -> void:
	selected_passive_id = passive_id
	_refresh_passives()


func _refresh_passives() -> void:
	if not is_inside_tree() or node_container == null:
		return

	for b_name in BRANCHES_PASSIVES:
		var b_btn: Button = passive_branch_buttons[b_name]
		b_btn.disabled = b_name == selected_passive_branch

	for passive_id in GameState.WITCH_PASSIVE_ORDER:
		var def: Dictionary = GameState.get_witch_passive_definition(passive_id)
		var is_super := bool(def.get("is_super", false))
		var is_unlocked: bool = GameState.is_witch_passive_unlocked(passive_id)
		var can_unlock: bool = GameState.can_unlock_witch_passive(passive_id)
		var node_btn: Button = passive_node_buttons[passive_id]

		var matches_branch: bool = (selected_passive_branch == "All" or str(def.get("branch", "")) == selected_passive_branch)
		node_btn.modulate = Color(1.0, 1.0, 1.0, 1.0 if matches_branch else 0.35)

		var style := StyleBoxFlat.new()
		style.set_corner_radius_all(8 if is_super else 5)
		style.set_border_width_all(3 if is_super else 2)

		if is_unlocked:
			style.bg_color = Color(0.08, 0.28, 0.24, 0.95) if not is_super else Color(0.35, 0.24, 0.05, 0.95)
			style.border_color = Color("#55e6c7") if not is_super else Color("#ffd559")
		elif can_unlock:
			style.bg_color = Color(0.12, 0.18, 0.24, 0.92)
			style.border_color = Color("#86cbe6")
		else:
			style.bg_color = Color(0.05, 0.07, 0.09, 0.85)
			style.border_color = Color(0.28, 0.34, 0.4, 0.8)

		if passive_id == selected_passive_id:
			style.border_color = Color("#ffffff")
			style.set_border_width_all(4)

		node_btn.add_theme_stylebox_override("normal", style)
		node_btn.add_theme_stylebox_override("hover", style)
		node_btn.add_theme_stylebox_override("pressed", style)

		var prefix := "[SUPER] " if is_super else ""
		var status_text := " [Allocated]" if is_unlocked else ""
		node_btn.text = "%s%s%s" % [prefix, def.get("name", ""), status_text]
		node_btn.add_theme_font_size_override("font_size", 13 if is_super else 12)

		var font_col := Color("#ffd559") if is_super else (Color("#b6f0e2") if is_unlocked else Color("#d6e0df"))
		node_btn.add_theme_color_override("font_color", font_col)

	node_container.queue_redraw()
	_refresh_passive_summary()
	_refresh_passive_details()


func _refresh_passive_summary() -> void:
	var totals := GameState.get_witch_passive_stat_totals()
	var spell_pct := roundi(float(totals.get("spell_damage_percent", 0.0)) * 100.0)
	var evasion_pct := roundi(float(totals.get("evasion", 0.0)) * 100.0)
	var red_pct := roundi(float(totals.get("damage_reduction_percent", 0.0)) * 100.0)
	var bonus_hp: int = totals.get("max_health", 0)
	var bonus_mp: int = totals.get("max_mana", 0)

	stats_summary_label.text = "Allocated Stats:  Spell Damage +%d%%  |  Evasion +%d%%  |  Damage Reduction -%d%%  |  Health +%d  |  Mana +%d" % [
		spell_pct,
		evasion_pct,
		red_pct,
		bonus_hp,
		bonus_mp
	]


func _refresh_passive_details() -> void:
	var def: Dictionary = GameState.get_witch_passive_definition(selected_passive_id)
	if def.is_empty():
		passive_details_label.text = "Select a passive node to inspect it."
		unlock_passive_button.disabled = true
		return

	var is_unlocked: bool = GameState.is_witch_passive_unlocked(selected_passive_id)
	var can_unlock: bool = GameState.can_unlock_witch_passive(selected_passive_id)
	var is_super := bool(def.get("is_super", false))

	var prereq_names: Array[String] = []
	for p_id in def.get("prerequisites", []):
		var p_def: Dictionary = GameState.get_witch_passive_definition(str(p_id))
		prereq_names.append(str(p_def.get("name", p_id)))
	var prereqs_text := ", ".join(prereq_names) if not prereq_names.is_empty() else "None"

	var type_label := "SUPER PASSIVE" if is_super else "PASSIVE"
	passive_details_label.text = "[%s] %s  |  %s\n%s\nCost: 1 Passive Point  |  Requires Level: %d  |  Prerequisites: %s" % [
		type_label,
		def.get("name", ""),
		def.get("branch", ""),
		def.get("description", ""),
		def.get("required_level", 1),
		prereqs_text
	]

	if is_unlocked:
		unlock_passive_button.text = "Allocated"
		unlock_passive_button.disabled = true
	elif can_unlock:
		unlock_passive_button.text = "Allocate Passive (1 Point)"
		unlock_passive_button.disabled = false
	else:
		unlock_passive_button.text = "Locked (Requires Level, Prerequisites, & 1 Point)"
		unlock_passive_button.disabled = true


func _unlock_selected_passive() -> void:
	if GameState.unlock_witch_passive(selected_passive_id):
		var def: Dictionary = GameState.get_witch_passive_definition(selected_passive_id)
		passive_status_label.text = "%s allocated!" % def.get("name", "Passive")
		passives_changed.emit()
	else:
		passive_status_label.text = "Could not allocate passive node."
	_refresh()


# ==============================================================================
# GENERAL REFRESH & CLOSE
# ==============================================================================
func _refresh() -> void:
	if not is_inside_tree() or points_label == null:
		return
	points_label.text = "Skill Points: %d   |   Passive Points: %d" % [
		GameState.skill_tree_points,
		GameState.passive_tree_points
	]
	if active_tab == "skills":
		_refresh_skills()
	else:
		_refresh_passives()


func _on_close_pressed() -> void:
	hide()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo \
			and event.keycode == KEY_ESCAPE:
		_on_close_pressed()
		get_viewport().set_input_as_handled()
