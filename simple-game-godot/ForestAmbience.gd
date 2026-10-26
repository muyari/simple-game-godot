extends Node2D
class_name ForestAmbience
## Forest atmosphere: a warm canopy tint, drifting fog with light shafts and a vignette, glowing motes,
## falling leaves, and butterflies/rabbits kept around the camera. Purely cosmetic.

const TINT := Color(0.88, 0.94, 0.84)
const BUTTERFLY_COUNT := 5
const RABBIT_COUNT := 2
## Critters further than this from the camera are moved to a fresh spot near it.
const CRITTER_RANGE := 1000.0
const FOG_SHADER := """
shader_type canvas_item;
render_mode blend_premul_alpha, unshaded;

uniform sampler2D noise_texture : repeat_enable, filter_linear;
uniform vec2 world_offset;
uniform vec2 aspect = vec2(1.7778, 1.0);
uniform vec4 fog_color : source_color = vec4(0.86, 0.93, 0.84, 1.0);
uniform float fog_strength = 0.2;
uniform vec4 light_color : source_color = vec4(1.0, 0.9, 0.58, 1.0);
uniform float light_strength = 0.16;
uniform float vignette_strength = 0.42;

void fragment() {
	// Fog is anchored to the world so it drifts past as the player walks.
	vec2 world_uv = (UV + world_offset) * aspect;
	float drift = TIME * 0.012;
	float n1 = texture(noise_texture, world_uv * 0.35 + vec2(drift, drift * 0.4)).r;
	float n2 = texture(noise_texture, world_uv * 0.8 + vec2(-drift * 0.8, drift * 0.6)).r;
	float fog = smoothstep(0.42, 0.78, n1 * 0.65 + n2 * 0.35) * fog_strength;

	// Slanted shafts of sunlight through the canopy, fading toward the bottom of the screen.
	float ray_coord = UV.x + UV.y * 0.5 + world_offset.x * 0.1;
	float rays = pow(max(0.0, sin(ray_coord * 6.0 + sin(TIME * 0.21) * 0.35)), 22.0);
	rays += 0.7 * pow(max(0.0, sin(ray_coord * 10.0 + 1.9 + sin(TIME * 0.16) * 0.45)), 30.0);
	rays *= (1.0 - UV.y * 0.75) * light_strength;
	rays *= 0.75 + 0.5 * texture(noise_texture, vec2(ray_coord * 0.4, TIME * 0.015)).r;

	float vignette = smoothstep(0.55, 1.25, length((UV - 0.5) * vec2(1.9, 2.1))) * vignette_strength;

	vec3 color = fog_color.rgb * fog + light_color.rgb * rays + vec3(0.01, 0.03, 0.01) * vignette;
	COLOR = vec4(color, clamp(fog + rays * 0.2 + vignette, 0.0, 1.0));
}
"""

var player: Player
var camera: Camera2D
var fog_material: ShaderMaterial
var motes: CPUParticles2D
var leaves: CPUParticles2D
var critters: Array[ForestCritter] = []
var canvas_tint: CanvasModulate
var fog_layer: CanvasLayer


func _ready() -> void:
	player = get_parent().get_node_or_null("Player") as Player
	camera = player.get_node_or_null("Camera2D") as Camera2D if player != null else null
	if camera == null:
		push_error("ForestAmbience needs the level's Player with a Camera2D.")
		set_process(false)
		return

	canvas_tint = CanvasModulate.new()
	canvas_tint.color = TINT
	add_child(canvas_tint)
	_build_fog_layer()
	motes = _build_motes()
	leaves = _build_leaves()
	z_index = 20
	_process(0.0)


func _process(_delta: float) -> void:
	var view_center := camera.get_screen_center_position()
	var view_size := get_viewport_rect().size / camera.zoom
	motes.global_position = view_center
	leaves.global_position = view_center + Vector2(0, -view_size.y * 0.25)
	fog_material.set_shader_parameter("world_offset", (view_center - view_size * 0.5) / view_size)
	_keep_critters_near(view_center, view_size)


## Underground (in the Gloomhollow) there's no sky: a cold dim tint, and no fog, sunlight, motes,
## leaves or critters.
func set_underground(underground: bool, tint := TINT) -> void:
	canvas_tint.color = tint if underground else TINT
	fog_layer.visible = not underground
	motes.visible = not underground
	leaves.visible = not underground
	for critter in critters:
		critter.visible = not underground
		critter.process_mode = Node.PROCESS_MODE_DISABLED if underground else Node.PROCESS_MODE_INHERIT
	set_process(not underground)


func _build_fog_layer() -> void:
	var noise := FastNoiseLite.new()
	noise.seed = 7
	noise.frequency = 0.012
	noise.fractal_octaves = 3
	var noise_texture := NoiseTexture2D.new()
	noise_texture.width = 256
	noise_texture.height = 256
	noise_texture.seamless = true
	noise_texture.noise = noise

	var shader := Shader.new()
	shader.code = FOG_SHADER
	fog_material = ShaderMaterial.new()
	fog_material.shader = shader
	fog_material.set_shader_parameter("noise_texture", noise_texture)
	var view_size := get_viewport_rect().size
	fog_material.set_shader_parameter("aspect", Vector2(view_size.x / view_size.y, 1.0))

	# Sits between the world and the HUD, so the HUD moves up a layer.
	fog_layer = CanvasLayer.new()
	fog_layer.layer = 1
	var ui := get_parent().get_node_or_null("UI") as CanvasLayer
	if ui != null and ui.layer <= fog_layer.layer:
		ui.layer = fog_layer.layer + 1
	var fog := ColorRect.new()
	fog.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fog.set_anchors_preset(Control.PRESET_FULL_RECT)
	fog.material = fog_material
	fog_layer.add_child(fog)
	add_child(fog_layer)


