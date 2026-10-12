extends Area2D
class_name GoldPickup

@export_range(1, 3, 1) var amount := 1

@onready var amount_label: Label = $Amount


func _ready() -> void:
	if amount < 1 or amount > 3:
		push_error("Gold pickup amount must be between 1 and 3.")
		set_deferred("monitoring", false)
		return

	amount_label.text = "+%d" % amount
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return

	GameState.add_gold(amount)
	queue_free()
