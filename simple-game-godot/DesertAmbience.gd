extends Node2D
class_name DesertAmbience
## Desert atmosphere: a sun-bleached tint, slow light and dark swells over the sand, drifting dust and cloud
## shadows with sun glare and a hot vignette, gusts of blowing sand, tumbleweeds rolling across the dunes,
## lizards darting about and vulture shadows circling overhead. Purely cosmetic.

const TINT := Color(1.0, 0.95, 0.87)
const TUMBLEWEED_TEXTURES: Array[Texture2D] = [
	preload("res://textures/desert_tumbleweed_large.png"),
	preload("res://textures/desert_tumbleweed_small.png"),
]
const TUMBLEWEED_COUNT := 2
const TUMBLEWEED_SCALE := Vector2(0.32, 0.42)
const TUMBLEWEED_SPEED := Vector2(70.0, 120.0)
const VULTURE_COUNT := 2
const VULTURE_CIRCLE_RADIUS := Vector2(160.0, 260.0)
## Seconds between the strongest gusts of wind.
const GUST_PERIOD := 9.0
const LIZARD_COUNT := 3
## Lizards further than this from the camera are moved to a fresh spot near it.
const LIZARD_RANGE := 1000.0
## Large, slow light and dark swells over the sand, anchored to the world, so the ripple tile never
## reads as a repeating pattern.
const GROUND_SHADER := """
shader_type canvas_item;

uniform sampler2D shade_noise : repeat_enable, filter_linear;
uniform float shade_scale = 0.0005;
uniform float shade_strength = 0.1;
varying vec2 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	// COLOR arrives as the sampled sand times the sprite modulate.
	vec4 sand = COLOR;
	float broad = texture(shade_noise, world_position * shade_scale).r;
	float fine = texture(shade_noise, world_position * shade_scale * 2.7 + vec2(0.37, 0.71)).r;
	float shade = (broad * 0.7 + fine * 0.3 - 0.5) * 2.0;
	sand.rgb *= 1.0 + shade * shade_strength;
	// Hollows lean a little more orange than the sunlit crests.
	sand.rgb = mix(sand.rgb, sand.rgb * vec3(1.03, 0.95, 0.86), clamp(-shade, 0.0, 1.0) * 0.6);
	COLOR = sand;
}
"""
const HAZE_SHADER := """
shader_type canvas_item;
render_mode blend_premul_alpha, unshaded;

uniform sampler2D noise_texture : repeat_enable, filter_linear;
uniform vec2 world_offset;
uniform vec2 aspect = vec2(1.7778, 1.0);
uniform vec4 dust_color : source_color = vec4(0.96, 0.82, 0.58, 1.0);
uniform float dust_strength = 0.16;
uniform vec4 glare_color : source_color = vec4(1.0, 0.93, 0.7, 1.0);
uniform float glare_strength = 0.2;
uniform float vignette_strength = 0.46;
uniform vec4 cloud_color : source_color = vec4(0.32, 0.17, 0.05, 1.0);
uniform float cloud_strength = 0.2;

void fragment() {
	// Dust is anchored to the world and blown along by the wind.
	vec2 world_uv = (UV + world_offset) * aspect;
	float drift = TIME * 0.03;
	float n1 = texture(noise_texture, world_uv * vec2(0.25, 0.5) + vec2(-drift, drift * 0.15)).r;
	float n2 = texture(noise_texture, world_uv * vec2(0.6, 1.2) + vec2(-drift * 1.7, 0.0)).r;
	float dust = smoothstep(0.45, 0.85, n1 * 0.6 + n2 * 0.4) * dust_strength;

	// Harsh sun from the top-right corner, slowly pulsing like heat off the sand.
	float sun = 1.0 - smoothstep(0.0, 0.95, length((UV - vec2(0.92, -0.1)) * vec2(aspect.x * 0.6, 1.0)));
	float glare = sun * sun * glare_strength * (0.9 + 0.1 * sin(TIME * 0.7));

	float vignette = smoothstep(0.55, 1.25, length((UV - 0.5) * vec2(1.9, 2.1))) * vignette_strength;

	// Shadows of high clouds sliding slowly across the dunes.
	float c = texture(noise_texture, world_uv * 0.09 + vec2(-TIME * 0.006, TIME * 0.002)).r;
	float cloud = smoothstep(0.56, 0.72, c) * cloud_strength;

	vec3 color = dust_color.rgb * dust + glare_color.rgb * glare + vec3(0.1, 0.04, 0.0) * vignette + cloud_color.rgb * cloud;
	COLOR = vec4(color, clamp(dust + glare * 0.25 + vignette + cloud, 0.0, 1.0));
}
"""

