extends Resource
class_name ItemData

@export var display_name := ""
@export var equipment_slot := ""
@export var icon_color := Color.WHITE
@export var damage_bonus := 0
@export var damage_reduction := 0
@export var price := 25
## Set for quest items (e.g. Rendel's coat). These advance a quest when looted and never enter the inventory.
@export var quest_id := ""

## Quality tiers, worked out from an item's stats so saved items need no extra field. Each area's gear lands
## one tier above the last: forest Common, desert Uncommon, ice Rare, underworld Epic, its boss Legendary.
enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY, QUEST }

const RARITY_NAMES := ["Common", "Uncommon", "Rare", "Epic", "Legendary", "Quest"]
const RARITY_COLORS := [
	Color("#e3ddd0"),
	Color("#72e06a"),
	Color("#4fa8ff"),
	Color("#c27bff"),
	Color("#ffa53a"),
	Color("#ffe27a")
]


func get_rarity() -> Rarity:
	if not quest_id.is_empty():
		return Rarity.QUEST
	return clampi(damage_bonus + damage_reduction - 1, Rarity.COMMON, Rarity.LEGENDARY) as Rarity


func get_rarity_name() -> String:
	return RARITY_NAMES[get_rarity()]


func get_rarity_color() -> Color:
	return RARITY_COLORS[get_rarity()]
