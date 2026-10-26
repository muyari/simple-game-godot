extends Node
class_name ForestQuests
## The quest sites of the campaign's Forest Outskirts. The forest is endless and rebuilt region by region,
## so each site belongs to a fixed region (relative to the start) and is built when the LevelController
## generates that region: Corwin's hunting camp by the road, Aldous's hermitage and the moonpetals round
## it, the Gloomhollow's mouth, Rendel's felling site, Pip hiding from the wolves, Old Scar-Ear's ground,
## the Mossy Shrine and its three wayfires. Also runs the encounters (Scar-Ear, the wolves circling Pip,
## Gloomfang) and the trip into and out of the Gloomhollow, and tells the HUD where the next objective is.

const GROUP := "forest_quests"
const WOLF_SCENE = preload("res://wolf.tscn")
## Quest monsters fight outside the level's tally: they are not saved with the level, never called in as
## stragglers, and come back while their quest still needs them.
const QUEST_MONSTER_META := "quest_monster"

const CORWIN_REGION := Vector2i(0, 0)
## Corwin's camp, from where the player enters the forest.
const CORWIN_OFFSET := Vector2(270, -50)
const ALDOUS_REGION := Vector2i(-2, 2)
const MOONPETAL_REGIONS: Array[Vector2i] = [Vector2i(-3, 2), Vector2i(-1, 2), Vector2i(-2, 3), Vector2i(-2, 1)]
const CAVE_REGION := Vector2i(-4, 2)
const FELLING_REGION := Vector2i(3, -2)
const PIP_REGION := Vector2i(2, 2)
const SCAR_EAR_REGION := Vector2i(5, 0)
const SHRINE_REGION := Vector2i(0, -2)
const WAYFIRE_REGIONS: Array[Vector2i] = [Vector2i(-2, -3), Vector2i(1, -4), Vector2i(3, -3)]
## Where in their regions the moonpetals and wayfires grow, so they aren't all dead centre.
const SCATTER_OFFSETS: Array[Vector2] = [Vector2(-140, 70), Vector2(160, -40), Vector2(-60, -110), Vector2(120, 100)]
## Pip's guards appear when the player comes this close to him.
const PIP_FIND_DISTANCE := 300.0
const PIP_GUARD_COUNT := 3
## The light underground.
const CAVE_TINT := Color(0.7, 0.7, 0.84)

var level_controller: Node
var level: Node2D
var player: Player
var pip: HubFolk
var pip_site := Vector2.ZERO
var pip_guards: Array[Wolf] = []
var scar_ear: Wolf
var cave: Gloomhollow
var cave_mouth: QuestObject
var in_cave := false
var cave_return_position := Vector2.ZERO
var fade: ColorRect

var travelling := false


## Called by the LevelController before its first scenery is generated.
func setup(controller: Node, level_root: Node2D, level_player: Player) -> void:
	level_controller = controller
	level = level_root
	player = level_player


func _ready() -> void:
	add_to_group(GROUP)
	add_to_group(QuestTracker.GUIDES_GROUP)
	GameState.quest_changed.connect(_on_quest_changed)
	var layer := CanvasLayer.new()
	layer.layer = 90
	add_child(layer)
	fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(fade)


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(player) or player.health <= 0:
		return
	_update_pip()


# --- Building sites --------------------------------------------------------------------------------------

## Builds whatever quest site belongs to this region. Runs before the region's trees are placed, so they
## grow round it.
func populate_region(region: Vector2i, region_center: Vector2) -> void:
	if region == CORWIN_REGION:
		_build_corwin_camp(_entry_point() + CORWIN_OFFSET)
	elif region == ALDOUS_REGION:
		_build_aldous_camp(region_center)
	elif region == CAVE_REGION:
		_build_cave_mouth(region_center)
	elif region == FELLING_REGION:
		_build_felling_site(region_center)
	elif region == PIP_REGION:
		_build_pip_site(region_center)
	elif region == SCAR_EAR_REGION:
		_spawn_scar_ear(region_center)
	elif region == SHRINE_REGION:
		_build_shrine(region_center)
	var petal_index := MOONPETAL_REGIONS.find(region)
	if petal_index >= 0:
		_add_object(QuestObject.Kind.MOONPETAL, region_center + SCATTER_OFFSETS[petal_index], "moonpetal_%d" % petal_index, Quests.MOONPETAL_REMEDY, Vector2(20, 10))
	var fire_index := WAYFIRE_REGIONS.find(region)
	if fire_index >= 0:
		_add_object(QuestObject.Kind.WAYFIRE, region_center + SCATTER_OFFSETS[fire_index + 1], "wayfire_%d" % fire_index, Quests.WAYFIRES, Vector2(26, 12), 12.0)


