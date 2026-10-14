extends StaticBody2D
class_name AppleTree
## A forest apple tree. Each one has a stable id so quests can find it later, e.g. via
## get_tree().get_nodes_in_group(AppleTree.GROUP).

const GROUP := "apple_trees"

@export var tree_index := 0


func _ready() -> void:
	add_to_group(GROUP)


func get_tree_id() -> String:
	return "forest_apple_%d" % tree_index
