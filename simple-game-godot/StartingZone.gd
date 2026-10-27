extends Node2D
class_name StartingZone
## Where every new character begins: a stretch of forest trail south of Oblath, built far from the rest of
## the Forest Outskirts (like the Gloomhollow) and walked once per character. The player wakes in a
## clearing, meets Perry - lost, and on his way to Oblath for a new hat - and leads him down the trail
## until, in sight of the town's chimney smoke, he runs ahead onto a hunter's hidden spike pit. His hat is
## left at the edge. The trail ends at Oblath's south gate, which takes the player into town and closes
## the starting zone for good (GameState.finish_starting_zone). The HUD's QuestTracker arrow points to
## Perry, then along the trail to the gate.

## Where the trail sits in the level, well beyond anywhere the forest is ever generated.
const ORIGIN := Vector2(-40000, 40000)
## The trail, from the clearing the player wakes in to Oblath's gate, relative to ORIGIN.
const TRAIL: Array[Vector2] = [
	Vector2(0, 0), Vector2(380, -60), Vector2(820, -170), Vector2(1250, -130), Vector2(1650, 40),
	Vector2(2150, 60), Vector2(2560, -110), Vector2(2750, -400), Vector2(2760, -640),
]
const TRAIL_HALF_WIDTH := 170.0
## Open ground off the trail: centre and radius.
const CLEARINGS: Array[Vector3] = [Vector3(-20, 10, 240), Vector3(840, -190, 220), Vector3(2760, -560, 250)]
const ARRIVAL := Vector2(-40, 30)
const PERRY_SPOT := Vector2(890, -220)
const PIT := Vector2(1950, 54)
const HAT_SPOT := Vector2(1996, 84)
const GATE := Vector2(2760, -660)
## Half the width of Oblath's palisade across the end of the trail.
const WALL_HALF_WIDTH := 470.0
## Perry runs ahead once the player is this close to the pit with him in tow.
const PIT_TRIGGER_DISTANCE := 330.0
const PERRY_SPEED := 240.0
const PERRY_DASH_SPEED := 330.0
## Perry stops this close behind the player.
const FOLLOW_GAP := 80.0
## He retraces the player's steps, so he follows round the bends instead of into the trees.
const CRUMB_SPACING := 26.0
const CHATTER_INTERVAL := 10.0
const PERRY_CHATTER: Array[String] = [
	"Do you think they'll still have it in green?",
	"Mind the roots. I nearly lost a boot back there. And I can't afford boots AND a hat.",
	"This hat's seen three winters, two weddings and one very rude goat. It's earned its rest.",
	"A feather! A real one! Off a real bird, probably.",
]
## How far ahead along the trail the arrow points, so it shows the way round the bends.
const ARROW_LOOKAHEAD := 1000.0
## Inside Oblath's south gate.
const TOWN_ARRIVAL := Vector2(576, 1100)
const GROUND_TEXTURE := preload("res://textures/town_grass.png")
const GROUND_TINT := Color(0.84, 0.92, 0.8)
const PATH_EDGE := Color(0.36, 0.27, 0.15, 0.35)
const PATH := Color(0.55, 0.43, 0.27, 0.55)
const PATH_LIGHT := Color(0.68, 0.56, 0.38, 0.35)
const TREES: Array[Dictionary] = [
	{"texture": preload("res://textures/town_tree_pine.png"), "scale": Vector2(0.55, 0.72)},
	{"texture": preload("res://textures/town_tree_spruce.png"), "scale": Vector2(0.68, 0.85)},
	{"texture": preload("res://textures/forest_tree_pine_tall.png"), "scale": Vector2(0.6, 0.75)},
	{"texture": preload("res://textures/forest_tree_oak.png"), "scale": Vector2(0.55, 0.68)},
	{"texture": preload("res://textures/forest_tree_maple.png"), "scale": Vector2(0.62, 0.78)},
	{"texture": preload("res://textures/forest_tree_willow.png"), "scale": Vector2(0.62, 0.75)},
]
const UNDERGROWTH: Array[Dictionary] = [
	{"texture": preload("res://textures/town_fern.png"), "scale": Vector2(0.4, 0.5)},
	{"texture": preload("res://textures/town_shrub_green.png"), "scale": Vector2(0.45, 0.6)},
	{"texture": preload("res://textures/town_shrub_round.png"), "scale": Vector2(0.45, 0.6)},
	{"texture": preload("res://textures/town_shrub_autumn.png"), "scale": Vector2(0.4, 0.5)},
	{"texture": preload("res://textures/town_sapling.png"), "scale": Vector2(0.45, 0.55)},
]
const GROUND_COVER: Array[Dictionary] = [
	{"texture": preload("res://textures/town_grass_clump.png"), "scale": Vector2(0.34, 0.44)},
	{"texture": preload("res://textures/town_flowers.png"), "scale": Vector2(0.34, 0.42)},
	{"texture": preload("res://textures/town_rocks_small.png"), "scale": Vector2(0.3, 0.38)},
]

