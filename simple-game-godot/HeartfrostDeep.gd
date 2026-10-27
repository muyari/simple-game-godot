extends Node2D
class_name HeartfrostDeep
## The Heartfrost Deep beneath the Wardhall, where the Rimewardens kept the frozen spring that holds the Rime
## Mother and her last child, Rimehollow's Sleeper, in the long dream. Built far from the caves the first
## time the player goes down: one hall of blue ice drawn smooth like the hubs, ringed with ice pillars and
## crystals, with the gate's stair at the south end and the Heartfrost at the north. In The Heartfrost Deep,
## fire-imps from the waking Underworld guard the three melt-rifts they climbed up through; in The Rime
## Mother, setting the Rimeward in the Heartfrost wakes the Rime Mother herself.

## Where the Deep sits in the level, well beyond anywhere the caves are ever generated.
const ORIGIN := Vector2(-40000, 40000)
## Marks the Deep's monsters, which are held still while the player is up in the caves.
const DEEP_META := "heartfrost_deep"
## Half size of the hall.
const HALF_SIZE := Vector2(680, 400)
const IMP_SCENE = preload("res://imp.tscn")
const SERPENT_SCENE = preload("res://shiverfang_ice_serpent.tscn")
const RIME_MOTHER_SCENE = preload("res://ice_boss.tscn")
const PILLARS: Array[Texture2D] = [
	preload("res://textures/ice_pillar_ornate.png"),
	preload("res://textures/ice_pillar_twisted.png"),
]
const CRYSTALS: Array[Texture2D] = [
	preload("res://textures/ice_crystals_a.png"),
	preload("res://textures/ice_crystals_b.png"),
]
const FLOOR := Color("#9cc3dc")
const FLOOR_LIGHT := Color("#b8d8ec")
const CRACK_LINE := Color("#6f9bbb")
const ROCK := Color("#070c12")
const WALL := Color("#2c3e50")
const RIME_GLOW := Color("#7fd0ff")
const RIFT_FIRE := Color("#ff5a1f")
const HEART_SPOT := Vector2(0, -HALF_SIZE.y + 130.0)
const RIFT_SPOTS: Array[Vector2] = [Vector2(-460, -40), Vector2(470, -130), Vector2(-120, 200)]
const IMP_SPOTS: Array[Vector2] = [Vector2(-380, 10), Vector2(400, -80), Vector2(-60, 150), Vector2(200, 120)]

var ice_quests: IceQuests
var imps: Array[Wolf] = []
var rime_mother: Wolf
var time := 0.0


func _ready() -> void:
	z_index = -9
	_build_walls()
	_build_props()
	var exit := QuestObject.new()
	exit.kind = QuestObject.Kind.DEEP_EXIT
	exit.object_id = "heartfrost_deep_exit"
	exit.door_open = func() -> bool: return true
	exit.used.connect(func(_exit: QuestObject) -> void: ice_quests.leave_cave())
	exit.position = ORIGIN + Vector2(0, HALF_SIZE.y - 50.0)
	get_parent().add_child.call_deferred(exit)
	for index in RIFT_SPOTS.size():
		var rift := QuestObject.new()
		rift.kind = QuestObject.Kind.MELT_RIFT
		rift.object_id = "melt_rift_%d" % index
		rift.quest_id = Quests.HEARTFROST_DEEP
		rift.position = ORIGIN + RIFT_SPOTS[index]
		get_parent().add_child.call_deferred(rift)
	var heart := QuestObject.new()
	heart.kind = QuestObject.Kind.HEARTFROST
	heart.object_id = "heartfrost"
	heart.quest_id = Quests.RIME_MOTHER
	var heart_body := StaticBody2D.new()
	heart_body.collision_mask = 0
	heart_body.position = ORIGIN + HEART_SPOT
	var shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 24.0
	capsule.height = 110.0
	shape.shape = capsule
	shape.rotation = PI * 0.5
	shape.position = Vector2(0, -8)
	heart_body.add_child(shape)
	heart_body.add_child(heart)
	get_parent().add_child.call_deferred(heart_body)


func _process(delta: float) -> void:
	time += delta
	queue_redraw()


## Where the player stands on coming down: at the foot of the stair.
func get_arrival() -> Vector2:
	return ORIGIN + Vector2(0, HALF_SIZE.y - 130.0)


## Sets out whoever the quests have waiting down here: the rift imps while the melt-rifts are open and
## guarded, the Rime Mother once the Rimeward is set.
func populate() -> void:
	imps = imps.filter(func(imp: Wolf) -> bool: return is_instance_valid(imp) and imp.health > 0.0)
	if GameState.get_quest_state(Quests.HEARTFROST_DEEP) == "entered" and imps.is_empty():
		for index in IMP_SPOTS.size():
			imps.append(_spawn(IMP_SCENE, IMP_SPOTS[index], {"name": "Rift Imp", "health": 1.6, "experience": 30}, _on_imp_died))
		Audio.play_sfx("boss_incoming")
	if GameState.get_quest_state(Quests.RIME_MOTHER) == "ward_set" and not is_instance_valid(rime_mother):
		rime_mother = _spawn(RIME_MOTHER_SCENE, HEART_SPOT + Vector2(0, 250), {
			"name": "The Rime Mother", "scale": 1.15, "health": 1.6, "damage": 1.2, "experience": 500,
			"tint": Color(0.8, 0.92, 1.1),
		}, _on_rime_mother_died)
		rime_mother.stagger_immune = true
		for side: float in [-1.0, 1.0]:
			_spawn(SERPENT_SCENE, HEART_SPOT + Vector2(side * 380.0, 260.0), {"name": "Rime Serpent", "health": 1.5, "experience": 30}, Callable())
		Audio.play_sfx("boss_incoming")
		Audio.play_music(Audio.BOSS_MUSIC, 0.6)