## Lets the player pick a wild apple tree for Mary.
func decorate_apple_tree(apple_tree: AppleTree) -> void:
	var picking := QuestObject.new()
	picking.kind = QuestObject.Kind.APPLES
	picking.object_id = apple_tree.get_tree_id()
	picking.quest_id = Quests.WILD_APPLES
	apple_tree.add_child(picking)


func _build_corwin_camp(center: Vector2) -> void:
	_claim(center, Vector2(130, 60))
	_hub_prop(HubProp.Kind.CAMPFIRE, center + Vector2(-46, 18), {}, 12.0)
	_hub_prop(HubProp.Kind.DRYING_RACK, center + Vector2(40, -26), {"tint": Color("#8a6a4a")}, 8.0)
	var corwin := _folk(center + Vector2(0, 26), {
		"display_name": "Corwin the Hunter",
		"skin": Color("#c08a5e"), "clothes": Color("#4f5f36"), "trim": Color("#8a6a3e"),
		"pants": Color("#3d3326"), "hair": Color("#5a3b22"), "beard": true,
		"headwear": HubFolk.Headwear.HOOD, "held": HubFolk.Held.SPEAR, "rest_facing": -1.0,
	})
	QuestTalker.attach(corwin, "corwin", 74.0)


func _build_aldous_camp(center: Vector2) -> void:
	_claim(center, Vector2(170, 70))
	_hub_prop(HubProp.Kind.TENT, center + Vector2(-70, -20), {"tint": Color("#5e6b3a"), "alt": Color("#c9b98a")}, 36.0)
	_hub_prop(HubProp.Kind.CAMPFIRE, center + Vector2(30, 24), {}, 12.0)
	_hub_prop(HubProp.Kind.DRYING_RACK, center + Vector2(90, -30), {"tint": Color("#7a9a4a")}, 8.0)
	_hub_prop(HubProp.Kind.JARS, center + Vector2(-140, 26), {"scale": 0.9}, 8.0)
	var aldous := _folk(center + Vector2(-10, 40), {
		"display_name": "Aldous the Hermit",
		"skin": Color("#d6a881"), "clothes": Color("#6d5a3a"), "trim": Color("#a3b06a"),
		"hair": Color("#d8d4cc"), "robe": true, "beard": true,
		"headwear": HubFolk.Headwear.HOOD, "held": HubFolk.Held.LANTERN,
	})
	QuestTalker.attach(aldous, "aldous", 74.0)


func _build_cave_mouth(center: Vector2) -> void:
	_claim(center, Vector2(150, 90))
	var body := StaticBody2D.new()
	body.collision_mask = 0
	body.position = center
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 58.0
	shape.shape = circle
	shape.position = Vector2(0, -40)
	body.add_child(shape)
	cave_mouth = QuestObject.new()
	cave_mouth.kind = QuestObject.Kind.CAVE_MOUTH
	cave_mouth.object_id = "gloomhollow_mouth"
	cave_mouth.door_open = func() -> bool: return Quests.is_quest_active(Quests.GLOOMHOLLOW)
	cave_mouth.used.connect(_on_cave_mouth_used.unbind(1))
	body.add_child(cave_mouth)
	level.add_child.call_deferred(body)
	# Gnawed bones and a warning cairn set it apart from the forest's other caves.
	_hub_prop(HubProp.Kind.CAIRN, center + Vector2(118, 18), {}, 12.0)
	for spot: Vector2 in [Vector2(-70, 40), Vector2(40, 56), Vector2(-20, 74)]:
		var bones := CaveProp.new()
		bones.kind = CaveProp.Kind.BONES
		bones.variant = absi(int(spot.x)) % 2
		bones.position = center + spot
		level.add_child.call_deferred(bones)


func _build_felling_site(center: Vector2) -> void:
	_claim(center, Vector2(180, 80))
	_add_object(QuestObject.Kind.AXE_STUMP, center, "rendels_axe", Quests.RENDELS_AXE, Vector2.ZERO, 18.0)
	for spot: Vector2 in [Vector2(-120, -30), Vector2(110, -40), Vector2(-70, 50), Vector2(140, 40)]:
		_sprite(preload("res://textures/town_stump.png"), center + spot, 0.36, 12.0)
	_sprite(preload("res://textures/town_logs.png"), center + Vector2(20, -70), 0.46, 16.0)
	_sprite(preload("res://textures/forest_log.png"), center + Vector2(-150, 60), 0.5, 14.0)