var player: Player
var perry: HubFolk
var pit: SpikePit
var hat: QuestObject
var gate: QuestObject
## The player's recent footsteps, oldest first, for Perry to walk.
var crumbs: Array[Vector2] = []
var dashing := false
var dash_time := 0.0
var chatter_time := 0.0
var chatter_index := 0
var travelling := false
var hint: Label
var hint_text := ""
## Cumulative length of the trail at each of its points.
var trail_lengths: Array[float] = []


## Where the player wakes.
static func get_arrival() -> Vector2:
	return ORIGIN + ARRIVAL


func _ready() -> void:
	add_to_group(QuestTracker.GUIDES_GROUP)
	z_index = -9
	trail_lengths.append(0.0)
	for index in range(1, TRAIL.size()):
		trail_lengths.append(trail_lengths[index - 1] + TRAIL[index - 1].distance_to(TRAIL[index]))
	_build_ground()
	_build_forest()
	_build_town_wall()
	_build_hint()
	pit = SpikePit.new()
	pit.position = ORIGIN + PIT
	get_parent().add_child.call_deferred(pit)
	_add_signpost(Vector2(150, -96), [1.0])
	# Spun round by some joker, which is how Perry got lost.
	_add_signpost(Vector2(770, -300), [1.0, -1.0])
	GameState.quest_changed.connect(_on_quest_changed)
	_restore_quest_state()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(player) or travelling:
		return
	_update_hint()
	if not is_instance_valid(perry) or GameState.get_quest_state(Quests.PERRYS_HAT) != Quests.STATE_ACCEPTED:
		return
	if dashing:
		_dash(delta)
		return
	_follow()
	chatter_time += delta
	if chatter_time >= CHATTER_INTERVAL:
		chatter_time = 0.0
		perry.say(PERRY_CHATTER[chatter_index % PERRY_CHATTER.size()])
		chatter_index += 1
	var pit_position := ORIGIN + PIT
	if player.global_position.distance_to(pit_position) < PIT_TRIGGER_DISTANCE \
			or perry.global_position.distance_to(pit_position) < PIT_TRIGGER_DISTANCE * 0.6:
		dashing = true
		perry.speed = PERRY_DASH_SPEED
		perry.say("Is that chimney smoke? It's Oblath! Out of my way, friend - that feather won't wait!", 3.0)


func _draw() -> void:
	for clearing in CLEARINGS:
		SmoothDraw.disc(self, ORIGIN + Vector2(clearing.x, clearing.y), clearing.z * 0.55, Color(PATH, 0.25))


# --- Building ---------------------------------------------------------------------------------------------

func _bounds() -> Rect2:
	var bounds := Rect2(TRAIL[0], Vector2.ZERO)
	for point in TRAIL:
		bounds = bounds.expand(point)
	return bounds.grow(700.0)


## How far a point (relative to ORIGIN) is from open ground: negative on the trail or in a clearing.
func _openness(point: Vector2) -> float:
	var nearest := INF
	for index in range(1, TRAIL.size()):
		var closest := Geometry2D.get_closest_point_to_segment(point, TRAIL[index - 1], TRAIL[index])
		nearest = minf(nearest, point.distance_to(closest) - TRAIL_HALF_WIDTH)
	for clearing in CLEARINGS:
		nearest = minf(nearest, point.distance_to(Vector2(clearing.x, clearing.y)) - clearing.z)
	return nearest


