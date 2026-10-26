extends Node2D
class_name TownDecor
## Builds Oblath around the streets, fence and the hand-placed buildings in town.tscn: rows of houses
## with front yards and smoking chimneys, the market by the plaza, lamp posts and benches, an orchard and
## vegetable gardens to the north, crop fields, a cow pasture and a pond to the south, villagers going
## about their day, and a meadow and forest ringing the fence. Draws soft meadow detail on the ground
## itself. Everything is seeded, so the town looks the same on every visit.

const FENCE := Rect2(-560, -420, 2272, 1600)
## Shadows on grass: cool and green-tinted rather than the desert's warm brown.
const GRASS_SHADOW := Color(0.05, 0.12, 0.04, 0.4)
const HOUSE_SCALE := 0.62
const FRONT_HOUSES: Array[Texture2D] = [
	preload("res://textures/town_house_1.png"),
	preload("res://textures/town_house_2.png"),
	preload("res://textures/town_house_3.png"),
]
const BACK_HOUSES: Array[Texture2D] = [
	preload("res://textures/town_house_back_1.png"),
	preload("res://textures/town_house_back_2.png"),
	preload("res://textures/town_house_back_3.png"),
]
## Houses facing the main street (base y 330) and the north lane (base y 50): [x, style, flip].
const ROW_MAIN := [[-430, 0, false], [-170, 2, false], [110, 1, true], [1045, 0, true], [1295, 1, false], [1545, 2, true]]
const ROW_LANE := [[-400, 1, false], [120, 0, false], [1020, 2, false], [1500, 0, true]]
## Back-view houses lining the south side of the main street (base y 615).
const ROW_SOUTH := [[-430, 0], [-150, 2], [1320, 1], [1580, 0]]
## Where house_1's chimney sits, as a fraction of the art (x from centre, y from the bottom).
const CHIMNEY := Vector2(0.27, 0.9)

const TREE_PINE = preload("res://textures/town_tree_pine.png")
const TREE_SPRUCE = preload("res://textures/town_tree_spruce.png")
const TREE_APPLE = preload("res://textures/town_apple_tree.png")
const TREE_OAK = preload("res://textures/forest_tree_oak.png")
const TREE_MAPLE = preload("res://textures/forest_tree_maple.png")
const TREE_TALL_PINE = preload("res://textures/forest_tree_pine_tall.png")
const TREE_CEDAR = preload("res://textures/forest_tree_cedar.png")
const SHRUBS: Array[Texture2D] = [
	preload("res://textures/town_shrub_green.png"),
	preload("res://textures/town_shrub_round.png"),
	preload("res://textures/town_shrub_autumn.png"),
	preload("res://textures/town_shrub_conifer.png"),
]
const FLOWERS = preload("res://textures/town_flowers.png")
const GRASS_CLUMP = preload("res://textures/town_grass_clump.png")
const FERN = preload("res://textures/town_fern.png")
const ROCKS_SMALL = preload("res://textures/town_rocks_small.png")
const ROCK_MOSSY = preload("res://textures/town_rock_mossy.png")
const LOG_PILE = preload("res://textures/town_log_pile.png")
const LOGS = preload("res://textures/town_logs.png")
const STUMP = preload("res://textures/town_stump.png")
const POND = preload("res://textures/forest_pond.svg")
const CRATES: Array[Texture2D] = [
	preload("res://textures/underworld_crate_a.png"),
	preload("res://textures/underworld_crate_b.png"),
	preload("res://textures/underworld_barrel_a.png"),
	preload("res://textures/underworld_barrel_b.png"),
]
const COW_WALK: Array[Texture2D] = [preload("res://textures/town_cow_walk_1.png"), preload("res://textures/town_cow_walk_2.png")]
const COW_GRAZE: Array[Texture2D] = [preload("res://textures/town_cow_graze.png")]
const CHICKEN_WALK: Array[Texture2D] = [
	preload("res://textures/town_chicken_walk_1.png"), preload("res://textures/town_chicken_walk_2.png"),
	preload("res://textures/town_chicken_walk_3.png"), preload("res://textures/town_chicken_walk_4.png"),
]
const CHICKEN_PECK: Array[Texture2D] = [
	preload("res://textures/town_chicken_peck_1.png"), preload("res://textures/town_chicken_peck_2.png"),
	preload("res://textures/town_chicken_peck_3.png"),
]
const ANIMAL_SCRIPT = preload("res://AnimalWander.gd")
## Where the reeve's notice board stands: on the verge of the main street, just east of the plaza.
const NOTICE_BOARD_SPOT := Vector2(812, 500)
const FOLK := {
	"mary": {"side_right": true},
	"gertrude": {"side_right": false},
	"sarah": {"side_right": true},
}

