extends Area2D
class_name ItemPickup

var item: ItemData

@onready var icon: Polygon2D = $Icon
@onready var item_name_label: Label = $ItemName


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if item == null:
		push_error("ItemPickup requires an ItemData resource.")
		set_deferred("monitoring", false)
		return

	icon.color = item.icon_color
	item_name_label.text = item.display_name


func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return

	var player := body as Player
	if player.try_add_item(item):
		queue_free()
	else:
		item_name_label.text = "Inventory Full"