## Inside Oblath, behind its palisade: rooftops instead of trees.
func _is_in_town(point: Vector2) -> bool:
	return point.y < GATE.y + 10.0 and absf(point.x - GATE.x) < WALL_HALF_WIDTH - 10.0 and point.y > GATE.y - 460.0


## Grass under the whole trail, with the forest floor's leaves, twigs and mushrooms scattered over it.
func _build_ground() -> void:
	var bounds := _bounds()
	var grass := Sprite2D.new()
	grass.texture = GROUND_TEXTURE
	grass.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	grass.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	grass.region_enabled = true
	grass.region_rect = Rect2(Vector2.ZERO, bounds.size)
	grass.centered = false
	grass.position = ORIGIN + bounds.position
	grass.modulate = GROUND_TINT
	grass.z_index = -1
	add_child(grass)
	# The trail: a worn dirt track with a darker edge and a lighter middle where most feet go.
	for stroke: Array in [[PATH_EDGE, 128.0], [PATH, 104.0], [PATH_LIGHT, 46.0]]:
		var line := Line2D.new()
		for point in TRAIL:
			line.add_point(ORIGIN + point)
		line.default_color = stroke[0]
		line.width = stroke[1]
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		line.antialiased = true
		add_child(line)
	var tile := Vector2(1152, 648)
	var random := RandomNumberGenerator.new()
	random.seed = 4471
	for x in range(int(bounds.position.x), int(bounds.end.x), int(tile.x)):
		for y in range(int(bounds.position.y), int(bounds.end.y), int(tile.y)):
			var floor_detail := ForestFloor.new()
			floor_detail.seed_value = random.randi()
			floor_detail.half_extents = tile * 0.5
			floor_detail.position = ORIGIN + Vector2(x, y) + tile * 0.5
			floor_detail.z_as_relative = false
			floor_detail.z_index = -8
			add_child(floor_detail)


## Dense forest on both sides of the trail, with a solid edge the player can't slip through, and
## undergrowth and grass along the margins.
func _build_forest() -> void:
	var random := RandomNumberGenerator.new()
	random.seed = 9071
	var bounds := _bounds()
	var level := get_parent()
	var edge := StaticBody2D.new()
	edge.collision_mask = 0
	edge.position = ORIGIN
	for y in range(int(bounds.position.y), int(bounds.end.y), 36):
		for x in range(int(bounds.position.x), int(bounds.end.x), 36):
			var cell := Vector2(x, y)
			var openness := _openness(cell)
			if openness > 16.0 and openness < 92.0:
				var shape := CollisionShape2D.new()
				var circle := CircleShape2D.new()
				circle.radius = 26.0
				shape.shape = circle
				shape.position = cell
				edge.add_child(shape)
	level.add_child.call_deferred(edge)
	for row in int(bounds.size.y / 50.0):
		for column in int(bounds.size.x / 70.0):
			var spot := bounds.position + Vector2((column + (0.5 if row % 2 == 1 else 0.0)) * 70.0, row * 50.0)
			spot += Vector2(random.randf_range(-22.0, 22.0), random.randf_range(-16.0, 16.0))
			var openness := _openness(spot)
			if openness < 24.0 or openness > 640.0 or _is_in_town(spot):
				continue
			if openness > 320.0 and random.randf() < 0.3:
				continue
			# Below the trail a tall canopy would hide whoever walks along it, so keep that side low.
			if _openness(spot - Vector2(0, 170)) < 10.0:
				if openness < 170.0:
					_add_sprite(UNDERGROWTH[random.randi() % UNDERGROWTH.size()], spot, random)
				continue
			_add_sprite(TREES[random.randi() % TREES.size()], spot, random)
	# Shrubs and ferns crowding the trail's edges, and grass and flowers on it.
	for index in 1400:
		var spot := bounds.position + Vector2(random.randf() * bounds.size.x, random.randf() * bounds.size.y)
		var openness := _openness(spot)
		if openness > -40.0 and openness < 30.0 and not _is_in_town(spot) and spot.distance_to(PIT) > 90.0:
			_add_sprite(UNDERGROWTH[random.randi() % UNDERGROWTH.size()], spot, random)
		elif openness < -60.0 and index % 3 == 0 and spot.distance_to(PIT) > 90.0:
			_add_sprite(GROUND_COVER[random.randi() % GROUND_COVER.size()], spot, random, -4)


