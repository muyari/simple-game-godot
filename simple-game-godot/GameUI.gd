extends CanvasLayer

const EXPERIENCE_BAR_WIDTH = 440.0
const BOSS_BANNER_DURATION = 3.0
const BOSS_BANNER_COLOR := Color("#ff6a4d")
const QUEST_BANNER_COLOR := Color("#ffd34d")
const ENDGAME_BANNER_COLOR := Color("#c99bff")


@onready var health_orb: ResourceGlobe = $HealthOrb
@onready var mana_orb: ResourceGlobe = $ManaOrb
@onready var health_potion: PotionFlask = $HealthPotion
@onready var mana_potion: PotionFlask = $ManaPotion
@onready var enemy_progress_label: Label = $EnemyProgressLabel
@onready var gold_label: Label = $GoldLabel
@onready var portal_hint_label: Label = $PortalHintLabel
var experience_bar: ProgressBar
var outcome_overlay: Control
var outcome_eyebrow: Label
var outcome_title: Label
var outcome_subtitle: Label
var outcome_actions: VBoxContainer
var return_to_town_button: Button
var experience_level_label: Label
var experience_tooltip: PanelContainer
var experience_tooltip_label: Label
var experience_feedback_label: Label
var experience_feedback_time := 0.0
var boss_banner: Label
var boss_banner_time := 0.0
var chest_loot_window: ChestLootWindow
var active_chest: TreasureChest
var quest_menu: QuestMenu
var witch_skill_tree: WitchSkillTree
var warrior_skill_tree: WarriorSkillTree
var warrior_passive_tree: WarriorPassiveTree
var ranger_skill_tree: RangerSkillTree
var ranger_passive_tree: RangerPassiveTree
var pause_menu: PauseMenu
var character_sheet: CharacterSheet


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_progression_hud()
	_build_boss_banner()
	_build_chest_loot_window()
	# Quest notices and the arrow to the next forest objective sit under every menu.
	add_child(QuestTracker.new())
	add_child(QuestToast.new())
	var quest_dialogue := QuestDialogue.new()
	quest_dialogue.opened.connect(_set_player_menu_paused.bind(true))
	quest_dialogue.closed.connect(_set_player_menu_paused.bind(false))
	add_child(quest_dialogue)
	quest_menu = QuestMenu.new()
	quest_menu.closed.connect(_set_player_menu_paused.bind(false))
	add_child(quest_menu)
	_build_pause_menu()
	var player: Player = get_node("../Player")
	_build_touch_controls(player)
	add_child(TargetHealthBar.create(player))
	_connect_skill_slot_clicks(player)
	_build_character_sheet(player)
	_build_outcome_overlay()
	for label in [enemy_progress_label, gold_label, portal_hint_label]:
		MenuStyle.outline_hud_label(label)
	if player.selected_character == "Witch":
		_build_witch_skill_tree()
	elif player.selected_character == "Warrior":
		_build_warrior_skill_tree()
	elif player.selected_character == "Ranger":
		_build_ranger_skill_tree()
	# Last, so it draws and takes clicks above the rest of the HUD. It hides itself
	# whenever a menu has the player paused.
	_build_hud_menu(player)
	health_orb.maximum = player.MAX_HEALTH
	health_orb.value = player.health
	mana_orb.maximum = player.MAX_MANA
	mana_orb.value = player.mana
	_update_potion_counts(player.health_potions, player.mana_potions, 0.0, 0.0)
	player.health_changed.connect(_on_health_changed)
	player.mana_changed.connect(_on_mana_changed)
	player.potion_counts_changed.connect(_update_potion_counts)
	player.town_portal_cast_started.connect(_on_town_portal_cast_started)
	player.town_portal_cast_cancelled.connect(_on_town_portal_cast_cancelled)
	player.town_portal_opened.connect(_on_town_portal_opened)
	player.died.connect(_on_player_died)
	GameState.progression_changed.connect(_on_progression_changed)
	GameState.experience_gained.connect(_on_experience_gained)
	GameState.player_leveled_up.connect(_on_player_leveled_up)
	_on_gold_changed(GameState.gold)
	_on_progression_changed(
		GameState.player_level,
		GameState.experience,
		GameState.get_xp_into_current_level(),
		GameState.get_xp_for_next_level(),
		GameState.passive_tree_points,
		GameState.skill_tree_points
	)
	GameState.gold_changed.connect(_on_gold_changed)
	var level_controller: Node = get_node("../LevelController")
	level_controller.progress_changed.connect(_on_enemy_progress_changed)
	level_controller.level_completed.connect(_on_level_completed)
	level_controller.boss_incoming.connect(_on_boss_incoming)
	level_controller.boss_progress_changed.connect(_on_boss_progress_changed)
	level_controller.chest_loot_opened.connect(_on_chest_loot_opened)
	level_controller.cleared_map_entered.connect(_on_cleared_map_entered)
	if _is_endgame() and not bool(level_controller.get("level_is_complete")):
		_show_banner("%s Random Map" % _endgame_tier_name(), ENDGAME_BANNER_COLOR)


