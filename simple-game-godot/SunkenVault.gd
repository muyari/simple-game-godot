extends Node2D
class_name SunkenVault
## The vault beneath Qasr Anuhm, where the Sunkeepers bound the First Sting with the Sunstone, and where
## Malik's pick cracked it. Built far from the Sands the first time the player goes down: one hall of
## sand-drifted flagstones drawn smooth like the hubs, ringed with pillars and toppled statues, with the stair
## up at the south end and the seal-dais at the north. In The Sunken Vault, Venomcoil and two of its brood
## guard the three shards of the Sunstone; in The Mother of Stings, setting the mended stone in the dais
## wakes the First Sting herself.

## Where the vault sits in the level, well beyond anywhere the Sands are ever generated.
const ORIGIN := Vector2(40000, -40000)
## Marks the vault's monsters, which are held still while the player is up in the Sands.
const VAULT_META := "sunken_vault"
## Half size of the hall.
const HALF_SIZE := Vector2(680, 400)
const SNAKE_SCENE = preload("res://snake.tscn")
const SCORPION_SCENE = preload("res://scorpion.tscn")
const FIRST_STING_SCENE = preload("res://desert_boss.tscn")
const PILLAR = preload("res://textures/desert_pillar_ornate.png")
const BROKEN_PILLARS: Array[Texture2D] = [
	preload("res://textures/desert_pillar_a.png"),
	preload("res://textures/desert_pillar_c.png"),
]
const RUBBLE = preload("res://textures/desert_rubble_low.png")
const FLOOR := Color("#7a6248")
const FLOOR_LIGHT := Color("#8f7656")
const TILE_LINE := Color("#5e4a36")
const ROCK := Color("#120d0a")
const WALL := Color("#4a3a2b")
const SAND := Color("#c9a874")
const SUN_GOLD := Color("#ffcf5a")
const SEAL_SPOT := Vector2(0, -HALF_SIZE.y + 120.0)
const SHARD_SPOTS: Array[Vector2] = [Vector2(-470, -60), Vector2(480, -150), Vector2(-160, 210)]

var desert_quests: DesertQuests
var venomcoil: Wolf
var first_sting: Wolf
var time := 0.0


func _ready() -> void:
	z_index = -9
	_build_walls()
	_build_props()
	var exit := QuestObject.new()
	exit.kind = QuestObject.Kind.VAULT_EXIT
	exit.object_id = "sunken_vault_exit"
	exit.door_open = func() -> bool: return true
	exit.used.connect(func(_exit: QuestObject) -> void: desert_quests.leave_cave())
	exit.position = ORIGIN + Vector2(0, HALF_SIZE.y - 50.0)
	get_parent().add_child.call_deferred(exit)
	for index in SHARD_SPOTS.size():
		var shard := QuestObject.new()
		shard.kind = QuestObject.Kind.SUN_SHARD
		shard.object_id = "sunstone_shard_%d" % index
		shard.quest_id = Quests.SUNKEN_VAULT
		shard.position = ORIGIN + SHARD_SPOTS[index]
		get_parent().add_child.call_deferred(shard)
	var seal := QuestObject.new()
	seal.kind = QuestObject.Kind.SUN_SEAL
	seal.object_id = "sun_seal"
	seal.quest_id = Quests.MOTHER_OF_STINGS
	var seal_body := StaticBody2D.new()
	seal_body.collision_mask = 0
	seal_body.position = ORIGIN + SEAL_SPOT
	var shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 22.0
	capsule.height = 90.0
	shape.shape = capsule
	shape.rotation = PI * 0.5
	shape.position = Vector2(0, -8)
	seal_body.add_child(shape)
	seal_body.add_child(seal)
	get_parent().add_child.call_deferred(seal_body)


func _process(delta: float) -> void:
	time += delta
	queue_redraw()


## Where the player stands on coming down: at the foot of the stair.
func get_arrival() -> Vector2:
	return ORIGIN + Vector2(0, HALF_SIZE.y - 130.0)


