extends CanvasLayer


@onready var health_orb: ResourceGlobe = $HealthOrb
@onready var mana_orb: ResourceGlobe = $ManaOrb
@onready var health_potion_label: Label = $HealthPotionLabel
@onready var mana_potion_label: Label = $ManaPotionLabel
@onready var defeated_label: Label = $DefeatedLabel
@onready var return_to_town_button: Button = $ReturnToTownButton
@onready var enemy_progress_label: Label = $EnemyProgressLabel
@onready var gold_label: Label = $GoldLabel
@onready var portal_hint_label: Label = $PortalHintLabel
@onready var level_complete_label: Label = $LevelCompleteLabel
@onready var return_to_levels_button: Button = $ReturnToLevelsButton
var portal_cast_panel: PanelContainer
var portal_cast_progress_bar: ProgressBar
var portal_cast_countdown: Label
@onready var character_menu: Control = $CharacterMenu
@onready var character_panel: PanelContainer = $CharacterMenu/Panel
@onready var inventory_panel: PanelContainer = $CharacterMenu/InventoryPanel
@onready var inventory_grid: GridContainer = $CharacterMenu/InventoryPanel/Contents/InventoryGrid
@onready var selected_item_label: Label = $CharacterMenu/InventoryPanel/Contents/SelectedItem
@onready var equip_item_button: Button = $CharacterMenu/InventoryPanel/Contents/EquipButton
@onready var inventory_gold_label: Label = $CharacterMenu/InventoryPanel/Contents/GoldTotal
@onready var equipment_stats_label: Label = $CharacterMenu/Panel/Contents/EquipmentStats
@onready var equipment_slot_labels: Dictionary = {
	"Weapon": $CharacterMenu/Panel/Contents/EquipmentGrid/WeaponSlot/SlotLabel,
	"Helm": $CharacterMenu/Panel/Contents/EquipmentGrid/HelmSlot/SlotLabel,
	"Chest": $CharacterMenu/Panel/Contents/EquipmentGrid/ChestSlot/SlotLabel,
	"Legs": $CharacterMenu/Panel/Contents/EquipmentGrid/LegsSlot/SlotLabel,
	"Gloves": $CharacterMenu/Panel/Contents/EquipmentGrid/GlovesSlot/SlotLabel,
	"Boots": $CharacterMenu/Panel/Contents/EquipmentGrid/BootsSlot/SlotLabel,
	"Ring 1": $CharacterMenu/Panel/Contents/EquipmentGrid/Ring1Slot/SlotLabel,
	"Ring 2": $CharacterMenu/Panel/Contents/EquipmentGrid/Ring2Slot/SlotLabel,
	"Amulet": $CharacterMenu/Panel/Contents/EquipmentGrid/AmuletSlot/SlotLabel
}

var inventory_slots: Array[Button] = []
var selected_inventory_index := -1


func _ready() -> void:
	_build_portal_cast_bar()
	_build_inventory_slots()
	equip_item_button.pressed.connect(_on_equip_item_pressed)
	var player: Player = get_node("../Player")
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
	player.town_portal_cast_started.connect(_on_town_portal_cast_started)
	player.town_portal_cast_progress.connect(_on_town_portal_cast_progress)
	player.town_portal_cast_cancelled.connect(_on_town_portal_cast_cancelled)
	player.town_portal_opened.connect(_on_town_portal_opened)
	player.died.connect(_on_player_died)
	_on_inventory_changed(player.inventory)
	_on_equipment_changed(player.equipment)
	_on_gold_changed(GameState.gold)
	GameState.gold_changed.connect(_on_gold_changed)
	var level_controller: Node = get_node("../LevelController")
	level_controller.progress_changed.connect(_on_enemy_progress_changed)
	level_controller.level_completed.connect(_on_level_completed)


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return

	if event.keycode == KEY_C:
		if character_menu.visible and character_panel.visible:
			character_menu.hide()
		else:
			character_panel.show()
			inventory_panel.hide()
			character_menu.show()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_I:
		if character_menu.visible and inventory_panel.visible:
			character_menu.hide()
		else:
			character_panel.hide()
			inventory_panel.show()
			character_menu.show()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_ESCAPE and character_menu.visible:
		character_menu.hide()
		get_viewport().set_input_as_handled()


