extends WarriorSkillTree
class_name RangerSkillTree


func _get_class_name() -> String:
	return "Ranger"


func _get_skill_branches() -> Array[String]:
	return ["All", "Precision", "Volley", "Control", "Mobility"]


func _get_skill_definitions() -> Array[Dictionary]:
	return GameState.get_ranger_skill_definitions()


func _get_skill_definition(skill_id: String) -> Dictionary:
	return GameState.get_ranger_skill_definition(skill_id)


func _get_skill_rank(skill_id: String) -> int:
	return GameState.get_ranger_skill_rank(skill_id)


func _can_unlock_skill(skill_id: String) -> bool:
	return GameState.can_unlock_ranger_skill(skill_id)


func _unlock_or_upgrade_skill(skill_id: String) -> bool:
	return GameState.unlock_or_upgrade_ranger_skill(skill_id)


func _assign_skill(skill_id: String, slot: String) -> bool:
	return GameState.assign_ranger_skill(skill_id, slot)