func _build_pip_site(center: Vector2) -> void:
	_claim(center, Vector2(90, 50))
	pip_site = center
	# He sits huddled against the fallen log he hid behind.
	_sprite(preload("res://textures/forest_log.png"), center + Vector2(10, -12), 0.55, 14.0)
	pip = _folk(center, {
		"display_name": "Pip", "body_scale": 0.78,
		"skin": Color("#e2b48c"), "clothes": Color("#5d7d3a"), "trim": Color("#c9a35a"),
		"pants": Color("#6b4a2e"), "hair": Color("#b8662e"), "pose": HubFolk.Pose.SIT,
	})
	QuestTalker.attach(pip, "pip", 50.0)
	_refresh_pip.call_deferred()


func _build_shrine(center: Vector2) -> void:
	_claim(center, Vector2(70, 50))
	var shrine := _add_object(QuestObject.Kind.SHRINE, center, "forest_shrine", "", Vector2.ZERO, 26.0)
	QuestTalker.attach(shrine, "forest_shrine", 70.0, "Read").talk_radius = 52.0


## A quest object standing at base, solid if collision_radius > 0. footprint (half size) is claimed from
## the region's scenery when set.
func _add_object(kind: QuestObject.Kind, base: Vector2, object_id: String, quest_id: String, footprint := Vector2.ZERO, collision_radius := 0.0) -> QuestObject:
	if footprint != Vector2.ZERO:
		_claim(base, footprint)
	var quest_object := QuestObject.new()
	quest_object.kind = kind
	quest_object.object_id = object_id
	quest_object.quest_id = quest_id
	if collision_radius <= 0.0:
		quest_object.position = base
		level.add_child.call_deferred(quest_object)
		return quest_object
	var body := _solid_body(base, collision_radius)
	body.add_child(quest_object)
	level.add_child.call_deferred(body)
	return quest_object


func _hub_prop(kind: HubProp.Kind, base: Vector2, settings: Dictionary, collision_radius: float) -> void:
	var prop := HubProp.new()
	prop.kind = kind
	for key in settings:
		if key == "scale":
			prop.scale = Vector2.ONE * float(settings[key])
		else:
			prop.set(key, settings[key])
	var body := _solid_body(base, collision_radius)
	body.add_child(prop)
	level.add_child.call_deferred(body)


func _folk(base: Vector2, settings: Dictionary) -> HubFolk:
	var person := HubFolk.new()
	for key in settings:
		person.set(key, settings[key])
	person.position = base
	level.add_child.call_deferred(person)
	return person


func _sprite(texture: Texture2D, base: Vector2, uniform_scale: float, collision_radius: float) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE * uniform_scale
	sprite.offset = Vector2(0, -texture.get_height() * 0.5)
	var body := _solid_body(base, collision_radius)
	body.add_child(sprite)
	level.add_child.call_deferred(body)


func _solid_body(base: Vector2, radius: float) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_mask = 0
	body.position = base
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	shape.position = Vector2(0, -radius * 0.4)
	body.add_child(shape)
	return body


## Keeps the region's random scenery off a site.
func _claim(base: Vector2, half_size: Vector2) -> void:
	level_controller.call("_claim_prop_spot", base, half_size, false)


func _entry_point() -> Vector2:
	return level_controller.get("region_origin") - player.get_node("Camera2D").offset


func _region_center(region: Vector2i) -> Vector2:
	return Vector2(level_controller.get("region_origin")) + Vector2(region) * Vector2(level_controller.get("region_size"))


# --- Quest monsters --------------------------------------------------------------------------------------

## Spawns a wolf that belongs to a quest. stats: name, scale, health, damage, experience, tint.
func spawn_quest_wolf(world_position: Vector2, stats: Dictionary, on_died: Callable) -> Wolf:
	var wolf := WOLF_SCENE.instantiate() as Wolf
	wolf.target_path = NodePath("../Player")
	wolf.set_meta(QUEST_MONSTER_META, true)
	wolf.monster_name = stats.get("name", "Wolf")
	wolf.scale = Vector2.ONE * float(stats.get("scale", 1.0))
	wolf.max_health = Wolf.MAX_HEALTH * float(stats.get("health", 1.0))
	wolf.attack_damage = roundi(Wolf.ATTACK_DAMAGE * float(stats.get("damage", 1.0)))
	wolf.experience_reward = int(stats.get("experience", wolf.experience_reward))
	wolf.died.connect(_on_quest_wolf_died.bind(wolf, on_died))
	level.add_child(wolf)
	wolf.global_position = world_position
	wolf.get_node("Sprite2D").modulate = stats.get("tint", Color.WHITE)
	return wolf


