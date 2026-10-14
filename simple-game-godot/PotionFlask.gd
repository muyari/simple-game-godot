extends Control
class_name PotionFlask

const PIP_RADIUS := 4.0
const PIP_SPACING := 13.0
const PIP_ROW_HEIGHT := 14.0
const LEVEL_SPEED := 1.6
const POP_DURATION := 0.35

## Texture rows (in pixels) where the liquid surface sits when full and where it bottoms out.
@export var liquid_top := 54.0
@export var liquid_bottom := 91.0
@export var pip_color := Color(0.9, 0.16, 0.18)
@export var max_charges := 3

var charges := 3
var target_level := 1.0
var displayed_level := 1.0
var pip_pops: Array[float] = []

@onready var empty_bottle: Sprite2D = $EmptyBottle
@onready var fill: Sprite2D = $Fill


func _ready() -> void:
	pip_pops.resize(max_charges)
	pip_pops.fill(0.0)
	resized.connect(_layout_sprites)
	_layout_sprites()


func set_charges(count: int, refill_remaining: float, refill_duration: float) -> void:
	var refill_progress := 0.0
	if count < max_charges and refill_remaining > 0.0 and refill_duration > 0.0:
		refill_progress = 1.0 - refill_remaining / refill_duration
	for index in range(charges, mini(count, pip_pops.size())):
		pip_pops[index] = POP_DURATION
	charges = count
	target_level = clampf((count + refill_progress) / max_charges, 0.0, 1.0)
	queue_redraw()


func _process(delta: float) -> void:
	var animating := displayed_level != target_level
	displayed_level = move_toward(displayed_level, target_level, LEVEL_SPEED * delta)
	for index in pip_pops.size():
		if pip_pops[index] > 0.0:
			pip_pops[index] = maxf(pip_pops[index] - delta, 0.0)
			animating = true
	if animating:
		_update_fill()
		queue_redraw()


func _layout_sprites() -> void:
	var texture_size := empty_bottle.texture.get_size()
	var bottle_area := Vector2(size.x, size.y - PIP_ROW_HEIGHT)
	var sprite_scale := minf(bottle_area.x / texture_size.x, bottle_area.y / texture_size.y)
	var origin := Vector2((size.x - texture_size.x * sprite_scale) / 2.0, bottle_area.y - texture_size.y * sprite_scale)
	for sprite: Sprite2D in [empty_bottle, fill]:
		sprite.scale = Vector2.ONE * sprite_scale
		sprite.position = origin
	_update_fill()


func _update_fill() -> void:
	var texture_size := fill.texture.get_size()
	# Show the full bottle only below the current liquid surface; the empty bottle shows above it.
	var surface := 0.0 if displayed_level >= 0.999 else lerpf(liquid_bottom, liquid_top, displayed_level)
	fill.visible = displayed_level > 0.0
	fill.region_rect = Rect2(0.0, surface, texture_size.x, texture_size.y - surface)
	fill.offset = Vector2(0.0, surface)


func _draw() -> void:
	var row_center := Vector2(size.x / 2.0, size.y - PIP_ROW_HEIGHT / 2.0)
	for index in max_charges:
		var pip_center := row_center + Vector2((index - (max_charges - 1) / 2.0) * PIP_SPACING, 0.0)
		draw_circle(pip_center, PIP_RADIUS + 1.5, Color(0.04, 0.05, 0.07, 0.9))
		if index < charges:
			var pop := pip_pops[index] / POP_DURATION
			if pop > 0.0:
				draw_circle(pip_center, PIP_RADIUS + 5.0 * pop, Color(pip_color, 0.45 * pop))
			draw_circle(pip_center, PIP_RADIUS * (1.0 + 0.35 * pop), pip_color)
			draw_circle(pip_center + Vector2(-1.2, -1.2), 1.4, pip_color.lightened(0.6))
		else:
			draw_circle(pip_center, PIP_RADIUS, Color(0.16, 0.18, 0.22))
