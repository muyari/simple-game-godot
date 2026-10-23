extends Node2D
class_name UnderworldAmbience
## Underworld atmosphere: a dim, blood-warm tint, slow swells of heat light and shadow over the cobbles,
## rolling smoke with a dark smouldering vignette, embers rising through the air, flakes of ash drifting
## down and heat shimmer flickering over the ground. Purely cosmetic.

const TINT := Color(0.86, 0.74, 0.74)
## Seconds between the strongest updrafts.
const UPDRAFT_PERIOD := 9.0
## Large, slow swells of firelight and shadow over the cobbles, anchored to the world, so the tile never
## reads as a repeating pattern.
const GROUND_SHADER := """
shader_type canvas_item;

uniform sampler2D shade_noise : repeat_enable, filter_linear;
uniform float shade_scale = 0.0005;
uniform float shade_strength = 0.16;
varying vec2 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec4 stone = COLOR;
	float broad = texture(shade_noise, world_position * shade_scale).r;
	float fine = texture(shade_noise, world_position * shade_scale * 3.1 + vec2(0.37, 0.21)).r;
	float shade = (broad * 0.7 + fine * 0.3 - 0.5) * 2.0;
	stone.rgb *= 1.0 + shade * shade_strength;
	// Rises catch a red glow from the fires below; hollows sink into soot.
	stone.rgb = mix(stone.rgb, stone.rgb * vec3(1.35, 0.92, 0.82), clamp(shade, 0.0, 1.0) * 0.6);
	COLOR = stone;
}
"""
const SMOKE_SHADER := """
shader_type canvas_item;
render_mode blend_premul_alpha, unshaded;

uniform sampler2D noise_texture : repeat_enable, filter_linear;
uniform vec2 world_offset;
uniform vec2 aspect = vec2(1.7778, 1.0);
uniform vec4 smoke_color : source_color = vec4(0.16, 0.08, 0.08, 1.0);
uniform float smoke_strength = 0.3;
uniform vec4 heat_color : source_color = vec4(0.85, 0.22, 0.06, 1.0);
uniform float heat_strength = 0.1;
uniform vec4 edge_color : source_color = vec4(0.07, 0.01, 0.01, 1.0);
uniform float edge_strength = 0.55;

void fragment() {
	// Smoke is anchored to the world and rolls slowly upward.
	vec2 world_uv = (UV + world_offset) * aspect;
	float drift = TIME * 0.018;
	float n1 = texture(noise_texture, world_uv * vec2(0.3, 0.45) + vec2(drift * 0.3, drift)).r;
	float n2 = texture(noise_texture, world_uv * vec2(0.7, 1.0) + vec2(-drift * 0.5, drift * 1.7)).r;
	float smoke = smoothstep(0.45, 0.85, n1 * 0.6 + n2 * 0.4) * smoke_strength;

	// Heat glow pulsing up from below, strongest in the lower part of the view.
	float h = texture(noise_texture, world_uv * 0.12 + vec2(0.0, TIME * 0.01)).r;
	float heat = smoothstep(0.5, 0.8, h) * heat_strength * (0.6 + 0.4 * UV.y) * (0.85 + 0.15 * sin(TIME * 1.3));

	// Dark smouldering edges, which also keep the HUD readable.
	float edge = smoothstep(0.45, 1.15, length((UV - 0.5) * vec2(1.9, 2.1)));
	float vignette = edge * edge_strength;

	vec3 color = smoke_color.rgb * smoke + heat_color.rgb * heat + edge_color.rgb * vignette;
	COLOR = vec4(color, clamp(smoke + heat + vignette, 0.0, 1.0));
}
"""

var player: Player
var camera: Camera2D
var smoke_material: ShaderMaterial
var embers: CPUParticles2D
var ash: CPUParticles2D
var sparks: CPUParticles2D
var elapsed := 0.0


func _ready() -> void:
	player = get_parent().get_node_or_null("Player") as Player
	camera = player.get_node_or_null("Camera2D") as Camera2D if player != null else null
	if camera == null:
		push_error("UnderworldAmbience needs the level's Player with a Camera2D.")
		set_process(false)
		return

	var canvas_tint := CanvasModulate.new()
	canvas_tint.color = TINT
	add_child(canvas_tint)
	_build_smoke_layer()
	_shade_ground()
	var view := get_viewport_rect().size
	embers = _build_embers(view)
	ash = _build_ash(view)
	sparks = _build_ground_sparks(view)
	z_index = 20
	_process(0.0)


func _process(delta: float) -> void:
	elapsed += delta
	var view_center := camera.get_screen_center_position()
	var view_size := get_viewport_rect().size / camera.zoom
	# Embers rise from below the view; ash drifts in from above it.
	embers.global_position = view_center + Vector2(0.0, view_size.y * 0.35)
	ash.global_position = view_center + Vector2(view_size.x * 0.1, -view_size.y * 0.3)
	sparks.global_position = view_center
	# Updrafts come and go, lifting the embers faster.
	var updraft := maxf(sin(elapsed * TAU / UPDRAFT_PERIOD), 0.0)
	embers.speed_scale = 0.8 + 0.7 * updraft
	smoke_material.set_shader_parameter("world_offset", (view_center - view_size * 0.5) / view_size)


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