const BED_SOIL := Color("#5a3f26")
const BED_EDGE := Color("#3d2a19")

var random := RandomNumberGenerator.new()
var level: Node
var player: Node2D
## Flower beds, drawn on the ground in _draw.
var beds: Array[Rect2] = []


func _ready() -> void:
	level = get_parent()
	player = level.get_node_or_null("Player") as Node2D
	random.seed = 7331
	z_index = -9
	# Every sprite in town (the scene's, the ones built below and anything spawned later) is drawn smooth.
	var ground := level.get_node_or_null("Ground") as Polygon2D
	if ground != null:
		ground.material = _ground_material(0)
	SmoothArt.watch(get_tree(), level)
	SmoothArt.apply.call_deferred(level)
	_build_houses()
	_build_market()
	_build_street_furniture()
	_build_trees_and_greenery()
	_build_north()
	_build_south()
	_build_outside()
	_scatter_greenery()
	_build_folk()
	queue_redraw()


## Ground kept clear of scattered greenery: streets, the plaza, house plots, fields, the pasture and pond.
const BUSY_AREAS: Array[Rect2] = [
	Rect2(-570, 340, 2290, 120), Rect2(518, -430, 116, 670), Rect2(-550, 60, 2250, 72), Rect2(540, 440, 72, 750),
	Rect2(380, 210, 392, 380), Rect2(-560, 180, 2270, 165), Rect2(-560, -110, 2270, 175), Rect2(-560, 470, 2270, 170),
	Rect2(-520, -420, 1000, 330), Rect2(690, -370, 940, 170), Rect2(-500, 780, 970, 240), Rect2(690, 690, 640, 420),
	Rect2(1380, 860, 290, 210),
]


## Wildflowers, grass, ferns, the odd shrub and young tree in the open green between everything else.
func _scatter_greenery() -> void:
	var placed := 0
	var attempts := 0
	while placed < 90 and attempts < 900:
		attempts += 1
		var spot := Vector2(random.randf_range(FENCE.position.x + 20, FENCE.end.x - 20), random.randf_range(FENCE.position.y + 30, FENCE.end.y - 20))
		if BUSY_AREAS.any(func(area: Rect2) -> bool: return area.has_point(spot)):
			continue
		placed += 1
		var roll := random.randf()
		if roll < 0.08:
			_tree([TREE_SPRUCE, TREE_PINE, TREE_MAPLE][random.randi() % 3], spot, random.randf_range(0.42, 0.52))
		elif roll < 0.25:
			_shrub(spot, 0.4)
		elif roll < 0.55:
			_place(FLOWERS, spot, 0.26, random.randf() < 0.5, false)
		else:
			_place([GRASS_CLUMP, GRASS_CLUMP, FERN, ROCKS_SMALL][random.randi() % 4], spot, 0.28, random.randf() < 0.5, false)


# --- Helpers -------------------------------------------------------------------------------------------

func _sprite(texture: Texture2D, scale_factor: float, flip := false) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE * scale_factor
	sprite.flip_h = flip
	sprite.offset = Vector2(0.0, -texture.get_height() * 0.5)
	return sprite


## A standing sprite with its base at `base`, y-sorted with everything else.
func _place(texture: Texture2D, base: Vector2, scale_factor: float, flip := false, shadow := true) -> Sprite2D:
	var sprite := _sprite(texture, scale_factor, flip)
	sprite.position = base
	if shadow:
		SunShadow.attach(sprite, Vector2(0.0, -2.0), texture.get_width() * 0.9, true, GRASS_SHADOW)
	level.add_child.call_deferred(sprite)
	return sprite


