extends StaticBody2D

const FRONT_TEXTURES := [
	preload("res://textures/town_house_1.png"),
	preload("res://textures/town_house_2.png"),
	preload("res://textures/town_house_3.png"),
]
const BACK_TEXTURES := [
	preload("res://textures/town_house_back_1.png"),
	preload("res://textures/town_house_back_2.png"),
	preload("res://textures/town_house_back_3.png"),
]

@export var randomize_look := true
@export var use_back_view := false

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	if randomize_look:
		var textures: Array = BACK_TEXTURES if use_back_view else FRONT_TEXTURES
		_sprite.texture = textures[randi() % textures.size()]
	# Node origin is the house's bottom-center.
	_sprite.offset = Vector2(0, -_sprite.texture.get_height() / 2.0)
	queue_redraw()


func _draw() -> void:
	var footprint := _sprite.texture.get_width() * absf(_sprite.scale.x)
	GroundShadows.draw_soft_ellipse(self, _sprite.position + Vector2(0, -3), Vector2(footprint * 0.95, 22))
