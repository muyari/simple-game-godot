extends Control
class_name CharacterSheet

## Character and inventory panels, shared by the town and level HUDs so both
## look and behave the same. Sized to fit a 648px-tall screen (phones in
## landscape). The host HUD pauses the player while it is open and listens to
## `closed`, `skills_requested` and `passives_requested`.

signal closed
signal skills_requested
signal passives_requested

const EQUIPMENT_SLOTS = ["Weapon", "Helm", "Chest", "Legs", "Gloves", "Boots", "Ring 1", "Ring 2", "Amulet"]
const EMPTY_SLOT_COLOR := Color(0.52, 0.53, 0.49, 1)
const SLOT_TEXT_COLOR := Color(0.88, 0.83, 0.72, 1)
const INVENTORY_COLUMNS = 5

var player: Player

var _character_panel: PanelContainer
var _inventory_panel: PanelContainer
var _name_label: Label
var _class_label: Label
var _progression_label: Label
var _stats_label: Label
var _equipment_labels: Dictionary = {}
var _inventory_slots: Array[Button] = []
var _selected_index := -1
var _gold_label: Label
var _selected_item_label: Label
var _equip_button: Button
var _equip_best_button: Button


static func create(for_player: Player) -> CharacterSheet:
	var sheet := CharacterSheet.new()
	sheet.player = for_player
	return sheet


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	hide()

	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.015, 0.02, 0.018, 0.72)
	add_child(backdrop)

	_build_character_panel()
	_build_inventory_panel()

	player.inventory_changed.connect(_on_inventory_changed)
	player.equipment_changed.connect(_on_equipment_changed)
	GameState.progression_changed.connect(_on_progression_changed.unbind(6))
	GameState.gold_changed.connect(_on_gold_changed)
	refresh()


func show_character() -> void:
	_character_panel.show()
	_inventory_panel.hide()
	show()


func show_inventory() -> void:
	_character_panel.hide()
	_inventory_panel.show()
	show()


func is_character_shown() -> bool:
	return visible and _character_panel.visible


func is_inventory_shown() -> bool:
	return visible and _inventory_panel.visible


func close() -> void:
	if not visible:
		return
	hide()
	closed.emit()


## Re-reads everything from the player, e.g. after passives change their stats.
func refresh() -> void:
	var character := GameState.get_active_character()
	_name_label.text = str(character.get("name", "Adventurer"))
	_class_label.text = player.selected_character
	_on_progression_changed()
	_on_equipment_changed(player.equipment)
	_on_inventory_changed(player.inventory)
	_on_gold_changed(GameState.gold)


static func item_stat_text(item: ItemData) -> String:
	var stat_text: Array[String] = []
	if item.damage_bonus > 0:
		stat_text.append("+%d damage" % item.damage_bonus)
	if item.damage_reduction > 0:
		stat_text.append("-%d damage taken" % item.damage_reduction)
	if stat_text.is_empty():
		return "No combat bonus"
	return ", ".join(stat_text)


func _build_character_panel() -> void:
	_character_panel = _create_panel(Vector2(700, 0))
	var contents := _add_contents(_character_panel)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	contents.add_child(header)
	var portrait := TextureRect.new()
	portrait.texture = MenuStyle.class_portrait(player.selected_character)
	portrait.custom_minimum_size = Vector2(64, 64)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	header.add_child(portrait)
	var name_column := VBoxContainer.new()
	name_column.alignment = BoxContainer.ALIGNMENT_CENTER
	name_column.add_theme_constant_override("separation", 0)
	header.add_child(name_column)
	_name_label = Label.new()
	_name_label.theme_type_variation = &"TitleLabel"
	_name_label.add_theme_font_size_override("font_size", 30)
	name_column.add_child(_name_label)
	_class_label = Label.new()
	_class_label.theme_type_variation = &"EyebrowLabel"
	name_column.add_child(_class_label)

	contents.add_child(HSeparator.new())

	_progression_label = Label.new()
	_progression_label.theme_type_variation = &"StatusLabel"
	contents.add_child(_progression_label)
	_stats_label = Label.new()
	_stats_label.theme_type_variation = &"SubtitleLabel"
	contents.add_child(_stats_label)

	var equipment_grid := GridContainer.new()
	equipment_grid.columns = 3
	equipment_grid.add_theme_constant_override("h_separation", 8)
	equipment_grid.add_theme_constant_override("v_separation", 8)
	contents.add_child(equipment_grid)
	for slot_name in EQUIPMENT_SLOTS:
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(0, 48)
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.add_theme_stylebox_override("panel", _slot_style())
		slot.mouse_filter = Control.MOUSE_FILTER_PASS
		equipment_grid.add_child(slot)
		var label := Label.new()
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.clip_text = true
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		label.add_theme_font_size_override("font_size", 15)
		label.mouse_filter = Control.MOUSE_FILTER_PASS
		slot.add_child(label)
		_equipment_labels[slot_name] = label

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	contents.add_child(actions)
	_add_action(actions, "Active Skills" + MenuStyle.key_hint("K"), skills_requested.emit)
	_add_action(actions, "Passive Tree" + MenuStyle.key_hint("P"), passives_requested.emit)
	_add_action(actions, "Close" + MenuStyle.key_hint("C"), close)


