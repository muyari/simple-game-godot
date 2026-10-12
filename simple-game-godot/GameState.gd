extends Node

signal gold_changed(total_gold: int)
signal progression_changed(level: int, experience: int, xp_into_level: int, xp_for_level: int, passive_points: int, skill_points: int)
signal experience_gained(amount: int)
signal player_leveled_up(level: int)

const SAVE_PATH = "user://character_save.json"
const SAVE_VERSION = 2
const ROSTER_PATH = "user://character_roster.json"
const ROSTER_VERSION = 1
const MAX_PLAYER_LEVEL = 25
const LEVEL_XP_THRESHOLDS: Array[int] = [
	0, 300, 750, 1350, 2100, 3000, 4050, 5250, 6600, 8100,
	9750, 11550, 13500, 15600, 17850, 20250, 22800, 25500,
	28350, 31350, 34500, 37800, 41250, 44850, 48600
]
const LEGACY_LEVEL_XP_THRESHOLDS: Array[int] = [
	0, 100, 250, 450, 700, 1000, 1350, 1750, 2200, 2700,
	3250, 3850, 4500, 5200, 5950, 6750, 7600, 8500, 9450,
	10450, 11500, 12600, 13750, 14950, 16200
]
const EQUIPMENT_SLOTS = [
	"Weapon",
	"Helm",
	"Chest",
	"Legs",
	"Gloves",
	"Boots",
	"Ring 1",
	"Ring 2",
	"Amulet"
]

var _inventory_records: Array[Dictionary] = []
var _equipment_records: Dictionary = {}
var _characters: Array[Dictionary] = []
var _active_character_id := ""
var _active_save_path := SAVE_PATH
var _roster_loaded := false
var gold := 0
var player_level := 1
var experience := 0
var passive_tree_points := 0
var skill_tree_points := 0


func _ready() -> void:
	_load_roster()
	_load_character()


func get_characters() -> Array[Dictionary]:
	_load_roster()
	if _characters.is_empty() and FileAccess.file_exists(SAVE_PATH):
		_characters.append({
			"id": "legacy",
			"name": "Adventurer",
			"class": "Warrior",
			"save_path": SAVE_PATH
		})
		_save_roster()

	var characters: Array[Dictionary] = []
	for character in _characters:
		characters.append({
			"id": character["id"],
			"name": character["name"],
			"class": character["class"]
		})
	return characters


func get_character(character_id: String) -> Dictionary:
	for character in _characters:
		if character["id"] == character_id:
			return character.duplicate()
	return {}


func create_character(display_name: String, character_class: String) -> String:
	var clean_name := display_name.strip_edges()
	if clean_name.is_empty() or character_class not in ["Warrior", "Witch"]:
		return ""

	_load_roster()
	var previous_character_id := _active_character_id
	if not previous_character_id.is_empty() and not save_character(get_inventory(), get_equipment()):
		return ""

	var character_id := "character_%d" % Time.get_ticks_usec()
	while _find_character_index(character_id) >= 0:
		character_id += "_1"
	var save_path := "user://characters/%s.json" % character_id
	var directory_error := DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path("user://characters")
	)
	if directory_error != OK:
		push_error("Could not create character save directory: %s" % error_string(directory_error))
		return ""

	_characters.append({
		"id": character_id,
		"name": clean_name,
		"class": character_class,
		"save_path": save_path
	})
	_active_character_id = character_id
	_active_save_path = save_path
	_clear_character_data()
	if not save_character([], {}) or not _save_roster():
		_characters.pop_back()
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
		_restore_active_character(previous_character_id)
		return ""
	return character_id


func select_character(character_id: String) -> bool:
	var character_index := _find_character_index(character_id)
	if character_index < 0:
		return false
	if _active_character_id == character_id:
		return true
	if not _active_character_id.is_empty() and not save_character(get_inventory(), get_equipment()):
		return false

	var character: Dictionary = _characters[character_index]
	_active_character_id = character_id
	_active_save_path = character["save_path"]
	_clear_character_data()
	_load_character()
	gold_changed.emit(gold)
	return true