func _build_inventory_slots() -> void:
	for slot_index in range(25):
		var slot := Button.new()
		slot.custom_minimum_size = Vector2(76, 64)
		slot.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		slot.add_theme_font_size_override("font_size", 11)

		var slot_style := StyleBoxFlat.new()
		slot_style.bg_color = Color(0.13, 0.15, 0.14, 1)
		slot_style.set_border_width_all(2)
		slot_style.border_color = Color(0.48, 0.4, 0.29, 1)
		slot_style.set_corner_radius_all(5)
		slot.add_theme_stylebox_override("normal", slot_style)
		slot.pressed.connect(_on_inventory_slot_pressed.bind(slot_index))
		inventory_grid.add_child(slot)
		inventory_slots.append(slot)


func _on_inventory_changed(items: Array[ItemData]) -> void:
	if selected_inventory_index >= items.size():
		selected_inventory_index = -1
	for index in range(inventory_slots.size()):
		if index < items.size():
			inventory_slots[index].text = items[index].display_name
			inventory_slots[index].tooltip_text = "%s (%s)" % [
				items[index].display_name,
				items[index].equipment_slot
			]
			inventory_slots[index].add_theme_color_override(
				"font_color",
				items[index].icon_color
			)
		else:
			inventory_slots[index].text = "-"
			inventory_slots[index].tooltip_text = "Empty"
			inventory_slots[index].add_theme_color_override(
				"font_color",
				Color(0.52, 0.53, 0.49, 1)
			)
	_update_selected_item(items)


func _on_inventory_slot_pressed(slot_index: int) -> void:
	var player: Player = get_node("../Player")
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


func _get_item_stat_text(item: ItemData) -> String:
	var stat_text: Array[String] = []
	if item.damage_bonus > 0:
		stat_text.append("+%d damage" % item.damage_bonus)
	if item.damage_reduction > 0:
		stat_text.append("-%d damage taken" % item.damage_reduction)
	if stat_text.is_empty():
		return "No combat bonus"
	return ", ".join(stat_text)


func _on_equip_item_pressed() -> void:
	if selected_inventory_index < 0:
		return
	var player: Player = get_node("../Player")
	if player.equip_inventory_item(selected_inventory_index):
		selected_inventory_index = -1
		_update_selected_item(player.inventory)


func _on_equipment_changed(equipment: Dictionary) -> void:
	var player: Player = get_node("../Player")
	var attack_name := "Spell damage" if player.selected_character == "Witch" else "Sword damage"
	equipment_stats_label.text = "%s: %d  |  Damage reduced: %d" % [
		attack_name,
		1 + player.get_weapon_damage_bonus(),
		player.get_damage_reduction()
	]
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
	if health_count < 3 and health_refill > 0.0:
		health_potion_label.text += "  +1 in %.1fs" % health_refill
	if mana_count < 3 and mana_refill > 0.0:
		mana_potion_label.text += "  +1 in %.1fs" % mana_refill


func _on_player_died() -> void:
	defeated_label.show()
	return_to_town_button.show()


func _on_enemy_progress_changed(defeated: int, total: int) -> void:
	enemy_progress_label.text = "Enemies defeated: %d/%d" % [defeated, total]


func _on_gold_changed(total_gold: int) -> void:
	gold_label.text = "Gold: %d" % total_gold
	inventory_gold_label.text = "Gold: %d" % total_gold


func _on_town_portal_opened() -> void:
	portal_cast_panel.hide()
	portal_cast_progress_bar.value = Player.TOWN_PORTAL_CAST_DURATION
	portal_cast_countdown.text = "%.1f s" % Player.TOWN_PORTAL_CAST_DURATION
	portal_hint_label.text = "Town portal open - walk into it to travel"


func _on_town_portal_cast_started() -> void:
	portal_cast_progress_bar.max_value = Player.TOWN_PORTAL_CAST_DURATION
	portal_cast_progress_bar.value = Player.TOWN_PORTAL_CAST_DURATION
	portal_cast_countdown.text = "%.1f s" % Player.TOWN_PORTAL_CAST_DURATION
	portal_cast_panel.show()
	portal_hint_label.text = "Channeling Town Portal (3 seconds)..."


