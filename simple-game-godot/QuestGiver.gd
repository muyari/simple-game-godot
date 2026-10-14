extends Area2D
class_name QuestGiver
## A town NPC who offers a quest. The town UI listens for talk_requested and runs the dialogue.

signal talk_requested(quest_giver: QuestGiver)

@export var npc_name := ""
@export var quest_id := ""

@onready var prompt: Label = $Prompt
@onready var marker: QuestMarker = $QuestMarker
@onready var sprite: Sprite2D = $Sprite2D

var player_nearby := false


func _ready() -> void:
	# Node origin is the NPC's feet; place the marker and prompt just above the sprite's head.
	if sprite.texture != null:
		sprite.offset = Vector2(0, -sprite.texture.get_height() / 2.0)
		var head_y := -sprite.texture.get_height() * absf(sprite.scale.y)
		marker.position.y = head_y - 6.0
		prompt.position.y = head_y - 52.0
	add_to_group("interactables")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	prompt.hide()
	refresh_marker()


func can_interact(_player: Player) -> bool:
	return player_nearby


func interact(_player: Player) -> void:
	if player_nearby:
		talk_requested.emit(self)


func refresh_marker() -> void:
	var quest_state := GameState.get_quest_state(quest_id)
	var quest := Quests.get_definition(quest_id)
	var turn_in_state: String = quest.get("quest_item", {}).get("sets_state", "")
	if quest_state == Quests.STATE_AVAILABLE:
		marker.mode = QuestMarker.Mode.AVAILABLE
	elif quest_state == Quests.STATE_COMPLETED:
		marker.mode = QuestMarker.Mode.HIDDEN
	elif not turn_in_state.is_empty() and quest_state == turn_in_state:
		marker.mode = QuestMarker.Mode.TURN_IN
	else:
		marker.mode = QuestMarker.Mode.IN_PROGRESS


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player_nearby = true
		prompt.show()


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		player_nearby = false
		prompt.hide()