var player: Player
var camera: Camera2D
var canvas_tint: CanvasModulate
var haze_layer: CanvasLayer
var haze_material: ShaderMaterial
var sand: CPUParticles2D
var tumbleweeds: Array[Node2D] = []
var tumbleweed_speeds: Array[float] = []
var vultures: Array[Sprite2D] = []
var vulture_center := Vector2.ZERO
var lizards: Array[DesertLizard] = []
var elapsed := 0.0


func _ready() -> void:
	player = get_parent().get_node_or_null("Player") as Player
	camera = player.get_node_or_null("Camera2D") as Camera2D if player != null else null
	if camera == null:
		push_error("DesertAmbience needs the level's Player with a Camera2D.")
		set_process(false)
		return

	canvas_tint = CanvasModulate.new()
	canvas_tint.color = TINT
	add_child(canvas_tint)
	_build_haze_layer()
	_shade_ground()
	sand = _build_blowing_sand()
	z_index = 20
	_process(0.0)


func _process(delta: float) -> void:
	elapsed += delta
	var view_center := camera.get_screen_center_position()
	var view_size := get_viewport_rect().size / camera.zoom
	sand.global_position = view_center + Vector2(-view_size.x * 0.25, 0.0)
	# Wind rises and falls so the sand comes in gusts.
	sand.speed_scale = 0.75 + 0.55 * maxf(sin(elapsed * TAU / GUST_PERIOD), 0.0)
	haze_material.set_shader_parameter("world_offset", (view_center - view_size * 0.5) / view_size)
	_roll_tumbleweeds(delta, view_center, view_size)
	_circle_vultures(view_center)
	_keep_lizards_near(view_center, view_size)


## Underground (in the Sunken Vault) there's no sky: a dim tint, and no haze, blowing sand, tumbleweeds,
## vultures or lizards.
func set_underground(underground: bool, tint := TINT) -> void:
	canvas_tint.color = tint if underground else TINT
	haze_layer.visible = not underground
	sand.visible = not underground
	for group: Array in [tumbleweeds, vultures, lizards]:
		for drifter: CanvasItem in group:
			drifter.visible = not underground
			drifter.process_mode = Node.PROCESS_MODE_DISABLED if underground else Node.PROCESS_MODE_INHERIT
	set_process(not underground)


func _build_haze_layer() -> void:
	var noise := FastNoiseLite.new()
	noise.seed = 3
	noise.frequency = 0.014
	noise.fractal_octaves = 3
	var noise_texture := NoiseTexture2D.new()
	noise_texture.width = 256
	noise_texture.height = 256
	noise_texture.seamless = true
	noise_texture.noise = noise

	var shader := Shader.new()
	shader.code = HAZE_SHADER
	haze_material = ShaderMaterial.new()
	haze_material.shader = shader
	haze_material.set_shader_parameter("noise_texture", noise_texture)
	var view_size := get_viewport_rect().size
	haze_material.set_shader_parameter("aspect", Vector2(view_size.x / view_size.y, 1.0))

	# Sits between the world and the HUD, so the HUD moves up a layer.
	haze_layer = CanvasLayer.new()
	haze_layer.layer = 1
	var ui := get_parent().get_node_or_null("UI") as CanvasLayer
	if ui != null and ui.layer <= haze_layer.layer:
		ui.layer = haze_layer.layer + 1
	var haze := ColorRect.new()
	haze.mouse_filter = Control.MOUSE_FILTER_IGNORE
	haze.set_anchors_preset(Control.PRESET_FULL_RECT)
	haze.material = haze_material
	haze_layer.add_child(haze)
	add_child(haze_layer)


