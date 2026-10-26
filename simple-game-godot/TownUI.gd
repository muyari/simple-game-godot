extends CanvasLayer

const MINIMUM_ITEM_PRICE = 25
const EXPERIENCE_BAR_WIDTH = 440.0
# World-space camera bounds for the town. Top and bottom leave room for the HUD so the
# fence is never hidden behind it; the sides stay wide so the outside scenery is visible.
const CAMERA_LIMIT_LEFT = -1000
const CAMERA_LIMIT_RIGHT = 2150
const CAMERA_LIMIT_TOP = -820
const CAMERA_LIMIT_BOTTOM = 1560

@onready var gold_label: Label = $GoldLabel
@onready var player: Player = get_node("../Player")
@onready var vendor: Vendor = get_node("../Vendor")
@onready var waystone: Area2D = get_node("../Waystone")
@onready var return_portal: Portal = get_node("../ReturnPortal")
@onready var health_orb: ResourceGlobe = $HealthOrb
@onready var mana_orb: ResourceGlobe = $ManaOrb
@onready var health_potion: PotionFlask = $HealthPotion
@onready var mana_potion: PotionFlask = $ManaPotion

var experience_bar: ProgressBar
var experience_level_label: Label
var experience_tooltip: PanelContainer
var experience_tooltip_label: Label
var shop_panel: PanelContainer
var shop_gold_label: Label
var item_list: VBoxContainer
var sell_item_list: VBoxContainer
var status_label: Label
var dialogue_overlay: Control
var dialogue_panel: PanelContainer
var quest_dialogue: QuestDialogue
var active_quest_giver: QuestGiver
var quest_menu: QuestMenu
var waystone_overlay: Control
var shop_overlay: Control
var character_sheet: CharacterSheet
var witch_skill_tree: WitchSkillTree
var warrior_skill_tree: WarriorSkillTree
var warrior_passive_tree: WarriorPassiveTree
var ranger_skill_tree: RangerSkillTree
var ranger_passive_tree: RangerPassiveTree
var pause_menu: PauseMenu


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_touch_controls()
	_build_pause_menu()
	_connect_skill_slot_clicks()
	_build_experience_bar()
	_update_gold(GameState.gold)
	MenuStyle.outline_hud_label(gold_label)
	GameState.gold_changed.connect(_update_gold)
	_restore_town_return_destination()
	_apply_camera_limits()
	health_orb.maximum = player.MAX_HEALTH
	health_orb.value = player.health
	mana_orb.maximum = player.MAX_MANA
	mana_orb.value = player.mana
	_update_potion_counts(player.health_potions, player.mana_potions, 0.0, 0.0)
	player.health_changed.connect(_on_health_changed)
	player.mana_changed.connect(_on_mana_changed)
	player.potion_counts_changed.connect(_update_potion_counts)
	player.inventory_changed.connect(_on_inventory_changed)
	player.equipment_changed.connect(_on_equipment_changed)
	GameState.progression_changed.connect(_on_progression_changed)
	vendor.shop_requested.connect(_open_dialogue)
	waystone.connect("level_selection_requested", _open_waystone)
	_build_shop()
	_build_dialogue()
	_build_quest_dialogue()
	_build_quest_menu()
	_build_waystone_menu()
	_build_character_menu()
	# Last, so it draws and takes clicks above the rest of the HUD. It hides itself
	# whenever a menu has the player paused.
	_build_hud_menu()
	_on_progression_changed(
		GameState.player_level,
		GameState.experience,
		GameState.get_xp_into_current_level(),
		GameState.get_xp_for_next_level(),
		GameState.passive_tree_points,
		GameState.skill_tree_points
	)


func _connect_skill_slot_clicks() -> void:
	for slot in ["Q", "W", "E", "R"]:
		var skill_slot := get_node_or_null("SkillSlot%s" % slot) as SkillSlot
		if skill_slot != null:
			skill_slot.skill_activated.connect(player.activate_skill_slot)


func _process(_delta: float) -> void:
	if player.selected_character == "Warrior":
		for slot in ["Q", "W", "E", "R"]:
			var skill_slot := get_node_or_null("SkillSlot%s" % slot)
			if skill_slot == null:
				continue
			var skill_id := GameState.get_warrior_equipped_skill(slot)
			var cooldown_ratio := player.get_warrior_skill_cooldown_ratio(skill_id)
			if absf(float(skill_slot.get("cooldown_progress")) - cooldown_ratio) > 0.01:
				skill_slot.set("cooldown_progress", cooldown_ratio)
				skill_slot.queue_redraw()
		return
	if player.selected_character == "Ranger":
		for slot in ["Q", "W", "E", "R"]:
			var skill_slot := get_node_or_null("SkillSlot%s" % slot)
			if skill_slot == null:
				continue
			var skill_id := GameState.get_ranger_equipped_skill(slot)
			var cooldown_ratio := player.get_ranger_skill_cooldown_ratio(skill_id)
			if absf(float(skill_slot.get("cooldown_progress")) - cooldown_ratio) > 0.01:
				skill_slot.set("cooldown_progress", cooldown_ratio)
				skill_slot.queue_redraw()
		return
	if player.selected_character != "Witch":
		return
	for slot in ["Q", "W", "E", "R"]:
		var skill_slot := get_node_or_null("SkillSlot%s" % slot)
		if skill_slot == null:
			continue
		var skill_id := GameState.get_witch_equipped_skill(slot)
		var cooldown_ratio := player.get_witch_skill_cooldown_ratio(skill_id)
		if absf(float(skill_slot.get("cooldown_progress")) - cooldown_ratio) > 0.01:
			skill_slot.set("cooldown_progress", cooldown_ratio)
			skill_slot.queue_redraw()