func _connect_skill_slot_clicks(player: Player) -> void:
	for slot in ["Q", "W", "E", "R"]:
		var skill_slot := get_node_or_null("SkillSlot%s" % slot) as SkillSlot
		if skill_slot != null:
			skill_slot.skill_activated.connect(player.activate_skill_slot)


func _process(delta: float) -> void:
	_update_witch_skill_cooldowns()
	_update_boss_banner(delta)
	if experience_feedback_time <= 0.0:
		return
	experience_feedback_time = maxf(experience_feedback_time - delta, 0.0)
	if experience_feedback_time == 0.0:
		experience_feedback_label.hide()


func _update_witch_skill_cooldowns() -> void:
	var player: Player = get_node("../Player")
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


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if chest_loot_window.visible:
		if event.keycode in [KEY_ESCAPE, KEY_E]:
			_close_chest_loot_window()
		get_viewport().set_input_as_handled()
		return
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
		elif character_sheet.visible:
			character_sheet.close()
		else:
			pause_menu.open_menu()
		get_viewport().set_input_as_handled()
		return

	if event.keycode == KEY_C:
		_toggle_character_panel()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_K:
		_open_skill_tree()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_P:
		_open_passive_tree()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_I:
		_toggle_inventory_panel()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_J:
		_open_quest_menu()
		get_viewport().set_input_as_handled()


func _toggle_character_panel() -> void:
	if character_sheet.is_character_shown():
		character_sheet.close()
	else:
		character_sheet.show_character()
		_set_player_menu_paused(true)


func _toggle_inventory_panel() -> void:
	if character_sheet.is_inventory_shown():
		character_sheet.close()
	else:
		character_sheet.show_inventory()
		_set_player_menu_paused(true)


func _build_character_sheet(player: Player) -> void:
	character_sheet = CharacterSheet.create(player)
	add_child(character_sheet)
	character_sheet.closed.connect(_set_player_menu_paused.bind(false))
	character_sheet.skills_requested.connect(_open_skill_tree)
	character_sheet.passives_requested.connect(_open_passive_tree)


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


func _open_quest_menu() -> void:
	character_sheet.hide()
	_set_player_menu_paused(true)
	quest_menu.open_menu()


func _build_hud_menu(player: Player) -> void:
	var hud_menu := HudMenu.new()
	hud_menu.is_available = func() -> bool:
		return player.is_physics_processing() and player.health > 0
	add_child(hud_menu)
	hud_menu.add_command("Character", "C", _toggle_character_panel)
	hud_menu.add_command("Inventory", "I", _toggle_inventory_panel)
	hud_menu.add_command("Skills", "K", _open_skill_tree)
	hud_menu.add_command("Passives", "P", _open_passive_tree)
	hud_menu.add_command("Quests", "J", _open_quest_menu)
	hud_menu.add_command("Town Portal", "T", player.cast_town_portal)
	hud_menu.add_command("Pause", "Esc", pause_menu.open_menu)


func _build_touch_controls(player: Player) -> void:
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
	var level_controller: Node = get_node("../LevelController")
	if not level_controller.save_current_level_state():
		push_error("Could not save the current level before returning to character selection.")
		return
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
	var level_controller: Node = get_node("../LevelController")
	if not level_controller.save_current_level_state():
		push_error("Could not save the current level before closing the game.")
		return
	if not GameState.save_character(GameState.get_inventory(), GameState.get_equipment()):
		push_error("Could not save the active character before closing the game.")
		return
	get_tree().quit()