func _build_blowing_sand() -> CPUParticles2D:
	var particles := CPUParticles2D.new()
	particles.texture = _make_grain_texture()
	particles.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	particles.amount = 70
	particles.lifetime = 3.5
	particles.preprocess = 3.5
	# Grains stay put in the world while the emitter follows the camera.
	particles.local_coords = false
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = get_viewport_rect().size * Vector2(0.45, 0.6)
	particles.direction = Vector2(1, 0.12)
	particles.spread = 8.0
	particles.gravity = Vector2(0, 6)
	particles.initial_velocity_min = 120.0
	particles.initial_velocity_max = 220.0
	particles.scale_amount_min = 1.0
	particles.scale_amount_max = 2.0
	var colors := Gradient.new()
	colors.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	colors.colors = PackedColorArray([Color("#f3d79a"), Color("#d9ae6a"), Color("#b98a4c")])
	particles.color_initial_ramp = colors
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.15, 0.75, 1.0])
	fade.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 0.8), Color(1, 1, 1, 0.6), Color(1, 1, 1, 0)])
	particles.color_ramp = fade
	add_child(particles)
	return particles


func _make_grain_texture() -> ImageTexture:
	var image := Image.create_empty(3, 1, false, Image.FORMAT_RGBA8)
	image.set_pixel(0, 0, Color(1, 1, 1, 0.45))
	image.set_pixel(1, 0, Color(1, 1, 1, 1))
	image.set_pixel(2, 0, Color(1, 1, 1, 0.45))
	return ImageTexture.create_from_image(image)


## Soft dark bird silhouette, wings spread, used as a shadow on the sand.
func _make_vulture_texture() -> ImageTexture:
	var shape := [
		"...........##...........",
		"..........####..........",
		"####.....######.....####",
		".######.########.######.",
		"...##################...",
		".....##############.....",
		"........###..###........",
		".........#....#.........",
	]
	var image := Image.create_empty(24, 8, false, Image.FORMAT_RGBA8)
	for y in shape.size():
		for x in 24:
			if shape[y][x] == "#":
				image.set_pixel(x, y, Color(0.18, 0.1, 0.04, 1))
	return ImageTexture.create_from_image(image)


func _roll_tumbleweeds(delta: float, view_center: Vector2, view_size: Vector2) -> void:
	if tumbleweeds.is_empty():
		for index in TUMBLEWEED_COUNT:
			var tumbleweed := Node2D.new()
			var shadow := Sprite2D.new()
			shadow.texture = _make_shadow_texture()
			shadow.position = Vector2(0, 2)
			tumbleweed.add_child(shadow)
			var sprite := Sprite2D.new()
			sprite.name = "Weed"
			sprite.texture = TUMBLEWEED_TEXTURES[index % TUMBLEWEED_TEXTURES.size()]
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			var weed_scale := randf_range(TUMBLEWEED_SCALE.x, TUMBLEWEED_SCALE.y)
			sprite.scale = Vector2.ONE * weed_scale
			tumbleweed.add_child(sprite)
			tumbleweed.position = view_center + Vector2(
				randf_range(-0.4, 0.4) * view_size.x,
				randf_range(-0.35, 0.35) * view_size.y
			)
			tumbleweeds.append(tumbleweed)
			tumbleweed_speeds.append(randf_range(TUMBLEWEED_SPEED.x, TUMBLEWEED_SPEED.y))
			get_parent().add_child.call_deferred(tumbleweed)
		return

	var gust := sand.speed_scale
	for index in tumbleweeds.size():
		var tumbleweed := tumbleweeds[index]
		if not tumbleweed.is_inside_tree():
			continue
		var speed := tumbleweed_speeds[index] * gust
		tumbleweed.position.x += speed * delta
		var weed := tumbleweed.get_node("Weed") as Sprite2D
		var radius := weed.texture.get_height() * weed.scale.y * 0.5
		weed.rotation += speed * delta / radius
		# Bounces along, hopping higher in a gust.
		weed.position.y = -radius - absf(sin(elapsed * 4.0 + index * 1.7)) * 10.0 * gust
		var half := view_size * 0.5
		var offset := tumbleweed.position - view_center
		if offset.x > half.x + 80.0 or absf(offset.x) > view_size.x * 1.5 or absf(offset.y) > view_size.y:
			tumbleweed.position = view_center + Vector2(
				-half.x - 60.0,
				randf_range(-0.4, 0.4) * view_size.y
			)
			tumbleweed_speeds[index] = randf_range(TUMBLEWEED_SPEED.x, TUMBLEWEED_SPEED.y)