func _input(event: InputEvent) -> void:
	if quest_dialogue != null and quest_dialogue.visible \
			and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			quest_dialogue.press_primary()
		elif event.keycode == KEY_ESCAPE:
			quest_dialogue.press_secondary()
		get_viewport().set_input_as_handled()
		return
	if not event is InputEventKey or not event.pressed or event.echo or event.keycode != KEY_E:
		return
	if dialogue_overlay != null and dialogue_overlay.visible:
		_open_shop()
		get_viewport().set_input_as_handled()
	elif (shop_overlay != null and shop_overlay.visible) \
			or (waystone_overlay != null and waystone_overlay.visible):
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if witch_skill_tree != null and witch_skill_tree.visible:
			if event.keycode in [KEY_ESCAPE, KEY_P, KEY_K]:
				_on_witch_skill_tree_closed()
			get_viewport().set_input_as_handled()
			return
		if warrior_skill_tree != null and warrior_skill_tree.visible:
			if event.keycode in [KEY_ESCAPE, KEY_P, KEY_K]:
				_on_warrior_skill_tree_closed()
			get_viewport().set_input_as_handled()
			return
		if warrior_passive_tree != null and warrior_passive_tree.visible:
			if event.keycode in [KEY_ESCAPE, KEY_P, KEY_K]:
				_on_warrior_passive_tree_closed()
			get_viewport().set_input_as_handled()
			return
		if ranger_skill_tree != null and ranger_skill_tree.visible:
			if event.keycode in [KEY_ESCAPE, KEY_P, KEY_K]:
				_on_ranger_skill_tree_closed()
			get_viewport().set_input_as_handled()
			return
		if ranger_passive_tree != null and ranger_passive_tree.visible:
			if event.keycode in [KEY_ESCAPE, KEY_P, KEY_K]:
				_on_ranger_passive_tree_closed()
			get_viewport().set_input_as_handled()
			return

		if event.keycode == KEY_ESCAPE:
			if pause_menu.visible:
				pause_menu.close_menu()
			elif warrior_skill_tree != null and warrior_skill_tree.visible:
				_on_warrior_skill_tree_closed()
			elif waystone_overlay != null and waystone_overlay.visible:
				_close_waystone()
			elif dialogue_overlay != null and dialogue_overlay.visible:
				_close_dialogue()
			elif shop_overlay != null and shop_overlay.visible:
				_close_shop()
			elif character_sheet.visible:
				_close_character_menu()
			else:
				pause_menu.open_menu()
			get_viewport().set_input_as_handled()
			return

		if witch_skill_tree != null and witch_skill_tree.visible:
			get_viewport().set_input_as_handled()
			return
		if warrior_skill_tree != null and warrior_skill_tree.visible:
			get_viewport().set_input_as_handled()
			return
		if warrior_passive_tree != null and warrior_passive_tree.visible:
			get_viewport().set_input_as_handled()
			return
		if ranger_skill_tree != null and ranger_skill_tree.visible:
			get_viewport().set_input_as_handled()
			return
		if ranger_passive_tree != null and ranger_passive_tree.visible:
			get_viewport().set_input_as_handled()
			return
		if waystone_overlay != null and waystone_overlay.visible:
			return
		if dialogue_overlay != null and dialogue_overlay.visible:
			return
		if shop_overlay != null and shop_overlay.visible:
			return
		if event.keycode == KEY_C:
			_toggle_character_menu()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_I:
			_toggle_inventory_menu()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_J:
			_open_quest_menu()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_K:
			_open_skill_tree()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_P:
			_open_passive_tree()
			get_viewport().set_input_as_handled()


func _toggle_character_menu() -> void:
	if character_sheet.is_character_shown():
		_close_character_menu()
	else:
		_open_character_menu()


func _toggle_inventory_menu() -> void:
	if character_sheet.is_inventory_shown():
		_close_character_menu()
	else:
		_open_inventory_menu()


func _open_skill_tree() -> void:
	if witch_skill_tree != null:
		_open_witch_skill_tree("skills")
	elif warrior_skill_tree != null:
		_open_warrior_skill_tree()
	elif ranger_skill_tree != null:
		_open_ranger_skill_tree()


func _open_passive_tree() -> void:
	if witch_skill_tree != null:
		_open_witch_skill_tree("passives")
	elif warrior_skill_tree != null:
		_open_warrior_passive_tree()
	elif ranger_skill_tree != null:
		_open_ranger_passive_tree()


func _build_hud_menu() -> void:
	var hud_menu := HudMenu.new()
	hud_menu.is_available = player.is_physics_processing
	add_child(hud_menu)
	hud_menu.add_command("Character", "C", _toggle_character_menu)
	hud_menu.add_command("Inventory", "I", _toggle_inventory_menu)
	hud_menu.add_command("Skills", "K", _open_skill_tree)
	hud_menu.add_command("Passives", "P", _open_passive_tree)
	hud_menu.add_command("Quests", "J", _open_quest_menu)
	hud_menu.add_command("Pause", "Esc", pause_menu.open_menu)