func _build_witch_skill_tree() -> void:
	witch_skill_tree = WitchSkillTree.new()
	add_child(witch_skill_tree)
	witch_skill_tree.hide()
	witch_skill_tree.closed.connect(_on_witch_skill_tree_closed)
	witch_skill_tree.loadout_changed.connect(_refresh_witch_skill_slots)
	witch_skill_tree.passives_changed.connect(_on_witch_passives_changed)

	_refresh_witch_skill_slots()


func _build_warrior_skill_tree() -> void:
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


func _build_ranger_skill_tree() -> void:
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


func _open_ranger_skill_tree() -> void:
	if ranger_skill_tree == null:
		return
	if ranger_passive_tree != null:
		ranger_passive_tree.hide()
	var player: Player = get_node("../Player")
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	ranger_skill_tree.open_tree()


func _on_ranger_skill_tree_closed() -> void:
	if ranger_skill_tree == null:
		return
	ranger_skill_tree.hide()
	character_sheet.hide()
	_set_player_menu_paused(false)


func _open_ranger_passive_tree() -> void:
	if ranger_passive_tree == null:
		return
	if ranger_skill_tree != null:
		ranger_skill_tree.hide()
	var player: Player = get_node("../Player")
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	ranger_passive_tree.open_tree("passives")


func _on_ranger_passive_tree_closed() -> void:
	if ranger_passive_tree == null:
		return
	ranger_passive_tree.hide()
	character_sheet.hide()
	_set_player_menu_paused(false)
	_on_ranger_passives_changed()


func _on_ranger_passives_changed() -> void:
	var player: Player = get_node_or_null("../Player")
	if player != null:
		player.refresh_passives_and_vitals()
		character_sheet.refresh()
	_refresh_ranger_skill_slots()


func _refresh_ranger_skill_slots() -> void:
	var player: Player = get_node("../Player")
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


func _open_warrior_skill_tree() -> void:
	if warrior_skill_tree == null:
		return
	if warrior_passive_tree != null:
		warrior_passive_tree.hide()
	var player: Player = get_node("../Player")
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	warrior_skill_tree.open_tree()


func _on_warrior_skill_tree_closed() -> void:
	if warrior_skill_tree == null:
		return
	warrior_skill_tree.hide()
	character_sheet.hide()
	_set_player_menu_paused(false)


func _open_warrior_passive_tree() -> void:
	if warrior_passive_tree == null:
		return
	if warrior_skill_tree != null:
		warrior_skill_tree.hide()
	var player: Player = get_node("../Player")
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	warrior_passive_tree.open_tree("passives")


func _on_warrior_passive_tree_closed() -> void:
	if warrior_passive_tree == null:
		return
	warrior_passive_tree.hide()
	character_sheet.hide()
	_set_player_menu_paused(false)
	_on_warrior_passives_changed()


func _on_warrior_passives_changed() -> void:
	var player: Player = get_node_or_null("../Player")
	if player != null:
		player.refresh_passives_and_vitals()
		character_sheet.refresh()
	_refresh_warrior_skill_slots()


func _refresh_warrior_skill_slots() -> void:
	var player: Player = get_node("../Player")
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


func _open_witch_skill_tree(initial_tab: String = "") -> void:
	if witch_skill_tree == null:
		return
	var player: Player = get_node("../Player")
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	witch_skill_tree.open_tree(initial_tab)


func _on_witch_skill_tree_closed() -> void:
	if witch_skill_tree == null:
		return
	witch_skill_tree.hide()
	character_sheet.hide()
	_set_player_menu_paused(false)
	_on_witch_passives_changed()


func _on_witch_passives_changed() -> void:
	var player: Player = get_node_or_null("../Player")
	if player != null:
		player.refresh_passives_and_vitals()
		character_sheet.refresh()
	_refresh_witch_skill_slots()


func _set_player_menu_paused(paused: bool) -> void:
	var player: Player = get_node("../Player")
	player.set_physics_process(not paused)
	player.set_process_unhandled_input(not paused)


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
		var player: Player = get_node("../Player")
		var skill_tooltip := player.get_witch_skill_tooltip(skill_id)
		skill_slot.set("skill_tooltip", skill_tooltip)
		skill_slot.tooltip_text = skill_tooltip
		skill_slot.queue_redraw()


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