func delete_character(character_id: String) -> bool:
	var character_index := _find_character_index(character_id)
	if character_index < 0:
		return false

	var character: Dictionary = _characters[character_index]
	_characters.remove_at(character_index)
	if not _save_roster():
		_characters.insert(character_index, character)
		return false

	if _active_character_id == character_id:
		_active_character_id = ""
		_active_save_path = SAVE_PATH
		_clear_character_data()

	var file_path := str(character["save_path"])
	if FileAccess.file_exists(file_path):
		var remove_error := DirAccess.remove_absolute(ProjectSettings.globalize_path(file_path))
		if remove_error != OK:
			push_error("Could not delete character save: %s" % error_string(remove_error))
			return false
	return true


func get_inventory() -> Array[ItemData]:
	var items: Array[ItemData] = []
	for record in _inventory_records:
		var item := _item_from_record(record)
		if item != null:
			items.append(item)
	return items


func get_equipment() -> Dictionary:
	var equipment: Dictionary = {}
	for slot_name in _equipment_records:
		var item := _item_from_record(_equipment_records[slot_name])
		if item != null:
			equipment[slot_name] = item
	return equipment


func get_xp_for_next_level() -> int:
	if player_level >= MAX_PLAYER_LEVEL:
		return 0
	return LEVEL_XP_THRESHOLDS[player_level] - LEVEL_XP_THRESHOLDS[player_level - 1]


func get_xp_into_current_level() -> int:
	if player_level >= MAX_PLAYER_LEVEL:
		return 0
	return experience - LEVEL_XP_THRESHOLDS[player_level - 1]


func get_progression_summary() -> String:
	var level_summary := "Level %d / %d" % [player_level, MAX_PLAYER_LEVEL]
	if player_level >= MAX_PLAYER_LEVEL:
		level_summary += "  |  MAX LEVEL"
	else:
		level_summary += "  |  XP: %d / %d" % [
			get_xp_into_current_level(),
			get_xp_for_next_level()
		]
	return "%s\nPassive points: %d  |  Skill points: %d" % [
		level_summary,
		passive_tree_points,
		skill_tree_points
	]


func add_experience(amount: int) -> bool:
	if amount <= 0:
		push_error("Experience gained must be greater than zero.")
		return false
	if player_level >= MAX_PLAYER_LEVEL:
		return true

	var previous_experience := experience
	var previous_level := player_level
	var previous_passive_points := passive_tree_points
	var previous_skill_points := skill_tree_points
	experience = mini(experience + amount, LEVEL_XP_THRESHOLDS[MAX_PLAYER_LEVEL - 1])

	while player_level < MAX_PLAYER_LEVEL \
			and experience >= LEVEL_XP_THRESHOLDS[player_level]:
		player_level += 1
		passive_tree_points += 1
		skill_tree_points += 1

	if not save_character(get_inventory(), get_equipment()):
		experience = previous_experience
		player_level = previous_level
		passive_tree_points = previous_passive_points
		skill_tree_points = previous_skill_points
		return false

	experience_gained.emit(amount)
	_emit_progression_changed()
	for reached_level in range(previous_level + 1, player_level + 1):
		player_leveled_up.emit(reached_level)
	return true


func _emit_progression_changed() -> void:
	progression_changed.emit(
		player_level,
		experience,
		get_xp_into_current_level(),
		get_xp_for_next_level(),
		passive_tree_points,
		skill_tree_points
	)


func add_gold(amount: int) -> void:
	if amount <= 0:
		push_error("Gold pickup amount must be greater than zero.")
		return

	gold += amount
	save_character(get_inventory(), get_equipment())
	gold_changed.emit(gold)


func get_vendor_items() -> Array[ItemData]:
	return [
		_create_item("Iron Sword", "Weapon", Color("#c5d7dc"), 1, 0, 100),
		_create_item("Iron Helm", "Helm", Color("#b8c5c9"), 0, 1, 50),
		_create_item("Oakbound Chestguard", "Chest", Color("#8e754f"), 0, 1, 125),
		_create_item("Trailblazer Legguards", "Legs", Color("#82917b"), 0, 1, 75),
		_create_item("Grips of Thorns", "Gloves", Color("#829b55"), 0, 1, 25),
		_create_item("Wanderer's Boots", "Boots", Color("#9b6741"), 0, 1, 25),
		_create_item("Wolf Fang Ring", "Ring", Color("#d3d0bb"), 1, 0, 150),
		_create_item("Mossstone Ring", "Ring", Color("#66a06b"), 1, 0, 175),
		_create_item("Forest Heart Amulet", "Amulet", Color("#d68e4d"), 1, 0, 200)
	]