func _build_touch_controls() -> void:
	if not TouchControls.is_supported():
		return
	var touch_controls := TouchControls.create(player)
	add_child(touch_controls)
	# First child, so every other HUD control sits above it and takes touches first.
	move_child(touch_controls, 0)


func _build_pause_menu() -> void:
	pause_menu = PauseMenu.new()
	pause_menu.return_to_character_selection_requested.connect(
		_on_return_to_character_selection_requested
	)
	pause_menu.close_game_requested.connect(_on_close_game_requested)
	add_child(pause_menu)


func _on_return_to_character_selection_requested() -> void:
	if not GameState.save_character(GameState.get_inventory(), GameState.get_equipment()):
		push_error("Could not save the active character before returning to character selection.")
		return

	get_tree().set_meta("return_to_character_select", true)
	get_tree().set_meta(
		"selected_character_id",
		str(get_tree().get_meta("selected_character_id", ""))
	)
	pause_menu.close_menu()
	var error := GameState.change_scene("res://Menu.tscn")
	if error != OK:
		get_tree().remove_meta("return_to_character_select")
		get_tree().remove_meta("selected_character_id")
		pause_menu.open_menu()
		push_error("Could not return to character selection: %s" % error_string(error))


func _on_close_game_requested() -> void:
	if not GameState.save_character(GameState.get_inventory(), GameState.get_equipment()):
		push_error("Could not save the active character before closing the game.")
		return
	get_tree().quit()


func _build_shop() -> void:
	shop_overlay = Control.new()
	shop_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shop_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	shop_overlay.visible = false
	add_child(shop_overlay)

	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.02, 0.03, 0.025, 0.72)
	shop_overlay.add_child(backdrop)

	shop_panel = PanelContainer.new()
	shop_panel.custom_minimum_size = Vector2(1100, 600)
	shop_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	shop_panel.offset_left = -550.0
	shop_panel.offset_top = -300.0
	shop_panel.offset_right = 550.0
	shop_panel.offset_bottom = 300.0
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.075, 0.09, 0.075, 0.99)
	panel_style.set_border_width_all(3)
	panel_style.border_color = Color(0.62, 0.49, 0.29, 1)
	panel_style.set_corner_radius_all(8)
	panel_style.content_margin_left = 20.0
	panel_style.content_margin_right = 20.0
	panel_style.content_margin_top = 16.0
	panel_style.content_margin_bottom = 16.0
	shop_panel.add_theme_stylebox_override("panel", panel_style)
	shop_overlay.add_child(shop_panel)

	var contents := VBoxContainer.new()
	contents.add_theme_constant_override("separation", 10)
	shop_panel.add_child(contents)

	var title := Label.new()
	title.text = "Oblath Trading Post"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("#e8ca86"))
	contents.add_child(title)

	shop_gold_label = Label.new()
	shop_gold_label.name = "ShopGold"
	shop_gold_label.text = "Gold: %d" % GameState.gold
	shop_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	shop_gold_label.add_theme_color_override("font_color", Color("#ffdc83"))
	contents.add_child(shop_gold_label)

	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 20)
	contents.add_child(columns)

	var shop_column := _build_shop_column(columns, "Buy Equipment")
	item_list = shop_column.get_node("Scroll/Items") as VBoxContainer
	var sell_column := _build_shop_column(columns, "Your Inventory - Sell Items")
	sell_item_list = sell_column.get_node("Scroll/Items") as VBoxContainer

	status_label = Label.new()
	status_label.custom_minimum_size.y = 22
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	contents.add_child(status_label)

	var close_button := Button.new()
	close_button.text = "Close" + MenuStyle.key_hint("Esc")
	_style_menu_button(close_button, 48.0)
	close_button.pressed.connect(_close_shop)
	contents.add_child(close_button)

	_refresh_shop_items()


func _build_shop_column(parent: HBoxContainer, heading_text: String) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 8)
	parent.add_child(column)

	var heading := Label.new()
	heading.text = heading_text
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	heading.add_theme_font_size_override("font_size", 20)
	heading.add_theme_color_override("font_color", Color("#e8ca86"))
	column.add_child(heading)

	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)

	var rows := VBoxContainer.new()
	rows.name = "Items"
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 5)
	scroll.add_child(rows)

	column.custom_minimum_size.x = 500.0
	return column


