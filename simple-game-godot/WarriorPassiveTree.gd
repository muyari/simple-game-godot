extends WitchSkillTree
class_name WarriorPassiveTree

signal skill_tree_requested

const WARRIOR_PASSIVE_BRANCHES: Array[String] = ["All", "Tank", "Bruiser", "Slayer"]


func _ready() -> void:
	active_tab = "passives"
	selected_passive_id = "iron_vitality"
	super._ready()
	tab_skills_button.hide()
	tab_passives_button.text = "Warrior Passive Tree"
	skills_container.hide()
	var active_skills_button := Button.new()
	active_skills_button.text = "Active Skills"
	active_skills_button.custom_minimum_size = Vector2(130.0, 36.0)
	active_skills_button.pressed.connect(func(): skill_tree_requested.emit())
	tab_passives_button.get_parent().add_child(active_skills_button)
	tab_passives_button.get_parent().move_child(active_skills_button, 0)


func _get_passive_order() -> Array[String]:
	return GameState.WARRIOR_PASSIVE_ORDER


func _get_passive_branches() -> Array[String]:
	return WARRIOR_PASSIVE_BRANCHES


func _get_passive_definition(passive_id: String) -> Dictionary:
	return GameState.get_warrior_passive_definition(passive_id)


func _get_passive_stat_totals() -> Dictionary:
	return GameState.get_warrior_passive_stat_totals()


func _is_passive_unlocked(passive_id: String) -> bool:
	return GameState.is_warrior_passive_unlocked(passive_id)


func _can_unlock_passive(passive_id: String) -> bool:
	return GameState.can_unlock_warrior_passive(passive_id)


func _unlock_passive(passive_id: String) -> bool:
	return GameState.unlock_warrior_passive(passive_id)


func _get_points_text() -> String:
	return "Warrior Passive Points: %d" % GameState.passive_tree_points


func _refresh_passive_summary() -> void:
	var totals := _get_passive_stat_totals()
	stats_summary_label.text = "Allocated Stats:  Health +%d  |  Armor +%d  |  Weapon Damage +%d  |  Damage Reduction -%d%%  |  Stamina +%d" % [
		int(totals.get("max_health", 0)),
		int(totals.get("armor", 0)),
		int(totals.get("weapon_damage_bonus", 0)),
		roundi(float(totals.get("damage_reduction_percent", 0.0)) * 100.0),
		int(totals.get("max_mana", 0))
	]