func _on_quest_wolf_died(wolf: Wolf, on_died: Callable) -> void:
	level_controller.call("reward_quest_monster", wolf)
	var updates := Quests.record_event("kill", "wolf")
	if on_died.is_valid():
		updates.append_array(on_died.call())
	QuestToast.show_updates(get_tree(), updates)


func _spawn_scar_ear(center: Vector2) -> void:
	if GameState.get_quest_state(Quests.SCAR_EAR_BOUNTY) != Quests.STATE_ACCEPTED:
		return
	_claim(center, Vector2(60, 30))
	_do_spawn_scar_ear.call_deferred(center)


func _do_spawn_scar_ear(center: Vector2) -> void:
	if is_instance_valid(scar_ear):
		return
	scar_ear = spawn_quest_wolf(center, {
		"name": "Old Scar-Ear", "scale": 1.4, "health": 6.0, "damage": 1.35, "experience": 80,
		"tint": Color(0.86, 0.8, 0.72),
	}, func() -> Array[Dictionary]: return Quests.record_event("kill", "scar_ear"))


# --- Pip -------------------------------------------------------------------------------------------------

func _update_pip() -> void:
	if not is_instance_valid(pip) or not pip.is_inside_tree() or in_cave:
		return
	var quest_state := GameState.get_quest_state(Quests.LOST_PIP)
	var near := player.global_position.distance_to(pip_site) < PIP_FIND_DISTANCE
	if quest_state == Quests.STATE_ACCEPTED and near:
		QuestToast.show_updates(get_tree(), Quests.record_event("find", "pip"))
	elif quest_state == "pip_found" and near and pip_guards.is_empty():
		_spawn_pip_guards()


func _spawn_pip_guards() -> void:
	for index in PIP_GUARD_COUNT:
		var angle := TAU * index / PIP_GUARD_COUNT + 0.4
		var guard := spawn_quest_wolf(pip_site + Vector2(cos(angle), sin(angle) * 0.6) * 130.0, {
			"name": "Wolf", "health": 1.5, "experience": 18,
		}, _on_pip_guard_died)
		guard.alert()
		pip_guards.append(guard)


func _on_pip_guard_died() -> Array[Dictionary]:
	pip_guards = pip_guards.filter(func(guard: Wolf) -> bool: return is_instance_valid(guard) and guard.health > 0.0)
	if not pip_guards.is_empty():
		return []
	return Quests.record_event("rescue", "pip")


func _refresh_pip() -> void:
	if not is_instance_valid(pip):
		return
	var quest_state := GameState.get_quest_state(Quests.LOST_PIP)
	if quest_state in [Quests.STATE_ACCEPTED, "pip_found", "pip_safe"]:
		pip.show()
		pip.process_mode = Node.PROCESS_MODE_INHERIT
	elif quest_state == "pip_home" and pip.visible:
		# Off he runs, straight down the road home.
		pip.pose = HubFolk.Pose.STAND
		var tween := pip.create_tween()
		tween.tween_property(pip, "global_position", pip.global_position + Vector2(-260, -60), 2.2)
		tween.parallel().tween_property(pip, "modulate:a", 0.0, 2.2)
		tween.tween_callback(pip.hide)
	else:
		pip.hide()
		pip.process_mode = Node.PROCESS_MODE_DISABLED


func _on_quest_changed(quest_id: String) -> void:
	if quest_id == Quests.LOST_PIP:
		_refresh_pip()


# --- The Gloomhollow -------------------------------------------------------------------------------------

func _on_cave_mouth_used() -> void:
	if travelling or in_cave:
		return
	cave_return_position = player.global_position
	_travel(_enter_cave)


func leave_cave() -> void:
	if travelling or not in_cave:
		return
	_travel(_exit_cave)


## Fades to black, runs move, then fades back in. The player can't act meanwhile.
func _travel(move: Callable) -> void:
	travelling = true
	player.set_physics_process(false)
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.3)
	tween.tween_callback(move)
	tween.tween_interval(0.15)
	tween.tween_property(fade, "color:a", 0.0, 0.4)
	tween.tween_callback(func() -> void:
		travelling = false
		if player.health > 0:
			player.set_physics_process(true)
	)


