extends WitchSkillTree
class_name RangerPassiveTree

signal skill_tree_requested

const RANGER_PASSIVE_BRANCHES: Array[String] = [
	"All", "Precision", "Skirmisher", "Trapper", "Fletcher", "Survivalist"
]


func _ready() -> void:
	active_tab = "passives"
	selected_passive_id = "keen_sight"
	super._ready()
	tab_skills_button.hide()
	tab_passives_button.text = "Ranger Passive Tree"
	skills_container.hide()
	var active_skills_button := Button.new()
	active_skills_button.text = "Active Skills"
	active_skills_button.custom_minimum_size = Vector2(130.0, 36.0)
	active_skills_button.pressed.connect(func(): skill_tree_requested.emit())
	tab_passives_button.get_parent().add_child(active_skills_button)
	tab_passives_button.get_parent().move_child(active_skills_button, 0)


func _get_passive_order() -> Array[String]:
	return GameState.RANGER_PASSIVE_ORDER


func _get_passive_branches() -> Array[String]:
	return RANGER_PASSIVE_BRANCHES


func _get_passive_definition(passive_id: String) -> Dictionary:
	return GameState.get_ranger_passive_definition(passive_id)


func _get_passive_stat_totals() -> Dictionary:
	return GameState.get_ranger_passive_stat_totals()


func _is_passive_unlocked(passive_id: String) -> bool:
	return GameState.is_ranger_passive_unlocked(passive_id)


func _can_unlock_passive(passive_id: String) -> bool:
	return GameState.can_unlock_ranger_passive(passive_id)


func _unlock_passive(passive_id: String) -> bool:
	return GameState.unlock_ranger_passive(passive_id)


func _get_points_text() -> String:
	return "Ranger Passive Points: %d" % GameState.passive_tree_points


func _refresh_passive_summary() -> void:
	var totals := _get_passive_stat_totals()
	stats_summary_label.text = "Allocated:  Accuracy +%d%%  |  Crit Chance +%d%%  |  Crit Damage +%d%%  |  Arrow Damage +%d%%  |  Pierce +%d  |  Evasion +%d%%  |  Projectile Speed +%d%%  |  Trap Effect +%d%%  |  Health +%d  |  Mana +%d  |  Regen %.1f HP / %.1f MP per sec  |  Damage Reduction -%d%%  |  Cooldowns -%d%%  |  Mana Costs -%d%%  |  Speed +%d%%" % [
		roundi(float(totals.get("accuracy", 0.0)) * 100.0),
		roundi(float(totals.get("critical_chance", 0.0)) * 100.0),
		roundi(float(totals.get("critical_damage", 0.0)) * 100.0),
		roundi(float(totals.get("skill_damage_percent", 0.0)) * 100.0),
		int(totals.get("pierce", 0)),
		roundi(float(totals.get("evasion", 0.0)) * 100.0),
		roundi(float(totals.get("projectile_speed", 0.0)) * 100.0),
		roundi(float(totals.get("trap_efficiency", 0.0)) * 100.0),
		int(totals.get("max_health", 0)),
		int(totals.get("max_mana", 0)),
		float(totals.get("health_regen", 0.0)),
		float(totals.get("mana_regen", 0.0)),
		roundi(float(totals.get("damage_reduction_percent", 0.0)) * 100.0),
		roundi(float(totals.get("cooldown_reduction", 0.0)) * 100.0),
		roundi(float(totals.get("mana_cost_reduction", 0.0)) * 100.0),
		roundi(float(totals.get("movement_speed", 0.0)) * 100.0)
	]
