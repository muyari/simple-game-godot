extends Control
class_name PotionFlask
## A potion flask in the globes' style, drawn by liquid_flask.gdshader so it stays crisp at any screen
## size. The liquid shows the stored charges plus progress on the next refill and glides between levels;
## gem pips underneath count whole charges and pop when one comes back.

const FLASK_SHADER = preload("res://liquid_flask.gdshader")
const PIP_RADIUS := 4.5
const PIP_SPACING := 14.0
const PIP_ROW_HEIGHT := 16.0
const LEVEL_SMOOTHING := 6.0
const POP_DURATION := 0.35
const SURGE_DECAY := 1.4
const PIP_RIM := Color("#140803")
const PIP_GOLD := Color("#c99a3c")
const PIP_EMPTY := Color(0.16, 0.13, 0.12)

@export var liquid_deep := Color(0.32, 0.01, 0.04)
@export var liquid_bright := Color(0.96, 0.2, 0.17)
@export var pip_color := Color(0.9, 0.16, 0.18)
@export var max_charges := 3

var charges := 3
var target_level := 1.0
var displayed_level := 1.0
var surge := 0.0
var pip_pops: Array[float] = []
var shader_material: ShaderMaterial

@onready var vessel: ColorRect = $Vessel


func _ready() -> void:
	pip_pops.resize(max_charges)
	pip_pops.fill(0.0)
	shader_material = ShaderMaterial.new()
	shader_material.shader = FLASK_SHADER
	shader_material.set_shader_parameter("liquid_deep", liquid_deep)
	shader_material.set_shader_parameter("liquid_bright", liquid_bright)
	shader_material.set_shader_parameter("seed", randf() * 100.0)
	vessel.material = shader_material
	resized.connect(_layout)
	_layout()
	_apply()


func set_charges(count: int, refill_remaining: float, refill_duration: float) -> void:
	var refill_progress := 0.0
	if count < max_charges and refill_remaining > 0.0 and refill_duration > 0.0:
		refill_progress = 1.0 - refill_remaining / refill_duration
	for index in range(charges, mini(count, pip_pops.size())):
		pip_pops[index] = POP_DURATION
		surge = 1.0
	charges = count
	target_level = clampf((count + refill_progress) / max_charges, 0.0, 1.0)
	queue_redraw()


func _process(delta: float) -> void:
	displayed_level = lerpf(displayed_level, target_level, 1.0 - exp(-LEVEL_SMOOTHING * delta))
	if absf(displayed_level - target_level) < 0.001:
		displayed_level = target_level
	surge = maxf(surge - SURGE_DECAY * delta, 0.0)
	var popping := false
	for index in pip_pops.size():
		if pip_pops[index] > 0.0:
			pip_pops[index] = maxf(pip_pops[index] - delta, 0.0)
			popping = true
	_apply()
	if popping:
		queue_redraw()


func _apply() -> void:
	shader_material.set_shader_parameter("fill_level", displayed_level)
	shader_material.set_shader_parameter("surge", surge)


## The flask fills the space above the pip row.
func _layout() -> void:
	vessel.position = Vector2.ZERO
	vessel.size = Vector2(size.x, maxf(size.y - PIP_ROW_HEIGHT, 1.0))
	shader_material.set_shader_parameter("aspect", vessel.size.x / vessel.size.y)
	queue_redraw()


func _draw() -> void:
	var row_center := Vector2(size.x / 2.0, size.y - PIP_ROW_HEIGHT / 2.0)
	for index in max_charges:
		var pip_center := row_center + Vector2((index - (max_charges - 1) / 2.0) * PIP_SPACING, 0.0)
		draw_circle(pip_center, PIP_RADIUS + 2.0, PIP_RIM)
		draw_circle(pip_center, PIP_RADIUS + 1.0, PIP_GOLD)
		if index < charges:
			var pop := pip_pops[index] / POP_DURATION
			if pop > 0.0:
				draw_circle(pip_center, PIP_RADIUS + 6.0 * pop, Color(pip_color, 0.45 * pop))
			draw_circle(pip_center, PIP_RADIUS * (1.0 + 0.3 * pop), pip_color.darkened(0.25))
			draw_circle(pip_center + Vector2(-0.6, -0.6), PIP_RADIUS * 0.7, pip_color)
			draw_circle(pip_center + Vector2(-1.4, -1.4), 1.3, pip_color.lightened(0.7))
		else:
			draw_circle(pip_center, PIP_RADIUS, PIP_EMPTY)