func _on_town_portal_cast_progress(remaining: float, duration: float) -> void:
	portal_cast_progress_bar.max_value = duration
	portal_cast_progress_bar.value = remaining
	portal_cast_countdown.text = "%.1f s" % remaining


func _on_town_portal_cast_cancelled() -> void:
	portal_cast_panel.hide()
	portal_cast_progress_bar.value = Player.TOWN_PORTAL_CAST_DURATION
	portal_cast_countdown.text = "%.1f s" % Player.TOWN_PORTAL_CAST_DURATION
	portal_hint_label.text = "Town Portal interrupted"


func _build_portal_cast_bar() -> void:
	portal_cast_panel = PanelContainer.new()
	portal_cast_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	portal_cast_panel.offset_left = -190.0
	portal_cast_panel.offset_top = 94.0
	portal_cast_panel.offset_right = 190.0
	portal_cast_panel.offset_bottom = 166.0
	portal_cast_panel.visible = false

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.045, 0.075, 0.11, 0.94)
	panel_style.set_border_width_all(2)
	panel_style.border_color = Color(0.28, 0.72, 0.94, 1.0)
	panel_style.set_corner_radius_all(6)
	panel_style.content_margin_left = 12.0
	panel_style.content_margin_right = 12.0
	panel_style.content_margin_top = 8.0
	panel_style.content_margin_bottom = 8.0
	portal_cast_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(portal_cast_panel)

	var contents := VBoxContainer.new()
	contents.add_theme_constant_override("separation", 4)
	portal_cast_panel.add_child(contents)

	var title := Label.new()
	title.text = "Channeling Town Portal"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("#b9eaff"))
	contents.add_child(title)

	var progress_row := HBoxContainer.new()
	progress_row.add_theme_constant_override("separation", 10)
	contents.add_child(progress_row)

	portal_cast_progress_bar = ProgressBar.new()
	portal_cast_progress_bar.custom_minimum_size = Vector2(300.0, 18.0)
	portal_cast_progress_bar.min_value = 0.0
	portal_cast_progress_bar.max_value = Player.TOWN_PORTAL_CAST_DURATION
	portal_cast_progress_bar.value = Player.TOWN_PORTAL_CAST_DURATION
	portal_cast_progress_bar.show_percentage = false
	progress_row.add_child(portal_cast_progress_bar)

	portal_cast_countdown = Label.new()
	portal_cast_countdown.custom_minimum_size.x = 42.0
	portal_cast_countdown.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	portal_cast_countdown.text = "%.1f s" % Player.TOWN_PORTAL_CAST_DURATION
	progress_row.add_child(portal_cast_countdown)


func _on_level_completed() -> void:
	level_complete_label.show()
	return_to_levels_button.show()


func _on_return_to_levels_pressed() -> void:
	get_tree().set_meta("return_to_level_select", true)
	var error := get_tree().change_scene_to_file("res://Menu.tscn")
	if error != OK:
		get_tree().remove_meta("return_to_level_select")
		push_error("Could not return to level select: %s" % error_string(error))


func _on_return_to_town_pressed() -> void:
	var player: Player = get_node("../Player")
	var scene_path := get_tree().current_scene.scene_file_path
	if scene_path not in ["res://main.tscn", "res://desert.tscn"]:
		push_error("Cannot return to town from an unsupported level: %s" % scene_path)
		return

	return_to_town_button.disabled = true
	get_tree().set_meta(Player.TOWN_RETURN_SCENE_META, scene_path)
	get_tree().set_meta(Player.TOWN_RETURN_POSITION_META, player.global_position)
	get_tree().set_meta("portal_spawn_position", Vector2(576, 350))
	get_tree().set_meta("portal_player_vitals", {
		"health": Player.MAX_HEALTH,
		"mana": player.mana
	})
	var error := get_tree().change_scene_to_file("res://town.tscn")
	if error != OK:
		get_tree().remove_meta(Player.TOWN_RETURN_SCENE_META)
		get_tree().remove_meta(Player.TOWN_RETURN_POSITION_META)
		get_tree().remove_meta("portal_spawn_position")
		get_tree().remove_meta("portal_player_vitals")
		return_to_town_button.disabled = false
		push_error("Could not return to town: %s" % error_string(error))


func _on_character_menu_close_pressed() -> void:
	character_menu.hide()
