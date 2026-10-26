extends Node2D
class_name HubDecor
## Shared building blocks for dressing a regional hub (Saltwind Camp, Rimehollow, Ashgate Outpost): ground
## painted by hub_ground.gdshader, standing sprites from the level art, drawn HubProps, HubFolk, and a ring
## of scenery round the hub's edge. Each hub's script lays itself out in build(). Everything is seeded, so
## a hub looks the same on every visit, and every sprite is drawn smooth like the town.

const GROUND_SHADER = preload("res://hub_ground.gdshader")

## The walkable area, in world pixels; matches the scene's boundary walls.
@export var bounds := Rect2(-100, -60, 1400, 1000)
## Shadows cast on this hub's ground.
@export var shadow_color := Color(0.36, 0.18, 0.05, 0.4)

var random := RandomNumberGenerator.new()
var level: Node
var player: Node2D
## Footprints already taken by solid scenery (centre, half size), so scattered pieces don't overlap them.
var taken: Array[Rect2] = []


func _ready() -> void:
	level = get_parent()
	player = level.get_node_or_null("Player") as Node2D
	random.seed = 4242
	z_index = -9
	SmoothArt.watch(get_tree(), level)
	SmoothArt.apply.call_deferred(level)
	build()


## Overridden by each hub to lay itself out.
func build() -> void:
	pass


# --- Ground --------------------------------------------------------------------------------------------

func ground_material(mode: int) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = GROUND_SHADER
	material.set_shader_parameter("mode", mode)
	material.set_shader_parameter("noise_texture", TownStreets.noise())
	return material


## Paints the scene's Ground polygon in `mode`.
func paint_ground(mode: int) -> void:
	var ground := level.get_node_or_null("Ground") as Polygon2D
	if ground != null:
		ground.material = ground_material(mode)


## A patch of ground in another mode, with softly wobbling edges.
func patch(center: Vector2, size: Vector2, mode: int, z := -8, wobble := 0.12) -> Polygon2D:
	var points := PackedVector2Array()
	var steps := 40
	var offset := random.randf() * TAU
	for index in steps:
		var angle := TAU * index / steps
		var r := 1.0 + wobble * sin(angle * 3.0 + offset) + wobble * 0.5 * sin(angle * 7.0 + offset * 2.0)
		points.append(center + Vector2(cos(angle) * size.x, sin(angle) * size.y) * r)
	return _ground_polygon(points, mode, z)


## A trail of ground in another mode along `points`, `width` wide, with rounded joints.
func trail(points: PackedVector2Array, width: float, mode: int, z := -8) -> void:
	for index in points.size() - 1:
		var from := points[index]
		var to := points[index + 1]
		var side := (to - from).normalized().orthogonal() * width * 0.5
		_ground_polygon(PackedVector2Array([from + side, to + side, to - side, from - side]), mode, z)
	for point in points:
		patch(point, Vector2(width * 0.5, width * 0.5), mode, z, 0.0)


func _ground_polygon(points: PackedVector2Array, mode: int, z: int) -> Polygon2D:
	var polygon := Polygon2D.new()
	polygon.polygon = points
	polygon.antialiased = true
	polygon.material = ground_material(mode)
	polygon.z_index = z
	level.add_child.call_deferred(polygon)
	return polygon


# --- Standing art --------------------------------------------------------------------------------------

func sprite(texture: Texture2D, scale_factor: float, flip := false) -> Sprite2D:
	var item := Sprite2D.new()
	item.texture = texture
	item.scale = Vector2.ONE * scale_factor
	item.flip_h = flip
	item.offset = Vector2(0.0, -texture.get_height() * 0.5)
	return item


## A standing sprite with its base at `base`, y-sorted with everything else.
func place(texture: Texture2D, base: Vector2, scale_factor: float, flip := false, shadow := true) -> Sprite2D:
	var item := sprite(texture, scale_factor, flip)
	item.position = base
	if shadow:
		SunShadow.attach(item, Vector2(0.0, -2.0), texture.get_width() * 0.9, true, shadow_color)
	level.add_child.call_deferred(item)
	return item


## A standing sprite that blocks movement with a circle at its base.
func solid(texture: Texture2D, base: Vector2, scale_factor: float, radius: float, flip := false) -> StaticBody2D:
	var body := _body(base)
	var item := sprite(texture, scale_factor, flip)
	SunShadow.attach(item, Vector2(0.0, -2.0), texture.get_width() * 0.9, true, shadow_color)
	body.add_child(item)
	_circle_shape(body, radius)
	level.add_child.call_deferred(body)
	return body


## One frame of a monster atlas (cells of `cell` pixels), standing on `base`: trophies, carcasses, the
## frozen and the dead.
func monster_frame(texture: Texture2D, cell: Vector2i, frame: Vector2i, base: Vector2, scale_factor: float, flip := false) -> Sprite2D:
	var item := Sprite2D.new()
	item.texture = texture
	item.region_enabled = true
	item.region_rect = Rect2(Vector2(frame * cell), Vector2(cell))
	item.scale = Vector2.ONE * scale_factor
	item.flip_h = flip
	item.offset = Vector2(0.0, -cell.y * 0.5 + 2.0)
	item.position = base
	return item