func _make_shadow_texture() -> ImageTexture:
	var image := Image.create_empty(16, 5, false, Image.FORMAT_RGBA8)
	for y in 5:
		for x in 16:
			var distance := Vector2((x - 7.5) / 8.0, (y - 2.0) / 2.5).length()
			if distance < 1.0:
				image.set_pixel(x, y, Color(0.2, 0.12, 0.05, 0.28 * (1.0 - distance * 0.5)))
	return ImageTexture.create_from_image(image)


func _circle_vultures(view_center: Vector2) -> void:
	if vultures.is_empty():
		vulture_center = view_center
		var texture := _make_vulture_texture()
		for index in VULTURE_COUNT:
			var vulture := Sprite2D.new()
			vulture.texture = texture
			vulture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			vulture.scale = Vector2.ONE * (2.4 - index * 0.4)
			vulture.modulate.a = 0.22
			# On the ground, under characters and props.
			vulture.z_index = -5
			vulture.z_as_relative = false
			vultures.append(vulture)
			get_parent().add_child.call_deferred(vulture)
		return

	# The circle drifts after the player so the birds stay overhead.
	vulture_center = vulture_center.lerp(view_center, 0.004)
	for index in vultures.size():
		var radius := lerpf(VULTURE_CIRCLE_RADIUS.x, VULTURE_CIRCLE_RADIUS.y, float(index) / maxf(VULTURE_COUNT - 1, 1))
		var angle := elapsed * (0.22 - index * 0.05) + index * PI
		var vulture := vultures[index]
		vulture.position = vulture_center + Vector2(cos(angle), sin(angle) * 0.6) * radius
		# The art's head points up; turn it along the direction of flight.
		var heading := Vector2(-sin(angle), cos(angle) * 0.6)
		vulture.rotation = heading.angle() + PI * 0.5


func _shade_ground() -> void:
	var ground := get_parent().get_node_or_null("Background/Sprite2D") as Sprite2D
	if ground == null:
		return
	var noise := FastNoiseLite.new()
	noise.seed = 17
	noise.frequency = 0.01
	noise.fractal_octaves = 2
	var noise_texture := NoiseTexture2D.new()
	noise_texture.width = 256
	noise_texture.height = 256
	noise_texture.seamless = true
	noise_texture.noise = noise
	var shader := Shader.new()
	shader.code = GROUND_SHADER
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("shade_noise", noise_texture)
	ground.material = material


func _keep_lizards_near(view_center: Vector2, view_size: Vector2) -> void:
	if lizards.is_empty():
		for _index in LIZARD_COUNT:
			var lizard := DesertLizard.new()
			lizard.player = player
			lizard.position = _random_spot(view_center, view_size, true)
			lizards.append(lizard)
			get_parent().add_child.call_deferred(lizard)
		return
	for lizard in lizards:
		if not lizard.is_inside_tree():
			continue
		if lizard.global_position.distance_to(view_center) > LIZARD_RANGE:
			lizard.position = _random_spot(view_center, view_size, false)
			lizard.home = lizard.position


## A spot in view on the first spawn, otherwise just beyond the edge of the screen so lizards wander in.
func _random_spot(view_center: Vector2, view_size: Vector2, in_view: bool) -> Vector2:
	var half := view_size * 0.5
	if in_view:
		return view_center + Vector2(randf_range(-half.x, half.x), randf_range(-half.y, half.y)) * 0.85
	var angle := randf() * TAU
	return view_center + Vector2(cos(angle) * (half.x + 80.0), sin(angle) * (half.y + 60.0))
