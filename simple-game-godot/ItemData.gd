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