## Sets out whoever the quests have waiting down here: Venomcoil and its brood while the shards are guarded,
## the First Sting once the Sunstone is set.
func populate() -> void:
	if GameState.get_quest_state(Quests.SUNKEN_VAULT) == "entered" and not is_instance_valid(venomcoil):
		venomcoil = _spawn(SNAKE_SCENE, Vector2(0, -60), {
			"name": "Venomcoil", "scale": 2.0, "health": 10.0, "damage": 1.45, "experience": 160,
			"tint": Color(0.92, 0.82, 0.42),
		}, func() -> Array[Dictionary]: return Quests.record_event("kill", "venomcoil"))
		for side: float in [-1.0, 1.0]:
			_spawn(SNAKE_SCENE, Vector2(side * 300.0, 40.0), {"name": "Vault Snake", "health": 1.6, "experience": 25}, Callable())
		Audio.play_sfx("boss_incoming")
	if GameState.get_quest_state(Quests.MOTHER_OF_STINGS) == "seal_set" and not is_instance_valid(first_sting):
		first_sting = _spawn(FIRST_STING_SCENE, SEAL_SPOT + Vector2(0, 230), {
			"name": "The First Sting", "scale": 1.4, "health": 2.4, "damage": 1.25, "experience": 450,
			"tint": Color(0.98, 0.78, 0.36),
		}, _on_first_sting_died)
		first_sting.stagger_immune = true
		for side: float in [-1.0, 1.0]:
			_spawn(SCORPION_SCENE, SEAL_SPOT + Vector2(side * 360.0, 260.0), {"name": "Brood Scorpion", "health": 1.5, "experience": 25}, Callable())
		Audio.play_sfx("boss_incoming")
		Audio.play_music(Audio.BOSS_MUSIC, 0.6)


func _spawn(scene: PackedScene, offset: Vector2, stats: Dictionary, on_died: Callable) -> Wolf:
	var monster := desert_quests.spawn_quest_monster(scene, ORIGIN + offset, stats, on_died)
	monster.set_meta(VAULT_META, true)
	monster.alert()
	return monster


func _on_first_sting_died() -> Array[Dictionary]:
	var updates := Quests.record_event("kill", "first_sting")
	desert_quests.on_first_sting_slain(first_sting.global_position)
	return updates


func _build_walls() -> void:
	var walls := StaticBody2D.new()
	walls.collision_mask = 0
	walls.position = ORIGIN
	var shape := CollisionPolygon2D.new()
	shape.build_mode = CollisionPolygon2D.BUILD_SEGMENTS
	var corners := _hall_outline()
	corners.append(corners[0])
	shape.polygon = corners
	walls.add_child(shape)
	get_parent().add_child.call_deferred(walls)


## A long hall with its corners cut, and a short neck at the south end where the stair comes down.
func _hall_outline() -> PackedVector2Array:
	var x := HALF_SIZE.x
	var y := HALF_SIZE.y
	return PackedVector2Array([
		Vector2(-x + 90, -y), Vector2(x - 90, -y), Vector2(x, -y + 90), Vector2(x, y - 90), Vector2(x - 90, y - 40),
		Vector2(120, y - 40), Vector2(90, y), Vector2(-90, y), Vector2(-120, y - 40), Vector2(-x + 90, y - 40),
		Vector2(-x, y - 90), Vector2(-x, -y + 90),
	])


func _build_props() -> void:
	# Two rows of standing pillars down the hall, a few toppled, and rubble the sand has half buried.
	for column: float in [-500.0, -250.0, 250.0, 500.0]:
		for row: float in [-210.0, 120.0]:
			var broken := absi(int(column + row)) % 3 == 0
			_standing(BROKEN_PILLARS[absi(int(column)) % 2] if broken else PILLAR, Vector2(column, row), 1.05 if broken else 1.15, 16.0)
	for spot: Vector2 in [Vector2(-380, 250), Vector2(390, 230), Vector2(-90, -250), Vector2(170, 60)]:
		_standing(RUBBLE, spot, 1.0, 0.0)