func _build_dialogue() -> void:
	dialogue_overlay = Control.new()
	dialogue_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dialogue_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	dialogue_overlay.visible = false
	add_child(dialogue_overlay)

	dialogue_panel = PanelContainer.new()
	dialogue_panel.custom_minimum_size = Vector2(600, 180)
	dialogue_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	dialogue_panel.offset_left = -300.0
	dialogue_panel.offset_top = -220.0
	dialogue_panel.offset_right = 300.0
	dialogue_panel.offset_bottom = -40.0
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.075, 0.09, 0.075, 0.98)
	panel_style.set_border_width_all(3)
	panel_style.border_color = Color(0.62, 0.49, 0.29, 1)
	panel_style.set_corner_radius_all(8)
	panel_style.content_margin_left = 20.0
	panel_style.content_margin_right = 20.0
	panel_style.content_margin_top = 12.0
	panel_style.content_margin_bottom = 12.0
	dialogue_panel.add_theme_stylebox_override("panel", panel_style)
	dialogue_overlay.add_child(dialogue_panel)

	var contents := VBoxContainer.new()
	contents.add_theme_constant_override("separation", 8)
	dialogue_panel.add_child(contents)

	var dialogue := Label.new()
	dialogue.text = "What do you want???\nI have everything, come look!"
	dialogue.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	dialogue.add_theme_color_override("font_color", Color("#e8ca86"))
	dialogue.add_theme_font_size_override("font_size", 20)
	contents.add_child(dialogue)

	var browse_button := Button.new()
	browse_button.text = "Browse wares" + MenuStyle.key_hint("E")
	_style_menu_button(browse_button, 48.0)
	browse_button.pressed.connect(_open_shop)
	contents.add_child(browse_button)

	var close_button := Button.new()
	close_button.text = "Not now" + MenuStyle.key_hint("Esc")
	_style_menu_button(close_button, 48.0)
	close_button.pressed.connect(_close_dialogue)
	contents.add_child(close_button)


func _build_quest_dialogue() -> void:
	quest_dialogue = QuestDialogue.new()
	quest_dialogue.accepted.connect(_on_quest_accepted)
	quest_dialogue.declined.connect(_on_quest_declined)
	quest_dialogue.closed.connect(_on_quest_dialogue_closed)
	add_child(quest_dialogue)
	for node in get_parent().get_children():
		if node is QuestGiver:
			node.talk_requested.connect(_on_quest_talk_requested)


func _on_quest_talk_requested(quest_giver: QuestGiver) -> void:
	var quest := Quests.get_definition(quest_giver.quest_id)
	if quest.is_empty():
		push_error("%s offers unknown quest '%s'." % [quest_giver.npc_name, quest_giver.quest_id])
		return
	active_quest_giver = quest_giver
	var quest_state := GameState.get_quest_state(quest_giver.quest_id)
	var dialogue: Dictionary = quest["dialogue"]
	var pages: Array[String] = []
	pages.assign(dialogue.get(quest_state, dialogue[Quests.STATE_COMPLETED]))
	# Handing over the quest item completes the quest; the dialogue pages tell the story of it.
	var turn_in_state: String = quest.get("quest_item", {}).get("sets_state", "")
	if not turn_in_state.is_empty() and quest_state == turn_in_state:
		if not GameState.set_quest_state(quest_giver.quest_id, Quests.STATE_COMPLETED):
			push_error("Could not save completion of quest '%s'." % quest_giver.quest_id)
		quest_giver.refresh_marker()
	var offer_choice := quest_state == Quests.STATE_AVAILABLE
	quest_dialogue.start(quest_giver.npc_name, quest["title"], pages, offer_choice)
	_set_quest_dialogue_open(true)


func _on_quest_accepted() -> void:
	var quest := Quests.get_definition(active_quest_giver.quest_id)
	if not GameState.set_quest_state(active_quest_giver.quest_id, Quests.STATE_ACCEPTED):
		push_error("Could not save acceptance of quest '%s'." % active_quest_giver.quest_id)
	active_quest_giver.refresh_marker()
	_show_quest_reply(quest, "accepted_reply")


func _on_quest_declined() -> void:
	_show_quest_reply(Quests.get_definition(active_quest_giver.quest_id), "declined_reply")


func _show_quest_reply(quest: Dictionary, reply_key: String) -> void:
	var reply: Array[String] = []
	reply.assign(quest["dialogue"][reply_key])
	quest_dialogue.start(active_quest_giver.npc_name, quest["title"], reply, false)


func _on_quest_dialogue_closed() -> void:
	active_quest_giver = null
	_set_quest_dialogue_open(false)


func _build_quest_menu() -> void:
	quest_menu = QuestMenu.new()
	quest_menu.closed.connect(_on_quest_menu_closed)
	add_child(quest_menu)


func _open_quest_menu() -> void:
	character_sheet.hide()
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	quest_menu.open_menu()


func _on_quest_menu_closed() -> void:
	player.set_physics_process(true)
	player.set_process_unhandled_input(true)


func _set_quest_dialogue_open(is_open: bool) -> void:
	player.set_physics_process(not is_open)
	player.set_process_unhandled_input(not is_open)


func _build_waystone_menu() -> void:
	waystone_overlay = Control.new()
	waystone_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	waystone_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	waystone_overlay.visible = false
	add_child(waystone_overlay)

	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.02, 0.03, 0.025, 0.72)
	waystone_overlay.add_child(backdrop)

	var panel := _create_menu_panel(Vector2(600, 470))
	waystone_overlay.add_child(panel)

	var contents := VBoxContainer.new()
	contents.add_theme_constant_override("separation", 12)
	panel.add_child(contents)
	_add_menu_title(contents, "Oblath Waystone")

	var description := Label.new()
	description.text = "Choose a region to begin another run."
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	contents.add_child(description)

	var level_options := [
		[1, "res://main.tscn", GameState.LEVEL_NAMES[1]],
		[2, "res://desert.tscn", GameState.LEVEL_NAMES[2]],
		[3, "res://ice_caves.tscn", GameState.LEVEL_NAMES[3]],
		[4, "res://underworld.tscn", GameState.LEVEL_NAMES[4]]
	]
	for level_option in level_options:
		var level_id: int = level_option[0]
		var scene_path: String = level_option[1]
		var level_name: String = level_option[2]
		var level_button := Button.new()
		level_button.text = "Level %d  -  %s" % [level_id, level_name]
		_style_menu_button(level_button, 48.0)
		level_button.disabled = not GameState.is_level_unlocked(level_id)
		level_button.pressed.connect(_enter_waystone_level.bind(scene_path, level_name))
		contents.add_child(level_button)

	var close_button := Button.new()
	close_button.text = "Close" + MenuStyle.key_hint("Esc")
	_style_menu_button(close_button, 48.0)
	close_button.pressed.connect(_close_waystone)
	contents.add_child(close_button)