## A standing sprite that blocks movement with a circle at its base.
func _solid(texture: Texture2D, base: Vector2, scale_factor: float, radius: float, flip := false) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_mask = 0
	body.position = base
	var sprite := _sprite(texture, scale_factor, flip)
	SunShadow.attach(sprite, Vector2(0.0, -2.0), texture.get_width() * 0.9, true, GRASS_SHADOW)
	body.add_child(sprite)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	shape.position = Vector2(0.0, -radius * 0.5)
	body.add_child(shape)
	level.add_child.call_deferred(body)
	return body


func _prop(kind: TownProp.Kind, base: Vector2, radius := 0.0, flip := false) -> TownProp:
	var prop := TownProp.new()
	prop.kind = kind
	prop.flip = flip
	if radius <= 0.0:
		prop.position = base
		level.add_child.call_deferred(prop)
		return prop
	var body := StaticBody2D.new()
	body.collision_mask = 0
	body.position = base
	body.add_child(prop)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	shape.position = Vector2(0.0, -radius * 0.4)
	body.add_child(shape)
	level.add_child.call_deferred(body)
	return prop


func _tree(texture: Texture2D, base: Vector2, scale_factor: float) -> void:
	_solid(texture, base, scale_factor, 11.0, random.randf() < 0.5)


func _shrub(base: Vector2, scale_factor := 0.42) -> void:
	_place(SHRUBS[random.randi() % SHRUBS.size()], base, scale_factor * random.randf_range(0.9, 1.1), random.randf() < 0.5)


# --- Houses --------------------------------------------------------------------------------------------

func _build_houses() -> void:
	for entry in ROW_MAIN:
		_house(Vector2(entry[0], 330), entry[1], entry[2])
	for entry in ROW_LANE:
		_house(Vector2(entry[0], 50), entry[1], entry[2])
	for entry in ROW_SOUTH:
		var texture: Texture2D = BACK_HOUSES[entry[1]]
		var house := _house_body(texture, Vector2(entry[0], 615), random.randf() < 0.5)
		level.add_child.call_deferred(house)
		# Back gardens: a shrub or two and a woodpile.
		_shrub(Vector2(entry[0] - 80, 640))
		if random.randf() < 0.6:
			_place(LOG_PILE, Vector2(entry[0] + 82, 628), 0.32)


func _house(base: Vector2, style: int, flip: bool) -> void:
	var texture: Texture2D = FRONT_HOUSES[style]
	var house := _house_body(texture, base, flip)
	level.add_child.call_deferred(house)
	if style == 0:
		var chimney := Vector2(CHIMNEY.x * (-1.0 if flip else 1.0) * texture.get_width(), -CHIMNEY.y * texture.get_height()) * HOUSE_SCALE
		_chimney_smoke(base + chimney)
	# Front yard: flower beds either side of the door, a shrub at each corner.
	var half_width := texture.get_width() * HOUSE_SCALE * 0.5
	for side in [-1.0, 1.0]:
		var bed := Rect2(base.x + side * 26.0 - (36.0 if side < 0.0 else 0.0), base.y + 4.0, 36.0, 12.0)
		beds.append(bed)
		for index in 3:
			_place(FLOWERS, Vector2(bed.position.x + 6.0 + index * 12.0, bed.end.y - 1.0), 0.24, random.randf() < 0.5, false)
		_shrub(Vector2(base.x + side * (half_width + 8.0), base.y + 6.0), 0.36)
	_butterfly(base + Vector2(random.randf_range(-40, 40), 10))


func _house_body(texture: Texture2D, base: Vector2, flip: bool) -> StaticBody2D:
	var house := StaticBody2D.new()
	house.collision_mask = 0
	house.position = base
	var sprite := _sprite(texture, HOUSE_SCALE, flip)
	house.add_child(sprite)
	SunShadow.attach(sprite, Vector2(0.0, -4.0), texture.get_width() * 1.05, true, GRASS_SHADOW)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(texture.get_width() * HOUSE_SCALE * 0.84, 46.0)
	shape.shape = rect
	shape.position = Vector2(0.0, -26.0)
	house.add_child(shape)
	return house


