extends CanvasLayer

const MINIMUM_ITEM_PRICE = 25
const EXPERIENCE_BAR_WIDTH = 440.0

@onready var gold_label: Label = $GoldLabel
@onready var player: Player = get_node("../Player")
@onready var vendor: Vendor = get_node("../Vendor")
@onready var waystone: Area2D = get_node("../Waystone")
@onready var return_portal: Portal = get_node("../ReturnPortal")
@onready var health_orb: ResourceGlobe = $HealthOrb
@onready var mana_orb: ResourceGlobe = $ManaOrb
@onready var health_potion_label: Label = $HealthPotionLabel
@onready var mana_potion_label: Label = $ManaPotionLabel
@onready var passive_tree_button: Button = $PassiveTreeButton

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
var waystone_overlay: Control
var shop_overlay: Control
var character_overlay: Control
var character_panel: PanelContainer
var inventory_panel: PanelContainer
var witch_skill_tree: WitchSkillTree
var equipment_stats_label: Label
var character_progression_label: Label
var equipment_slot_labels: Dictionary = {}
var inventory_grid: GridContainer
var selected_item_label: Label
var equip_item_button: Button
var inventory_gold_label: Label
var inventory_slots: Array[Button] = []
var selected_inventory_index := -1


func _ready() -> void:
	passive_tree_button.visible = player.selected_character == "Witch"
	_build_experience_bar()
	_update_gold(GameState.gold)
	GameState.gold_changed.connect(_update_gold)
	_restore_town_return_destination()
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
	_build_waystone_menu()
	_build_character_menu()
	_on_inventory_changed(player.inventory)
	_on_equipment_changed(player.equipment)
	_on_progression_changed(
		GameState.player_level,
		GameState.experience,
		GameState.get_xp_into_current_level(),
		GameState.get_xp_for_next_level(),
		GameState.passive_tree_points,
		GameState.skill_tree_points
	)