func _build_character_menu() -> void:
	character_sheet = CharacterSheet.create(player)
	add_child(character_sheet)
	character_sheet.closed.connect(_close_character_menu)
	character_sheet.skills_requested.connect(_open_skill_tree)
	character_sheet.passives_requested.connect(_open_passive_tree)

	if player.selected_character == "Witch":
		witch_skill_tree = WitchSkillTree.new()
		add_child(witch_skill_tree)
		witch_skill_tree.hide()
		witch_skill_tree.closed.connect(_on_witch_skill_tree_closed)
		witch_skill_tree.loadout_changed.connect(_refresh_witch_skill_slots)
		witch_skill_tree.passives_changed.connect(_on_witch_passives_changed)

		_refresh_witch_skill_slots()
	elif player.selected_character == "Warrior":
		warrior_skill_tree = WarriorSkillTree.new()
		add_child(warrior_skill_tree)
		warrior_skill_tree.hide()
		warrior_skill_tree.closed.connect(_on_warrior_skill_tree_closed)
		warrior_skill_tree.loadout_changed.connect(_refresh_warrior_skill_slots)
		warrior_skill_tree.passive_tree_requested.connect(_open_warrior_passive_tree)

		warrior_passive_tree = WarriorPassiveTree.new()
		add_child(warrior_passive_tree)
		warrior_passive_tree.hide()
		warrior_passive_tree.closed.connect(_on_warrior_passive_tree_closed)
		warrior_passive_tree.passives_changed.connect(_on_warrior_passives_changed)
		warrior_passive_tree.skill_tree_requested.connect(_open_warrior_skill_tree)
		_refresh_warrior_skill_slots()
	elif player.selected_character == "Ranger":
		ranger_skill_tree = RangerSkillTree.new()
		add_child(ranger_skill_tree)
		ranger_skill_tree.hide()
		ranger_skill_tree.closed.connect(_on_ranger_skill_tree_closed)
		ranger_skill_tree.loadout_changed.connect(_refresh_ranger_skill_slots)
		ranger_skill_tree.passive_tree_requested.connect(_open_ranger_passive_tree)

		ranger_passive_tree = RangerPassiveTree.new()
		add_child(ranger_passive_tree)
		ranger_passive_tree.hide()
		ranger_passive_tree.closed.connect(_on_ranger_passive_tree_closed)
		ranger_passive_tree.passives_changed.connect(_on_ranger_passives_changed)
		ranger_passive_tree.skill_tree_requested.connect(_open_ranger_skill_tree)
		_refresh_ranger_skill_slots()


func _open_witch_skill_tree(initial_tab: String = "") -> void:
	if witch_skill_tree == null:
		return
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	witch_skill_tree.open_tree(initial_tab)


func _open_warrior_skill_tree() -> void:
	if warrior_skill_tree == null:
		return
	if warrior_passive_tree != null:
		warrior_passive_tree.hide()
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	warrior_skill_tree.open_tree()


func _open_ranger_skill_tree() -> void:
	if ranger_skill_tree == null:
		return
	if ranger_passive_tree != null:
		ranger_passive_tree.hide()
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	ranger_skill_tree.open_tree()


func _on_ranger_skill_tree_closed() -> void:
	if ranger_skill_tree == null:
		return
	ranger_skill_tree.hide()
	_close_character_menu()


func _open_ranger_passive_tree() -> void:
	if ranger_passive_tree == null:
		return
	if ranger_skill_tree != null:
		ranger_skill_tree.hide()
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	ranger_passive_tree.open_tree("passives")


func _on_ranger_passive_tree_closed() -> void:
	if ranger_passive_tree == null:
		return
	ranger_passive_tree.hide()
	_close_character_menu()
	_on_ranger_passives_changed()


func _on_ranger_passives_changed() -> void:
	player.refresh_passives_and_vitals()
	character_sheet.refresh()
	_refresh_ranger_skill_slots()


func _refresh_ranger_skill_slots() -> void:
	for slot in ["Q", "W", "E", "R"]:
		var skill_slot := get_node_or_null("SkillSlot%s" % slot)
		if skill_slot == null:
			continue
		var skill_id := GameState.get_ranger_equipped_skill(slot)
		var definition := GameState.get_ranger_skill_definition(skill_id)
		skill_slot.set("skill_label", str(definition.get("short_label", "")))
		var icon_path := str(definition.get("icon_path", ""))
		skill_slot.set("skill_icon", load(icon_path) if not icon_path.is_empty() else null)
		var skill_tooltip := player.get_ranger_skill_tooltip(skill_id)
		skill_slot.set("skill_tooltip", skill_tooltip)
		skill_slot.tooltip_text = skill_tooltip
		skill_slot.queue_redraw()