func _chimney_smoke(top: Vector2) -> void:
	var smoke := CPUParticles2D.new()
	smoke.position = top
	smoke.amount = 10
	smoke.lifetime = 3.5
	smoke.preprocess = 3.5
	smoke.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	smoke.emission_sphere_radius = 2.0
	smoke.direction = Vector2(0.35, -1.0)
	smoke.spread = 10.0
	smoke.gravity = Vector2(6.0, -4.0)
	smoke.initial_velocity_min = 10.0
	smoke.initial_velocity_max = 16.0
	smoke.scale_amount_min = 4.0
	smoke.scale_amount_max = 7.0
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 0.4))
	grow.add_point(Vector2(1.0, 1.6))
	smoke.scale_amount_curve = grow
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.15, 1.0])
	fade.colors = PackedColorArray([Color(0.85, 0.85, 0.85, 0.0), Color(0.82, 0.82, 0.8, 0.45), Color(0.9, 0.9, 0.9, 0.0)])
	smoke.color_ramp = fade
	smoke.texture = _soft_dot()
	# Above the roof it belongs to, below the HUD.
	smoke.z_index = 5
	level.add_child.call_deferred(smoke)


static var _dot: ImageTexture


func _soft_dot() -> ImageTexture:
	if _dot == null:
		var image := Image.create_empty(8, 8, false, Image.FORMAT_RGBA8)
		for y in 8:
			for x in 8:
				var d := Vector2(x - 3.5, y - 3.5).length() / 4.0
				image.set_pixel(x, y, Color(1, 1, 1, clampf(1.0 - d, 0.0, 1.0)))
		_dot = ImageTexture.create_from_image(image)
	return _dot


# --- Market and street furniture -----------------------------------------------------------------------

func _build_market() -> void:
	# Crates and barrels round the vendor's stall (the stall itself is in town.tscn), and outside the tavern.
	for spot in [Vector2(808, 322), Vector2(826, 334), Vector2(952, 324), Vector2(968, 338), Vector2(940, 344)]:
		_solid(CRATES[random.randi() % CRATES.size()], spot, 0.7, 9.0)
	for spot in [Vector2(-262, 336), Vector2(-246, 346), Vector2(-92, 338)]:
		_solid(CRATES[2 + random.randi() % 2], spot, 0.7, 9.0)


func _build_street_furniture() -> void:
	for x in [-300, -40, 250, 960, 1170, 1420, 1665]:
		_prop(TownProp.Kind.LAMP, Vector2(x, 344), 5.0)
	for x in [-490, -290, -20, 270, 900, 1180, 1450]:
		_prop(TownProp.Kind.LAMP, Vector2(x, 462), 5.0)
	# Benches round the plaza, and the well and signpost off it.
	for spot in [Vector2(462, 296), Vector2(462, 520), Vector2(690, 520)]:
		_prop(TownProp.Kind.BENCH, spot, 10.0)
	_prop(TownProp.Kind.WELL, Vector2(720, 196), 24.0)
	_prop(TownProp.Kind.SIGNPOST, Vector2(640, 472), 5.0)
	_prop(TownProp.Kind.SIGNPOST, Vector2(510, 236), 5.0, true)
	# The notice board, where the reeve posts bounties.
	var board := _prop(TownProp.Kind.NOTICE_BOARD, NOTICE_BOARD_SPOT, 14.0)
	QuestTalker.attach(board, "notice_board", 64.0, "Read").talk_radius = 50.0


# --- Greenery inside the fence -------------------------------------------------------------------------

func _build_trees_and_greenery() -> void:
	# Between the houses along the main street and the north lane.
	for x in [-300, -35, 260, 1165, 1420, 1665]:
		_tree(TREE_APPLE if random.randf() < 0.35 else TREE_SPRUCE, Vector2(x + random.randf_range(-10, 10), 290), random.randf_range(0.5, 0.6))
	for x in [-505, -150, 330, 760, 1240, 1660]:
		_tree([TREE_PINE, TREE_SPRUCE, TREE_MAPLE][random.randi() % 3], Vector2(x, 20 + random.randf_range(-10, 10)), random.randf_range(0.48, 0.58))
	# South of the main street, between the back gardens.
	for x in [-520, -290, 30, 330, 1100, 1450, 1680]:
		_tree([TREE_OAK, TREE_MAPLE, TREE_SPRUCE][random.randi() % 3], Vector2(x + random.randf_range(-12, 12), 600 + random.randf_range(-10, 30)), random.randf_range(0.42, 0.52))
	# Grass and ferns tucked against the fence.
	for index in 60:
		var t := float(index) / 60.0
		for spot in [Vector2(lerpf(FENCE.position.x, FENCE.end.x, t), FENCE.position.y + 14), Vector2(lerpf(FENCE.position.x, FENCE.end.x, t), FENCE.end.y - 6)]:
			if random.randf() < 0.45:
				_place(GRASS_CLUMP if random.randf() < 0.7 else FERN, spot + Vector2(random.randf_range(-10, 10), 0), 0.3, random.randf() < 0.5, false)