func _add_sprite(prop: Dictionary, spot: Vector2, random: RandomNumberGenerator, z := 0) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = prop["texture"]
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var scale_range: Vector2 = prop["scale"]
	sprite.scale = Vector2.ONE * random.randf_range(scale_range.x, scale_range.y)
	sprite.offset = Vector2(0.0, -sprite.texture.get_height() * 0.5)
	sprite.flip_h = random.randf() < 0.5
	sprite.position = ORIGIN + spot
	sprite.z_index = z
	get_parent().add_child.call_deferred(sprite)


## Oblath's south palisade across the end of the trail, its gate, and the town's roofs beyond.
func _build_town_wall() -> void:
	var level := get_parent()
	var wall := StaticBody2D.new()
	wall.collision_mask = 0
	wall.position = ORIGIN + GATE
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(WALL_HALF_WIDTH * 2.0, 30.0)
	shape.shape = rectangle
	shape.position = Vector2(0, -12)
	wall.add_child(shape)
	level.add_child.call_deferred(wall)
	var wing_length := WALL_HALF_WIDTH - 76.0
	for side: float in [-1.0, 1.0]:
		var wing := HubProp.new()
		wing.kind = HubProp.Kind.PALISADE
		wing.length = wing_length
		wing.position = ORIGIN + GATE + Vector2(side * (76.0 + wing_length * 0.5), 0)
		level.add_child.call_deferred(wing)
	var roofs := OblathRoofs.new()
	roofs.position = ORIGIN + GATE + Vector2(0, -50)
	level.add_child.call_deferred(roofs)
	gate = QuestObject.new()
	gate.kind = QuestObject.Kind.TOWN_GATE
	gate.object_id = "oblath_south_gate"
	gate.door_open = func() -> bool:
		return GameState.get_quest_state(Quests.PERRYS_HAT) == "hat_taken" and GameState.is_in_starting_zone()
	gate.used.connect(_on_gate_used.unbind(1))
	gate.position = ORIGIN + GATE + Vector2(0, 2)
	level.add_child.call_deferred(gate)


func _add_signpost(spot: Vector2, pointing: Array) -> void:
	var signpost := Signpost.new()
	signpost.pointing.assign(pointing)
	var body := StaticBody2D.new()
	body.collision_mask = 0
	body.position = ORIGIN + spot
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 6.0
	shape.shape = circle
	body.add_child(shape)
	body.add_child(signpost)
	get_parent().add_child.call_deferred(body)


# --- Perry -----------------------------------------------------------------------------------------------

func _restore_quest_state() -> void:
	var quest_state := GameState.get_quest_state(Quests.PERRYS_HAT)
	if quest_state in [Quests.STATE_AVAILABLE, Quests.STATE_ACCEPTED]:
		# Back after a break mid-walk, he's waiting where the player wakes.
		_spawn_perry(PERRY_SPOT if quest_state == Quests.STATE_AVAILABLE else ARRIVAL + Vector2(70, -20))
		return
	pit.opened = true
	if quest_state == "perry_fell":
		_spawn_hat()


func _spawn_perry(spot: Vector2) -> void:
	perry = HubFolk.new()
	perry.display_name = "Perry"
	perry.skin = Color("#e0b18c")
	perry.clothes = Color("#7a6248")
	perry.trim = Color("#a8875a")
	perry.pants = Color("#4e4436")
	perry.hair = Color("#c9c3b8")
	perry.headwear = HubFolk.Headwear.FELT_HAT
	perry.held = HubFolk.Held.STAFF
	perry.rest_facing = -1.0
	perry.position = ORIGIN + spot
	_refresh_perry_lines()
	get_parent().add_child.call_deferred(perry)
	QuestTalker.attach(perry, "perry", 74.0)