func _on_warrior_skill_tree_closed() -> void:
	if warrior_skill_tree == null:
		return
	warrior_skill_tree.hide()
	_close_character_menu()


func _on_witch_skill_tree_closed() -> void:
	if witch_skill_tree == null:
		return
	witch_skill_tree.hide()
	_close_character_menu()
	_on_witch_passives_changed()


func _on_witch_passives_changed() -> void:
	player.refresh_passives_and_vitals()
	character_sheet.refresh()
	_refresh_witch_skill_slots()


func _refresh_witch_skill_slots() -> void:
	for slot in ["Q", "W", "E", "R"]:
		var skill_slot := get_node_or_null("SkillSlot%s" % slot)
		if skill_slot == null:
			continue
		var skill_id := GameState.get_witch_equipped_skill(slot)
		var definition := GameState.get_witch_skill_definition(skill_id)
		skill_slot.set("skill_label", str(definition.get("short_label", "")))
		var icon_path := str(definition.get("icon_path", ""))
		skill_slot.set("skill_icon", load(icon_path) if not icon_path.is_empty() else null)
		var skill_tooltip := player.get_witch_skill_tooltip(skill_id)
		skill_slot.set("skill_tooltip", skill_tooltip)
		skill_slot.tooltip_text = skill_tooltip
		skill_slot.queue_redraw()


func _open_warrior_passive_tree() -> void:
	if warrior_passive_tree == null:
		return
	if warrior_skill_tree != null:
		warrior_skill_tree.hide()
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	warrior_passive_tree.open_tree("passives")


func _on_warrior_passive_tree_closed() -> void:
	if warrior_passive_tree == null:
		return
	warrior_passive_tree.hide()
	_close_character_menu()
	_on_warrior_passives_changed()


func _on_warrior_passives_changed() -> void:
	player.refresh_passives_and_vitals()
	character_sheet.refresh()
	_refresh_warrior_skill_slots()


func _refresh_warrior_skill_slots() -> void:
	for slot in ["Q", "W", "E", "R"]:
		var skill_slot := get_node_or_null("SkillSlot%s" % slot)
		if skill_slot == null:
			continue
		var skill_id := GameState.get_warrior_equipped_skill(slot)
		var definition := GameState.get_warrior_skill_definition(skill_id)
		skill_slot.set("skill_label", str(definition.get("short_label", "")))
		var icon_path := str(definition.get("icon_path", ""))
		skill_slot.set("skill_icon", load(icon_path) if not icon_path.is_empty() else null)
		var skill_tooltip := player.get_warrior_skill_tooltip(skill_id)
		skill_slot.set("skill_tooltip", skill_tooltip)
		skill_slot.tooltip_text = skill_tooltip
		skill_slot.queue_redraw()


func _create_menu_panel(size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = size
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -size.x / 2.0
	panel.offset_top = -size.y / 2.0
	panel.offset_right = size.x / 2.0
	panel.offset_bottom = size.y / 2.0
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.075, 0.09, 0.075, 0.98)
	panel_style.set_border_width_all(3)
	panel_style.border_color = Color(0.62, 0.49, 0.29, 1)
	panel_style.set_corner_radius_all(8)
	panel_style.content_margin_left = 24.0
	panel_style.content_margin_right = 24.0
	panel_style.content_margin_top = 20.0
	panel_style.content_margin_bottom = 20.0
	panel.add_theme_stylebox_override("panel", panel_style)
	return panel


func _style_menu_button(button: Button, minimum_height: float = 52.0) -> void:
	button.custom_minimum_size.y = minimum_height
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", 18)


func _add_menu_title(contents: VBoxContainer, title_text: String) -> void:
	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("#e8ca86"))
	contents.add_child(title)


func _on_health_changed(current_health: int, maximum_health: int) -> void:
	health_orb.maximum = maximum_health
	health_orb.value = current_health


func _on_mana_changed(current_mana: int, maximum_mana: int) -> void:
	mana_orb.maximum = maximum_mana
	mana_orb.value = current_mana


func _update_potion_counts(
	health_count: int,
	mana_count: int,
	health_refill: float,
	mana_refill: float
) -> void:
	health_potion.set_charges(health_count, health_refill, Player.POTION_REFILL_TIME)
	mana_potion.set_charges(mana_count, mana_refill, Player.POTION_REFILL_TIME)


func _open_character_menu() -> void:
	if shop_overlay.visible or dialogue_overlay.visible or waystone_overlay.visible:
		return
	character_sheet.show_character()
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)


func _open_inventory_menu() -> void:
	if shop_overlay.visible or dialogue_overlay.visible or waystone_overlay.visible:
		return
	character_sheet.show_inventory()
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)


## Hides the sheet if it is open and gives control back to the player.
func _close_character_menu() -> void:
	character_sheet.hide()
	player.set_physics_process(true)
	player.set_process_unhandled_input(true)


func _open_waystone() -> void:
	if shop_overlay.visible or dialogue_overlay.visible or character_sheet.visible:
		return
	waystone_overlay.show()
	player.set_physics_process(false)