func _spawn(scene: PackedScene, offset: Vector2, stats: Dictionary, on_died: Callable) -> Wolf:
	var monster := ice_quests.spawn_quest_monster(scene, ORIGIN + offset, stats, on_died)
	monster.set_meta(DEEP_META, true)
	monster.alert()
	return monster


func _on_imp_died() -> Array[Dictionary]:
	imps = imps.filter(func(imp: Wolf) -> bool: return is_instance_valid(imp) and imp.health > 0.0)
	if not imps.is_empty():
		return []
	return Quests.record_event("clear", "rift_imps")


func _on_rime_mother_died() -> Array[Dictionary]:
	var updates := Quests.record_event("kill", "rime_mother")
	ice_quests.on_rime_mother_slain(rime_mother.global_position)
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


## A long cavern with its corners rounded off, and a short neck at the south end where the stair comes down.
func _hall_outline() -> PackedVector2Array:
	var x := HALF_SIZE.x
	var y := HALF_SIZE.y
	return PackedVector2Array([
		Vector2(-x + 120, -y), Vector2(x - 120, -y), Vector2(x, -y + 120), Vector2(x, y - 110), Vector2(x - 110, y - 40),
		Vector2(120, y - 40), Vector2(90, y), Vector2(-90, y), Vector2(-120, y - 40), Vector2(-x + 110, y - 40),
		Vector2(-x, y - 110), Vector2(-x, -y + 120),
	])


func _build_props() -> void:
	# Ice pillars down both sides of the hall, and crystal beds where the walls meet the floor.
	for column: float in [-520.0, -260.0, 260.0, 520.0]:
		for row: float in [-200.0, 130.0]:
			if Vector2(column, row).distance_to(RIFT_SPOTS[0]) < 120.0 or Vector2(column, row).distance_to(RIFT_SPOTS[1]) < 120.0:
				continue
			_standing(PILLARS[absi(int(column + row)) % 2], Vector2(column, row), 0.85, 14.0)
	for spot: Vector2 in [Vector2(-560, 260), Vector2(560, 240), Vector2(-300, -300), Vector2(320, -300), Vector2(380, 230)]:
		_standing(CRYSTALS[absi(int(spot.x)) % 2], spot, 0.8, 0.0)


func _standing(texture: Texture2D, offset: Vector2, uniform_scale: float, collision_radius: float) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE * uniform_scale
	sprite.offset = Vector2(0, -texture.get_height() * 0.5)
	sprite.modulate = Color(0.78, 0.88, 1.0)
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
	# Solid rock as far as the camera can see, then the cavern's walls and its floor of old blue ice.
	draw_rect(Rect2(-HALF_SIZE * 4.0, HALF_SIZE * 8.0), ROCK)
	var outline := _hall_outline()
	var rim := PackedVector2Array()
	for point in outline:
		rim.append(point * Vector2(1.05, 1.08))
	draw_colored_polygon(rim, WALL)
	SmoothDraw.polygon(self, outline, FLOOR, WALL.lightened(0.25), 6.0)
	# Pale sheets of clearer ice, and the cracks that run through all of it.
	for sheet: Vector3 in [Vector3(-300, -120, 170), Vector3(320, 80, 190), Vector3(0, 120, 140), Vector3(-480, 200, 110)]:
		draw_set_transform(Vector2(sheet.x, sheet.y), 0.0, Vector2(1.0, 0.45))
		draw_circle(Vector2.ZERO, sheet.z, Color(FLOOR_LIGHT, 0.6), true, -1.0, true)
		draw_set_transform(Vector2.ZERO)
	var random := RandomNumberGenerator.new()
	random.seed = 6113
	for _crack in 30:
		var start := Vector2(random.randf_range(-HALF_SIZE.x + 60, HALF_SIZE.x - 60), random.randf_range(-HALF_SIZE.y + 60, HALF_SIZE.y - 80))
		var bend := start + Vector2(random.randf_range(-36, 36), random.randf_range(-12, 12))
		draw_polyline(PackedVector2Array([start, bend, bend + Vector2(random.randf_range(-30, 30), random.randf_range(-10, 10))]), Color(CRACK_LINE, 0.55), 1.5, true)
	# A ring of Warden runes round the Heartfrost, and cold light falling down the stair.
	draw_set_transform(HEART_SPOT, 0.0, Vector2(1.0, 0.45))
	draw_arc(Vector2.ZERO, 210.0, 0.0, TAU, 64, Color(RIME_GLOW, 0.25), 3.0, true)
	draw_arc(Vector2.ZERO, 160.0, 0.0, TAU, 64, Color(RIME_GLOW, 0.18), 2.0, true)
	draw_set_transform(Vector2.ZERO)
	var stair := Vector2(0, HALF_SIZE.y - 50.0)
	for ring in 4:
		draw_set_transform(stair, 0.0, Vector2(1.0, 0.5))
		draw_circle(Vector2.ZERO, 150.0 - ring * 30.0, Color(0.85, 0.95, 1.0, 0.05), true, -1.0, true)
		draw_set_transform(Vector2.ZERO)
	# Heat haze round each open melt-rift.
	var pulse := 0.5 + 0.5 * sin(time * 2.0)
	for index in RIFT_SPOTS.size():
		if Quests.is_object_used(Quests.HEARTFROST_DEEP, "melt_rift_%d" % index):
			continue
		draw_set_transform(RIFT_SPOTS[index], 0.0, Vector2(1.0, 0.5))
		draw_circle(Vector2.ZERO, 90.0, Color(RIFT_FIRE, 0.05 + 0.04 * pulse), true, -1.0, true)
		draw_set_transform(Vector2.ZERO)
