extends Node2D
class_name Gloomhollow
## The cave west of Aldous's camp where Gloomfang has made its den, and where the herbwife Ilsa's journal
## lies hidden. Built far from the forest the first time the player goes in: one walled chamber drawn smooth
## like the hubs (damp stone floor, a rim of rock, glowing crystals and mushrooms, old bones), with the way
## out at the south end and the journal at the back. Gloomfang and two of its pack wait inside until the
## quest is past them.

## Where the cave sits in the level, well beyond anywhere the forest is ever generated.
const ORIGIN := Vector2(40000, 40000)
## Marks the cave's monsters, which are held still while the player is out in the forest.
const CAVE_META := "gloomhollow"
## Half size of the chamber.
const HALF_SIZE := Vector2(620, 380)
const WALL_STEPS := 72
const FLOOR := Color("#4a4552")
const FLOOR_LIGHT := Color("#5b5664")
const ROCK := Color("#0c0b0f")
const ROCK_EDGE := Color("#6a6474")
const BOULDER := Color("#34303c")
const CRYSTAL := Color("#8fd8ff")
const OUTLINE := Color(0.06, 0.05, 0.07)

var forest_quests: ForestQuests
var outline := PackedVector2Array()
var gloomfang: Wolf
var pack: Array[Wolf] = []
var random := RandomNumberGenerator.new()
var time := 0.0


func _ready() -> void:
	random.seed = 9134
	z_index = -9
	outline = _chamber_outline()
	_build_walls()
	_build_props()
	var exit := QuestObject.new()
	exit.kind = QuestObject.Kind.CAVE_EXIT
	exit.object_id = "gloomhollow_exit"
	exit.door_open = func() -> bool: return true
	exit.used.connect(func(_exit: QuestObject) -> void: forest_quests.leave_cave())
	exit.position = ORIGIN + Vector2(0, HALF_SIZE.y - 60.0)
	get_parent().add_child.call_deferred(exit)
	var journal := QuestObject.new()
	journal.kind = QuestObject.Kind.JOURNAL
	journal.object_id = "ilsas_journal"
	journal.quest_id = Quests.GLOOMHOLLOW
	journal.position = ORIGIN + Vector2(40, -HALF_SIZE.y + 110.0)
	get_parent().add_child.call_deferred(journal)


func _process(delta: float) -> void:
	time += delta
	queue_redraw()


## Where the player stands on coming in: just inside the mouth.
func get_arrival() -> Vector2:
	return ORIGIN + Vector2(0, HALF_SIZE.y - 150.0)


## Sets out the den's wolves while the quest still has the player fighting them.
func populate() -> void:
	if GameState.get_quest_state(Quests.GLOOMHOLLOW) != "entered" or is_instance_valid(gloomfang):
		return
	gloomfang = forest_quests.spawn_quest_wolf(ORIGIN + Vector2(0, -120), {
		"name": "Gloomfang", "scale": 1.6, "health": 8.0, "damage": 1.45, "experience": 120,
		"tint": Color(0.36, 0.32, 0.42),
	}, func() -> Array[Dictionary]: return Quests.record_event("kill", "gloomfang"))
	gloomfang.set_meta(CAVE_META, true)
	pack.clear()
	for side: float in [-1.0, 1.0]:
		var wolf := forest_quests.spawn_quest_wolf(ORIGIN + Vector2(side * 260.0, -40.0), {
			"name": "Gloomhollow Wolf", "health": 1.6, "experience": 20, "tint": Color(0.55, 0.52, 0.6),
		}, Callable())
		wolf.set_meta(CAVE_META, true)
		pack.append(wolf)


## An uneven oval: the chamber's floor edge, wobbled by a few low-frequency waves.
func _chamber_outline() -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in WALL_STEPS:
		var angle := TAU * index / WALL_STEPS
		var wobble := 1.0 + 0.07 * sin(angle * 3.0 + 0.6) + 0.05 * sin(angle * 5.0 + 2.1) + 0.03 * sin(angle * 9.0)
		# A narrower neck at the south end, where the mouth is.
		var neck := 1.0 - 0.45 * pow(maxf(sin(angle), 0.0), 12.0)
		points.append(Vector2(cos(angle) * HALF_SIZE.x * wobble * neck, sin(angle) * HALF_SIZE.y * wobble))
	return points