func _build_north() -> void:
	# Orchard: rows of apple trees north-west.
	for row in 2:
		for column in 6:
			var spot := Vector2(-480 + column * 135 + (row % 2) * 60, -330 + row * 140)
			if spot.x > 470:
				continue
			_tree(TREE_APPLE, spot + Vector2(random.randf_range(-8, 8), random.randf_range(-6, 6)), random.randf_range(0.5, 0.58))
	for index in 8:
		_place(GRASS_CLUMP, Vector2(random.randf_range(-500, 450), random.randf_range(-380, -110)), 0.3, false, false)
	# Vegetable gardens north-east, with a scarecrow keeping watch.
	var plots := [[Vector2(820, -290), Vector2(220, 130), TownField.Crop.CABBAGE], [Vector2(1100, -290), Vector2(240, 130), TownField.Crop.PUMPKIN], [Vector2(1390, -290), Vector2(240, 130), TownField.Crop.CABBAGE]]
	for plot in plots:
		_field(plot[0], plot[1], plot[2])
	_prop(TownProp.Kind.SCARECROW, Vector2(1100, -270))
	_prop(TownProp.Kind.HAY, Vector2(1580, -150), 14.0)
	_place(LOGS, Vector2(700, -140), 0.36)
	_place(STUMP, Vector2(760, -120), 0.32)


func _build_south() -> void:
	# Fields south-west.
	_field(Vector2(-320, 900), Vector2(340, 220), TownField.Crop.WHEAT)
	_field(Vector2(130, 900), Vector2(300, 220), TownField.Crop.CABBAGE)
	_prop(TownProp.Kind.SCARECROW, Vector2(-320, 930))
	for spot in [Vector2(-120, 760), Vector2(-90, 772), Vector2(380, 770), Vector2(-510, 1060)]:
		_prop(TownProp.Kind.HAY, spot, 14.0)
	# Chickens scratching about by the south lane.
	for index in 4:
		_animal(CHICKEN_WALK, CHICKEN_PECK, Vector2(470 + index * 22, 720 + (index % 2) * 30), 0.28, 38.0, 80.0, true, true)
	# Pasture with cows, south-east.
	var pasture := Rect2(700, 700, 620, 400)
	var back := TownFence.new()
	back.fence_rect = pasture
	back.draw_bottom = false
	back.position = Vector2(0, pasture.position.y)
	level.add_child.call_deferred(back)
	var front := TownFence.new()
	front.fence_rect = pasture
	front.draw_top = false
	front.draw_sides = false
	front.top_gates = []
	front.position = Vector2(0, pasture.end.y)
	level.add_child.call_deferred(front)
	_pasture_walls(pasture)
	for index in 4:
		var spot := pasture.position + Vector2(120 + index * 130, 120 + (index % 2) * 140)
		_animal(COW_WALK, COW_GRAZE, spot, 0.33, 18.0, 90.0, true, false)
	_place(LOGS, Vector2(1290, 760), 0.34)
	# Pond with rocks and reeds.
	var pond := Sprite2D.new()
	pond.texture = POND
	pond.position = Vector2(1520, 960)
	pond.scale = Vector2.ONE * 0.9
	pond.z_index = -6
	level.add_child.call_deferred(pond)
	var pond_body := StaticBody2D.new()
	pond_body.collision_mask = 0
	var pond_shape := CollisionShape2D.new()
	var pond_circle := CircleShape2D.new()
	pond_circle.radius = POND.get_width() * 0.32
	pond_shape.shape = pond_circle
	pond_shape.scale = Vector2(1.0, 0.6)
	pond_shape.position = pond.position
	pond_body.add_child(pond_shape)
	level.add_child.call_deferred(pond_body)
	for spot in [Vector2(1420, 900), Vector2(1630, 1010), Vector2(1450, 1040)]:
		_place(GRASS_CLUMP, spot, 0.34, random.randf() < 0.5, false)
	_place(ROCK_MOSSY, Vector2(1640, 900), 0.3)
	_place(ROCKS_SMALL, Vector2(1400, 1010), 0.28)