func _build_motes() -> CPUParticles2D:
	var particles := _make_particles(_make_mote_texture(), 30, 7.0)
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.initial_velocity_min = 3.0
	particles.initial_velocity_max = 12.0
	particles.tangential_accel_min = -6.0
	particles.tangential_accel_max = 6.0
	particles.scale_amount_min = 1.0
	particles.scale_amount_max = 1.6
	particles.color = Color(0.9, 1.0, 0.55, 0.85)
	# Fade in, pulse, fade out, so each mote twinkles.
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.2, 0.45, 0.6, 0.85, 1.0])
	ramp.colors = PackedColorArray([
		Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 0.35),
		Color(1, 1, 1, 1), Color(1, 1, 1, 0.6), Color(1, 1, 1, 0),
	])
	particles.color_ramp = ramp
	var glow := CanvasItemMaterial.new()
	glow.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	particles.material = glow
	return particles


func _build_leaves() -> CPUParticles2D:
	var particles := _make_particles(_make_leaf_texture(), 12, 11.0)
	particles.direction = Vector2(1, 0.4)
	particles.spread = 35.0
	particles.gravity = Vector2(0, 7)
	particles.initial_velocity_min = 8.0
	particles.initial_velocity_max = 20.0
	particles.angle_min = 0.0
	particles.angle_max = 360.0
	particles.angular_velocity_min = -70.0
	particles.angular_velocity_max = 70.0
	particles.scale_amount_min = 1.6
	particles.scale_amount_max = 2.2
	var colors := Gradient.new()
	colors.offsets = PackedFloat32Array([0.0, 0.35, 0.7, 1.0])
	colors.colors = PackedColorArray([Color("#7e9a34"), Color("#d6a23c"), Color("#c46d2b"), Color("#9a4f24")])
	particles.color_initial_ramp = colors
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.1, 0.85, 1.0])
	fade.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	particles.color_ramp = fade
	return particles


func _make_particles(texture: Texture2D, amount: int, lifetime: float) -> CPUParticles2D:
	var particles := CPUParticles2D.new()
	particles.texture = texture
	particles.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	particles.amount = amount
	particles.lifetime = lifetime
	particles.preprocess = lifetime
	# Particles stay put in the world while the emitter follows the camera.
	particles.local_coords = false
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = get_viewport_rect().size * 0.6
	particles.gravity = Vector2.ZERO
	add_child(particles)
	return particles


func _make_mote_texture() -> ImageTexture:
	var image := Image.create_empty(5, 5, false, Image.FORMAT_RGBA8)
	for y in 5:
		for x in 5:
			var distance := Vector2(x - 2, y - 2).length()
			var alpha := 1.0 if distance < 0.5 else (0.4 if distance < 1.5 else 0.0)
			image.set_pixel(x, y, Color(1, 1, 1, alpha))
	return ImageTexture.create_from_image(image)


func _make_leaf_texture() -> ImageTexture:
	var shape := [".##", "###", "##."]
	var image := Image.create_empty(3, 3, false, Image.FORMAT_RGBA8)
	for y in 3:
		for x in 3:
			if shape[y][x] == "#":
				image.set_pixel(x, y, Color(1, 1, 1, 1) if x + y < 3 else Color(0.78, 0.78, 0.78, 1))
	return ImageTexture.create_from_image(image)


func _keep_critters_near(view_center: Vector2, view_size: Vector2) -> void:
	if critters.is_empty():
		for index in BUTTERFLY_COUNT + RABBIT_COUNT:
			var critter := ForestCritter.new()
			critter.kind = ForestCritter.Kind.BUTTERFLY if index < BUTTERFLY_COUNT else ForestCritter.Kind.RABBIT
			critter.player = player
			critter.position = _random_spot(view_center, view_size, true)
			critters.append(critter)
			get_parent().add_child.call_deferred(critter)
		return
	for critter in critters:
		if not critter.is_inside_tree():
			continue
		if critter.global_position.distance_to(view_center) > CRITTER_RANGE:
			critter.position = _random_spot(view_center, view_size, false)
			critter.home = critter.position


## A spot in view on the first spawn, otherwise just beyond the edge of the screen so critters wander in.
func _random_spot(view_center: Vector2, view_size: Vector2, in_view: bool) -> Vector2:
	var half := view_size * 0.5
	if in_view:
		return view_center + Vector2(randf_range(-half.x, half.x), randf_range(-half.y, half.y)) * 0.85
	var angle := randf() * TAU
	return view_center + Vector2(cos(angle) * (half.x + 80.0), sin(angle) * (half.y + 60.0))
