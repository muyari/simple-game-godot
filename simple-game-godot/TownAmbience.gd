extends Node2D
class_name TownAmbience
## Oblath on a fine day: warm sunlight, cloud shadows drifting slowly over the rooftops, a soft vignette,
## pollen floating in the air, sparkles on the fountain and birds now and then flying over, their
## shadows sweeping across the ground. Purely cosmetic.

const TINT := Color(1.0, 0.98, 0.93)
const BIRD_INTERVAL := Vector2(7.0, 14.0)
const SKY_SHADER := """
shader_type canvas_item;
render_mode blend_premul_alpha, unshaded;

uniform sampler2D noise_texture : repeat_enable, filter_linear;
uniform vec2 world_offset;
uniform vec2 aspect = vec2(1.7778, 1.0);
uniform float cloud_strength = 0.16;
uniform vec4 cloud_color : source_color = vec4(0.08, 0.12, 0.2, 1.0);
uniform vec4 sun_color : source_color = vec4(1.0, 0.86, 0.55, 1.0);
uniform float sun_strength = 0.06;
uniform float vignette_strength = 0.28;

void fragment() {
	// Cloud shadows, anchored to the world and drifting slowly east.
	vec2 world_uv = (UV + world_offset) * aspect;
	vec2 drift = vec2(TIME * 0.012, TIME * 0.004);
	float n = texture(noise_texture, world_uv * 0.28 - drift).r * 0.65 + texture(noise_texture, world_uv * 0.6 - drift * 1.4).r * 0.35;
	float cloud = smoothstep(0.52, 0.7, n) * cloud_strength;
	// Warm sun from the top left, and soft darkening at the edges.
	float sun = (1.0 - smoothstep(0.0, 1.3, length(UV - vec2(0.1, -0.1)))) * sun_strength;
	float vignette = smoothstep(0.55, 1.25, length((UV - 0.5) * vec2(1.8, 2.0))) * vignette_strength;
	vec3 color = cloud_color.rgb * cloud + sun_color.rgb * sun;
	COLOR = vec4(color, clamp(cloud + sun * 0.5 + vignette, 0.0, 1.0));
}
"""

var player: Player
var camera: Camera2D
var sky_material: ShaderMaterial
var pollen: CPUParticles2D
var bird_timer := 3.0


func _ready() -> void:
	player = get_parent().get_node_or_null("Player") as Player
	camera = player.get_node_or_null("Camera2D") as Camera2D if player != null else null
	if camera == null:
		push_error("TownAmbience needs the town's Player with a Camera2D.")
		set_process(false)
		return
	var canvas_tint := CanvasModulate.new()
	canvas_tint.color = TINT
	add_child(canvas_tint)
	_build_sky_layer()
	pollen = _build_pollen(get_viewport_rect().size)
	var fountain := get_parent().get_node_or_null("Fountain") as Node2D
	if fountain != null:
		_build_fountain_sparkle(fountain.global_position + Vector2(0.0, -50.0))
	z_index = 20
	_process(0.0)


func _process(delta: float) -> void:
	var view_center := camera.get_screen_center_position()
	var view_size := get_viewport_rect().size / camera.zoom
	pollen.global_position = view_center
	sky_material.set_shader_parameter("world_offset", (view_center - view_size * 0.5) / view_size)
	bird_timer -= delta
	if bird_timer <= 0.0:
		bird_timer = randf_range(BIRD_INTERVAL.x, BIRD_INTERVAL.y)
		_launch_flock(view_center, view_size)


func _build_sky_layer() -> void:
	var shader := Shader.new()
	shader.code = SKY_SHADER
	sky_material = ShaderMaterial.new()
	sky_material.shader = shader
	var noise := FastNoiseLite.new()
	noise.seed = 4
	noise.frequency = 0.012
	noise.fractal_octaves = 3
	var noise_texture := NoiseTexture2D.new()
	noise_texture.width = 256
	noise_texture.height = 256
	noise_texture.seamless = true
	noise_texture.noise = noise
	sky_material.set_shader_parameter("noise_texture", noise_texture)
	var view_size := get_viewport_rect().size
	sky_material.set_shader_parameter("aspect", Vector2(view_size.x / view_size.y, 1.0))
	# Between the world and the HUD, so the HUD moves up a layer.
	var layer := CanvasLayer.new()
	layer.layer = 1
	var ui := get_parent().get_node_or_null("TownUI") as CanvasLayer
	if ui != null and ui.layer <= layer.layer:
		ui.layer = layer.layer + 1
	var sky := ColorRect.new()
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.material = sky_material
	layer.add_child(sky)
	add_child(layer)