func _process(_delta: float) -> void:
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
			if event.keycode == KEY_ESCAPE:
				_on_witch_skill_tree_closed()
			get_viewport().set_input_as_handled()
			return
		if waystone_overlay != null and waystone_overlay.visible:
			if event.keycode == KEY_ESCAPE:
				_close_waystone()
				get_viewport().set_input_as_handled()
		if dialogue_overlay != null and dialogue_overlay.visible:
			if event.keycode == KEY_ESCAPE:
				_close_dialogue()
				get_viewport().set_input_as_handled()
			return
		if shop_overlay != null and shop_overlay.visible:
			if event.keycode == KEY_ESCAPE:
				_close_shop()
				get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_C:
			if character_overlay.visible and character_panel.visible:
				_close_character_menu()
			else:
				_open_character_menu()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_I:
			if character_overlay.visible and inventory_panel.visible:
				_close_character_menu()
			else:
				_open_inventory_menu()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_P and witch_skill_tree != null:
			if (shop_overlay == null or not shop_overlay.visible) \
					and (dialogue_overlay == null or not dialogue_overlay.visible) \
					and (waystone_overlay == null or not waystone_overlay.visible):
				_open_witch_skill_tree()
				get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE and character_overlay.visible:
			_close_character_menu()
			get_viewport().set_input_as_handled()


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
	title.text = "Hearthvale Trading Post"
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
	close_button.text = "Close  (Esc)"
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
	browse_button.text = "Browse wares  (E)"
	_style_menu_button(browse_button, 48.0)
	browse_button.pressed.connect(_open_shop)
	contents.add_child(browse_button)

	var close_button := Button.new()
	close_button.text = "Not now  (Esc)"
	_style_menu_button(close_button, 48.0)
	close_button.pressed.connect(_close_dialogue)
	contents.add_child(close_button)


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
	_add_menu_title(contents, "Hearthvale Waystone")

	var description := Label.new()
	description.text = "Choose a region to begin another run."
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	contents.add_child(description)

	var level_options := [
		[1, "res://main.tscn", "Forest Outskirts"],
		[2, "res://desert.tscn", "Sunscorch Sands"],
		[3, "res://ice_caves.tscn", "The Ice Caves"],
		[4, "res://futuristic_ai_zone.tscn", "The Futuristic AI Zone"]
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
	close_button.text = "Close  (Esc)"
	_style_menu_button(close_button, 48.0)
	close_button.pressed.connect(_close_waystone)
	contents.add_child(close_button)


func _build_character_menu() -> void:
	character_overlay = Control.new()
	character_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	character_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	character_overlay.visible = false
	add_child(character_overlay)

	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.02, 0.03, 0.025, 0.72)
	character_overlay.add_child(backdrop)

	character_panel = _create_menu_panel(Vector2(560, 600))
	inventory_panel = _create_menu_panel(Vector2(600, 620))
	character_overlay.add_child(character_panel)
	character_overlay.add_child(inventory_panel)

	var character_contents := VBoxContainer.new()
	character_contents.add_theme_constant_override("separation", 12)
	character_panel.add_child(character_contents)
	_add_menu_title(character_contents, "Character")

	equipment_stats_label = Label.new()
	equipment_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	character_contents.add_child(equipment_stats_label)

	character_progression_label = Label.new()
	character_progression_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	character_progression_label.add_theme_color_override("font_color", Color("#f3dfae"))
	character_contents.add_child(character_progression_label)

	var equipment_grid := GridContainer.new()
	equipment_grid.columns = 2
	equipment_grid.add_theme_constant_override("h_separation", 10)
	equipment_grid.add_theme_constant_override("v_separation", 10)
	character_contents.add_child(equipment_grid)
	for slot_name in ["Weapon", "Helm", "Chest", "Legs", "Gloves", "Boots", "Ring 1", "Ring 2", "Amulet"]:
		var slot_label := Label.new()
		slot_label.custom_minimum_size = Vector2(235, 48)
		slot_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot_label.text = "%s  -  Empty" % slot_name
		equipment_grid.add_child(slot_label)
		equipment_slot_labels[slot_name] = slot_label

	var character_close_button := Button.new()
	character_close_button.text = "Close  (C / Esc)"
	_style_menu_button(character_close_button, 42.0)
	character_close_button.pressed.connect(_close_character_menu)
	if player.selected_character == "Witch":
		var skill_tree_button := Button.new()
		skill_tree_button.text = "Witch Skill Tree"
		_style_menu_button(skill_tree_button, 42.0)
		skill_tree_button.pressed.connect(_open_witch_skill_tree)
		character_contents.add_child(skill_tree_button)
	character_contents.add_child(character_close_button)

	var inventory_contents := VBoxContainer.new()
	inventory_contents.add_theme_constant_override("separation", 12)
	inventory_panel.add_child(inventory_contents)
	_add_menu_title(inventory_contents, "Inventory")

	inventory_gold_label = Label.new()
	inventory_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	inventory_gold_label.add_theme_color_override("font_color", Color("#ffdc83"))
	inventory_contents.add_child(inventory_gold_label)
	_update_gold(GameState.gold)

	selected_item_label = Label.new()
	selected_item_label.custom_minimum_size.y = 42
	selected_item_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	selected_item_label.text = "Select an item to inspect it."
	inventory_contents.add_child(selected_item_label)

	inventory_grid = GridContainer.new()
	inventory_grid.columns = 5
	inventory_grid.add_theme_constant_override("h_separation", 8)
	inventory_grid.add_theme_constant_override("v_separation", 8)
	inventory_contents.add_child(inventory_grid)
	for slot_index in range(Player.MAX_INVENTORY_SIZE):
		var slot := Button.new()
		slot.custom_minimum_size = Vector2(76, 54)
		slot.alignment = HORIZONTAL_ALIGNMENT_LEFT
		slot.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		slot.add_theme_font_size_override("font_size", 11)
		slot.pressed.connect(_on_inventory_slot_pressed.bind(slot_index))
		inventory_grid.add_child(slot)
		inventory_slots.append(slot)

	equip_item_button = Button.new()
	equip_item_button.text = "Equip Selected Item"
	_style_menu_button(equip_item_button, 42.0)
	equip_item_button.disabled = true
	equip_item_button.pressed.connect(_on_equip_item_pressed)
	inventory_contents.add_child(equip_item_button)

	var inventory_close_button := Button.new()
	inventory_close_button.text = "Close  (I / Esc)"
	_style_menu_button(inventory_close_button, 42.0)
	inventory_close_button.pressed.connect(_close_character_menu)
	inventory_contents.add_child(inventory_close_button)

	_show_character_panel()
	if player.selected_character == "Witch":
		witch_skill_tree = WitchSkillTree.new()
		add_child(witch_skill_tree)
		witch_skill_tree.hide()
		witch_skill_tree.closed.connect(_on_witch_skill_tree_closed)
		witch_skill_tree.loadout_changed.connect(_refresh_witch_skill_slots)
		_refresh_witch_skill_slots()