func _on_player_died() -> void:
	_show_outcome(
		"FALLEN",
		"You were defeated",
		"The frontier claims another exile, for now. Regroup in %s." % _hub_name(),
		[["Return to %s" % _hub_name(), _on_return_to_town_pressed]]
	)


## Centred panel shown when the player dies. Each action is
## [label, callable]; the "Return to Town" one is kept so it can be disabled
## while the level saves.
func _show_outcome(eyebrow: String, title: String, subtitle: String, actions: Array) -> void:
	outcome_eyebrow.text = eyebrow
	outcome_title.text = title
	outcome_subtitle.text = subtitle
	for child in outcome_actions.get_children():
		child.queue_free()
	for action in actions:
		var button := Button.new()
		button.text = action[0]
		button.custom_minimum_size.y = 50.0
		button.pressed.connect(action[1])
		outcome_actions.add_child(button)
		if action[1] == _on_return_to_town_pressed:
			return_to_town_button = button
	outcome_overlay.show()


func _build_outcome_overlay() -> void:
	outcome_overlay = Control.new()
	outcome_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outcome_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	outcome_overlay.hide()
	add_child(outcome_overlay)

	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.015, 0.02, 0.018, 0.55)
	outcome_overlay.add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outcome_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"MenuPanel"
	panel.custom_minimum_size = Vector2(460.0, 0.0)
	center.add_child(panel)

	var contents := VBoxContainer.new()
	contents.add_theme_constant_override("separation", 12)
	panel.add_child(contents)
	outcome_eyebrow = Label.new()
	outcome_eyebrow.theme_type_variation = &"EyebrowLabel"
	outcome_eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	contents.add_child(outcome_eyebrow)
	outcome_title = Label.new()
	outcome_title.theme_type_variation = &"TitleLabel"
	outcome_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	contents.add_child(outcome_title)
	outcome_subtitle = Label.new()
	outcome_subtitle.theme_type_variation = &"SubtitleLabel"
	outcome_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outcome_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	outcome_subtitle.custom_minimum_size.x = 392.0
	contents.add_child(outcome_subtitle)
	contents.add_child(HSeparator.new())
	outcome_actions = VBoxContainer.new()
	outcome_actions.add_theme_constant_override("separation", 10)
	contents.add_child(outcome_actions)


func _on_enemy_progress_changed(defeated: int, total: int) -> void:
	enemy_progress_label.text = "Enemies defeated: %d/%d" % [defeated, total]
	if _is_endgame():
		enemy_progress_label.text = "%s map  -  %s" % [_endgame_tier_name(), enemy_progress_label.text]


func _is_endgame() -> bool:
	var level_controller := get_node_or_null("../LevelController")
	return level_controller != null and level_controller.has_method("is_endgame") \
			and bool(level_controller.call("is_endgame"))


func _endgame_tier_name() -> String:
	return GameState.get_endgame_tier_name(int(get_node("../LevelController").get("endgame_tier")))


func _on_boss_incoming() -> void:
	_show_banner("Incoming Boss", BOSS_BANNER_COLOR)


## Big centred announcement that punches in and fades out (boss warnings, quest updates).
func _show_banner(text: String, color: Color) -> void:
	boss_banner.text = text
	boss_banner.add_theme_color_override("font_color", color)
	boss_banner_time = BOSS_BANNER_DURATION
	boss_banner.show()


func _on_boss_progress_changed(defeated: int, total: int) -> void:
	if total > 1:
		enemy_progress_label.text = "Boss pack: %d/%d" % [defeated, total]
	else:
		enemy_progress_label.text = "Boss: %d/%d" % [defeated, total]


func _update_boss_banner(delta: float) -> void:
	if boss_banner_time <= 0.0:
		return
	boss_banner_time = maxf(boss_banner_time - delta, 0.0)
	var elapsed := BOSS_BANNER_DURATION - boss_banner_time
	# Punch in, hold, then fade out over the last second.
	boss_banner.scale = Vector2.ONE * lerpf(1.4, 1.0, clampf(elapsed / 0.25, 0.0, 1.0))
	boss_banner.modulate.a = clampf(boss_banner_time, 0.0, 1.0)
	if boss_banner_time == 0.0:
		boss_banner.hide()


