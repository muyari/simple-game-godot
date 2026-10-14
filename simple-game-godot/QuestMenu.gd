extends Control
class_name QuestMenu
## Quest log opened with J. Styled after the skill/passive tree screens, with a tab per area.

signal closed

const PANEL_BG := Color("#0d1216")
const PANEL_BORDER := Color("#4fb8c7")
const TEXT := Color("#d5e5df")
const MUTED := Color("#9aacab")
const ACCENT := Color("#aee8dd")
const GOLD := Color("#ffd559")
## Tab key for the Quest Rewards tab (area tabs use their level id, which start at 1).
const REWARDS_TAB := 0

var selected_area := 1
var selected_quest_id := ""
var area_buttons: Dictionary = {}
var quest_list: VBoxContainer
var count_label: Label
var empty_label: Label
var detail_title: Label
var detail_giver: Label
var detail_summary: Label
var detail_objectives: VBoxContainer
var objectives_header: Label
var detail_status: Label
var detail_panel: PanelContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	hide()


func open_menu() -> void:
	# Start on the first area that has an active quest, otherwise keep the last tab.
	for area in Quests.AREAS:
		if Quests.get_logged_quests_in_area(area["level_id"]).any(
			func(quest_id): return Quests.is_active(GameState.get_quest_state(quest_id))
		):
			selected_area = area["level_id"]
			break
	selected_quest_id = ""
	show()
	_refresh()


func close_menu() -> void:
	hide()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not event is InputEventKey or not event.pressed:
		return
	# Swallow every key while open so other menu hotkeys don't fire underneath.
	if not event.echo and event.keycode in [KEY_ESCAPE, KEY_J]:
		close_menu()
	get_viewport().set_input_as_handled()


func _build_ui() -> void:
	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.015, 0.02, 0.03, 0.92)
	add_child(backdrop)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 8.0
	panel.offset_top = 8.0
	panel.offset_right = -8.0
	panel.offset_bottom = -8.0
	panel.add_theme_stylebox_override("panel", _box(PANEL_BG, PANEL_BORDER, 2, 14.0, 9.0))
	add_child(panel)

	var contents := VBoxContainer.new()
	contents.add_theme_constant_override("separation", 7)
	panel.add_child(contents)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	contents.add_child(header)
	var title_tab := Button.new()
	title_tab.text = "Quest Log"
	title_tab.custom_minimum_size = Vector2(130.0, 36.0)
	title_tab.disabled = true
	title_tab.add_theme_stylebox_override("disabled", _box(Color("#17363b"), Color("#66cfc8"), 2))
	title_tab.add_theme_color_override("font_disabled_color", GOLD)
	header.add_child(title_tab)
	count_label = Label.new()
	count_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_label.add_theme_font_size_override("font_size", 15)
	count_label.add_theme_color_override("font_color", ACCENT)
	header.add_child(count_label)
	var close_button := Button.new()
	close_button.text = "Close (J / Esc)"
	close_button.custom_minimum_size = Vector2(120.0, 36.0)
	close_button.pressed.connect(close_menu)
	header.add_child(close_button)

	var area_row := HBoxContainer.new()
	area_row.add_theme_constant_override("separation", 8)
	contents.add_child(area_row)
	for area in Quests.AREAS:
		var area_button := Button.new()
		area_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		area_button.custom_minimum_size.y = 32.0
		area_button.add_theme_font_size_override("font_size", 13)
		area_button.pressed.connect(_select_area.bind(area["level_id"]))
		area_row.add_child(area_button)
		area_buttons[area["level_id"]] = area_button
	var rewards_button := Button.new()
	rewards_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rewards_button.custom_minimum_size.y = 32.0
	rewards_button.add_theme_font_size_override("font_size", 13)
	rewards_button.pressed.connect(_select_area.bind(REWARDS_TAB))
	area_row.add_child(rewards_button)
	area_buttons[REWARDS_TAB] = rewards_button

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	contents.add_child(body)

	var list_scroll := ScrollContainer.new()
	list_scroll.custom_minimum_size.x = 330.0
	list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(list_scroll)
	quest_list = VBoxContainer.new()
	quest_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quest_list.add_theme_constant_override("separation", 8)
	list_scroll.add_child(quest_list)

	detail_panel = PanelContainer.new()
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_panel.add_theme_stylebox_override("panel", _box(Color("#11181c"), Color("#3d5158"), 2, 16.0, 12.0))
	body.add_child(detail_panel)
	var details := VBoxContainer.new()
	details.add_theme_constant_override("separation", 8)
	detail_panel.add_child(details)
	detail_title = _label(details, 22, GOLD)
	detail_giver = _label(details, 14, MUTED)
	detail_summary = _label(details, 15, TEXT)
	detail_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objectives_header = _label(details, 15, ACCENT)
	objectives_header.text = "Objectives"
	detail_objectives = VBoxContainer.new()
	detail_objectives.add_theme_constant_override("separation", 4)
	details.add_child(detail_objectives)
	detail_status = _label(details, 14, ACCENT)

	empty_label = _label(details, 16, MUTED)
	empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _select_area(level_id: int) -> void:
	selected_area = level_id
	selected_quest_id = ""
	_refresh()


func _select_quest(quest_id: String) -> void:
	selected_quest_id = quest_id
	_refresh()


