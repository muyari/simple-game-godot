extends Node2D
class_name CinderThrone
## The Cinder Throne beneath the Black Gate, where Azkareth the Ember King sleeps under the Emberseal. Built
## far from the Underworld the first time the player goes down: one hall of cracked obsidian drawn smooth like
## the hubs, crossed by channels of lava, lined with skull pillars, with the gate's stair at the south end and
## the throne and its seal at the north. In Beneath the Black Gate, forge-wardens guard the three soul-forges
## feeding the King; in The Ember King, setting the Founders' Brand in the Emberseal wakes the King himself.

## Where the throne room sits in the level, well beyond anywhere the Underworld is ever generated.
const ORIGIN := Vector2(40000, 40000)
## Marks the throne room's monsters, which are held still while the player is up in the Underworld.
const THRONE_META := "cinder_throne"
## Half size of the hall.
const HALF_SIZE := Vector2(720, 420)
const HOUND_SCENE = preload("res://hellhound.tscn")
const FIEND_SCENE = preload("res://fire_fiend.tscn")
const EMBER_KING_SCENE = preload("res://archdemon.tscn")
const PILLARS: Array[Texture2D] = [
	preload("res://textures/underworld_pillar_skull_a.png"),
	preload("res://textures/underworld_pillar_skull_b.png"),
]
const BRAZIER = preload("res://textures/underworld_brazier_box.png")
const FLOOR := Color("#3a2c2c")
const FLOOR_LIGHT := Color("#4a3836")
const CRACK_LINE := Color("#1c1214")
const ROCK := Color("#070303")
const WALL := Color("#2a1616")
const LAVA := Color("#ff5a1f")
const SEAL_GOLD := Color("#ffb347")
const SEAL_SPOT := Vector2(0, -HALF_SIZE.y + 170.0)
const THRONE_SPOT := Vector2(0, -HALF_SIZE.y + 70.0)
const FORGE_SPOTS: Array[Vector2] = [Vector2(-500, -60), Vector2(500, -110), Vector2(-160, 220)]
const WARDEN_SPOTS: Array[Vector2] = [Vector2(-400, 0), Vector2(420, -40), Vector2(-60, 160), Vector2(220, 120)]

var underworld_quests: UnderworldQuests
var wardens: Array[Wolf] = []
var ember_king: Wolf
var time := 0.0


func _ready() -> void:
	z_index = -9
	_build_walls()
	_build_props()
	var exit := QuestObject.new()
	exit.kind = QuestObject.Kind.THRONE_EXIT
	exit.object_id = "cinder_throne_exit"
	exit.door_open = func() -> bool: return true
	exit.used.connect(func(_exit: QuestObject) -> void: underworld_quests.leave_cave())
	exit.position = ORIGIN + Vector2(0, HALF_SIZE.y - 50.0)
	get_parent().add_child.call_deferred(exit)
	for index in FORGE_SPOTS.size():
		var forge := QuestObject.new()
		forge.kind = QuestObject.Kind.SOUL_FORGE
		forge.object_id = "soul_forge_%d" % index
		forge.quest_id = Quests.BLACK_GATE
		var forge_body := _solid(ORIGIN + FORGE_SPOTS[index], 24.0)
		forge_body.add_child(forge)
		get_parent().add_child.call_deferred(forge_body)
	var seal := QuestObject.new()
	seal.kind = QuestObject.Kind.EMBERSEAL
	seal.object_id = "emberseal"
	seal.quest_id = Quests.EMBER_KING
	var seal_body := StaticBody2D.new()
	seal_body.collision_mask = 0
	seal_body.position = ORIGIN + SEAL_SPOT
	var shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 24.0
	capsule.height = 120.0
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