func _build_walls() -> void:
	var walls := StaticBody2D.new()
	walls.collision_mask = 0
	walls.position = ORIGIN
	var shape := CollisionPolygon2D.new()
	shape.build_mode = CollisionPolygon2D.BUILD_SEGMENTS
	var closed := outline.duplicate()
	closed.append(outline[0])
	shape.polygon = closed
	walls.add_child(shape)
	get_parent().add_child.call_deferred(walls)


func _build_props() -> void:
	# Crystal clusters and stalagmites stand up (and y-sort); mushrooms and bones lie flat.
	for spot: Vector2 in [Vector2(-470, -150), Vector2(430, -210), Vector2(-260, -280), Vector2(330, 120), Vector2(-380, 160), Vector2(150, -300)]:
		_standing(CaveProp.Kind.CRYSTAL, spot, 14.0)
	for spot: Vector2 in [Vector2(-180, 40), Vector2(240, -90), Vector2(-520, 20), Vector2(520, -20), Vector2(60, 210)]:
		_standing(CaveProp.Kind.STALAGMITE, spot, 12.0)
	for spot: Vector2 in [Vector2(-300, 250), Vector2(380, 250), Vector2(-90, -200), Vector2(470, 60), Vector2(-430, -40)]:
		_standing(CaveProp.Kind.MUSHROOMS, spot, 0.0)
	for spot: Vector2 in [Vector2(-60, -60), Vector2(120, -150), Vector2(-220, -130), Vector2(200, 40)]:
		_standing(CaveProp.Kind.BONES, spot, 0.0)


func _standing(kind: CaveProp.Kind, offset: Vector2, collision_radius: float) -> void:
	var prop := CaveProp.new()
	prop.kind = kind
	prop.variant = random.randi() % 3
	if collision_radius <= 0.0:
		prop.position = ORIGIN + offset
		get_parent().add_child.call_deferred(prop)
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
	body.add_child(prop)
	get_parent().add_child.call_deferred(body)


func _draw() -> void:
	# Solid rock as far as the camera can see, then the chamber floor with a rim of lit stone.
	draw_rect(Rect2(-HALF_SIZE * 4.0, HALF_SIZE * 8.0), ROCK)
	var rim := PackedVector2Array()
	for point in outline:
		rim.append(point * 1.06)
	draw_colored_polygon(rim, ROCK_EDGE.darkened(0.35))
	SmoothDraw.polygon(self, outline, FLOOR, ROCK_EDGE, 6.0)
	# Damp, lighter patches on the floor.
	for patch: Vector3 in [Vector3(-200, -60, 150), Vector3(230, 40, 170), Vector3(-30, 180, 120), Vector3(320, -200, 110), Vector3(-380, 80, 120)]:
		draw_set_transform(Vector2(patch.x, patch.y), 0.0, Vector2(1.0, 0.55))
		SmoothDraw.disc(self, Vector2.ZERO, patch.z, Color(FLOOR_LIGHT, 0.55))
		draw_set_transform(Vector2.ZERO)
	# Boulders heaped round the edge make the walls.
	var boulders := RandomNumberGenerator.new()
	boulders.seed = 31
	for index in range(0, outline.size(), 2):
		var point := outline[index] * 1.05
		SmoothDraw.dome(self, point, boulders.randf_range(20.0, 34.0), BOULDER.lightened(boulders.randf_range(0.0, 0.15)), OUTLINE)
	# Pebbles scattered over the floor.
	var pebbles := RandomNumberGenerator.new()
	pebbles.seed = 77
	for _index in 70:
		var spot := Vector2(pebbles.randf_range(-0.85, 0.85) * HALF_SIZE.x, pebbles.randf_range(-0.8, 0.8) * HALF_SIZE.y)
		SmoothDraw.disc(self, spot, pebbles.randf_range(1.5, 3.5), Color(ROCK_EDGE, 0.55))
	# Daylight spilling in at the mouth, and the glow round the journal's resting stone.
	var mouth := Vector2(0, HALF_SIZE.y - 60.0)
	for ring in 4:
		draw_set_transform(mouth, 0.0, Vector2(1.0, 0.5))
		SmoothDraw.disc(self, Vector2.ZERO, 150.0 - ring * 30.0, Color(1.0, 0.95, 0.8, 0.05))
		draw_set_transform(Vector2.ZERO)
	var pulse := 0.5 + 0.5 * sin(time * 1.6)
	draw_set_transform(Vector2(40, -HALF_SIZE.y + 110.0), 0.0, Vector2(1.0, 0.5))
	SmoothDraw.disc(self, Vector2.ZERO, 90.0, Color(CRYSTAL, 0.05 + 0.03 * pulse))
	draw_set_transform(Vector2.ZERO)