func _open_witch_skill_tree() -> void:
	if witch_skill_tree == null:
		return
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	witch_skill_tree.open_tree()


func _on_witch_skill_tree_closed() -> void:
	if witch_skill_tree == null:
		return
	witch_skill_tree.hide()
	_close_character_menu()
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
	health_potion_label.text = "1  x%d" % health_count
	mana_potion_label.text = "2  x%d" % mana_count
	if health_count < player.MAX_POTIONS and health_refill > 0.0:
		health_potion_label.text += "  +1 in %.1fs" % health_refill
	if mana_count < player.MAX_POTIONS and mana_refill > 0.0:
		mana_potion_label.text += "  +1 in %.1fs" % mana_refill


func _show_character_panel() -> void:
	character_panel.show()
	inventory_panel.hide()


func _show_inventory_panel() -> void:
	character_panel.hide()
	inventory_panel.show()


func _open_character_menu() -> void:
	if shop_overlay.visible or dialogue_overlay.visible or waystone_overlay.visible:
		return
	_show_character_panel()
	character_overlay.show()
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	dialogue_overlay.hide()


func _on_passive_tree_button_pressed() -> void:
	if player.selected_character == "Witch":
		_open_witch_skill_tree()


func _open_inventory_menu() -> void:
	if shop_overlay.visible or dialogue_overlay.visible or waystone_overlay.visible:
		return
	_show_inventory_panel()
	character_overlay.show()
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	dialogue_overlay.hide()


func _close_character_menu() -> void:
	character_overlay.hide()
	player.set_physics_process(true)
	player.set_process_unhandled_input(true)


func _open_waystone() -> void:
	if shop_overlay.visible or dialogue_overlay.visible or character_overlay.visible:
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
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		get_tree().remove_meta(Player.TOWN_RETURN_SCENE_META)
		get_tree().remove_meta(Player.TOWN_RETURN_POSITION_META)
		get_tree().remove_meta("portal_spawn_position")
		get_tree().remove_meta("portal_player_vitals")
		push_error("Could not enter %s through the waystone: %s" % [
			level_name,
			error_string(error)
		])


func _on_inventory_changed(items: Array[ItemData]) -> void:
	if selected_inventory_index >= items.size():
		selected_inventory_index = -1
	for index in range(inventory_slots.size()):
		var slot := inventory_slots[index]
		if index < items.size():
			slot.text = items[index].display_name
			slot.tooltip_text = "%s (%s)" % [items[index].display_name, items[index].equipment_slot]
			slot.add_theme_color_override("font_color", items[index].icon_color)
		else:
			slot.text = "-"
			slot.tooltip_text = "Empty"
			slot.add_theme_color_override("font_color", Color(0.52, 0.53, 0.49, 1))
	_update_selected_item(items)
	if item_list != null and shop_overlay != null and shop_overlay.visible:
		_refresh_shop_items()


func _on_inventory_slot_pressed(slot_index: int) -> void:
	selected_inventory_index = slot_index if slot_index < player.inventory.size() else -1
	_update_selected_item(player.inventory)


func _update_selected_item(items: Array[ItemData]) -> void:
	if selected_inventory_index < 0 or selected_inventory_index >= items.size():
		selected_inventory_index = -1
		selected_item_label.text = "Select an item to inspect it."
		equip_item_button.disabled = true
		return
	var item := items[selected_inventory_index]
	selected_item_label.text = "%s  |  %s\n%s" % [
		item.display_name,
		item.equipment_slot,
		_get_item_stat_text(item)
	]
	equip_item_button.disabled = false


func _on_equip_item_pressed() -> void:
	if selected_inventory_index < 0:
		return
	if player.equip_inventory_item(selected_inventory_index):
		selected_inventory_index = -1
		_update_selected_item(player.inventory)