## Sets out whoever the quests have waiting down here: the forge-wardens while the soul-forges burn, the
## Ember King once the Founders' Brand is set in the Emberseal.
func populate() -> void:
	wardens = wardens.filter(func(warden: Wolf) -> bool: return is_instance_valid(warden) and warden.health > 0.0)
	if GameState.get_quest_state(Quests.BLACK_GATE) == "entered" and wardens.is_empty():
		for index in WARDEN_SPOTS.size():
			var scene := FIEND_SCENE if index % 2 == 0 else HOUND_SCENE
			wardens.append(_spawn(scene, WARDEN_SPOTS[index], {"name": "Forge-Warden", "health": 1.6, "experience": 36}, _on_warden_died))
		Audio.play_sfx("boss_incoming")
	if GameState.get_quest_state(Quests.EMBER_KING) == "seal_set" and not is_instance_valid(ember_king):
		ember_king = _spawn(EMBER_KING_SCENE, SEAL_SPOT + Vector2(0, 240), {
			"name": "Azkareth, the Ember King", "scale": 1.25, "health": 1.5, "damage": 1.15, "experience": 900,
			"tint": Color(1.15, 0.8, 0.65),
		}, _on_ember_king_died)
		ember_king.stagger_immune = true
		ember_king.always_alert = true
		for side: float in [-1.0, 1.0]:
			_spawn(FIEND_SCENE, SEAL_SPOT + Vector2(side * 400.0, 280.0), {"name": "Ember Guard", "health": 1.6, "experience": 36}, Callable())
		Audio.play_sfx("boss_incoming")
		Audio.play_music(Audio.BOSS_MUSIC, 0.6)


func _spawn(scene: PackedScene, offset: Vector2, stats: Dictionary, on_died: Callable) -> Wolf:
	var monster := underworld_quests.spawn_quest_monster(scene, ORIGIN + offset, stats, on_died)
	monster.set_meta(THRONE_META, true)
	monster.alert()
	return monster


func _on_warden_died() -> Array[Dictionary]:
	wardens = wardens.filter(func(warden: Wolf) -> bool: return is_instance_valid(warden) and warden.health > 0.0)
	if not wardens.is_empty():
		return []
	return Quests.record_event("clear", "forge_wardens")


func _on_ember_king_died() -> Array[Dictionary]:
	var updates := Quests.record_event("kill", "azkareth")
	underworld_quests.on_ember_king_slain(ember_king.global_position)
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
	# The throne itself stands solid at the head of the hall.
	get_parent().add_child.call_deferred(_solid(ORIGIN + THRONE_SPOT, 60.0))


## A long hall with its corners cut, widening toward the throne, and a short neck at the south end where the
## stair comes down.
func _hall_outline() -> PackedVector2Array:
	var x := HALF_SIZE.x
	var y := HALF_SIZE.y
	return PackedVector2Array([
		Vector2(-x + 140, -y), Vector2(x - 140, -y), Vector2(x, -y + 140), Vector2(x - 40, y - 100), Vector2(x - 140, y - 40),
		Vector2(120, y - 40), Vector2(90, y), Vector2(-90, y), Vector2(-120, y - 40), Vector2(-x + 140, y - 40),
		Vector2(-x + 40, y - 100), Vector2(-x, -y + 140),
	])


func _build_props() -> void:
	# Skull pillars down both sides of the hall, and braziers either side of the throne.
	for column: float in [-560.0, -300.0, 300.0, 560.0]:
		for row: float in [-220.0, 150.0]:
			var spot := Vector2(column, row)
			var near_forge := false
			for forge_spot in FORGE_SPOTS:
				near_forge = near_forge or spot.distance_to(forge_spot) < 130.0
			if not near_forge:
				_standing(PILLARS[absi(int(column + row)) % 2], spot, 0.85, 14.0)
	for side: float in [-1.0, 1.0]:
		_standing(BRAZIER, THRONE_SPOT + Vector2(side * 150.0, 30.0), 0.8, 12.0)


func _solid(world_position: Vector2, radius: float) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_mask = 0
	body.position = world_position
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	shape.position = Vector2(0, -radius * 0.4)
	body.add_child(shape)
	return body