func _build_smoke_layer() -> void:
	var shader := Shader.new()
	shader.code = SMOKE_SHADER
	smoke_material = ShaderMaterial.new()
	smoke_material.shader = shader
	smoke_material.set_shader_parameter("noise_texture", _make_noise_texture(66, 0.014, 3))
	var view_size := get_viewport_rect().size
	smoke_material.set_shader_parameter("aspect", Vector2(view_size.x / view_size.y, 1.0))

	# Sits between the world and the HUD, so the HUD moves up a layer.
	var smoke_layer := CanvasLayer.new()
	smoke_layer.layer = 1
	var ui := get_parent().get_node_or_null("UI") as CanvasLayer
	if ui != null and ui.layer <= smoke_layer.layer:
		ui.layer = smoke_layer.layer + 1
	var smoke := ColorRect.new()
	smoke.mouse_filter = Control.MOUSE_FILTER_IGNORE
	smoke.set_anchors_preset(Control.PRESET_FULL_RECT)
	smoke.material = smoke_material
	smoke_layer.add_child(smoke)
	add_child(smoke_layer)


func _shade_ground() -> void:
	var ground := get_parent().get_node_or_null("Background/Sprite2D") as Sprite2D
	if ground == null:
		return
	var shader := Shader.new()
	shader.code = GROUND_SHADER
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("shade_noise", _make_noise_texture(13, 0.01, 2))
	ground.material = material


## Glowing embers drifting up and wavering as they cool. Embers stay put in the world while the emitter
## follows the camera.
func _build_embers(view: Vector2) -> CPUParticles2D:
	var particles := CPUParticles2D.new()
	particles.texture = _make_dot_texture()
	particles.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	particles.amount = 70
	particles.lifetime = 6.0
	particles.preprocess = 6.0
	particles.local_coords = false
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = view * Vector2(0.7, 0.4)
	particles.direction = Vector2(0.1, -1.0)
	particles.spread = 18.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 25.0
	particles.initial_velocity_max = 60.0
	particles.tangential_accel_min = -10.0
	particles.tangential_accel_max = 10.0
	particles.scale_amount_min = 1.0
	particles.scale_amount_max = 2.5
	var colors := Gradient.new()
	colors.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	colors.colors = PackedColorArray([Color("#fff1a8"), Color("#ff8a2a"), Color("#d9381e")])
	particles.color_initial_ramp = colors
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.1, 0.7, 1.0])
	fade.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 0.6, 0.4, 0.7), Color(0.6, 0.2, 0.1, 0)])
	particles.color_ramp = fade
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	particles.material = additive
	add_child(particles)
	return particles


## Grey ash flakes settling slowly.
func _build_ash(view: Vector2) -> CPUParticles2D:
	var particles := CPUParticles2D.new()
	particles.texture = _make_dot_texture()
	particles.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	particles.amount = 60
	particles.lifetime = 8.0
	particles.preprocess = 8.0
	particles.local_coords = false
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = view * Vector2(0.7, 0.6)
	particles.direction = Vector2(-0.3, 1.0)
	particles.spread = 15.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 12.0
	particles.initial_velocity_max = 30.0
	particles.tangential_accel_min = -5.0
	particles.tangential_accel_max = 5.0
	particles.scale_amount_min = 1.0
	particles.scale_amount_max = 2.0
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.15, 0.85, 1.0])
	fade.colors = PackedColorArray([Color(0.6, 0.56, 0.55, 0), Color(0.6, 0.56, 0.55, 0.55), Color(0.5, 0.46, 0.45, 0.45), Color(0.5, 0.46, 0.45, 0)])
	particles.color_ramp = fade
	add_child(particles)
	return particles


## Brief sparks flaring up out of cracks in the ground.
func _build_ground_sparks(view: Vector2) -> CPUParticles2D:
	var particles := CPUParticles2D.new()
	particles.texture = _make_dot_texture()
	particles.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	particles.amount = 20
	particles.lifetime = 0.8
	particles.local_coords = false
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = view * 0.5
	particles.direction = Vector2(0.0, -1.0)
	particles.spread = 25.0
	particles.gravity = Vector2(0.0, 60.0)
	particles.initial_velocity_min = 20.0
	particles.initial_velocity_max = 50.0
	particles.scale_amount_min = 1.0
	particles.scale_amount_max = 2.0
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.3, 1.0])
	fade.colors = PackedColorArray([Color("#fff1a8"), Color("#ff8a2a"), Color(0.85, 0.2, 0.05, 0.0)])
	particles.color_ramp = fade
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	particles.material = additive
	# On the ground, under characters and props.
	particles.z_index = -25
	add_child(particles)
	return particles


func _make_dot_texture() -> ImageTexture:
	var image := Image.create_empty(2, 2, false, Image.FORMAT_RGBA8)
	image.fill(Color(1, 1, 1, 1))
	image.set_pixel(1, 1, Color(1, 1, 1, 0.7))
	return ImageTexture.create_from_image(image)