func _close_waystone() -> void:
	waystone_overlay.hide()
	player.set_physics_process(true)


func _enter_waystone_level(scene_path: String, level_name: String) -> void:
	var level_id := GameState.get_level_id(scene_path)
	if not GameState.is_level_unlocked(level_id):
		return
	if not ResourceLoader.exists(scene_path):
		push_error("Waystone level does not exist: %s" % scene_path)
		return

	get_tree().set_meta(Player.TOWN_RETURN_SCENE_META, scene_path)
	get_tree().set_meta(Player.TOWN_RETURN_POSITION_META, Vector2(84, 574))
	get_tree().set_meta("portal_spawn_position", Vector2(84, 574))
	get_tree().set_meta("portal_player_vitals", {
		"health": player.health,
		"mana": player.mana
	})
	var error := GameState.change_scene(scene_path)
	if error != OK:
		get_tree().remove_meta(Player.TOWN_RETURN_SCENE_META)
		get_tree().remove_meta(Player.TOWN_RETURN_POSITION_META)
		get_tree().remove_meta("portal_spawn_position")
		get_tree().remove_meta("portal_player_vitals")
		push_error("Could not enter %s through the waystone: %s" % [
			level_name,
			error_string(error)
		])


func _on_inventory_changed(_items: Array[ItemData]) -> void:
	if item_list != null and shop_overlay != null and shop_overlay.visible:
		_refresh_shop_items()


func _on_equipment_changed(_equipment: Dictionary) -> void:
	if player.selected_character == "Witch":
		_refresh_witch_skill_slots()


func _on_progression_changed(
	_level: int,
	_experience: int,
	xp_into_level: int,
	xp_for_level: int,
	_passive_points: int,
	_skill_points: int
) -> void:
	experience_level_label.text = "Lv. %d" % GameState.player_level
	if GameState.player_level >= GameState.MAX_PLAYER_LEVEL:
		experience_bar.max_value = 1.0
		experience_bar.value = 1.0
		experience_tooltip_label.text = "MAX LEVEL"
	else:
		experience_bar.max_value = xp_for_level
		experience_bar.value = xp_into_level
		experience_tooltip_label.text = "%d / %d XP" % [xp_into_level, xp_for_level]


func _on_experience_bar_mouse_entered() -> void:
	experience_tooltip.show()


func _on_experience_bar_mouse_exited() -> void:
	experience_tooltip.hide()


func _build_experience_bar() -> void:
	experience_level_label = Label.new()
	experience_level_label.anchor_left = 0.5
	experience_level_label.anchor_right = 0.5
	experience_level_label.anchor_top = 1.0
	experience_level_label.anchor_bottom = 1.0
	experience_level_label.offset_left = -(EXPERIENCE_BAR_WIDTH * 0.5) - 58.0
	experience_level_label.offset_top = -26.0
	experience_level_label.offset_right = -(EXPERIENCE_BAR_WIDTH * 0.5) - 8.0
	experience_level_label.offset_bottom = -6.0
	experience_level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	experience_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	experience_level_label.add_theme_color_override("font_color", ExperienceBar.LIQUID_HIGHLIGHT)
	experience_level_label.add_theme_color_override("font_outline_color", ExperienceBar.OUTLINE_COLOR)
	experience_level_label.add_theme_constant_override("outline_size", 4)
	add_child(experience_level_label)

	experience_bar = ExperienceBar.new()
	experience_bar.anchor_left = 0.5
	experience_bar.anchor_right = 0.5
	experience_bar.anchor_top = 1.0
	experience_bar.anchor_bottom = 1.0
	experience_bar.offset_left = -EXPERIENCE_BAR_WIDTH * 0.5
	experience_bar.offset_top = -25.0
	experience_bar.offset_right = EXPERIENCE_BAR_WIDTH * 0.5
	experience_bar.offset_bottom = -10.0
	experience_bar.min_value = 0.0
	experience_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(experience_bar)

	experience_tooltip = PanelContainer.new()
	experience_tooltip.anchor_left = 0.5
	experience_tooltip.anchor_right = 0.5
	experience_tooltip.anchor_top = 1.0
	experience_tooltip.anchor_bottom = 1.0
	experience_tooltip.offset_left = -70.0
	experience_tooltip.offset_top = -52.0
	experience_tooltip.offset_right = 70.0
	experience_tooltip.offset_bottom = -28.0
	experience_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tooltip_style := StyleBoxFlat.new()
	tooltip_style.bg_color = Color(ExperienceBar.GLASS_COLOR, 0.95)
	tooltip_style.set_border_width_all(1)
	tooltip_style.border_color = ExperienceBar.RIM_COLOR
	tooltip_style.content_margin_left = 6.0
	tooltip_style.content_margin_right = 6.0
	tooltip_style.content_margin_top = 2.0
	tooltip_style.content_margin_bottom = 2.0
	experience_tooltip.add_theme_stylebox_override("panel", tooltip_style)
	experience_tooltip_label = Label.new()
	experience_tooltip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	experience_tooltip.add_child(experience_tooltip_label)
	experience_tooltip.hide()
	add_child(experience_tooltip)
	experience_bar.mouse_entered.connect(_on_experience_bar_mouse_entered)
	experience_bar.mouse_exited.connect(_on_experience_bar_mouse_exited)