func _standing(texture: Texture2D, offset: Vector2, uniform_scale: float, collision_radius: float) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE * uniform_scale
	sprite.offset = Vector2(0, -texture.get_height() * 0.5)
	sprite.modulate = Color(0.82, 0.74, 0.66)
	if collision_radius <= 0.0:
		sprite.position = ORIGIN + offset
		get_parent().add_child.call_deferred(sprite)
		return
	var body := StaticBody2D.new()
	body.collision_mask = 0
	body.position = ORIGIN + offset
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = collision_radius
	shape.shape = circle
	shape.position = Vector2(0, -collision_radius * 0.4)
	body.add_child(shape)
	body.add_child(sprite)
	get_parent().add_child.call_deferred(body)


func _draw() -> void:
	# Solid rock as far as the camera can see, then the hall's walls and flagstone floor.
	draw_rect(Rect2(-HALF_SIZE * 4.0, HALF_SIZE * 8.0), ROCK)
	var outline := _hall_outline()
	var rim := PackedVector2Array()
	for point in outline:
		rim.append(point * Vector2(1.05, 1.08))
	draw_colored_polygon(rim, WALL)
	SmoothDraw.polygon(self, outline, FLOOR, WALL.lightened(0.2), 6.0)
	# Flagstones, offset row by row.
	var tile := Vector2(96, 56)
	var row := 0
	var y := -HALF_SIZE.y + tile.y
	while y < HALF_SIZE.y - 40.0:
		draw_line(Vector2(-HALF_SIZE.x + 20, y), Vector2(HALF_SIZE.x - 20, y), Color(TILE_LINE, 0.55), 1.5, true)
		var x := -HALF_SIZE.x + (tile.x * 0.5 if row % 2 == 1 else 0.0)
		while x < HALF_SIZE.x:
			if Geometry2D.is_point_in_polygon(Vector2(x, y - tile.y * 0.5), outline):
				draw_line(Vector2(x, y - tile.y), Vector2(x, y), Color(TILE_LINE, 0.45), 1.5, true)
			x += tile.x
		y += tile.y
		row += 1
	# Sand drifted in down the stair and heaped in the corners.
	for drift: Vector3 in [Vector3(0, HALF_SIZE.y - 80, 150), Vector3(-560, -250, 120), Vector3(560, 260, 110), Vector3(420, -300, 90), Vector3(-450, 280, 100)]:
		draw_set_transform(Vector2(drift.x, drift.y), 0.0, Vector2(1.0, 0.45))
		draw_circle(Vector2.ZERO, drift.z, Color(SAND, 0.5), true, -1.0, true)
		draw_set_transform(Vector2.ZERO)
	# A sun-disc inlaid round the dais, and light falling down the stair.
	draw_set_transform(SEAL_SPOT, 0.0, Vector2(1.0, 0.45))
	draw_arc(Vector2.ZERO, 200.0, 0.0, TAU, 64, Color(SUN_GOLD, 0.25), 3.0, true)
	draw_arc(Vector2.ZERO, 150.0, 0.0, TAU, 64, Color(SUN_GOLD, 0.18), 2.0, true)
	draw_set_transform(Vector2.ZERO)
	var stair := Vector2(0, HALF_SIZE.y - 50.0)
	for ring in 4:
		draw_set_transform(stair, 0.0, Vector2(1.0, 0.5))
		draw_circle(Vector2.ZERO, 150.0 - ring * 30.0, Color(1.0, 0.92, 0.7, 0.05), true, -1.0, true)
		draw_set_transform(Vector2.ZERO)
	var pulse := 0.5 + 0.5 * sin(time * 1.4)
	for index in SHARD_SPOTS.size():
		if Quests.is_object_used(Quests.SUNKEN_VAULT, "sunstone_shard_%d" % index):
			continue
		draw_set_transform(SHARD_SPOTS[index], 0.0, Vector2(1.0, 0.5))
		draw_circle(Vector2.ZERO, 60.0, Color(SUN_GOLD, 0.03 + 0.03 * pulse), true, -1.0, true)
		draw_set_transform(Vector2.ZERO)