func _build_chest_loot_window() -> void:
	chest_loot_window = ChestLootWindow.new()
	chest_loot_window.take_requested.connect(_on_chest_take_requested)
	chest_loot_window.take_all_requested.connect(_on_chest_take_all_requested)
	chest_loot_window.close_requested.connect(_close_chest_loot_window)
	add_child(chest_loot_window)


func _on_chest_loot_opened(chest: TreasureChest) -> void:
	active_chest = chest
	chest_loot_window.open(chest.loot)
	_set_player_menu_paused(true)


func _on_chest_take_requested(index: int) -> void:
	if not _take_chest_item(index):
		return
	_after_chest_take()


func _on_chest_take_all_requested() -> void:
	while not active_chest.loot.is_empty():
		if not _take_chest_item(0):
			return
	_after_chest_take()


## Moves one item from the open chest into the player's inventory.
func _take_chest_item(index: int) -> bool:
	if active_chest == null or index < 0 or index >= active_chest.loot.size():
		return false
	var item := active_chest.loot[index]
	if not item.quest_id.is_empty():
		# Quest items advance their quest instead of taking an inventory slot.
		var status := Quests.loot_quest_item(item.quest_id)
		if not status.is_empty():
			_show_banner("Quest Updated", QUEST_BANNER_COLOR)
		active_chest.loot.remove_at(index)
		return true
	var player: Player = get_node("../Player")
	if not player.try_add_item(item):
		chest_loot_window.refresh(active_chest.loot)
		chest_loot_window.show_status("Inventory full.")
		return false
	active_chest.loot.remove_at(index)
	return true


func _after_chest_take() -> void:
	active_chest.update_prompt()
	if active_chest.loot.is_empty():
		_close_chest_loot_window()
	else:
		chest_loot_window.refresh(active_chest.loot)


func _close_chest_loot_window() -> void:
	chest_loot_window.hide()
	_set_player_menu_paused(false)
	if active_chest != null and is_instance_valid(active_chest):
		active_chest.update_prompt()
	active_chest = null


func _build_boss_banner() -> void:
	boss_banner = Label.new()
	boss_banner.text = "Incoming Boss"
	boss_banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	boss_banner.offset_left = -260.0
	boss_banner.offset_right = 260.0
	boss_banner.offset_top = 120.0
	boss_banner.offset_bottom = 176.0
	boss_banner.pivot_offset = Vector2(260.0, 28.0)
	boss_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	boss_banner.add_theme_font_size_override("font_size", 40)
	boss_banner.add_theme_color_override("font_color", Color("#ff6a4d"))
	boss_banner.add_theme_color_override("font_outline_color", Color("#1a0805"))
	boss_banner.add_theme_constant_override("outline_size", 8)
	boss_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_banner.hide()
	add_child(boss_banner)