func _refresh_shop_items() -> void:
	for child in item_list.get_children():
		child.queue_free()
	for child in sell_item_list.get_children():
		child.queue_free()

	for item in GameState.get_vendor_items():
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = 42
		row.add_theme_constant_override("separation", 10)
		item_list.add_child(row)

		var description := Label.new()
		description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		description.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		description.text = "%s  (%s)  -  %s" % [
			item.display_name,
			item.equipment_slot,
			CharacterSheet.item_stat_text(item)
		]
		description.add_theme_color_override("font_color", item.get_rarity_color())
		row.add_child(description)

		var buy_button := Button.new()
		buy_button.custom_minimum_size.x = 128
		buy_button.text = "Buy  %d G" % item.price
		_style_menu_button(buy_button, 42.0)
		buy_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		buy_button.pressed.connect(_on_buy_item_pressed.bind(item))
		row.add_child(buy_button)

	if player.inventory.is_empty():
		var empty_message := Label.new()
		empty_message.text = "Your inventory is empty."
		empty_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		sell_item_list.add_child(empty_message)
		return

	for inventory_index in range(player.inventory.size()):
		var owned_item := player.inventory[inventory_index]
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = 42
		row.add_theme_constant_override("separation", 10)
		sell_item_list.add_child(row)

		var description := Label.new()
		description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		description.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		description.text = "%s  (%s)  -  %s" % [
			owned_item.display_name,
			owned_item.equipment_slot,
			CharacterSheet.item_stat_text(owned_item)
		]
		description.add_theme_color_override("font_color", owned_item.get_rarity_color())
		row.add_child(description)

		var sell_price := GameState.get_item_sell_price(owned_item)
		var sell_button := Button.new()
		sell_button.custom_minimum_size.x = 128
		sell_button.text = "Sell  %d G" % sell_price
		_style_menu_button(sell_button, 42.0)
		sell_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		sell_button.pressed.connect(_on_sell_item_pressed.bind(inventory_index))
		row.add_child(sell_button)


func _on_buy_item_pressed(item: ItemData) -> void:
	if item.price < MINIMUM_ITEM_PRICE:
		push_error("Vendor item price is below the minimum price.")
		return
	if player.purchase_item(item):
		status_label.text = "Purchased %s." % item.display_name
	else:
		if player.inventory.size() >= player.MAX_INVENTORY_SIZE:
			status_label.text = "Inventory is full."
		else:
			status_label.text = "Not enough gold."


func _on_sell_item_pressed(inventory_index: int) -> void:
	if inventory_index < 0 or inventory_index >= player.inventory.size():
		push_error("Shop sale index no longer matches the player inventory.")
		return

	var item := player.inventory[inventory_index]
	var sale_price := GameState.get_item_sell_price(item)
	if player.sell_inventory_item(inventory_index):
		status_label.text = "Sold %s for %d gold." % [item.display_name, sale_price]
	else:
		status_label.text = "Could not sell %s. Your character was not changed." % item.display_name


func _open_dialogue() -> void:
	character_sheet.hide()
	dialogue_overlay.show()
	player.set_physics_process(false)


func _open_shop() -> void:
	dialogue_overlay.hide()
	character_sheet.hide()
	_refresh_shop_items()
	status_label.text = ""
	shop_overlay.show()
	player.set_physics_process(false)


func _close_dialogue() -> void:
	if dialogue_overlay == null:
		return
	dialogue_overlay.hide()
	player.set_physics_process(true)


func _close_shop() -> void:
	if shop_panel == null:
		return
	shop_overlay.hide()
	player.set_physics_process(true)


func _update_gold(total_gold: int) -> void:
	gold_label.text = "Gold: %d" % total_gold
	if shop_gold_label != null:
		shop_gold_label.text = "Gold: %d" % total_gold


func _apply_camera_limits() -> void:
	var camera: Camera2D = player.get_node("Camera2D")
	# Limits clamp the camera before its offset is applied, so compensate to keep the
	# visible edges at the limits above.
	camera.limit_left = CAMERA_LIMIT_LEFT - int(camera.offset.x)
	camera.limit_right = CAMERA_LIMIT_RIGHT - int(camera.offset.x)
	camera.limit_top = CAMERA_LIMIT_TOP - int(camera.offset.y)
	camera.limit_bottom = CAMERA_LIMIT_BOTTOM - int(camera.offset.y)
	camera.reset_smoothing()


func _restore_town_return_destination() -> void:
	if not get_tree().has_meta(Player.TOWN_RETURN_SCENE_META):
		return

	var scene_path: Variant = get_tree().get_meta(Player.TOWN_RETURN_SCENE_META)
	var world_position: Variant = get_tree().get_meta(Player.TOWN_RETURN_POSITION_META)
	get_tree().remove_meta(Player.TOWN_RETURN_SCENE_META)
	get_tree().remove_meta(Player.TOWN_RETURN_POSITION_META)
	if typeof(scene_path) != TYPE_STRING or not ResourceLoader.exists(scene_path):
		push_error("Town return scene is invalid: %s" % str(scene_path))
		return
	if not world_position is Vector2:
		push_error("Town return position must be a Vector2.")
		return

	return_portal.destination_scene = scene_path
	return_portal.destination_position = world_position
