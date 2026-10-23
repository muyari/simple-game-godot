extends Sprite2D
class_name FireGlow
## A soft warm light pool that flickers like firelight, drawn additively over the ground and props around
## braziers, lava and burning things. Purely cosmetic.

const FLICKER_SPEED := 9.0

static var _texture: GradientTexture2D

var strength := 0.6
var phase := 0.0
var time := 0.0


## Adds a glow `radius` world pixels across under `parent`, at `offset` from its origin.
static func attach(parent: Node2D, offset: Vector2, radius: float, color: Color, glow_strength := 0.6) -> FireGlow:
	var glow := FireGlow.new()
	glow.texture = _get_texture()
	glow.position = offset
	glow.scale = Vector2(1.0, 0.62) * (radius * 2.0 / 128.0)
	glow.modulate = color
	glow.strength = glow_strength
	glow.phase = randf() * TAU
	parent.add_child(glow)
	return glow


static func _get_texture() -> GradientTexture2D:
	if _texture == null:
		var gradient := Gradient.new()
		gradient.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
		gradient.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.35), Color(1, 1, 1, 0)])
		_texture = GradientTexture2D.new()
		_texture.gradient = gradient
		_texture.fill = GradientTexture2D.FILL_RADIAL
		_texture.fill_from = Vector2(0.5, 0.5)
		_texture.fill_to = Vector2(1.0, 0.5)
		_texture.width = 128
		_texture.height = 128
	return _texture


func _ready() -> void:
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = additive
	# Lights the ground and whatever stands on it, without being y-sorted with them.
	z_as_relative = false
	z_index = -2
	_process(0.0)


func _process(delta: float) -> void:
	time += delta
	var flicker := sin(time * FLICKER_SPEED + phase) * 0.5 + sin(time * FLICKER_SPEED * 2.3 + phase * 1.7) * 0.3
	modulate.a = strength * (0.88 + flicker * 0.12)