func _build_inventory_panel() -> void:
	_inventory_panel = _create_panel(Vector2(820, 0))
	var contents := _add_contents(_inventory_panel)

	var title := Label.new()
	title.text = "Inventory"
	title.theme_type_variation = &"TitleLabel"
	title.add_theme_font_size_override("font_size", 30)
	contents.add_child(title)
	contents.add_child(HSeparator.new())

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 20)
	contents.add_child(body)

	var grid := GridContainer.new()
	grid.columns = INVENTORY_COLUMNS
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	body.add_child(grid)
	for slot_index in range(Player.MAX_INVENTORY_SIZE):
		var slot := Button.new()
		slot.custom_minimum_size = Vector2(100, 58)
		slot.alignment = HORIZONTAL_ALIGNMENT_LEFT
		slot.autowrap_mode = TextServer.AUTOWRAP_WORD
		slot.clip_text = true
		slot.add_theme_font_size_override("font_size", 13)
		slot.add_theme_stylebox_override("normal", _slot_style())
		slot.add_theme_stylebox_override("hover", _slot_style(MenuStyle.GOLD))
		slot.add_theme_stylebox_override("pressed", _slot_style(MenuStyle.GOLD))
		slot.add_theme_stylebox_override("focus", _slot_style(MenuStyle.GOLD))
		slot.pressed.connect(_on_inventory_slot_pressed.bind(slot_index))
		grid.add_child(slot)
		_inventory_slots.append(slot)

	var side := VBoxContainer.new()
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.add_theme_constant_override("separation", 10)
	body.add_child(side)
	_gold_label = Label.new()
	_gold_label.add_theme_color_override("font_color", MenuStyle.GOLD)
	side.add_child(_gold_label)
	_selected_item_label = Label.new()
	_selected_item_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_selected_item_label.theme_type_variation = &"SubtitleLabel"
	_selected_item_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side.add_child(_selected_item_label)
	_equip_button = _add_action(side, "Equip Selected", _on_equip_pressed)
	_equip_best_button = _add_action(side, "Equip Best", _on_equip_best_pressed)
	_equip_best_button.tooltip_text = "Upgrade each slot using damage bonus and damage reduction."
	_add_action(side, "Close" + MenuStyle.key_hint("I"), close)


func _create_panel(minimum_size: Vector2) -> PanelContainer:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"MenuPanel"
	panel.custom_minimum_size = minimum_size
	var style := (MenuStyle.get_theme().get_stylebox("panel", "MenuPanel") as StyleBoxFlat).duplicate()
	style.set_content_margin_all(24.0)
	style.bg_color.a = 0.97
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	return panel


func _add_contents(panel: PanelContainer) -> VBoxContainer:
	var contents := VBoxContainer.new()
	contents.add_theme_constant_override("separation", 10)
	panel.add_child(contents)
	return contents


func _add_action(parent: Container, label_text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size.y = 48.0
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func _slot_style(border: Color = Color(MenuStyle.GOLD_DIM, 0.6)) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.115, 0.105, 0.95)
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 10.0
	style.content_margin_right = 8.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	return style


