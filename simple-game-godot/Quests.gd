class_name Quests
## Static quest definitions. Quest progress is stored per character via GameState.get/set_quest_state.

const STATE_AVAILABLE := ""
const STATE_ACCEPTED := "accepted"
const STATE_COMPLETED := "completed"

const FIND_RENDEL := "find_rendel"
## find_rendel stage: the player has looted Rendel's coat and must return it to Beth.
const STATE_COAT_FOUND := "coat_found"

## Areas shown as tabs in the quest menu, keyed by GameState level id.
const AREAS := [
	{"level_id": 1, "name": "Forest Outskirts"},
	{"level_id": 2, "name": "Sunscorch Sands"},
	{"level_id": 3, "name": "The Ice Caves"},
	{"level_id": 4, "name": "The Futuristic AI Zone"},
]

const DEFINITIONS := {
	FIND_RENDEL: {
		"title": "The Missing Woodsman",
		"giver": "Beth",
		"giver_location": "Oblath",
		"area": 1,
		"summary": "Beth's husband Rendel went into the forest to cut timber three days ago and never came home. The wolves have grown bold, and Beth fears the worst.",
		"objectives": [
			"Search the Forest Outskirts for Rendel",
			"Return Rendel's wool coat to Beth in Oblath",
		],
		# How many objectives are done, and the status line, for each stage of the quest.
		"stages": {
			STATE_ACCEPTED: {"objectives_done": 0, "status": "Search the forest for any sign of Rendel."},
			STATE_COAT_FOUND: {"objectives_done": 1, "status": "You found Rendel's wool coat in the wolves' lair. Return it to Beth in Oblath."},
			STATE_COMPLETED: {"objectives_done": 2, "status": "Completed. Beth now knows what became of Rendel."},
		},
		# Looting this item from the boss chest moves the quest from requires_state to sets_state.
		"quest_item": {
			"name": "Rendel's Wool Coat",
			"color": "#9b6b43",
			"requires_state": STATE_ACCEPTED,
			"sets_state": STATE_COAT_FOUND,
		},
		"reward": {
			"name": "Rendel's Compass",
			"description": "A battered brass compass, its needle still steady. Beth pressed it into your hands so a part of Rendel could keep travelling. It has no use in battle, only in memory.",
		},
		"dialogue": {
			STATE_AVAILABLE: [
				"Oh, thank the stars, a traveller who can hold a blade. Please, I need your help.",
				"My husband Rendel went into the forest three days ago to cut timber, like he does every week. He always comes home before the lamps are lit.",
				"He hasn't come back. And the hunters say the wolves have grown bold out there... whole packs of them, led by a great grey beast.",
				"I can't bear to think of it. Will you search the forest for Rendel and bring him home to Oblath?",
			],
			"accepted_reply": [
				"Bless you. Take the portal to the forest, and please be careful. If you find him... tell him I'm waiting.",
			],
			"declined_reply": [
				"I... I understand. It's dangerous out there. If you change your mind, I'll be right here.",
			],
			STATE_ACCEPTED: [
				"Any sign of Rendel? Please, keep searching the forest. He's stubborn, but he's all I have.",
			],
			STATE_COAT_FOUND: [
				"You're back. What... what is that you're carrying?",
				"That's his coat. I stitched that patch on the elbow myself, last winter. He never went anywhere without it.",
				"So the wolves... oh, Rendel. My Rendel. *Beth clutches the coat and weeps.*",
				"I'm sorry. Thank you for bringing him back to me, in the only way you could.",
				"Here. This was his compass. He always said it would lead him home. Take it, so a part of him can keep travelling.\n\nYou received Rendel's Compass.",
			],
			STATE_COMPLETED: [
				"I miss him. Every evening I still look toward the forest road, hoping to see him walking home.",
			],
		},
	},
}


static func get_definition(quest_id: String) -> Dictionary:
	return DEFINITIONS.get(quest_id, {})


static func is_active(quest_state: String) -> bool:
	return quest_state != STATE_AVAILABLE and quest_state != STATE_COMPLETED


## Ids of the active character's quests in the given area that have been accepted (active or completed).
static func get_logged_quests_in_area(level_id: int) -> Array[String]:
	var quest_ids: Array[String] = []
	for quest_id in DEFINITIONS:
		if int(DEFINITIONS[quest_id]["area"]) == level_id \
				and GameState.get_quest_state(quest_id) != STATE_AVAILABLE:
			quest_ids.append(quest_id)
	return quest_ids


static func get_active_quest_count() -> int:
	var count := 0
	for quest_id in DEFINITIONS:
		if is_active(GameState.get_quest_state(quest_id)):
			count += 1
	return count


## Rewards earned from completed quests, as dictionaries with name, description and quest title.
static func get_earned_rewards() -> Array[Dictionary]:
	var rewards: Array[Dictionary] = []
	for quest_id in DEFINITIONS:
		var quest: Dictionary = DEFINITIONS[quest_id]
		if quest.has("reward") and GameState.get_quest_state(quest_id) == STATE_COMPLETED:
			var reward: Dictionary = quest["reward"].duplicate()
			reward["quest_title"] = quest["title"]
			rewards.append(reward)
	return rewards


## The quest items a boss chest should contain for the active character's current quest stages.
static func create_chest_quest_items() -> Array[ItemData]:
	var items: Array[ItemData] = []
	for quest_id in DEFINITIONS:
		var quest: Dictionary = DEFINITIONS[quest_id]
		if not quest.has("quest_item"):
			continue
		var quest_item: Dictionary = quest["quest_item"]
		if GameState.get_quest_state(quest_id) != quest_item["requires_state"]:
			continue
		var item := ItemData.new()
		item.display_name = quest_item["name"]
		item.equipment_slot = "Quest Item"
		item.icon_color = Color(quest_item["color"])
		item.price = 0
		item.quest_id = quest_id
		items.append(item)
	return items


## Called when a quest item is looted; advances its quest. Returns the new status line ("" if nothing changed).
static func loot_quest_item(quest_id: String) -> String:
	var quest := get_definition(quest_id)
	if quest.is_empty() or not quest.has("quest_item"):
		return ""
	var quest_item: Dictionary = quest["quest_item"]
	if GameState.get_quest_state(quest_id) != quest_item["requires_state"]:
		return ""
	if not GameState.set_quest_state(quest_id, quest_item["sets_state"]):
		push_error("Could not save progress for quest '%s'." % quest_id)
		return ""
	return quest["stages"][quest_item["sets_state"]]["status"]
