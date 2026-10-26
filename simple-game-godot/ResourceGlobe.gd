extends Control
class_name ResourceGlobe
## A health or mana globe, drawn by liquid_globe.gdshader so it stays crisp at any screen size. The
## liquid glides to each new value instead of jumping; what was just lost lingers as a pale band that
## drains after it, gains shimmer as they come in, and the globe pulses when it runs low.

const GLOBE_SHADER = preload("res://liquid_globe.gdshader")
## How quickly the liquid catches up with the value (per second, exponential).
const LEVEL_SMOOTHING := 9.0
## The pale "just lost" band waits this long, then drains at this rate (fraction per second).
const TRAIL_HOLD := 0.45
const TRAIL_DRAIN := 0.55
const SURGE_DECAY := 1.6
## Below this fraction the globe starts to pulse.
const LOW_FRACTION := 0.25

@export var liquid_deep := Color(0.35, 0.02, 0.04)
@export var liquid_bright := Color(0.95, 0.18, 0.16)
@export var gem_color := Color(0.78, 0.13, 0.16)
## Whether to pulse when low (health does, mana doesn't).
@export var pulse_when_low := true

var value := 100.0:
	set(new_value):
		if new_value > value:
			surge = 1.0
		elif new_value < value:
			trail_hold = TRAIL_HOLD
		value = new_value
		_update_label()

var maximum := 100.0:
	set(new_maximum):
		maximum = new_maximum
		_update_label()

var displayed_fraction := -1.0
var trail_fraction := 1.0
var trail_hold := 0.0
var surge := 0.0
var shader_material: ShaderMaterial

@onready var vessel: ColorRect = $Vessel
@onready var value_label: Label = $ValueLabel


func _ready() -> void:
	shader_material = ShaderMaterial.new()
	shader_material.shader = GLOBE_SHADER
	shader_material.set_shader_parameter("liquid_deep", liquid_deep)
	shader_material.set_shader_parameter("liquid_bright", liquid_bright)
	shader_material.set_shader_parameter("gem_color", gem_color)
	shader_material.set_shader_parameter("seed", randf() * 100.0)
	vessel.material = shader_material
	resized.connect(_layout)
	_layout()
	surge = 0.0
	displayed_fraction = _target_fraction()
	trail_fraction = displayed_fraction
	_update_label()
	_apply()


func _target_fraction() -> float:
	return clampf(value / maximum, 0.0, 1.0) if maximum > 0.0 else 0.0


func _process(delta: float) -> void:
	var target := _target_fraction()
	displayed_fraction = lerpf(displayed_fraction, target, 1.0 - exp(-LEVEL_SMOOTHING * delta))
	if absf(displayed_fraction - target) < 0.001:
		displayed_fraction = target
	if trail_fraction <= displayed_fraction:
		trail_fraction = displayed_fraction
	elif trail_hold > 0.0:
		trail_hold -= delta
	else:
		trail_fraction = maxf(trail_fraction - TRAIL_DRAIN * delta, displayed_fraction)
	surge = maxf(surge - SURGE_DECAY * delta, 0.0)
	_apply()


func _apply() -> void:
	shader_material.set_shader_parameter("fill_level", displayed_fraction)
	shader_material.set_shader_parameter("trail_level", trail_fraction)
	shader_material.set_shader_parameter("surge", surge)
	var low := pulse_when_low and displayed_fraction > 0.0 and displayed_fraction < LOW_FRACTION
	shader_material.set_shader_parameter("pulse", 1.0 - displayed_fraction / LOW_FRACTION if low else 0.0)


## Keeps the globe square and centred, with the number sized to the globe.
func _layout() -> void:
	var side := minf(size.x, size.y)
	vessel.size = Vector2(side, side)
	vessel.position = (size - vessel.size) / 2.0
	value_label.add_theme_font_size_override("font_size", maxi(roundi(side * 0.15), 10))


func _update_label() -> void:
	if is_node_ready():
		value_label.text = str(roundi(value))