func _build_pollen(view: Vector2) -> CPUParticles2D:
	var particles := CPUParticles2D.new()
	particles.texture = _dot_texture()
	particles.amount = 40
	particles.lifetime = 7.0
	particles.preprocess = 7.0
	particles.local_coords = false
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = view * 0.6
	particles.direction = Vector2(1.0, -0.2)
	particles.spread = 40.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 6.0
	particles.initial_velocity_max = 16.0
	particles.tangential_accel_min = -4.0
	particles.tangential_accel_max = 4.0
	particles.scale_amount_min = 1.0
	particles.scale_amount_max = 2.0
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.2, 0.8, 1.0])
	fade.colors = PackedColorArray([Color(1, 0.97, 0.8, 0), Color(1, 0.97, 0.8, 0.7), Color(1, 0.97, 0.8, 0.6), Color(1, 0.97, 0.8, 0)])
	particles.color_ramp = fade
	add_child(particles)
	return particles


func _build_fountain_sparkle(spot: Vector2) -> void:
	var sparkle := CPUParticles2D.new()
	sparkle.texture = _dot_texture()
	sparkle.position = spot
	sparkle.amount = 18
	sparkle.lifetime = 0.9
	sparkle.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	sparkle.emission_sphere_radius = 6.0
	sparkle.direction = Vector2.UP
	sparkle.spread = 50.0
	sparkle.gravity = Vector2(0.0, 160.0)
	sparkle.initial_velocity_min = 40.0
	sparkle.initial_velocity_max = 70.0
	sparkle.scale_amount_min = 1.0
	sparkle.scale_amount_max = 2.0
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.6, 1.0])
	fade.colors = PackedColorArray([Color(0.9, 0.97, 1.0, 0.9), Color(0.7, 0.88, 1.0, 0.7), Color(0.6, 0.8, 1.0, 0.0)])
	sparkle.color_ramp = fade
	sparkle.z_index = 2
	get_parent().add_child.call_deferred(sparkle)


## A small flock crossing the view, with their shadows far below them on the ground.
func _launch_flock(view_center: Vector2, view_size: Vector2) -> void:
	var from_left := randf() < 0.5
	var start := view_center + Vector2((-0.65 if from_left else 0.65) * view_size.x, randf_range(-0.4, 0.2) * view_size.y)
	var direction := Vector2(1.0 if from_left else -1.0, randf_range(-0.15, 0.15)).normalized()
	for index in randi_range(3, 5):
		var bird := Bird.new()
		bird.direction = direction
		bird.position = start + Vector2(-direction.x * index * 22.0, (index % 2) * 14.0 - index * 4.0)
		bird.phase = randf() * TAU
		get_parent().add_child(bird)


func _dot_texture() -> ImageTexture:
	var image := Image.create_empty(2, 2, false, Image.FORMAT_RGBA8)
	image.fill(Color(1, 1, 1, 1))
	return ImageTexture.create_from_image(image)


## A bird gliding across the sky: drawn high above the town, its shadow on the ground below.
class Bird extends Node2D:
	const SPEED := 150.0
	const ALTITUDE := 140.0
	const LIFETIME := 14.0
	var direction := Vector2.RIGHT
	var phase := 0.0
	var time := 0.0

	func _ready() -> void:
		z_index = 30
		z_as_relative = false

	func _process(delta: float) -> void:
		time += delta
		position += direction * SPEED * delta
		if time > LIFETIME:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var flap := sin(time * 9.0 + phase) * 4.0
		var wing := PackedVector2Array([Vector2(-9, -flap), Vector2(0, 0), Vector2(9, -flap)])
		# Shadow first, far below on the ground.
		draw_polyline(_offset(wing, Vector2(30, ALTITUDE)), Color(0, 0, 0, 0.12), 3.0, true)
		draw_polyline(wing, Color("#2b2420"), 2.0, true)

	func _offset(points: PackedVector2Array, by: Vector2) -> PackedVector2Array:
		var moved := PackedVector2Array()
		for point in points:
			moved.append(point + by)
		return moved