func _enter_cave() -> void:
	if cave == null:
		cave = Gloomhollow.new()
		cave.forest_quests = self
		level.add_child(cave)
		cave.global_position = Gloomhollow.ORIGIN
	in_cave = true
	# The forest holds still while the player is underground.
	for node in get_tree().get_nodes_in_group("enemies"):
		if not node.has_meta(Gloomhollow.CAVE_META):
			node.process_mode = Node.PROCESS_MODE_DISABLED
	_set_ambience_underground(true)
	_place_player(cave.get_arrival())
	QuestToast.show_updates(get_tree(), Quests.record_event("enter", "gloomhollow"))
	cave.populate()


func _exit_cave() -> void:
	in_cave = false
	for node in get_tree().get_nodes_in_group("enemies"):
		if not node.has_meta(Gloomhollow.CAVE_META):
			node.process_mode = Node.PROCESS_MODE_INHERIT
	_set_ambience_underground(false)
	_place_player(cave_return_position)
	level_controller.set("last_player_position", player.global_position)


func _set_ambience_underground(underground: bool) -> void:
	for node in level.get_children():
		if node is ForestAmbience:
			node.set_underground(underground, CAVE_TINT)


func _place_player(world_position: Vector2) -> void:
	player.global_position = world_position
	player.velocity = Vector2.ZERO
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if camera != null:
		camera.reset_smoothing()


## Where the level should remember the player: outside the cave's mouth while they're inside it, since
## the cave is rebuilt only when entered.
func get_save_position() -> Vector2:
	return cave_return_position if in_cave else player.global_position


# --- Tracking --------------------------------------------------------------------------------------------

## The nearest place an active quest wants the player to go in the forest, as {position, label}, or {}.
func get_tracked_target() -> Dictionary:
	var best := {}
	var best_distance := INF
	for target in _get_targets():
		var distance := player.global_position.distance_squared_to(target["position"])
		if distance < best_distance:
			best_distance = distance
			best = target
	return best


func _get_targets() -> Array[Dictionary]:
	var targets: Array[Dictionary] = []
	if in_cave:
		return targets
	for quest_id in Quests.DEFINITIONS:
		var quest_state := GameState.get_quest_state(quest_id)
		if not Quests.is_active(quest_state):
			continue
		var label: String = Quests.get_definition(quest_id)["title"]
		for talk in Quests.DEFINITIONS[quest_id].get("talks", []):
			if talk["requires_state"] == quest_state and _npc_position(talk["npc"]) != Vector2.INF:
				targets.append({"position": _npc_position(talk["npc"]), "label": label})
		for event in Quests.DEFINITIONS[quest_id].get("events", []):
			if event["requires_state"] != quest_state:
				continue
			for spot in _event_positions(quest_id, event["target"]):
				targets.append({"position": spot, "label": label})
	return targets


func _npc_position(npc_id: String) -> Vector2:
	match npc_id:
		"corwin":
			return _entry_point() + CORWIN_OFFSET
		"aldous":
			return _region_center(ALDOUS_REGION)
		"pip":
			return _region_center(PIP_REGION)
		"forest_shrine":
			return _region_center(SHRINE_REGION)
	return Vector2.INF


func _event_positions(quest_id: String, target: String) -> Array[Vector2]:
	var spots: Array[Vector2] = []
	match target:
		"apple":
			var regions: Array = level_controller.get_script().get_script_constant_map()["FOREST_APPLE_TREE_REGIONS"]
			for index in regions.size():
				if not Quests.is_object_used(quest_id, "forest_apple_%d" % index):
					spots.append(_region_center(regions[index]))
		"moonpetal":
			for index in MOONPETAL_REGIONS.size():
				if not Quests.is_object_used(quest_id, "moonpetal_%d" % index):
					spots.append(_region_center(MOONPETAL_REGIONS[index]) + SCATTER_OFFSETS[index])
		"wayfire":
			for index in WAYFIRE_REGIONS.size():
				if not Quests.is_object_used(quest_id, "wayfire_%d" % index):
					spots.append(_region_center(WAYFIRE_REGIONS[index]) + SCATTER_OFFSETS[index + 1])
		"gloomhollow", "gloomfang", "ilsas_journal":
			spots.append(_region_center(CAVE_REGION))
		"rendels_axe":
			spots.append(_region_center(FELLING_REGION))
		"pip":
			spots.append(_region_center(PIP_REGION))
		"scar_ear":
			spots.append(scar_ear.global_position if is_instance_valid(scar_ear) else _region_center(SCAR_EAR_REGION))
	return spots