func _field(center: Vector2, size: Vector2, crop: TownField.Crop) -> void:
	var field := TownField.new()
	field.position = center
	field.size = size
	field.crop = crop
	field.seed_value = random.randi()
	field.z_index = -7
	level.add_child.call_deferred(field)


## Invisible walls along the pasture fence so cows stay in and the player walks round.
func _pasture_walls(pasture: Rect2) -> void:
	var walls := StaticBody2D.new()
	walls.collision_mask = 0
	for segment in [
		Rect2(pasture.position.x, pasture.position.y - 6, pasture.size.x, 12),
		Rect2(pasture.position.x, pasture.end.y - 6, pasture.size.x, 12),
		Rect2(pasture.position.x - 6, pasture.position.y, 12, pasture.size.y),
		Rect2(pasture.end.x - 6, pasture.position.y, 12, pasture.size.y),
	]:
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = segment.size
		shape.shape = rect
		shape.position = segment.get_center()
		walls.add_child(shape)
	level.add_child.call_deferred(walls)


func _animal(walk: Array[Texture2D], idle: Array[Texture2D], spot: Vector2, scale_factor: float, speed: float, radius: float, walk_right: bool, idle_right: bool) -> void:
	var animal := CharacterBody2D.new()
	animal.set_script(ANIMAL_SCRIPT)
	animal.position = spot
	animal.set("walk_frames", walk)
	animal.set("idle_frames", idle)
	animal.set("walk_faces_right", walk_right)
	animal.set("idle_faces_right", idle_right)
	animal.set("speed", speed)
	animal.set("wander_radius", radius)
	var sprite := Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE * scale_factor
	sprite.texture = walk[0]
	sprite.offset = Vector2(0.0, -walk[0].get_height() * 0.5)
	animal.add_child(sprite)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 8.0 if scale_factor < 0.3 else 14.0
	shape.shape = circle
	shape.position = Vector2(0.0, -6.0)
	animal.add_child(shape)
	level.add_child.call_deferred(animal)


# --- Outside the fence ---------------------------------------------------------------------------------

## A strip of meadow round the fence, then forest as far as the camera can see.
func _build_outside() -> void:
	var trees: Array[Texture2D] = [TREE_PINE, TREE_SPRUCE, TREE_OAK, TREE_MAPLE, TREE_TALL_PINE, TREE_CEDAR, TREE_SPRUCE, TREE_PINE]
	var outer := FENCE.grow(560)
	var spacing := 74.0
	var y := outer.position.y
	var row := 0
	while y < outer.end.y:
		var x := outer.position.x + (spacing * 0.5 if row % 2 == 1 else 0.0)
		while x < outer.end.x:
			var spot := Vector2(x + random.randf_range(-24, 24), y + random.randf_range(-20, 20))
			var distance := _distance_outside_fence(spot)
			if distance > 70.0 and random.randf() < clampf((distance - 40.0) / 120.0, 0.25, 0.92):
				var texture: Texture2D = trees[random.randi() % trees.size()]
				_place(texture, spot, random.randf_range(0.42, 0.62), random.randf() < 0.5)
			elif distance > 4.0 and distance <= 70.0 and random.randf() < 0.35:
				_place([FLOWERS, GRASS_CLUMP, GRASS_CLUMP, FERN][random.randi() % 4], spot, 0.28, random.randf() < 0.5, false)
			x += spacing
		y += spacing * 0.8
		row += 1
	# The streets run on out of the gates as dirt tracks into the trees.
	for track in [Rect2(-900, 370, 340, 60), Rect2(1712, 370, 340, 60), Rect2(548, -760, 56, 340), Rect2(550, 1180, 52, 340)]:
		var path := Polygon2D.new()
		path.polygon = PackedVector2Array([track.position, Vector2(track.end.x, track.position.y), track.end, Vector2(track.position.x, track.end.y)])
		path.antialiased = true
		path.material = _ground_material(3)
		path.z_index = -8
		level.add_child.call_deferred(path)