func purchase_item(
	item: ItemData,
	inventory: Array[ItemData],
	equipment: Dictionary,
	max_inventory_size: int
) -> bool:
	if item == null:
		push_error("Cannot purchase a null item.")
		return false
	if item.price < 25:
		push_error("Vendor item '%s' has an invalid price." % item.display_name)
		return false
	if inventory.size() >= max_inventory_size or gold < item.price:
		return false

	var updated_inventory := inventory.duplicate()
	updated_inventory.append(item)
	var previous_gold := gold
	gold -= item.price
	if not save_character(updated_inventory, equipment):
		gold = previous_gold
		return false

	gold_changed.emit(gold)
	return true


func get_item_sell_price(item: ItemData) -> int:
	if item == null:
		push_error("Cannot calculate the sale price of a null item.")
		return 0
	return maxi(floori(float(item.price) / 2.0), 1)


func sell_inventory_item(
	inventory: Array[ItemData],
	equipment: Dictionary,
	inventory_index: int
) -> bool:
	if inventory_index < 0 or inventory_index >= inventory.size():
		push_error("Inventory sale index is out of range.")
		return false

	var item := inventory[inventory_index]
	if item == null:
		push_error("Cannot sell a null inventory item.")
		return false

	var updated_inventory := inventory.duplicate()
	updated_inventory.remove_at(inventory_index)
	var sale_price := get_item_sell_price(item)
	var previous_gold := gold
	gold += sale_price
	if not save_character(updated_inventory, equipment):
		gold = previous_gold
		return false

	gold_changed.emit(gold)
	return true