## A drawn prop, optionally solid: a circle of `radius`, or a box of `box` (size, resting on the base).
## A float "scale" in `settings` sizes the prop and its collision together.
func prop(kind: HubProp.Kind, base: Vector2, settings := {}, radius := 0.0, box := Vector2.ZERO) -> HubProp:
	var item := HubProp.new()
	item.kind = kind
	for key in settings:
		if key == "scale" and settings[key] is float:
			item.scale = Vector2.ONE * settings[key]
			radius *= settings[key]
			box *= settings[key]
		else:
			item.set(key, settings[key])
	if radius <= 0.0 and box == Vector2.ZERO:
		item.position = base
		level.add_child.call_deferred(item)
		return item
	var body := _body(base)
	body.add_child(item)
	if box != Vector2.ZERO:
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = box
		shape.shape = rect
		shape.position = Vector2(0.0, -box.y * 0.5)
		body.add_child(shape)
		taken.append(Rect2(base - Vector2(box.x * 0.5, box.y), box))
	else:
		_circle_shape(body, radius)
	level.add_child.call_deferred(body)
	return item


## A resident of the hub. `settings` sets HubFolk's fields (display_name, lines, clothes, headwear...).
func folk(base: Vector2, settings := {}, parent: Node = null) -> HubFolk:
	var person := HubFolk.new()
	for key in settings:
		if key == "lines":
			person.lines.assign(settings[key])
		else:
			person.set(key, settings[key])
	person.position = base
	(parent if parent != null else level).add_child.call_deferred(person)
	return person


func _body(base: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_mask = 0
	body.position = base
	return body


func _circle_shape(body: StaticBody2D, radius: float) -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	shape.position = Vector2(0.0, -radius * 0.4)
	body.add_child(shape)
	taken.append(Rect2(body.position - Vector2(radius, radius * 1.4), Vector2(radius * 2.0, radius * 1.8)))


# --- Scatter -------------------------------------------------------------------------------------------

## Fills the band outside `bounds` (out to `reach`) with `pieces`, denser further out, so the hub is
## ringed by its region rather than an edge. Each piece is {texture, scale: Vector2(min, max)}.
func ring(pieces: Array, reach: float, spacing: float, inner_chance := 0.55, keep_clear: Array[Rect2] = []) -> void:
	var outer := bounds.grow(reach)
	var y := outer.position.y
	while y < outer.end.y:
		var x := outer.position.x
		while x < outer.end.x:
			var spot := Vector2(x, y) + Vector2(random.randf_range(-0.4, 0.4), random.randf_range(-0.4, 0.4)) * spacing
			var distance := distance_outside(spot)
			if distance > 6.0 and not keep_clear.any(func(area: Rect2) -> bool: return area.has_point(spot)) and random.randf() < clampf(inner_chance + distance / reach, 0.0, 0.95):
				var piece: Dictionary = pieces[random.randi() % pieces.size()]
				var scale_range: Vector2 = piece.get("scale", Vector2.ONE)
				place(piece["texture"], spot, random.randf_range(scale_range.x, scale_range.y), random.randf() < 0.5)
			x += spacing
		y += spacing * 0.75


## Scatters `count` small pieces inside the hub, away from anything solid and from `keep_clear`.
func scatter(pieces: Array, count: int, keep_clear: Array[Rect2] = [], shadow := false) -> void:
	var placed := 0
	var attempts := 0
	while placed < count and attempts < count * 12:
		attempts += 1
		var spot := Vector2(random.randf_range(bounds.position.x + 20, bounds.end.x - 20), random.randf_range(bounds.position.y + 30, bounds.end.y - 10))
		if keep_clear.any(func(area: Rect2) -> bool: return area.has_point(spot)):
			continue
		if taken.any(func(area: Rect2) -> bool: return area.grow(14.0).has_point(spot)):
			continue
		var piece: Dictionary = pieces[random.randi() % pieces.size()]
		var scale_range: Vector2 = piece.get("scale", Vector2.ONE)
		place(piece["texture"], spot, random.randf_range(scale_range.x, scale_range.y), random.randf() < 0.5, shadow)
		placed += 1


## How far `point` lies outside the walkable bounds; negative inside.
func distance_outside(point: Vector2) -> float:
	var dx := maxf(bounds.position.x - point.x, point.x - bounds.end.x)
	var dy := maxf(bounds.position.y - point.y, point.y - bounds.end.y)
	if dx <= 0.0 and dy <= 0.0:
		return -1.0
	return Vector2(maxf(dx, 0.0), maxf(dy, 0.0)).length()


## A slow column of smoke rising from `top`, for fires and the smouldering outpost.
func smoke(top: Vector2, amount := 10, dark := false) -> void:
	var particles := CPUParticles2D.new()
	particles.position = top
	particles.amount = amount
	particles.lifetime = 4.0
	particles.preprocess = 4.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 4.0
	particles.direction = Vector2(0.3, -1.0)
	particles.spread = 12.0
	particles.gravity = Vector2(5.0, -4.0)
	particles.initial_velocity_min = 12.0
	particles.initial_velocity_max = 20.0
	particles.scale_amount_min = 5.0
	particles.scale_amount_max = 9.0
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 0.4))
	grow.add_point(Vector2(1.0, 2.0))
	particles.scale_amount_curve = grow
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.15, 1.0])
	var tone := Color(0.18, 0.15, 0.14) if dark else Color(0.82, 0.8, 0.78)
	fade.colors = PackedColorArray([Color(tone, 0.0), Color(tone, 0.5), Color(tone, 0.0)])
	particles.color_ramp = fade
	particles.texture = _soft_dot()
	particles.z_index = 6
	level.add_child.call_deferred(particles)


static var _dot: ImageTexture


func _soft_dot() -> ImageTexture:
	if _dot == null:
		var image := Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
		for y in 16:
			for x in 16:
				var d := Vector2(x - 7.5, y - 7.5).length() / 8.0
				image.set_pixel(x, y, Color(1, 1, 1, clampf(1.0 - d, 0.0, 1.0)))
		_dot = ImageTexture.create_from_image(image)
	return _dot