func _standing(texture: Texture2D, offset: Vector2, uniform_scale: float, collision_radius: float) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE * uniform_scale
	sprite.offset = Vector2(0, -texture.get_height() * 0.5)
	sprite.modulate = Color(0.9, 0.78, 0.74)
	var body := _solid(ORIGIN + offset, collision_radius)
	body.add_child(sprite)
	get_parent().add_child.call_deferred(body)


func _draw() -> void:
	# Solid rock as far as the camera can see, then the hall's walls and its floor of cracked obsidian.
	draw_rect(Rect2(-HALF_SIZE * 4.0, HALF_SIZE * 8.0), ROCK)
	var outline := _hall_outline()
	var rim := PackedVector2Array()
	for point in outline:
		rim.append(point * Vector2(1.05, 1.08))
	draw_colored_polygon(rim, WALL)
	SmoothDraw.polygon(self, outline, FLOOR, WALL.lightened(0.2), 6.0)
	var random := RandomNumberGenerator.new()
	random.seed = 4021
	for _crack in 34:
		var start := Vector2(random.randf_range(-HALF_SIZE.x + 80, HALF_SIZE.x - 80), random.randf_range(-HALF_SIZE.y + 80, HALF_SIZE.y - 80))
		var bend := start + Vector2(random.randf_range(-40, 40), random.randf_range(-12, 12))
		draw_polyline(PackedVector2Array([start, bend, bend + Vector2(random.randf_range(-30, 30), random.randf_range(-10, 10))]), Color(CRACK_LINE, 0.7), 1.5, true)
	# Two lava channels down the hall, glowing brighter while the forges burn.
	var forges_lit := not Quests.is_completed(Quests.BLACK_GATE) and GameState.get_quest_state(Quests.BLACK_GATE) != "forges_quenched"
	var heat := (0.6 + 0.4 * sin(time * 1.8)) * (1.0 if forges_lit else 0.4)
	for side: float in [-1.0, 1.0]:
		var channel := PackedVector2Array()
		for step in 9:
			channel.append(Vector2(side * (180.0 + sin(step * 0.8) * 20.0), -HALF_SIZE.y + 120.0 + step * 80.0))
		draw_polyline(channel, Color(0.1, 0.03, 0.02), 14.0, true)
		draw_polyline(channel, Color(LAVA, 0.5 + 0.4 * heat), 8.0, true)
	# The throne: a great seat of black stone with horned back, under the Emberseal's ring of gold.
	draw_set_transform(SEAL_SPOT, 0.0, Vector2(1.0, 0.45))
	draw_arc(Vector2.ZERO, 220.0, 0.0, TAU, 64, Color(SEAL_GOLD, 0.22), 3.0, true)
	draw_set_transform(Vector2.ZERO)
	var seat := THRONE_SPOT
	SmoothDraw.polygon(self, PackedVector2Array([
		seat + Vector2(-70, 0), seat + Vector2(-60, -90), seat + Vector2(-90, -170), seat + Vector2(-40, -120), seat + Vector2(0, -190),
		seat + Vector2(40, -120), seat + Vector2(90, -170), seat + Vector2(60, -90), seat + Vector2(70, 0),
	]), Color("#1a1214"), Color(LAVA, 0.4), 2.0)
	SmoothDraw.polygon(self, PackedVector2Array([seat + Vector2(-50, 0), seat + Vector2(-46, -50), seat + Vector2(46, -50), seat + Vector2(50, 0)]), Color("#2a2228"), Color("#0a0606"), 1.5)
	if is_instance_valid(ember_king) or Quests.is_completed(Quests.EMBER_KING) or GameState.get_quest_state(Quests.EMBER_KING) == "king_slain":
		return
	# Until he wakes, a shape of smouldering coals sits slumped on the throne.
	var breath := 0.5 + 0.5 * sin(time * 0.9)
	SmoothDraw.disc(self, seat + Vector2(0, -80), 30.0, Color(LAVA, 0.15 + 0.15 * breath))
	SmoothDraw.disc(self, seat + Vector2(0, -112), 14.0, Color(LAVA, 0.2 + 0.2 * breath))