func _distance_outside_fence(point: Vector2) -> float:
	var dx := maxf(FENCE.position.x - point.x, point.x - FENCE.end.x)
	var dy := maxf(FENCE.position.y - point.y, point.y - FENCE.end.y)
	if dx <= 0.0 and dy <= 0.0:
		return -1.0
	return Vector2(maxf(dx, 0.0), maxf(dy, 0.0)).length()


# --- Villagers and critters ----------------------------------------------------------------------------

func _build_folk() -> void:
	# Mary, Gertrude, Sarah and Elsa each have work for a traveller; see Quests.
	_folk("mary", Vector2(-200, 400), Rect2(-460, 362, 860, 76), 34.0)
	_folk("gertrude", Vector2(520, 520), Rect2(440, 470, 280, 70), 16.0)
	_folk("sarah", Vector2(1100, 400), Rect2(980, 362, 640, 76), 30.0)
	# Elsa, the tavern maid, stands outside with her tray.
	var elsa := Townsfolk.new()
	elsa.front_frames = [load("res://textures/town_folk_elsa_front_a.png"), load("res://textures/town_folk_elsa_front_b.png")]
	elsa.position = Vector2(-96, 352)
	_add_talker(elsa, "elsa")
	level.add_child.call_deferred(elsa)
	# Pip, home again once he's been found in the forest, plays by his mother's end of the street.
	if Quests.is_completed(Quests.LOST_PIP):
		var pip := HubFolk.new()
		pip.display_name = "Pip"
		pip.lines = ["Ember's real! She's a fox! Mum doesn't believe me.", "I'm not allowed past the gate till midwinter.", "When I grow up I'm going to fight wolves like you."]
		pip.body_scale = 0.78
		pip.skin = Color("#e2b48c")
		pip.clothes = Color("#5d7d3a")
		pip.trim = Color("#c9a35a")
		pip.pants = Color("#6b4a2e")
		pip.hair = Color("#b8662e")
		pip.area = Rect2(1180, 470, 220, 60)
		pip.speed = 44.0
		pip.position = Vector2(1240, 490)
		level.add_child.call_deferred(pip)


func _folk(name_id: String, spot: Vector2, area: Rect2, speed: float) -> void:
	var folk := Townsfolk.new()
	var path := "res://textures/town_folk_%s_" % name_id
	folk.front_frames = [load(path + "front_a.png"), load(path + "front_b.png")]
	folk.back_frame = load(path + "back.png")
	var sides: Array[Texture2D] = [load(path + "side_a.png")]
	if ResourceLoader.exists(path + "side_b.png"):
		sides.append(load(path + "side_b.png"))
	folk.side_frames = sides
	folk.side_faces_right = FOLK[name_id]["side_right"]
	folk.area = area
	folk.speed = speed
	folk.position = spot
	_add_talker(folk, name_id)
	level.add_child.call_deferred(folk)


## Lets the player talk to a villager about quests, with the marker just over her head.
func _add_talker(folk: Townsfolk, npc_id: String) -> void:
	QuestTalker.attach(folk, npc_id, folk.front_frames[0].get_height() * folk.sprite_scale)


func _butterfly(spot: Vector2) -> void:
	var critter := ForestCritter.new()
	critter.kind = ForestCritter.Kind.BUTTERFLY
	critter.player = player
	critter.position = spot
	level.add_child.call_deferred(critter)


# --- Ground detail -------------------------------------------------------------------------------------

## The meadow itself is painted by town_ground.gdshader on the Ground polygon; this only adds the front
## yards' flower beds.
func _draw() -> void:
	for bed in beds:
		SmoothDraw.flat(self, bed.grow(2.0), BED_EDGE, 5.0)
		SmoothDraw.flat(self, bed, BED_SOIL, 4.0)
		draw_line(bed.position + Vector2(4, 3), Vector2(bed.end.x - 4, bed.position.y + 3), Color(BED_SOIL.lightened(0.25), 0.6), 1.5, true)


## Paints a polygon with town_ground.gdshader (0 grass, 1 bricks, 2 cobbles, 3 dirt).
func _ground_material(mode: int) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = TownStreets.GROUND_SHADER
	material.set_shader_parameter("mode", mode)
	material.set_shader_parameter("noise_texture", TownStreets.noise())
	return material
