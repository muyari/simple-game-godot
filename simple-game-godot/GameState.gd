extends Node

signal gold_changed(total_gold: int)

const SAVE_PATH = "user://character_save.json"
const SAVE_VERSION = 1
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
var gold := 0


func _ready() -> void:
	_load_character()


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
	return maxi(item.price / 2, 1)


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
		"inventory": inventory_records,
		"equipment": equipment_records
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
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
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
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
	if int(save_data.get("version", -1)) != SAVE_VERSION:
		push_error("Character save has an unsupported version.")
		return

	var saved_gold: Variant = save_data.get("gold", 0)
	if typeof(saved_gold) not in [TYPE_INT, TYPE_FLOAT] or int(saved_gold) < 0:
		push_error("Character save gold amount is invalid.")
		return
	gold = int(saved_gold)

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