func save_character(inventory: Array[ItemData], equipment: Dictionary) -> bool:
	var inventory_records: Array[Dictionary] = []
	for item in inventory:
		inventory_records.append(_record_from_item(item))

	var equipment_records: Dictionary = {}
	for slot_name in equipment:
		var item: ItemData = equipment[slot_name]
		equipment_records[slot_name] = _record_from_item(item)

	var save_data := {
		"version": SAVE_VERSION,
		"gold": gold,
		"level": player_level,
		"experience": experience,
		"passive_tree_points": passive_tree_points,
		"skill_tree_points": skill_tree_points,
		"inventory": inventory_records,
		"equipment": equipment_records
	}
	var file := FileAccess.open(_active_save_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not save character data: %s" % error_string(FileAccess.get_open_error()))
		return false

	file.store_string(JSON.stringify(save_data, "\t"))
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		push_error("Could not write character save: %s" % error_string(write_error))
		return false
	_inventory_records = inventory_records
	_equipment_records = equipment_records
	return true


func _load_character() -> void:
	if not FileAccess.file_exists(_active_save_path):
		return

	var file := FileAccess.open(_active_save_path, FileAccess.READ)
	if file == null:
		push_error("Could not open character save: %s" % error_string(FileAccess.get_open_error()))
		return

	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	file.close()
	if parse_error != OK:
		push_error(
			"Could not parse character save at line %d: %s" % [
				json.get_error_line(),
				json.get_error_message()
			]
		)
		return

	if typeof(json.data) != TYPE_DICTIONARY:
		push_error("Character save must contain a JSON object.")
		return

	var save_data: Dictionary = json.data
	var saved_version: Variant = save_data.get("version", -1)
	if typeof(saved_version) not in [TYPE_INT, TYPE_FLOAT] \
			or float(saved_version) != float(int(saved_version)) \
			or int(saved_version) < 1 or int(saved_version) > SAVE_VERSION:
		push_error("Character save has an unsupported version.")
		return

	var saved_gold: Variant = save_data.get("gold", 0)
	if typeof(saved_gold) not in [TYPE_INT, TYPE_FLOAT] or int(saved_gold) < 0:
		push_error("Character save gold amount is invalid.")
		return
	gold = int(saved_gold)

	var saved_level: Variant = save_data.get("level", 1)
	var saved_experience: Variant = save_data.get("experience", 0)
	var saved_passive_points: Variant = save_data.get("passive_tree_points", 0)
	var saved_skill_points: Variant = save_data.get("skill_tree_points", 0)
	var progression_thresholds: Array[int] = (
		LEGACY_LEVEL_XP_THRESHOLDS
		if int(saved_version) == 1
		else LEVEL_XP_THRESHOLDS
	)
	if typeof(saved_level) not in [TYPE_INT, TYPE_FLOAT] \
			or typeof(saved_experience) not in [TYPE_INT, TYPE_FLOAT] \
			or typeof(saved_passive_points) not in [TYPE_INT, TYPE_FLOAT] \
			or typeof(saved_skill_points) not in [TYPE_INT, TYPE_FLOAT] \
			or float(saved_level) != float(int(saved_level)) \
			or float(saved_experience) != float(int(saved_experience)) \
			or float(saved_passive_points) != float(int(saved_passive_points)) \
			or float(saved_skill_points) != float(int(saved_skill_points)) \
			or int(saved_level) < 1 or int(saved_level) > MAX_PLAYER_LEVEL \
			or int(saved_experience) < 0 \
			or int(saved_experience) > progression_thresholds[MAX_PLAYER_LEVEL - 1] \
			or int(saved_passive_points) < 0 \
			or int(saved_skill_points) < 0 \
			or int(saved_experience) < progression_thresholds[int(saved_level) - 1]:
		push_error("Character save progression data is invalid.")
		return
	player_level = int(saved_level)
	experience = int(saved_experience)
	if int(saved_version) == 1:
		experience = _migrate_legacy_experience(player_level, experience)
	passive_tree_points = int(saved_passive_points)
	skill_tree_points = int(saved_skill_points)

	var raw_inventory: Variant = save_data.get("inventory", [])
	var raw_equipment: Variant = save_data.get("equipment", {})
	if typeof(raw_inventory) != TYPE_ARRAY or typeof(raw_equipment) != TYPE_DICTIONARY:
		push_error("Character save inventory or equipment data is invalid.")
		return

	for raw_item in raw_inventory:
		if typeof(raw_item) != TYPE_DICTIONARY:
			push_error("Ignoring an invalid item in the character inventory save.")
			continue
		var item_record: Dictionary = raw_item
		if _item_from_record(item_record) != null:
			_inventory_records.append(item_record)

	for raw_slot in raw_equipment:
		var slot_name := str(raw_slot)
		if slot_name not in EQUIPMENT_SLOTS:
			push_error("Ignoring unsupported saved equipment slot '%s'." % slot_name)
			continue
		var raw_item: Variant = raw_equipment[raw_slot]
		if typeof(raw_item) != TYPE_DICTIONARY:
			push_error("Ignoring invalid saved equipment in slot '%s'." % slot_name)
			continue
		var item_record: Dictionary = raw_item
		if _item_from_record(item_record) != null:
			_equipment_records[slot_name] = item_record

	if int(saved_version) == 1:
		save_character(get_inventory(), get_equipment())


func _migrate_legacy_experience(saved_level: int, saved_experience: int) -> int:
	if saved_level >= MAX_PLAYER_LEVEL:
		return LEVEL_XP_THRESHOLDS[MAX_PLAYER_LEVEL - 1]

	var old_level_start := LEGACY_LEVEL_XP_THRESHOLDS[saved_level - 1]
	var old_level_xp := LEGACY_LEVEL_XP_THRESHOLDS[saved_level] - old_level_start
	var progress := float(saved_experience - old_level_start) / float(old_level_xp)
	var new_level_start := LEVEL_XP_THRESHOLDS[saved_level - 1]
	var new_level_xp := LEVEL_XP_THRESHOLDS[saved_level] - new_level_start
	return new_level_start + roundi(new_level_xp * progress)


func _load_roster() -> void:
	if _roster_loaded:
		return
	_roster_loaded = true
	if not FileAccess.file_exists(ROSTER_PATH):
		return

	var file := FileAccess.open(ROSTER_PATH, FileAccess.READ)
	if file == null:
		push_error("Could not open character roster: %s" % error_string(FileAccess.get_open_error()))
		return

	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	file.close()
	if parse_error != OK or typeof(json.data) != TYPE_DICTIONARY:
		push_error("Could not parse the character roster.")
		return

	var roster: Dictionary = json.data
	if int(roster.get("version", -1)) != ROSTER_VERSION:
		push_error("Character roster has an unsupported version.")
		return

	var saved_characters: Variant = roster.get("characters", [])
	if typeof(saved_characters) != TYPE_ARRAY:
		push_error("Character roster entries must be an array.")
		return

	for saved_character in saved_characters:
		if typeof(saved_character) != TYPE_DICTIONARY:
			continue
		var character: Dictionary = saved_character
		var character_id: Variant = character.get("id", null)
		var display_name: Variant = character.get("name", null)
		var character_class: Variant = character.get("class", null)
		var save_path: Variant = character.get("save_path", null)
		if typeof(character_id) != TYPE_STRING \
				or typeof(display_name) != TYPE_STRING \
				or typeof(character_class) != TYPE_STRING \
				or typeof(save_path) != TYPE_STRING \
				or character_class not in ["Warrior", "Witch"] \
				or (save_path != SAVE_PATH and not str(save_path).begins_with("user://characters/")):
			continue
		_characters.append({
			"id": character_id,
			"name": display_name,
			"class": character_class,
			"save_path": save_path
		})


func _save_roster() -> bool:
	var file := FileAccess.open(ROSTER_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not save character roster: %s" % error_string(FileAccess.get_open_error()))
		return false

	file.store_string(JSON.stringify({
		"version": ROSTER_VERSION,
		"characters": _characters
	}, "\t"))
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		push_error("Could not write character roster: %s" % error_string(write_error))
		return false
	return true


func _find_character_index(character_id: String) -> int:
	for index in range(_characters.size()):
		if _characters[index]["id"] == character_id:
			return index
	return -1


func _clear_character_data() -> void:
	_inventory_records.clear()
	_equipment_records.clear()
	gold = 0
	player_level = 1
	experience = 0
	passive_tree_points = 0
	skill_tree_points = 0


func _restore_active_character(character_id: String) -> void:
	if character_id.is_empty():
		_active_character_id = ""
		_active_save_path = SAVE_PATH
		_clear_character_data()
		_load_character()
		return

	var character_index := _find_character_index(character_id)
	if character_index < 0:
		return
	_active_character_id = character_id
	_active_save_path = _characters[character_index]["save_path"]
	_clear_character_data()
	_load_character()


func _record_from_item(item: ItemData) -> Dictionary:
	return {
		"display_name": item.display_name,
		"equipment_slot": item.equipment_slot,
		"icon_color": item.icon_color.to_html(false),
		"damage_bonus": item.damage_bonus,
		"damage_reduction": item.damage_reduction,
		"price": item.price
	}


func _item_from_record(record: Dictionary) -> ItemData:
	var display_name: Variant = record.get("display_name", null)
	var equipment_slot: Variant = record.get("equipment_slot", null)
	var icon_color: Variant = record.get("icon_color", null)
	var damage_bonus: Variant = record.get("damage_bonus", null)
	var damage_reduction: Variant = record.get("damage_reduction", null)
	var price: Variant = record.get("price", 25)
	if typeof(display_name) != TYPE_STRING \
			or typeof(equipment_slot) != TYPE_STRING \
			or typeof(icon_color) != TYPE_STRING \
			or typeof(damage_bonus) not in [TYPE_INT, TYPE_FLOAT] \
			or typeof(damage_reduction) not in [TYPE_INT, TYPE_FLOAT] \
			or typeof(price) not in [TYPE_INT, TYPE_FLOAT]:
		push_error("Ignoring a character save item with invalid fields.")
		return null

	var item := ItemData.new()
	item.display_name = display_name
	item.equipment_slot = equipment_slot
	item.icon_color = Color.from_string(icon_color, Color.WHITE)
	item.damage_bonus = int(damage_bonus)
	item.damage_reduction = int(damage_reduction)
	item.price = int(price)
	return item


func _create_item(
	item_name: String,
	slot_name: String,
	item_color: Color,
	damage_bonus: int,
	damage_reduction: int,
	item_price: int
) -> ItemData:
	var item := ItemData.new()
	item.display_name = item_name
	item.equipment_slot = slot_name
	item.icon_color = item_color
	item.damage_bonus = damage_bonus
	item.damage_reduction = damage_reduction
	item.price = item_price
	return item