func _refresh() -> void:
	for area in Quests.AREAS:
		var level_id: int = area["level_id"]
		var area_count := Quests.get_logged_quests_in_area(level_id).size()
		_style_tab(area_buttons[level_id], area["name"], area_count, level_id == selected_area)
	var rewards := Quests.get_earned_rewards()
	_style_tab(area_buttons[REWARDS_TAB], "Quest Rewards", rewards.size(), selected_area == REWARDS_TAB)
	var active := Quests.get_active_quest_count()
	count_label.text = "%d active quest%s" % [active, "" if active == 1 else "s"]

	for child in quest_list.get_children():
		child.queue_free()
	if selected_area == REWARDS_TAB:
		var reward_keys: Array[String] = []
		for index in rewards.size():
			reward_keys.append("reward:%d" % index)
		if not selected_quest_id in reward_keys:
			selected_quest_id = reward_keys[0] if not reward_keys.is_empty() else ""
		for index in rewards.size():
			var reward: Dictionary = rewards[index]
			quest_list.add_child(_make_card(
				"%s\nFrom: %s" % [reward["name"], reward["quest_title"]],
				reward_keys[index],
				reward_keys[index] == selected_quest_id,
				false
			))
		_refresh_reward_details(rewards)
		return

	var quest_ids := Quests.get_logged_quests_in_area(selected_area)
	if not selected_quest_id in quest_ids:
		selected_quest_id = quest_ids[0] if not quest_ids.is_empty() else ""
	for quest_id in quest_ids:
		var quest := Quests.get_definition(quest_id)
		var is_completed := GameState.get_quest_state(quest_id) == Quests.STATE_COMPLETED
		quest_list.add_child(_make_card(
			"%s\n%s  -  %s" % [quest["title"], quest["giver"], "Completed" if is_completed else "In progress"],
			quest_id,
			quest_id == selected_quest_id,
			is_completed
		))
	_refresh_details()


func _style_tab(button: Button, label: String, count: int, is_selected: bool) -> void:
	button.text = "%s (%d)" % [label, count] if count > 0 else label
	button.add_theme_stylebox_override("normal", _box(
		Color("#19383a") if is_selected else Color("#13181b"),
		Color("#5bc7c4") if is_selected else Color("#20272b"),
		2
	))
	button.add_theme_color_override("font_color", Color("#d6f1e7") if is_selected else Color("#cbd2d1"))


func _make_card(text: String, key: String, is_selected: bool, is_completed: bool) -> Button:
	var card := Button.new()
	card.custom_minimum_size = Vector2(0.0, 70.0)
	card.alignment = HORIZONTAL_ALIGNMENT_LEFT
	card.text = text
	card.add_theme_font_size_override("font_size", 14)
	var text_color := MUTED if is_completed else Color("#d6e0df")
	card.add_theme_color_override("font_color", GOLD if is_selected else text_color)
	var border := Color("#4f8f6a") if is_completed else Color("#c99b52")
	card.add_theme_stylebox_override("normal", _box(
		Color("#1b2622") if is_completed else Color("#27352c"),
		GOLD if is_selected else border,
		2,
		12.0,
		6.0
	))
	card.pressed.connect(_select_quest.bind(key))
	return card


func _show_details(has_entry: bool, show_objectives: bool) -> void:
	for node in [detail_title, detail_giver, detail_summary, detail_status]:
		node.visible = has_entry
	objectives_header.visible = has_entry and show_objectives
	detail_objectives.visible = has_entry and show_objectives
	empty_label.visible = not has_entry
	for child in detail_objectives.get_children():
		child.queue_free()


func _refresh_details() -> void:
	var has_quest := not selected_quest_id.is_empty()
	_show_details(has_quest, true)
	if not has_quest:
		var area_name := ""
		for area in Quests.AREAS:
			if area["level_id"] == selected_area:
				area_name = area["name"]
		empty_label.text = "No quests in %s yet.\nSpeak with the townsfolk of Oblath to find work." % area_name
		return

	var quest := Quests.get_definition(selected_quest_id)
	var stage: Dictionary = quest["stages"].get(GameState.get_quest_state(selected_quest_id), {})
	var objectives_done: int = stage.get("objectives_done", 0)
	detail_title.text = quest["title"]
	detail_giver.text = "Given by %s in %s" % [quest["giver"], quest["giver_location"]]
	detail_summary.text = quest["summary"]
	for index in quest["objectives"].size():
		var is_done: bool = index < objectives_done
		var line := _label(detail_objectives, 15, MUTED if is_done else TEXT)
		line.text = "%s  %s" % ["[x]" if is_done else "[  ]", quest["objectives"][index]]
	detail_status.text = "Status: %s" % stage.get("status", "In progress")


func _refresh_reward_details(rewards: Array[Dictionary]) -> void:
	var has_reward := not selected_quest_id.is_empty()
	_show_details(has_reward, false)
	if not has_reward:
		empty_label.text = "No quest rewards yet.\nKeepsakes and rewards from completed quests are kept here."
		return
	var reward: Dictionary = rewards[selected_quest_id.trim_prefix("reward:").to_int()]
	detail_title.text = reward["name"]
	detail_giver.text = "Reward from: %s" % reward["quest_title"]
	detail_summary.text = reward["description"]
	detail_status.text = "Keepsake  -  no effect in battle"


func _label(parent: Control, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label


func _box(bg: Color, border: Color, border_width: int, margin_x := 8.0, margin_y := 4.0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(6)
	style.content_margin_left = margin_x
	style.content_margin_right = margin_x
	style.content_margin_top = margin_y
	style.content_margin_bottom = margin_y
	return style