func _refresh_perry_lines() -> void:
	if GameState.get_quest_state(Quests.PERRYS_HAT) == Quests.STATE_AVAILABLE:
		perry.lines.assign(["Hello? Is somebody there? Please be a person.", "Which way is Oblath? The sign says both ways. Signs shouldn't do that."])
	else:
		perry.lines.clear()
		# He walks the player's path himself, so he doesn't stop when they come near.
		perry.stops_for_player = false


func _follow() -> void:
	if crumbs.is_empty() or player.global_position.distance_to(crumbs.back()) > CRUMB_SPACING:
		crumbs.append(player.global_position)
	var distance := perry.global_position.distance_to(player.global_position)
	if distance < FOLLOW_GAP:
		crumbs.clear()
		perry.walking = false
		perry.velocity = Vector2.ZERO
		return
	while crumbs.size() > 1 and perry.global_position.distance_to(crumbs[0]) < 18.0:
		crumbs.pop_front()
	perry.target = crumbs[0] if not crumbs.is_empty() else player.global_position
	perry.speed = PERRY_SPEED if distance < 280.0 else PERRY_SPEED * 1.5
	perry.walking = true


## Perry runs for the town, straight onto the pit's covering.
func _dash(delta: float) -> void:
	dash_time += delta
	var pit_position := ORIGIN + PIT
	if perry.global_position.distance_to(pit_position) < 14.0 or dash_time > 4.0:
		_drop_perry()
		return
	perry.target = pit_position
	perry.walking = true


