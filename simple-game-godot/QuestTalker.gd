extends Area2D
class_name QuestTalker
## Makes whatever it is attached to someone (or something) the player can talk to about quests: a talk
## radius, an "E  Talk" prompt and a quest marker over its head. Talking opens the HUD's QuestDialogue
## for npc_id. Works on standing quest givers, wandering townsfolk, forest folk and talking objects
## such as Oblath's notice board.

@export var npc_id := ""
## Height of the speaker's head above its origin (its feet), for the marker and prompt.
@export var head_height := 60.0
@export var talk_radius := 40.0
@export var action := "Talk"

var prompt: Label
var marker: QuestMarker
var player_nearby := false


## Adds a talker for npc_id under parent and returns it.
static func attach(parent: Node2D, talker_npc_id: String, talker_head_height: float, talker_action := "Talk") -> QuestTalker:
	var talker := QuestTalker.new()
	talker.npc_id = talker_npc_id
	talker.head_height = talker_head_height
	talker.action = talker_action
	parent.add_child(talker)
	return talker


func _ready() -> void:
	collision_layer = 0
	if get_node_or_null("TalkArea") == null:
		var shape := CollisionShape2D.new()
		shape.name = "TalkArea"
		var circle := CircleShape2D.new()
		circle.radius = talk_radius
		shape.shape = circle
		shape.position = Vector2(0, -12)
		add_child(shape)
	marker = get_node_or_null("QuestMarker") as QuestMarker
	if marker == null:
		marker = QuestMarker.new()
		marker.name = "QuestMarker"
		add_child(marker)
	prompt = get_node_or_null("Prompt") as Label
	if prompt == null:
		prompt = Label.new()
		prompt.name = "Prompt"
		prompt.size = Vector2(120, 23)
		prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		prompt.add_theme_color_override("font_color", Color(1, 0.91, 0.68, 1))
		prompt.add_theme_color_override("font_outline_color", Color(0.08, 0.08, 0.07, 1))
		prompt.add_theme_constant_override("outline_size", 4)
		add_child(prompt)
	marker.position.y = -head_height - 6.0
	prompt.position = Vector2(-prompt.size.x * 0.5, -head_height - 52.0)
	# Above the trees and roofs the speaker may stand in front of.
	marker.z_index = 30
	prompt.z_index = 30
	marker.z_as_relative = false
	prompt.z_as_relative = false
	prompt.text = MenuStyle.interact_prompt(action)
	prompt.hide()
	add_to_group("interactables")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	GameState.quest_changed.connect(_on_quest_changed)
	refresh_marker()


func can_interact(_player: Player) -> bool:
	return player_nearby and is_visible_in_tree()


func interact(_player: Player) -> void:
	if not can_interact(_player):
		return
	var dialogue := get_tree().get_first_node_in_group(QuestDialogue.GROUP) as QuestDialogue
	if dialogue == null:
		push_error("No quest dialogue to talk to %s with." % npc_id)
		return
	dialogue.talk_to(npc_id)


func refresh_marker() -> void:
	marker.mode = Quests.get_marker_mode(npc_id)


func _on_quest_changed(_quest_id: String) -> void:
	refresh_marker()


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player_nearby = true
		prompt.show()


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		player_nearby = false
		prompt.hide()