func _on_equipment_changed(equipment: Dictionary) -> void:
	var attack_name := "Spell damage" if player.selected_character == "Witch" else "Sword damage"
	equipment_stats_label.text = "%s: %d  |  Damage reduced: %d" % [
		attack_name,
		1 + player.get_weapon_damage_bonus(),
		player.get_damage_reduction()
	]
	if player.selected_character == "Witch":
		_refresh_witch_skill_slots()
	for slot_name in equipment_slot_labels:
		var label: Label = equipment_slot_labels[slot_name]
		if equipment.has(slot_name):
			var item: ItemData = equipment[slot_name]
			label.text = "%s  -  %s" % [slot_name, item.display_name]
			label.tooltip_text = _get_item_stat_text(item)
			label.add_theme_color_override("font_color", item.icon_color)
		else:
			label.text = "%s  -  Empty" % slot_name
			label.tooltip_text = ""
			label.add_theme_color_override("font_color", Color(0.88, 0.83, 0.72, 1))


func _on_progression_changed(
	_level: int,
	_experience: int,
	xp_into_level: int,
	xp_for_level: int,
	_passive_points: int,
	_skill_points: int
) -> void:
	character_progression_label.text = GameState.get_progression_summary()
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
	add_child(experience_level_label)

	experience_bar = ProgressBar.new()
	experience_bar.anchor_left = 0.5
	experience_bar.anchor_right = 0.5
	experience_bar.anchor_top = 1.0
	experience_bar.anchor_bottom = 1.0
	experience_bar.offset_left = -EXPERIENCE_BAR_WIDTH * 0.5
	experience_bar.offset_top = -22.0
	experience_bar.offset_right = EXPERIENCE_BAR_WIDTH * 0.5
	experience_bar.offset_bottom = -10.0
	experience_bar.min_value = 0.0
	experience_bar.show_percentage = false
	experience_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	var experience_background := StyleBoxFlat.new()
	experience_background.bg_color = Color("#10233b")
	experience_background.set_border_width_all(1)
	experience_background.border_color = Color("#4875a5")
	experience_background.set_corner_radius_all(4)
	experience_bar.add_theme_stylebox_override("background", experience_background)
	var experience_fill := StyleBoxFlat.new()
	experience_fill.bg_color = Color("#2389e8")
	experience_fill.set_corner_radius_all(4)
	experience_bar.add_theme_stylebox_override("fill", experience_fill)
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
	tooltip_style.bg_color = Color("#10233b")
	tooltip_style.set_border_width_all(1)
	tooltip_style.border_color = Color("#4875a5")
	tooltip_style.set_corner_radius_all(4)
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
		description.text = "%s  (%s)  -  %s" % [
			item.display_name,
			item.equipment_slot,
			_get_item_stat_text(item)
		]
		description.add_theme_color_override("font_color", item.icon_color)
		row.add_child(description)

		var buy_button := Button.new()
		buy_button.custom_minimum_size.x = 112
		buy_button.text = "Buy  %d G" % item.price
		_style_menu_button(buy_button, 42.0)
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
		description.text = "%s  (%s)  -  %s" % [
			owned_item.display_name,
			owned_item.equipment_slot,
			_get_item_stat_text(owned_item)
		]
		description.add_theme_color_override("font_color", owned_item.icon_color)
		row.add_child(description)

		var sell_price := GameState.get_item_sell_price(owned_item)
		var sell_button := Button.new()
		sell_button.custom_minimum_size.x = 112
		sell_button.text = "Sell  %d G" % sell_price
		_style_menu_button(sell_button, 42.0)
		sell_button.pressed.connect(_on_sell_item_pressed.bind(inventory_index))
		row.add_child(sell_button)


func _get_item_stat_text(item: ItemData) -> String:
	if item.damage_bonus > 0:
		return "+%d damage" % item.damage_bonus
	if item.damage_reduction > 0:
		return "-%d damage taken" % item.damage_reduction
	return "No combat bonus"


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
	character_overlay.hide()
	dialogue_overlay.show()
	player.set_physics_process(false)


func _open_shop() -> void:
	dialogue_overlay.hide()
	character_overlay.hide()
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
	if is_instance_valid(inventory_gold_label):
		inventory_gold_label.text = "Gold: %d" % total_gold


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


func _on_character_button_pressed() -> void:
	_open_character_menu()


func _on_inventory_button_pressed() -> void:
	_open_inventory_menu()