func _on_progression_changed(
	_level: int,
	_total_experience: int,
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


func _on_experience_gained(amount: int) -> void:
	experience_feedback_label.text = "+%d XP" % amount
	experience_feedback_label.show()
	experience_feedback_time = 2.5


func _on_player_leveled_up(_level: int) -> void:
	experience_feedback_label.text = "LEVEL UP!"
	experience_feedback_label.show()
	experience_feedback_time = 3.5


func _on_gold_changed(total_gold: int) -> void:
	gold_label.text = "Gold: %d" % total_gold


func _on_town_portal_opened() -> void:
	portal_hint_label.text = "Portal to %s open - walk into it to travel" % _hub_name()


func _on_town_portal_cast_started() -> void:
	portal_hint_label.text = "Channeling Town Portal (3 seconds)..."


func _on_town_portal_cast_cancelled() -> void:
	portal_hint_label.text = "Town Portal interrupted"


func _build_progression_hud() -> void:
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

	experience_feedback_label = Label.new()
	experience_feedback_label.position = Vector2(20.0, 180.0)
	experience_feedback_label.add_theme_font_size_override("font_size", 18)
	experience_feedback_label.add_theme_color_override("font_color", Color("#ffe58a"))
	experience_feedback_label.add_theme_color_override("font_shadow_color", Color("#251a0b"))
	experience_feedback_label.add_theme_constant_override("shadow_offset_x", 1)
	experience_feedback_label.add_theme_constant_override("shadow_offset_y", 1)
	experience_feedback_label.hide()
	add_child(experience_feedback_label)


func _on_level_completed() -> void:
	var level_id := GameState.get_level_id(get_tree().current_scene.scene_file_path)
	if level_id == GameState.ENDGAME_LEVEL_ID:
		_on_endgame_map_completed()
		return
	var campaign_was_complete := GameState.is_campaign_complete()
	if not GameState.complete_level(level_id):
		push_error("Could not persist completion for level %d." % level_id)
	# No pop-up: the boss's loot is still on the ground. A banner, a marker in the corner and a way home.
	enemy_progress_label.text = "✓  %s secured" % str(GameState.LEVEL_NAMES.get(level_id, "Area"))
	enemy_progress_label.add_theme_color_override("font_color", Color("#a9d98a"))
	if not campaign_was_complete and GameState.is_campaign_complete():
		# The last campaign level just fell: point the player at the endgame.
		_show_banner("Random Maps Unlocked", ENDGAME_BANNER_COLOR)
		portal_hint_label.text = "The waystones stir: random maps await at any hub's waystone."
	else:
		_show_banner("Area Secured", QUEST_BANNER_COLOR)
	_show_corner_return_button()


func _on_endgame_map_completed() -> void:
	var tier := int(GameState.get_endgame_run().get("tier", 1))
	if not GameState.finish_endgame_run():
		push_error("Could not record the cleared random map.")
	_show_banner("Map Cleared", ENDGAME_BANNER_COLOR)
	enemy_progress_label.text = "✓  %s map cleared  (%d at this tier)" % [
		GameState.get_endgame_tier_name(tier),
		GameState.get_endgame_clears(tier)
	]
	enemy_progress_label.add_theme_color_override("font_color", Color("#a9d98a"))
	portal_hint_label.text = "New random maps are started at a waystone."
	_show_corner_return_button()


## Back on a random map that was already cleared: nothing left to fight, just the way home.
func _on_cleared_map_entered() -> void:
	enemy_progress_label.text = "✓  %s map cleared" % _endgame_tier_name()
	enemy_progress_label.add_theme_color_override("font_color", Color("#a9d98a"))
	_show_corner_return_button()


## The hub of the region this level belongs to.
func _hub_name() -> String:
	return GameState.get_hub_name(GameState.get_level_id(get_tree().current_scene.scene_file_path))


## A small "Return to Town" button tucked under the top-left HUD once the level is cleared.
func _show_corner_return_button() -> void:
	var button := Button.new()
	button.text = "Return to %s" % _hub_name()
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 15)
	button.position = Vector2(20.0, 96.0)
	button.custom_minimum_size = Vector2(150.0, 34.0 if not TouchControls.is_supported() else 46.0)
	button.pressed.connect(_on_return_to_town_pressed)
	add_child(button)
	return_to_town_button = button


func _on_return_to_town_pressed() -> void:
	var player: Player = get_node("../Player")
	var scene_path := get_tree().current_scene.scene_file_path
	if GameState.get_level_id(scene_path) == 0:
		push_error("Cannot return to town from an unsupported level: %s" % scene_path)
		return

	return_to_town_button.disabled = true
	var level_controller: Node = get_node("../LevelController")
	if not level_controller.has_method("save_current_level_state") \
			or not bool(level_controller.call("save_current_level_state")):
		return_to_town_button.disabled = false
		push_error("Could not save the current level before returning to town.")
		return
	get_tree().set_meta(Player.TOWN_RETURN_SCENE_META, scene_path)
	get_tree().set_meta(Player.TOWN_RETURN_POSITION_META, player.global_position)
	var level_id := GameState.get_level_id(scene_path)
	get_tree().set_meta("portal_spawn_position", GameState.get_hub_arrival(level_id))
	get_tree().set_meta("portal_player_vitals", {
		"health": Player.MAX_HEALTH,
		"mana": player.mana
	})
	var error := GameState.change_scene(GameState.get_hub_scene(level_id))
	if error != OK:
		get_tree().remove_meta(Player.TOWN_RETURN_SCENE_META)
		get_tree().remove_meta(Player.TOWN_RETURN_POSITION_META)
		get_tree().remove_meta("portal_spawn_position")
		get_tree().remove_meta("portal_player_vitals")
		return_to_town_button.disabled = false
		push_error("Could not return to town: %s" % error_string(error))
