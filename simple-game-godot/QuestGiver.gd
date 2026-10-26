extends QuestTalker
class_name QuestGiver
## A quest giver standing in place, drawn from a sprite (e.g. Beth in Oblath). See QuestTalker.

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	# Node origin is the NPC's feet; place the marker and prompt just above the sprite's head.
	if sprite.texture != null:
		sprite.offset = Vector2(0, -sprite.texture.get_height() / 2.0)
		head_height = sprite.texture.get_height() * absf(sprite.scale.y)
	super._ready()