func _drop_perry() -> void:
	var falling := perry
	perry = null
	falling.walking = false
	falling.velocity = Vector2.ZERO
	falling.say("Wh-", 0.6)
	pit.collapse()
	Audio.play_sfx_at("pit_collapse", pit.global_position)
	var tween := falling.create_tween()
	tween.tween_property(falling, "global_position", ORIGIN + PIT + Vector2(0, 4), 0.12)
	tween.tween_property(falling, "global_position:y", ORIGIN.y + PIT.y + 22.0, 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(falling, "scale", Vector2(0.75, 0.5), 0.3)
	tween.parallel().tween_property(falling, "modulate:a", 0.0, 0.3)
	tween.tween_callback(falling.queue_free)
	# A moment of silence before the quest moves on; on the zone, since Perry is gone by then.
	var aftermath := create_tween()
	aftermath.tween_interval(1.6)
	aftermath.tween_callback(func() -> void:
		QuestToast.show_updates(get_tree(), Quests.record_event("fall", "perry"))
	)


func _spawn_hat() -> void:
	if is_instance_valid(hat):
		return
	hat = QuestObject.new()
	hat.kind = QuestObject.Kind.PERRYS_HAT
	hat.object_id = "perrys_hat"
	hat.quest_id = Quests.PERRYS_HAT
	hat.position = ORIGIN + HAT_SPOT
	get_parent().add_child.call_deferred(hat)


func _on_quest_changed(quest_id: String) -> void:
	if quest_id != Quests.PERRYS_HAT:
		return
	var quest_state := GameState.get_quest_state(quest_id)
	if quest_state == Quests.STATE_ACCEPTED and is_instance_valid(perry):
		_refresh_perry_lines()
		chatter_time = CHATTER_INTERVAL * 0.4
	elif quest_state == "perry_fell":
		_spawn_hat()


# --- Oblath's gate ---------------------------------------------------------------------------------------

func _on_gate_used() -> void:
	if travelling or not GameState.is_in_starting_zone():
		return
	travelling = true
	player.set_physics_process(false)
	player.velocity = Vector2.ZERO
	Audio.play_sfx("gate_open")
	QuestToast.show_updates(get_tree(), Quests.record_event("enter", "oblath"))
	if not GameState.finish_starting_zone():
		push_error("Could not save the end of the starting zone.")
	_set_hint("")
	var tween := gate.create_tween()
	tween.tween_property(gate, "open_amount", 1.0, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_interval(1.4)
	tween.tween_callback(_enter_oblath)


func _enter_oblath() -> void:
	get_tree().set_meta("portal_spawn_position", TOWN_ARRIVAL)
	get_tree().set_meta("portal_player_vitals", {"health": player.health, "mana": player.mana})
	var error := GameState.change_scene(GameState.get_hub_scene(1))
	if error != OK:
		get_tree().remove_meta("portal_spawn_position")
		get_tree().remove_meta("portal_player_vitals")
		travelling = false
		player.set_physics_process(true)
		push_error("Could not enter Oblath: %s" % error_string(error))


# --- Guidance --------------------------------------------------------------------------------------------

## Where the HUD's arrow should point, as {position, label}: to Perry, then down the trail to the gate.
func get_tracked_target() -> Dictionary:
	match GameState.get_quest_state(Quests.PERRYS_HAT):
		Quests.STATE_AVAILABLE:
			if is_instance_valid(perry):
				return {"position": _along_trail(perry.global_position), "label": "Someone calling for help"}
		Quests.STATE_ACCEPTED, "hat_taken":
			return {"position": _along_trail(ORIGIN + GATE), "label": "Oblath"}
		"perry_fell":
			return {"position": ORIGIN + HAT_SPOT, "label": "Perry's hat"}
	return {}


## goal, or the point a little way ahead of the player along the trail toward it if it's further than that.
func _along_trail(goal: Vector2) -> Vector2:
	var from := _trail_distance(player.global_position - ORIGIN)
	var to := _trail_distance(goal - ORIGIN)
	if absf(to - from) <= ARROW_LOOKAHEAD:
		return goal
	return ORIGIN + _trail_point(from + signf(to - from) * ARROW_LOOKAHEAD)


## How far along the trail the point nearest this one lies.
func _trail_distance(point: Vector2) -> float:
	var best := INF
	var along := 0.0
	for index in range(1, TRAIL.size()):
		var closest := Geometry2D.get_closest_point_to_segment(point, TRAIL[index - 1], TRAIL[index])
		var distance := point.distance_squared_to(closest)
		if distance < best:
			best = distance
			along = trail_lengths[index - 1] + TRAIL[index - 1].distance_to(closest)
	return along


func _trail_point(along: float) -> Vector2:
	for index in range(1, TRAIL.size()):
		if along <= trail_lengths[index]:
			var weight := (along - trail_lengths[index - 1]) / maxf(trail_lengths[index] - trail_lengths[index - 1], 0.001)
			return TRAIL[index - 1].lerp(TRAIL[index], clampf(weight, 0.0, 1.0))
	return TRAIL.back()


func _build_hint() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	hint = Label.new()
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	hint.offset_left = -300.0
	hint.offset_right = 300.0
	hint.offset_top = -236.0
	hint.offset_bottom = -196.0
	hint.add_theme_font_size_override("font_size", 17)
	hint.add_theme_color_override("font_color", Color("#f3ead8"))
	MenuStyle.outline_hud_label(hint)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.modulate.a = 0.0
	layer.add_child(hint)


## A line of guidance at the bottom of the screen for each step of the walk.
func _update_hint() -> void:
	var quest_state := GameState.get_quest_state(Quests.PERRYS_HAT)
	var text := ""
	var dialogue := get_tree().get_first_node_in_group(QuestDialogue.GROUP) as Control
	if dialogue != null and dialogue.is_visible_in_tree():
		pass
	elif quest_state == Quests.STATE_AVAILABLE:
		if player.global_position.distance_to(get_arrival()) < 220.0:
			text = "Drag the left stick to walk." if TouchControls.is_supported() \
					else "Click the ground to walk there, hold the mouse to keep walking, or use the arrow keys."
		elif is_instance_valid(perry) and player.global_position.distance_to(perry.global_position) > 240.0:
			text = "Someone is calling for help. Follow the gold arrow at the edge of the screen."
		else:
			text = "Walk up to the stranger and talk to them."
	elif quest_state == Quests.STATE_ACCEPTED and not dashing:
		text = "Perry is following you. Lead him down the trail to Oblath."
	elif quest_state == "perry_fell":
		text = "Perry is gone. Take his hat from the edge of the pit."
	elif quest_state == "hat_taken":
		text = "Follow the trail to Oblath's gate and enter the town."
	_set_hint(text)


func _set_hint(text: String) -> void:
	if text == hint_text:
		return
	hint_text = text
	var tween := hint.create_tween()
	tween.tween_property(hint, "modulate:a", 0.0, 0.2)
	if not text.is_empty():
		tween.tween_callback(func() -> void: hint.text = text)
		tween.tween_property(hint, "modulate:a", 1.0, 0.3)


# --- Scenery ---------------------------------------------------------------------------------------------

## A hunter's pit dug across the trail and covered with branches and leaves. collapse() drops the covering
## to show the sharpened stakes beneath, with a burst of dust.
class SpikePit extends Node2D:
	const OUTLINE := Color(0.13, 0.08, 0.05)
	const EARTH := Color("#5e4429")
	const EARTH_DARK := Color("#3a2918")
	const STAKE := Color("#b48452")
	const STAKE_TIP := Color("#e2cfa8")
	const LEAF := Color("#7a6a30")
	const RADII := Vector2(48, 22)

	var opened := false:
		set(value):
			opened = value
			queue_redraw()
	var dust_time := -1.0
	var solid: StaticBody2D

	func _ready() -> void:
		z_index = -5
		solid = StaticBody2D.new()
		solid.collision_mask = 0
		var shape := CollisionPolygon2D.new()
		var points := PackedVector2Array()
		for index in 16:
			var angle := TAU * index / 16.0
			points.append(Vector2(cos(angle), sin(angle)) * (RADII - Vector2(6, 4)))
		shape.polygon = points
		solid.add_child(shape)
		add_child(solid)
		solid.process_mode = Node.PROCESS_MODE_INHERIT if opened else Node.PROCESS_MODE_DISABLED

	func collapse() -> void:
		opened = true
		dust_time = 0.0
		solid.process_mode = Node.PROCESS_MODE_INHERIT

	func _process(delta: float) -> void:
		if dust_time < 0.0:
			return
		dust_time += delta
		if dust_time > 1.2:
			dust_time = -1.0
		queue_redraw()

	func _draw() -> void:
		if not opened:
			# Branches and dead leaves over the hole: easy to miss if you're looking at the horizon.
			_ellipse(Vector2.ZERO, RADII, Color(LEAF, 0.45))
			for twig: Vector4 in [Vector4(-40, -6, 30, 8), Vector4(-30, 10, 36, -10), Vector4(-12, -18, 6, 18), Vector4(10, -16, 42, 4)]:
				draw_line(Vector2(twig.x, twig.y), Vector2(twig.z, twig.w), Color("#5a3b22"), 2.0, true)
			for leaf: Vector2 in [Vector2(-28, 2), Vector2(-6, -8), Vector2(16, 8), Vector2(30, -4), Vector2(2, 12), Vector2(-18, -14)]:
				SmoothDraw.disc(self, leaf, 3.0, Color("#9a7a36"))
			return
		_ellipse(Vector2.ZERO, RADII + Vector2(6, 4), EARTH)
		_ellipse(Vector2(0, 2), RADII, EARTH_DARK)
		_ellipse(Vector2(0, 5), RADII - Vector2(8, 6), Color(0.06, 0.04, 0.02))
		# Stakes, back row first, their points just showing over the rim.
		for stake: Vector3 in [Vector3(-26, 0, 14), Vector3(-8, -2, 17), Vector3(10, -1, 15), Vector3(26, 1, 13),
				Vector3(-18, 8, 16), Vector3(2, 9, 18), Vector3(20, 9, 15)]:
			var base := Vector2(stake.x, stake.y + 6.0)
			var tip := Vector2(stake.x + 1.0, stake.y - stake.z + 6.0)
			draw_colored_polygon(PackedVector2Array([base + Vector2(-3, 0), tip, base + Vector2(3, 0)]), STAKE)
			draw_line(tip, tip + Vector2(0, 5), STAKE_TIP, 2.0, true)
		# What's left of the covering, snapped at the rim.
		for twig: Vector4 in [Vector4(-52, -2, -38, 4), Vector4(40, -8, 54, 0), Vector4(-20, -22, -8, -16)]:
			draw_line(Vector2(twig.x, twig.y), Vector2(twig.z, twig.w), Color("#5a3b22"), 2.0, true)
		if dust_time >= 0.0:
			var spread := dust_time / 1.2
			for index in 9:
				var angle := TAU * index / 9.0
				var center := Vector2(cos(angle) * RADII.x, sin(angle) * RADII.y) * (0.6 + spread * 0.9) + Vector2(0, -spread * 26.0)
				SmoothDraw.disc(self, center, 9.0 + spread * 10.0, Color(0.62, 0.52, 0.38, 0.45 * (1.0 - spread)))

	func _ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
		var points := PackedVector2Array()
		for index in 32:
			var angle := TAU * index / 32.0
			points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
		draw_colored_polygon(points, color)


## A weathered wooden signpost; each entry in `pointing` is one board, pointing right (1) or left (-1),
## all reading "OBLATH".
class Signpost extends Node2D:
	const OUTLINE := Color(0.13, 0.08, 0.05)
	const WOOD := Color("#8a5d33")
	const WOOD_LIGHT := Color("#b48452")

	var pointing: Array[float] = [1.0]

	func _draw() -> void:
		SmoothDraw.shadow(self, Vector2(-2, 1), Vector2(22, 6))
		SmoothDraw.box(self, Rect2(-3, -56, 6, 56), WOOD.darkened(0.15), 2.0)
		var font := ThemeDB.fallback_font
		for index in pointing.size():
			var side := pointing[index]
			var y := -52.0 + index * 15.0
			var tip := side * 34.0
			SmoothDraw.polygon(self, PackedVector2Array([
				Vector2(-side * 20.0, y), Vector2(tip - side * 8.0, y), Vector2(tip, y + 6.0),
				Vector2(tip - side * 8.0, y + 12.0), Vector2(-side * 20.0, y + 12.0),
			]), WOOD_LIGHT.darkened(index * 0.12), OUTLINE, 1.0)
			var width := font.get_string_size("OBLATH", HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
			draw_string(font, Vector2(side * 6.0 - width * 0.5, y + 10.0), "OBLATH", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, WOOD.darkened(0.5))


## Oblath's rooftops over the palisade, with chimney smoke drifting up: the end of the trail in sight.
class OblathRoofs extends Node2D:
	const OUTLINE := Color(0.13, 0.08, 0.05)
	const PLASTER := Color("#d9c9a8")
	const BEAM := Color("#5c3c22")
	const STONE := Color("#8f8a7c")
	## x, base y, width, roof colour.
	const HOUSES: Array[Array] = [
		[-330.0, -20.0, 150.0, Color("#8c4a32")], [-140.0, -90.0, 130.0, Color("#6e5a3a")],
		[150.0, -70.0, 160.0, Color("#7a3e2c")], [340.0, -10.0, 130.0, Color("#6e5a3a")],
	]

	var time := 0.0

	func _process(delta: float) -> void:
		time += delta
		queue_redraw()

	func _draw() -> void:
		for house: Array in HOUSES:
			var x: float = house[0]
			var base: float = house[1]
			var width: float = house[2]
			var roof: Color = house[3]
			SmoothDraw.box(self, Rect2(x - width * 0.4, base - 60.0, width * 0.8, 60.0), PLASTER, 2.0)
			draw_line(Vector2(x - width * 0.4, base - 34.0), Vector2(x + width * 0.4, base - 34.0), BEAM, 3.0, true)
			SmoothDraw.box(self, Rect2(x + width * 0.18, base - 112.0, 16, 34), STONE, 2.0)
			SmoothDraw.polygon(self, PackedVector2Array([
				Vector2(x - width * 0.52, base - 56.0), Vector2(x, base - 108.0), Vector2(x + width * 0.52, base - 56.0),
			]), roof, OUTLINE, 1.5)
			draw_line(Vector2(x - width * 0.3, base - 77.0), Vector2(x + width * 0.3, base - 77.0), Color(roof.darkened(0.25), 0.7), 1.5, true)
			# Smoke curling up from the chimney.
			for puff in 5:
				var rise := fmod(time * 0.25 + puff / 5.0 + x * 0.001, 1.0)
				var center := Vector2(x + width * 0.18 + 8.0 + sin(rise * 5.0 + x) * 8.0 + rise * 30.0, base - 116.0 - rise * 120.0)
				SmoothDraw.disc(self, center, 6.0 + rise * 12.0, Color(0.85, 0.85, 0.82, 0.35 * (1.0 - rise)))
