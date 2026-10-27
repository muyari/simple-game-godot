extends LevelQuests
class_name ForestQuests
## The quest sites of the campaign's Forest Outskirts (see LevelQuests): Corwin's hunting camp by the road,
## Aldous's hermitage and the moonpetals round it, the Gloomhollow's mouth, Rendel's felling site, Pip
## hiding from the wolves, Old Scar-Ear's ground, the Mossy Shrine and its three wayfires. Also runs the
## encounters (Scar-Ear, the wolves circling Pip, Gloomfang) and the trip into and out of the Gloomhollow.

const WOLF_SCENE = preload("res://wolf.tscn")

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
## Pip's guards appear when the player comes this close to him.
const PIP_FIND_DISTANCE := 300.0
const PIP_GUARD_COUNT := 3
## The light underground.
const CAVE_TINT := Color(0.7, 0.7, 0.84)

var pip: HubFolk
var pip_site := Vector2.ZERO
var pip_guards: Array[Wolf] = []
var scar_ear: Wolf
var cave: Gloomhollow
var cave_mouth: QuestObject


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(player) or player.health <= 0:
		return
	_update_pip()


# --- Building sites --------------------------------------------------------------------------------------

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


# --- Quest monsters --------------------------------------------------------------------------------------

## Spawns a wolf that belongs to a quest (see LevelQuests.spawn_quest_monster).
func spawn_quest_wolf(world_position: Vector2, stats: Dictionary, on_died: Callable) -> Wolf:
	var quest_stats := {"name": "Wolf"}
	quest_stats.merge(stats, true)
	return spawn_quest_monster(WOLF_SCENE, world_position, quest_stats, on_died)


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
	_travel(_enter_cave)


func _enter_cave() -> void:
	if cave == null:
		cave = Gloomhollow.new()
		cave.forest_quests = self
		level.add_child(cave)
		cave.global_position = Gloomhollow.ORIGIN
	_go_underground(cave.get_arrival(), Gloomhollow.CAVE_META, CAVE_TINT)
	QuestToast.show_updates(get_tree(), Quests.record_event("enter", "gloomhollow"))
	cave.populate()


func _exit_cave() -> void:
	_return_to_surface(Gloomhollow.CAVE_META)


# --- Tracking --------------------------------------------------------------------------------------------

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
			spots = _unused_spots(quest_id, "moonpetal", MOONPETAL_REGIONS)
		"wayfire":
			spots = _unused_spots(quest_id, "wayfire", WAYFIRE_REGIONS, 1)
		"gloomhollow", "gloomfang", "ilsas_journal":
			spots.append(_region_center(CAVE_REGION))
		"rendels_axe":
			spots.append(_region_center(FELLING_REGION))
		"pip":
			spots.append(_region_center(PIP_REGION))
		"scar_ear":
			spots.append(scar_ear.global_position if is_instance_valid(scar_ear) else _region_center(SCAR_EAR_REGION))
	return spots
