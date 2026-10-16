extends Node2D
class_name IceAmbience
## Ice cave atmosphere: a cold tint, slow light and shadow swells over the snow, drifting freezing fog
## with a frosted vignette, steady snowfall, gusts of blowing snow and glints twinkling on the snow.
## Purely cosmetic.

const TINT := Color(0.9, 0.94, 1.0)
## Seconds between the strongest gusts of wind.
const GUST_PERIOD := 11.0
## Large, slow light and shadow swells over the snow, anchored to the world, so the ripple tile never
## reads as a repeating pattern.
const GROUND_SHADER := """
shader_type canvas_item;

uniform sampler2D shade_noise : repeat_enable, filter_linear;
uniform float shade_scale = 0.00045;
uniform float shade_strength = 0.07;
varying vec2 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec4 snow = COLOR;
	float broad = texture(shade_noise, world_position * shade_scale).r;
	float fine = texture(shade_noise, world_position * shade_scale * 2.9 + vec2(0.41, 0.17)).r;
	float shade = (broad * 0.7 + fine * 0.3 - 0.5) * 2.0;
	snow.rgb *= 1.0 + shade * shade_strength;
	// Hollows sink into cold blue shadow; crests stay bright white.
	snow.rgb = mix(snow.rgb, snow.rgb * vec3(0.88, 0.94, 1.04), clamp(-shade, 0.0, 1.0) * 0.7);
	COLOR = snow;
}
"""
const FOG_SHADER := """
shader_type canvas_item;
render_mode blend_premul_alpha, unshaded;

uniform sampler2D noise_texture : repeat_enable, filter_linear;
uniform vec2 world_offset;
uniform vec2 aspect = vec2(1.7778, 1.0);
uniform vec4 fog_color : source_color = vec4(0.9, 0.96, 1.0, 1.0);
uniform float fog_strength = 0.2;
uniform vec4 frost_color : source_color = vec4(0.24, 0.38, 0.62, 1.0);
uniform float frost_strength = 0.42;
uniform vec4 shadow_color : source_color = vec4(0.1, 0.2, 0.42, 1.0);
uniform float shadow_strength = 0.12;

void fragment() {
	// Freezing fog is anchored to the world and drifts slowly with the wind.
	vec2 world_uv = (UV + world_offset) * aspect;
	float drift = TIME * 0.02;
	float n1 = texture(noise_texture, world_uv * vec2(0.22, 0.4) + vec2(-drift, drift * 0.2)).r;
	float n2 = texture(noise_texture, world_uv * vec2(0.55, 1.0) + vec2(-drift * 1.6, 0.0)).r;
	float fog = smoothstep(0.42, 0.85, n1 * 0.6 + n2 * 0.4) * fog_strength;

	// Cold blue shade creeping in from the edges of the screen, which also keeps the HUD readable
	// against the bright snow.
	float edge = smoothstep(0.5, 1.2, length((UV - 0.5) * vec2(1.9, 2.1)));
	float frost = edge * frost_strength * (0.85 + 0.15 * texture(noise_texture, UV * 3.0).r);

	// Shadows of heavy snow clouds sliding over the caves.
	float c = texture(noise_texture, world_uv * 0.08 + vec2(-TIME * 0.005, TIME * 0.002)).r;
	float cloud = smoothstep(0.55, 0.72, c) * shadow_strength;

	vec3 color = fog_color.rgb * fog + frost_color.rgb * frost + shadow_color.rgb * cloud;
	COLOR = vec4(color, clamp(fog + frost + cloud, 0.0, 1.0));
}
"""

var player: Player
var camera: Camera2D
var fog_material: ShaderMaterial
var snowfall: CPUParticles2D
var near_snow: CPUParticles2D
var gusts: CPUParticles2D
var glints: CPUParticles2D
var elapsed := 0.0


func _ready() -> void:
	player = get_parent().get_node_or_null("Player") as Player
	camera = player.get_node_or_null("Camera2D") as Camera2D if player != null else null
	if camera == null:
		push_error("IceAmbience needs the level's Player with a Camera2D.")
		set_process(false)
		return

	var canvas_tint := CanvasModulate.new()
	canvas_tint.color = TINT
	add_child(canvas_tint)
	_build_fog_layer()
	_shade_ground()
	var view := get_viewport_rect().size
	snowfall = _build_snow(160, 1.0, 2.0, Vector2(40.0, 70.0), view)
	near_snow = _build_snow(26, 3.0, 4.0, Vector2(90.0, 140.0), view)
	gusts = _build_gusts(view)
	glints = _build_glints(view)
	z_index = 20
	_process(0.0)


func _process(delta: float) -> void:
	elapsed += delta
	var view_center := camera.get_screen_center_position()
	var view_size := get_viewport_rect().size / camera.zoom
	# Emitters sit above and upwind of the view so flakes drift down across it.
	snowfall.global_position = view_center + Vector2(-view_size.x * 0.1, -view_size.y * 0.25)
	near_snow.global_position = snowfall.global_position
	gusts.global_position = view_center + Vector2(-view_size.x * 0.25, 0.0)
	glints.global_position = view_center
	# Wind rises and falls so the snow comes in gusts.
	var gust := maxf(sin(elapsed * TAU / GUST_PERIOD), 0.0)
	gusts.speed_scale = 0.6 + 0.8 * gust
	snowfall.speed_scale = 0.9 + 0.5 * gust
	fog_material.set_shader_parameter("world_offset", (view_center - view_size * 0.5) / view_size)


