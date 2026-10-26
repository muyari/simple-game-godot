class_name DevMode
## Developer Mode: test late-game content without replaying the campaign, even after a rebuild wipes saves.
##
## While it's on, every launch makes sure the roster has a Dev Warrior, Dev Witch and Dev Ranger (recreating
## any that were lost) and tops each one up to the max level, with enough skill and passive points to max
## both trees, every region cleared (which opens random maps), spending gold and the best gear that drops.
## Points already spent and gear at least as good as the best are kept. Other characters are never touched.
##
## Switch it with the `developer/mode` project setting (Project Settings > Developer > Mode, or project.godot).
## It's always off in release exports (`developer/mode.release=false`). To remove it for good: delete this
## file, the setting, the dev-mode branch in GameState._ready() and the badge line in Menu._ready().

const SETTING := "developer/mode"
const CHARACTERS: Array[Dictionary] = [
	{"id": "dev_warrior", "name": "Dev Warrior", "class": "Warrior"},
	{"id": "dev_witch", "name": "Dev Witch", "class": "Witch"},
	{"id": "dev_ranger", "name": "Dev Ranger", "class": "Ranger"},
]
const GOLD := 50000
## The best gear that drops: the Underworld boss's Hellforged set (LevelController._create_underworld_gear).
## Slots it doesn't cover are filled from the vendor's stock.
const BOSS_GEAR: Array[Dictionary] = [
	{"name": "Hellforged Trident", "slot": "Weapon", "color": "#ff7a3d", "damage": 5, "reduction": 0},
	{"name": "Hellforged Horned Helm", "slot": "Helm", "color": "#d9573a", "damage": 0, "reduction": 5},
	{"name": "Hellforged Ember Ring", "slot": "Ring", "color": "#ffb347", "damage": 5, "reduction": 0},
]


static func is_enabled() -> bool:
	return bool(ProjectSettings.get_setting(SETTING, false))


## Creates or tops up the developer characters. Leaves whichever character it prepared last active, so
## GameState reloads its own startup character afterwards.
static func prepare_characters() -> void:
	for character in CHARACTERS:
		_prepare_character(character["id"], character["name"], character["class"])


static func _prepare_character(character_id: String, display_name: String, character_class: String) -> void:
	if GameState.get_character(character_id).is_empty() \
			and GameState.create_character(display_name, character_class, character_id).is_empty():
		push_error("Developer Mode could not create %s." % display_name)
		return
	if not GameState.select_character(character_id):
		push_error("Developer Mode could not load %s." % display_name)
		return

	GameState.player_level = GameState.MAX_PLAYER_LEVEL
	GameState.experience = GameState.LEVEL_XP_THRESHOLDS[GameState.MAX_PLAYER_LEVEL - 1]
	GameState.skill_tree_points = _remaining_skill_cost(character_class)
	GameState.passive_tree_points = _remaining_passive_cost(character_class)
	GameState.gold = maxi(GameState.gold, GOLD)
	for level_id in GameState.LEVEL_SCENE_PATHS:
		# complete_level() on a cleared level resets its map, so only clear the ones still open.
		if not GameState.get_completed_levels().has(level_id):
			GameState.complete_level(level_id)
	if not GameState.save_character(GameState.get_inventory(), _with_best_gear(GameState.get_equipment())):
		push_error("Developer Mode could not save %s." % display_name)


## Skill points still needed to take every skill in the class's tree to its max rank.
static func _remaining_skill_cost(character_class: String) -> int:
	var tree: Dictionary = {
		"Warrior": GameState.WARRIOR_SKILL_TREE,
		"Witch": GameState.WITCH_SKILL_TREE,
		"Ranger": GameState.RANGER_SKILL_TREE,
	}[character_class]
	var ranks: Dictionary = {
		"Warrior": GameState.warrior_skill_ranks,
		"Witch": GameState.witch_skill_ranks,
		"Ranger": GameState.ranger_skill_ranks,
	}[character_class]
	var cost := 0
	for skill_id in tree:
		var skill: Dictionary = tree[skill_id]
		var missing_ranks := maxi(int(skill["max_rank"]) - int(ranks.get(skill_id, 0)), 0)
		cost += missing_ranks * int(skill["point_cost"])
	return cost


## Passive points still needed to unlock every node in the class's passive tree.
static func _remaining_passive_cost(character_class: String) -> int:
	var tree: Dictionary = {
		"Warrior": GameState.WARRIOR_PASSIVE_TREE,
		"Witch": GameState.WITCH_PASSIVE_TREE,
		"Ranger": GameState.RANGER_PASSIVE_TREE,
	}[character_class]
	var unlocked: Array[String] = {
		"Warrior": GameState.warrior_unlocked_passives,
		"Witch": GameState.witch_unlocked_passives,
		"Ranger": GameState.ranger_unlocked_passives,
	}[character_class]
	var cost := 0
	for passive_id in tree:
		if not unlocked.has(passive_id):
			cost += int(tree[passive_id].get("point_cost", 1))
	return cost


## The equipment with every slot holding the best item for it, unless what's there is at least as good.
static func _with_best_gear(equipment: Dictionary) -> Dictionary:
	var best_by_slot := {}
	var candidates := GameState.get_vendor_items()
	for gear in BOSS_GEAR:
		var item := ItemData.new()
		item.display_name = gear["name"]
		item.equipment_slot = gear["slot"]
		item.icon_color = Color(gear["color"])
		item.damage_bonus = gear["damage"]
		item.damage_reduction = gear["reduction"]
		item.price = 45
		candidates.append(item)
	for item in candidates:
		var best: ItemData = best_by_slot.get(item.equipment_slot)
		if best == null or _score(item) > _score(best):
			best_by_slot[item.equipment_slot] = item

	var updated := equipment.duplicate()
	for slot in GameState.EQUIPMENT_SLOTS:
		var best: ItemData = best_by_slot.get("Ring" if slot.begins_with("Ring") else slot)
		var current: ItemData = updated.get(slot)
		if best != null and (current == null or _score(current) < _score(best)):
			updated[slot] = best
	return updated


static func _score(item: ItemData) -> int:
	return item.damage_bonus + item.damage_reduction


## A "DEVELOPER MODE" tag in the corner of the title screen, so a dev build is never mistaken for a release.
static func add_badge(parent: Control) -> void:
	var badge := Label.new()
	badge.text = "DEVELOPER MODE"
	badge.add_theme_color_override("font_color", MenuStyle.DANGER)
	badge.add_theme_font_size_override("font_size", 14)
	badge.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	badge.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	badge.offset_left = -200.0
	badge.offset_right = -16.0
	badge.offset_top = 10.0
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(badge)
