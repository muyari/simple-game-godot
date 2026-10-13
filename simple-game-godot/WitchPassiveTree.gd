extends WitchSkillTree
class_name WitchPassiveTree


func _init() -> void:
	active_tab = "passives"


func _ready() -> void:
	active_tab = "passives"
	super._ready()
	switch_tab("passives")


func open_tree(initial_tab: Variant = "passives") -> void:
	var tab_str := str(initial_tab) if initial_tab != null else "passives"
	if tab_str.is_empty():
		tab_str = "passives"
	super.open_tree(tab_str)