func _make_noise_texture(seed_value: int, frequency: float, octaves: int) -> NoiseTexture2D:
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = frequency
	noise.fractal_octaves = octaves
	var noise_texture := NoiseTexture2D.new()
	noise_texture.width = 256
	noise_texture.height = 256
	noise_texture.seamless = true
	noise_texture.noise = noise
	return noise_texture


func _build_fog_layer() -> void:
	var shader := Shader.new()
	shader.code = FOG_SHADER
	fog_material = ShaderMaterial.new()
	fog_material.shader = shader
	fog_material.set_shader_parameter("noise_texture", _make_noise_texture(5, 0.014, 3))
	var view_size := get_viewport_rect().size
	fog_material.set_shader_parameter("aspect", Vector2(view_size.x / view_size.y, 1.0))

	# Sits between the world and the HUD, so the HUD moves up a layer.
	var fog_layer := CanvasLayer.new()
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


func _shade_ground() -> void:
	var ground := get_parent().get_node_or_null("Background/Sprite2D") as Sprite2D
	if ground == null:
		return
	var shader := Shader.new()
	shader.code = GROUND_SHADER
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("shade_noise", _make_noise_texture(23, 0.01, 2))
	ground.material = material


## Flakes drifting down and a little downwind. Flakes stay put in the world while the emitter follows
## the camera.
func _build_snow(amount: int, min_size: float, max_size: float, speed: Vector2, view: Vector2) -> CPUParticles2D:
	var particles := CPUParticles2D.new()
	particles.texture = _make_flake_texture()
	particles.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	particles.amount = amount
	particles.lifetime = 7.0
	particles.preprocess = 7.0
	particles.local_coords = false
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = view * Vector2(0.65, 0.6)
	particles.direction = Vector2(0.35, 1.0)
	particles.spread = 12.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = speed.x
	particles.initial_velocity_max = speed.y
	# Flakes flutter side to side as they fall.
	particles.tangential_accel_min = -6.0
	particles.tangential_accel_max = 6.0
	particles.scale_amount_min = min_size
	particles.scale_amount_max = max_size
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.1, 0.85, 1.0])
	fade.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 0.9), Color(1, 1, 1, 0.8), Color(1, 1, 1, 0)])
	particles.color_ramp = fade
	add_child(particles)
	return particles


## Fine snow skimming sideways along the ground in the gusts.
func _build_gusts(view: Vector2) -> CPUParticles2D:
	var particles := CPUParticles2D.new()
	particles.texture = _make_streak_texture()
	particles.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	particles.amount = 50
	particles.lifetime = 3.0
	particles.preprocess = 3.0
	particles.local_coords = false
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = view * Vector2(0.45, 0.6)
	particles.direction = Vector2(1, 0.08)
	particles.spread = 6.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 160.0
	particles.initial_velocity_max = 260.0
	particles.scale_amount_min = 1.0
	particles.scale_amount_max = 2.0
	var colors := Gradient.new()
	colors.offsets = PackedFloat32Array([0.0, 1.0])
	colors.colors = PackedColorArray([Color("#ffffff"), Color("#cfe6f7")])
	particles.color_initial_ramp = colors
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.2, 0.75, 1.0])
	fade.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 0.55), Color(1, 1, 1, 0.4), Color(1, 1, 1, 0)])
	particles.color_ramp = fade
	add_child(particles)
	return particles


## Brief sparkles where light catches ice crystals in the snow.
func _build_glints(view: Vector2) -> CPUParticles2D:
	var particles := CPUParticles2D.new()
	particles.texture = _make_glint_texture()
	particles.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	particles.amount = 24
	particles.lifetime = 0.9
	particles.local_coords = false
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = view * 0.5
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 0.0
	particles.initial_velocity_max = 0.0
	particles.scale_amount_min = 1.0
	particles.scale_amount_max = 2.0
	var pulse := Curve.new()
	pulse.add_point(Vector2(0.0, 0.0))
	pulse.add_point(Vector2(0.4, 1.0))
	pulse.add_point(Vector2(1.0, 0.0))
	particles.scale_amount_curve = pulse
	# On the ground, under characters and props.
	particles.z_index = -25
	add_child(particles)
	return particles


func _make_flake_texture() -> ImageTexture:
	var image := Image.create_empty(2, 2, false, Image.FORMAT_RGBA8)
	image.fill(Color(1, 1, 1, 1))
	image.set_pixel(1, 1, Color(0.85, 0.93, 1.0, 0.8))
	return ImageTexture.create_from_image(image)


func _make_streak_texture() -> ImageTexture:
	var image := Image.create_empty(5, 1, false, Image.FORMAT_RGBA8)
	for x in 5:
		image.set_pixel(x, 0, Color(1, 1, 1, 1.0 - absf(x - 2.0) * 0.3))
	return ImageTexture.create_from_image(image)


## A tiny four-pointed star.
func _make_glint_texture() -> ImageTexture:
	var image := Image.create_empty(5, 5, false, Image.FORMAT_RGBA8)
	for index in 5:
		var strength := 1.0 - absf(index - 2.0) * 0.35
		image.set_pixel(index, 2, Color(1, 1, 1, strength))
		image.set_pixel(2, index, Color(1, 1, 1, strength))
	return ImageTexture.create_from_image(image)