func _on_progression_changed() -> void:
	_progression_label.text = GameState.get_progression_summary()


func _on_gold_changed(total_gold: int) -> void:
	_gold_label.text = "Gold: %d" % total_gold


func _on_equipment_changed(equipment: Dictionary) -> void:
	var attack_name := "Spell damage" if player.selected_character == "Witch" \
		else "Bow damage" if player.selected_character == "Ranger" \
		else "Sword damage"
	var base_damage := 1 + player.get_weapon_damage_bonus()
	var damage_text := str(base_damage)
	if player.selected_character == "Witch":
		var multiplier := player.get_spell_damage_multiplier()
		damage_text = "%.1f (x%.2f)" % [float(base_damage) * multiplier, multiplier]
	var evasion_info := ""
	if player.selected_character in ["Witch", "Ranger"]:
		evasion_info = "  |  Evasion: %d%%" % roundi(player.get_evasion() * 100.0)
	_stats_label.text = "%s: %s  |  Damage reduced: %d%s" % [
		attack_name,
		damage_text,
		player.get_damage_reduction(),
		evasion_info
	]
	for slot_name in _equipment_labels:
		var label: Label = _equipment_labels[slot_name]
		if equipment.has(slot_name):
			var item: ItemData = equipment[slot_name]
			label.text = "%s:  %s" % [slot_name, item.display_name]
			label.tooltip_text = "%s\n%s  |  %s" % [item.display_name, item.get_rarity_name(), item_stat_text(item)]
			label.add_theme_color_override("font_color", item.get_rarity_color())
		else:
			label.text = "%s:  Empty" % slot_name
			label.tooltip_text = ""
			label.add_theme_color_override("font_color", Color(SLOT_TEXT_COLOR, 0.6))


func _on_inventory_changed(items: Array[ItemData]) -> void:
	if _selected_index >= items.size():
		_selected_index = -1
	for index in range(_inventory_slots.size()):
		var slot := _inventory_slots[index]
		if index < items.size():
			slot.text = items[index].display_name
			slot.tooltip_text = "%s (%s %s)" % [items[index].display_name, items[index].get_rarity_name(), items[index].equipment_slot]
			slot.add_theme_color_override("font_color", items[index].get_rarity_color())
			slot.add_theme_color_override("font_hover_color", items[index].get_rarity_color().lightened(0.2))
		else:
			slot.text = ""
			slot.tooltip_text = "Empty"
			slot.add_theme_color_override("font_color", EMPTY_SLOT_COLOR)
	_update_selected_item(items)
	_equip_best_button.disabled = items.is_empty()


func _on_inventory_slot_pressed(slot_index: int) -> void:
	_selected_index = slot_index if slot_index < player.inventory.size() else -1
	_update_selected_item(player.inventory)


func _update_selected_item(items: Array[ItemData]) -> void:
	for index in range(_inventory_slots.size()):
		var border := MenuStyle.GOLD if index == _selected_index else Color(MenuStyle.GOLD_DIM, 0.6)
		_inventory_slots[index].add_theme_stylebox_override("normal", _slot_style(border))
	if _selected_index < 0 or _selected_index >= items.size():
		_selected_index = -1
		_selected_item_label.text = "Select an item to inspect it."
		_equip_button.disabled = true
		return
	var item := items[_selected_index]
	_selected_item_label.text = "%s\n%s %s\n%s" % [
		item.display_name,
		item.get_rarity_name(),
		item.equipment_slot,
		item_stat_text(item)
	]
	_equip_button.disabled = false


func _on_equip_pressed() -> void:
	if _selected_index < 0:
		return
	if player.equip_inventory_item(_selected_index):
		_selected_index = -1
		_update_selected_item(player.inventory)


func _on_equip_best_pressed() -> void:
	_selected_index = -1
	var equipped_slots := player.equip_best_inventory_items()
	_update_selected_item(player.inventory)
	if equipped_slots < 0:
		_selected_item_label.text = "Could not equip best gear. See the error log."
	elif equipped_slots == 0:
		_selected_item_label.text = "You're already wearing your best gear."
	else:
		_selected_item_label.text = "Equipped best gear in %d slot(s)." % equipped_slots
