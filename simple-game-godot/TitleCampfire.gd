extends Node2D
class_name TitleCampfire

# Animated campfire vignette for the title menu. Children are laid out in the
# backdrop SVG's 1600x900 space; fit_to_backdrop() maps that space onto the
# backdrop TextureRect (which uses "keep aspect covered").

const BACKDROP_SIZE = Vector2(1600, 900)
const FIRE_POSITION = Vector2(1370, 790)
const CAMPFIRE_SHEET = preload("res://textures/title_campfire_sheet.png")
const CAMPFIRE_FRAMES = 8
const CAMPFIRE_FPS = 10.0
const HERO_FRAME_SIZE = 100

# class, position, atlas row, atlas frame, flip
const HEROES = [
	["Ranger", Vector2(1428, 706), 0, 0, false],
	["Warrior", Vector2(1236, 794), 1, 1, false],
	["Witch", Vector2(1512, 794), 1, 0, false],
]

var fire: Sprite2D
var glow: Sprite2D
var hero_sprites: Array[Sprite2D] = []
var flicker_noise := FastNoiseLite.new()
var elapsed := 0.0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	flicker_noise.frequency = 2.2
	_build_glow()
	for hero in HEROES:
		if hero[0] == "Ranger":
			_build_hero(hero)
	_build_smoke()
	_build_fire()
	_build_embers()
	for hero in HEROES:
		if hero[0] != "Ranger":
			_build_hero(hero)


func fit_to_backdrop(backdrop_size: Vector2) -> void:
	var cover_scale := maxf(
		backdrop_size.x / BACKDROP_SIZE.x,
		backdrop_size.y / BACKDROP_SIZE.y
	)
	scale = Vector2.ONE * cover_scale
	position = (backdrop_size - BACKDROP_SIZE * cover_scale) * 0.5


func _process(delta: float) -> void:
	elapsed += delta
	fire.frame = int(elapsed * CAMPFIRE_FPS) % CAMPFIRE_FRAMES
	var flicker := flicker_noise.get_noise_1d(elapsed * 10.0)
	glow.modulate.a = 0.82 + flicker * 0.22
	glow.scale = Vector2(5.4, 3.5) * (1.0 + flicker * 0.04)
	var warmth := Color(1.0, 0.9, 0.78).lerp(Color(1.0, 0.97, 0.9), 0.5 + flicker)
	for hero_sprite in hero_sprites:
		hero_sprite.modulate = warmth


func _build_fire() -> void:
	fire = Sprite2D.new()
	fire.texture = CAMPFIRE_SHEET
	fire.hframes = CAMPFIRE_FRAMES
	fire.centered = true
	fire.offset = Vector2(0, -24)
	fire.scale = Vector2(2.4, 2.4)
	fire.position = FIRE_POSITION
	add_child(fire)


func _build_glow() -> void:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 0.62, 0.25, 0.55))
	gradient.set_color(1, Color(1.0, 0.45, 0.15, 0.0))
	gradient.add_point(0.45, Color(1.0, 0.55, 0.2, 0.22))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 64
	texture.height = 64
	glow = Sprite2D.new()
	glow.texture = texture
	glow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	glow.position = FIRE_POSITION + Vector2(0, -24)
	glow.scale = Vector2(5.4, 3.5)
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = material
	add_child(glow)


func _build_hero(hero: Array) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = MenuStyle.PORTRAIT_SHEETS[hero[0]]
	sprite.region_enabled = true
	sprite.region_rect = Rect2(
		hero[3] * HERO_FRAME_SIZE,
		hero[2] * HERO_FRAME_SIZE,
		HERO_FRAME_SIZE,
		HERO_FRAME_SIZE
	)
	sprite.flip_h = hero[4]
	sprite.offset = Vector2(0, -44)
	sprite.scale = Vector2(1.3, 1.3)
	sprite.position = hero[1]
	add_child(sprite)
	hero_sprites.append(sprite)


func _build_embers() -> void:
	var embers := CPUParticles2D.new()
	embers.position = FIRE_POSITION + Vector2(0, -40)
	embers.amount = 26
	embers.lifetime = 2.4
	embers.preprocess = 2.4
	embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	embers.emission_rect_extents = Vector2(18, 8)
	embers.direction = Vector2.UP
	embers.spread = 22.0
	embers.gravity = Vector2(6, -18)
	embers.initial_velocity_min = 40.0
	embers.initial_velocity_max = 85.0
	embers.damping_min = 8.0
	embers.damping_max = 18.0
	embers.scale_amount_min = 2.4
	embers.scale_amount_max = 4.2
	embers.orbit_velocity_min = -0.04
	embers.orbit_velocity_max = 0.04
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1.0, 0.95, 0.6, 1.0))
	ramp.set_color(1, Color(0.85, 0.2, 0.08, 0.0))
	ramp.add_point(0.35, Color(1.0, 0.62, 0.2, 0.95))
	embers.color_ramp = ramp
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	embers.material = material
	add_child(embers)


func _build_smoke() -> void:
	var puff_gradient := Gradient.new()
	puff_gradient.set_color(0, Color(1, 1, 1, 1))
	puff_gradient.set_color(1, Color(1, 1, 1, 0))
	var puff := GradientTexture2D.new()
	puff.gradient = puff_gradient
	puff.fill = GradientTexture2D.FILL_RADIAL
	puff.fill_from = Vector2(0.5, 0.5)
	puff.fill_to = Vector2(1.0, 0.5)
	puff.width = 32
	puff.height = 32

	var smoke := CPUParticles2D.new()
	smoke.texture = puff
	smoke.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	smoke.position = FIRE_POSITION + Vector2(0, -110)
	smoke.amount = 12
	smoke.lifetime = 5.0
	smoke.preprocess = 5.0
	smoke.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	smoke.emission_rect_extents = Vector2(10, 6)
	smoke.direction = Vector2.UP
	smoke.spread = 12.0
	smoke.gravity = Vector2(7, -4)
	smoke.initial_velocity_min = 18.0
	smoke.initial_velocity_max = 30.0
	smoke.scale_amount_min = 1.2
	smoke.scale_amount_max = 2.0
	var growth := Curve.new()
	growth.add_point(Vector2(0, 0.6))
	growth.add_point(Vector2(1, 2.6))
	smoke.scale_amount_curve = growth
	var fade := Gradient.new()
	fade.set_color(0, Color(0.55, 0.55, 0.58, 0.0))
	fade.set_color(1, Color(0.4, 0.42, 0.48, 0.0))
	fade.add_point(0.2, Color(0.55, 0.55, 0.58, 0.16))
	smoke.color_ramp = fade
	add_child(smoke)
