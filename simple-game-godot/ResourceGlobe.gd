extends Control
class_name ResourceGlobe

var value := 100.0:
	set(new_value):
		value = new_value
		_update_fill()

var maximum := 100.0:
	set(new_maximum):
		maximum = new_maximum
		_update_fill()

@onready var glass: Sprite2D = $Glass
@onready var fill: Sprite2D = $Fill
@onready var value_label: Label = $ValueLabel


func _ready() -> void:
	resized.connect(_layout_sprites)
	_layout_sprites()


func _layout_sprites() -> void:
	var texture_size := glass.texture.get_size()
	var sprite_scale := minf(size.x, size.y) / texture_size.x
	var origin := (size - texture_size * sprite_scale) / 2.0
	for sprite: Sprite2D in [glass, fill]:
		sprite.scale = Vector2.ONE * sprite_scale
		sprite.position = origin
	_update_fill()


func _update_fill() -> void:
	if not is_node_ready():
		return
	var fraction := clampf(value / maximum, 0.0, 1.0) if maximum > 0.0 else 0.0
	var texture_size := fill.texture.get_size()
	# Show only the bottom part of the full globe so the liquid drains from the top.
	var empty_height := texture_size.y * (1.0 - fraction)
	fill.visible = fraction > 0.0
	fill.region_rect = Rect2(0.0, empty_height, texture_size.x, texture_size.y - empty_height)
	fill.offset = Vector2(0.0, empty_height)
	value_label.text = str(roundi(value))
