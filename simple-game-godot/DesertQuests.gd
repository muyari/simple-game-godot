extends LevelQuests
class_name DesertQuests
## The quest sites of the campaign's Sunscorch Sands (see LevelQuests): the wreck of Malik's caravan and
## the graves of its drivers, his scattered spice crates, the red rocks where Yusuf hides from the snakes,
## the ruins of Qasr Anuhm with Imani's camp, its three obelisks and the stair down into the Sunken Vault,
## Tarek's three lookout rocks at the edges of the map, the old wells, the sunbloom cacti, and Old
## Glasstail's salt flats. Also runs the encounters (the snakes round Yusuf, Glasstail, and down in the vault
## Venomcoil and the First Sting) and the trip into and out of the vault.

const SNAKE_SCENE = preload("res://snake.tscn")
const SCORPION_SCENE = preload("res://scorpion.tscn")

const WRECK_REGION := Vector2i(3, 1)
const GRAVE_REGIONS: Array[Vector2i] = [Vector2i(2, 2), Vector2i(3, 3), Vector2i(4, 2)]
const CRATE_REGIONS: Array[Vector2i] = [Vector2i(1, -2), Vector2i(-2, 2), Vector2i(5, 1), Vector2i(-1, 3)]
const YUSUF_REGION := Vector2i(-1, 4)
const RUINS_REGION := Vector2i(4, -3)
## North, east and south of the ruins.
const OBELISK_REGIONS: Array[Vector2i] = [Vector2i(4, -4), Vector2i(5, -3), Vector2i(4, -2)]
## Tarek's lookouts at the far north-west, south-west and south-east.
const LOOKOUT_REGIONS: Array[Vector2i] = [Vector2i(-5, -4), Vector2i(-5, 4), Vector2i(5, 4)]
const GLASSTAIL_REGION := Vector2i(-5, 0)
const WELL_REGIONS: Array[Vector2i] = [Vector2i(-2, -2), Vector2i(-3, 1), Vector2i(1, 3)]
const SUNBLOOM_REGIONS: Array[Vector2i] = [Vector2i(-1, -1), Vector2i(2, -1), Vector2i(1, 1), Vector2i(-3, -2), Vector2i(-2, 3), Vector2i(0, -3)]
## Imani's camp, from the heart of the ruins.
const IMANI_OFFSET := Vector2(-330, 130)
## Places are found (Malik's wreck, Yusuf, the ruins) when the player comes this close.
const WRECK_FIND_DISTANCE := 320.0
const YUSUF_FIND_DISTANCE := 300.0
const RUINS_FIND_DISTANCE := 460.0
const YUSUF_GUARD_COUNT := 3
## The light in the vault.
const VAULT_TINT := Color(0.78, 0.68, 0.58)
const WRECK_CRATES: Array[Texture2D] = [
	preload("res://textures/underworld_crate_a.png"),
	preload("res://textures/underworld_crate_b.png"),
	preload("res://textures/underworld_barrel_a.png"),
]
const RED_ROCKS: Array[Texture2D] = [
	preload("res://textures/desert_rock_heap_tall.png"),
	preload("res://textures/desert_hoodoo_a.png"),
	preload("res://textures/desert_hoodoo_b.png"),
]
const RUIN_WALL = preload("res://textures/desert_ruin_wall.png")
const RUIN_RUBBLE = preload("res://textures/desert_rubble_low.png")
const RUIN_PILLARS: Array[Texture2D] = [
	preload("res://textures/desert_pillar_ornate.png"),
	preload("res://textures/desert_pillar_a.png"),
	preload("res://textures/desert_pillar_b.png"),
	preload("res://textures/desert_pillar_d.png"),
]

var yusuf: HubFolk
var yusuf_site := Vector2.ZERO
var yusuf_guards: Array[Wolf] = []
var wreck_site := Vector2.INF
var ruins_site := Vector2.INF
var glasstail: Wolf
var vault: SunkenVault


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(player) or player.health <= 0 or in_cave:
		return
	_find_places()
	_update_yusuf()


## Places a quest asks the player to find are found by walking up to them.
func _find_places() -> void:
	if wreck_site != Vector2.INF and GameState.get_quest_state(Quests.LAST_CARAVAN) == Quests.STATE_ACCEPTED \
			and player.global_position.distance_to(wreck_site) < WRECK_FIND_DISTANCE:
		QuestToast.show_updates(get_tree(), Quests.record_event("find", "malik_wreck"))
	if ruins_site != Vector2.INF and GameState.get_quest_state(Quests.CITY_THE_SAND_ATE) == Quests.STATE_ACCEPTED \
			and player.global_position.distance_to(ruins_site) < RUINS_FIND_DISTANCE:
		QuestToast.show_updates(get_tree(), Quests.record_event("find", "qasr_anuhm"))


# --- Building sites --------------------------------------------------------------------------------------

func populate_region(region: Vector2i, region_center: Vector2) -> void:
	if region == WRECK_REGION:
		_build_wreck(region_center)
	elif region == YUSUF_REGION:
		_build_yusuf_site(region_center)
	elif region == RUINS_REGION:
		_build_ruins(region_center)
	elif region == GLASSTAIL_REGION:
		_build_salt_flats(region_center)
	_add_scattered(region, region_center, GRAVE_REGIONS, QuestObject.Kind.GRAVE, "grave", Quests.STONES_FOR_THE_LOST, 14.0)
	_add_scattered(region, region_center, CRATE_REGIONS, QuestObject.Kind.SPICE_CRATE, "spice_crate", Quests.SALVAGE_RIGHTS, 0.0)
	_add_scattered(region, region_center, OBELISK_REGIONS, QuestObject.Kind.OBELISK, "obelisk", Quests.WORDS_IN_STONE, 16.0)
	_add_scattered(region, region_center, LOOKOUT_REGIONS, QuestObject.Kind.SIGNAL_ROCK, "lookout", Quests.EYES_ON_THE_DUNES, 30.0)
	_add_scattered(region, region_center, WELL_REGIONS, QuestObject.Kind.OLD_WELL, "old_well", Quests.SWEETWATER, 22.0)
	_add_scattered(region, region_center, SUNBLOOM_REGIONS, QuestObject.Kind.SUNBLOOM, "sunbloom", Quests.SUNBLOOM_STEW, 12.0)


## The object of this kind that stands in region, if it's one of regions: "<prefix>_<index>", at the
## index's scatter offset.
func _add_scattered(region: Vector2i, region_center: Vector2, regions: Array[Vector2i], kind: QuestObject.Kind, prefix: String, quest_id: String, collision_radius: float) -> void:
	var index := regions.find(region)
	if index < 0:
		return
	# Room round it, so the tall cacti and rocks of the region don't stand in front of it.
	var footprint := Vector2(collision_radius * 2.5 + 40.0, collision_radius * 1.2 + 30.0)
	_add_object(kind, region_center + SCATTER_OFFSETS[index % SCATTER_OFFSETS.size()], "%s_%d" % [prefix, index], quest_id, footprint, collision_radius)


## What's left of Malik's caravan: an overturned wagon, its cargo spilled, camel bones, and his strongbox.
func _build_wreck(center: Vector2) -> void:
	wreck_site = center
	_claim(center, Vector2(200, 90))
	_hub_prop(HubProp.Kind.WAGON_WRECK, center, {"scale": 1.2}, 34.0)
	for entry: Array in [[Vector2(-130, -30), 0], [Vector2(-104, -12), 2], [Vector2(150, 40), 1], [Vector2(118, -50), 2]]:
		_sprite(WRECK_CRATES[entry[1]], center + entry[0], 0.62, 10.0, entry[0].x > 0.0)
	for spot: Vector2 in [Vector2(-60, 70), Vector2(80, 80), Vector2(-170, 50)]:
		var bones := CaveProp.new()
		bones.kind = CaveProp.Kind.BONES
		bones.variant = absi(int(spot.x)) % 2
		bones.position = center + spot
		level.add_child.call_deferred(bones)
	_add_object(QuestObject.Kind.STRONGBOX, center + Vector2(64, 46), "malik_strongbox", Quests.LAST_CARAVAN)


## A ring of red rock with Yusuf huddled in the middle of it.
func _build_yusuf_site(center: Vector2) -> void:
	yusuf_site = center
	_claim(center, Vector2(180, 90))
	for entry: Array in [[Vector2(-120, -40), 0], [Vector2(110, -50), 1], [Vector2(-40, -90), 2], [Vector2(150, 30), 0]]:
		var rock: Texture2D = RED_ROCKS[entry[1]]
		_sprite(rock, center + entry[0], 0.8, 22.0, entry[0].x > 0.0)
	yusuf = _folk(center + Vector2(10, -10), {
		"display_name": "Yusuf", "body_scale": 0.92, "pose": HubFolk.Pose.SIT,
		"skin": Color("#a7744c"), "clothes": Color("#c9a13f"), "trim": Color("#8a3b2c"),
		"pants": Color("#6e5032"), "headwear": HubFolk.Headwear.BANDANA,
	})
	QuestTalker.attach(yusuf, "yusuf", 62.0)
	_refresh_yusuf.call_deferred()


## Qasr Anuhm: pillars and broken walls poking out of the dunes round the stair down into the vault, and
## Imani's camp on the western edge.
func _build_ruins(center: Vector2) -> void:
	ruins_site = center
	_claim(center, Vector2(330, 160))
	for index in 8:
		var angle := TAU * index / 8.0 + 0.3
		var spot := center + Vector2(cos(angle) * 250.0, sin(angle) * 120.0)
		if spot.distance_to(center + IMANI_OFFSET) < 110.0:
			continue
		_sprite(RUIN_PILLARS[index % RUIN_PILLARS.size()], spot, 1.15, 14.0)
	for entry: Array in [[Vector2(-150, -150), false], [Vector2(170, -140), true]]:
		_sprite(RUIN_WALL, center + entry[0], 1.0, 34.0, entry[1])
	for spot: Vector2 in [Vector2(120, 100), Vector2(-60, 140), Vector2(220, 20)]:
		_sprite(RUIN_RUBBLE, center + spot, 1.0, 0.0)
	var stairs := _add_object(QuestObject.Kind.VAULT_STAIRS, center, "vault_stairs", "")
	stairs.door_open = func() -> bool:
		return Quests.is_quest_active(Quests.SUNKEN_VAULT) or Quests.is_quest_active(Quests.MOTHER_OF_STINGS)
	stairs.used.connect(_on_vault_stairs_used.unbind(1))
	var camp := center + IMANI_OFFSET
	_hub_prop(HubProp.Kind.TENT, camp + Vector2(-60, -30), {"tint": Color("#d8c39a"), "alt": Color("#3f5f8a")}, 34.0)
	_hub_prop(HubProp.Kind.CAMPFIRE, camp + Vector2(50, 20), {}, 12.0)
	_hub_prop(HubProp.Kind.RUG, camp + Vector2(10, 40), {"length": 60.0, "tint": Color("#3f5f8a"), "alt": Color("#e8d6a8"), "z_index": -7}, 0.0)
	_hub_prop(HubProp.Kind.JARS, camp + Vector2(-120, 20), {"scale": 0.9}, 8.0)
	var imani := _folk(camp + Vector2(-4, 46), {
		"display_name": "Scholar Imani", "robe": true, "headwear": HubFolk.Headwear.HOOD, "held": HubFolk.Held.SCROLL,
		"skin": Color("#8a5a3a"), "clothes": Color("#3a4f6e"), "trim": Color("#e0c27a"), "rest_facing": 1.0,
		"lines": ["Mind the pillars. They've stood three hundred years; they deserve some respect.", "The carvings face the sun. Everything here faces the sun."],
	})
	QuestTalker.attach(imani, "imani", 74.0)


## The western salt flats, white crust over the sand, where Old Glasstail hunts while the bounty stands.
func _build_salt_flats(center: Vector2) -> void:
	var flats := SaltFlats.new()
	flats.position = center
	flats.z_index = -7
	level.add_child.call_deferred(flats)
	if GameState.get_quest_state(Quests.GLASSTAIL_BOUNTY) != Quests.STATE_ACCEPTED:
		return
	_claim(center, Vector2(60, 30))
	_spawn_glasstail.call_deferred(center)


func _spawn_glasstail(center: Vector2) -> void:
	if is_instance_valid(glasstail):
		return
	glasstail = spawn_quest_monster(SCORPION_SCENE, center, {
		"name": "Old Glasstail", "scale": 1.8, "health": 9.0, "damage": 1.4, "experience": 200,
		"tint": Color(0.72, 0.9, 1.12),
	}, func() -> Array[Dictionary]: return Quests.record_event("kill", "glasstail"))
	glasstail.stagger_immune = true


# --- Yusuf -----------------------------------------------------------------------------------------------

func _update_yusuf() -> void:
	if not is_instance_valid(yusuf) or not yusuf.is_inside_tree():
		return
	var quest_state := GameState.get_quest_state(Quests.VOICE_IN_THE_DUNES)
	var near := player.global_position.distance_to(yusuf_site) < YUSUF_FIND_DISTANCE
	if quest_state == Quests.STATE_ACCEPTED and near:
		QuestToast.show_updates(get_tree(), Quests.record_event("find", "yusuf"))
	elif quest_state == "yusuf_found" and near and yusuf_guards.is_empty():
		_spawn_yusuf_guards()


func _spawn_yusuf_guards() -> void:
	for index in YUSUF_GUARD_COUNT:
		var angle := TAU * index / YUSUF_GUARD_COUNT + 0.9
		var guard := spawn_quest_monster(SNAKE_SCENE, yusuf_site + Vector2(cos(angle), sin(angle) * 0.6) * 150.0, {
			"name": "Rock Snake", "health": 1.4, "experience": 24,
		}, _on_yusuf_guard_died)
		guard.alert()
		yusuf_guards.append(guard)


func _on_yusuf_guard_died() -> Array[Dictionary]:
	yusuf_guards = yusuf_guards.filter(func(guard: Wolf) -> bool: return is_instance_valid(guard) and guard.health > 0.0)
	if not yusuf_guards.is_empty():
		return []
	return Quests.record_event("rescue", "yusuf")


func _refresh_yusuf() -> void:
	if not is_instance_valid(yusuf):
		return
	var quest_state := GameState.get_quest_state(Quests.VOICE_IN_THE_DUNES)
	if quest_state in [Quests.STATE_ACCEPTED, "yusuf_found", "yusuf_safe"]:
		yusuf.show()
		yusuf.process_mode = Node.PROCESS_MODE_INHERIT
	elif quest_state == "yusuf_home" and yusuf.visible:
		# Off he goes, back toward Saltwind.
		yusuf.pose = HubFolk.Pose.STAND
		var tween := yusuf.create_tween()
		tween.tween_property(yusuf, "global_position", yusuf.global_position + Vector2(-280, -90), 2.4)
		tween.parallel().tween_property(yusuf, "modulate:a", 0.0, 2.4)
		tween.tween_callback(yusuf.hide)
	else:
		yusuf.hide()
		yusuf.process_mode = Node.PROCESS_MODE_DISABLED


func _on_quest_changed(quest_id: String) -> void:
	if quest_id == Quests.VOICE_IN_THE_DUNES:
		_refresh_yusuf()
	elif quest_id == Quests.MOTHER_OF_STINGS and in_cave and vault != null:
		# Setting the Sunstone wakes the First Sting.
		vault.populate()


# --- The Sunken Vault ------------------------------------------------------------------------------------

func _on_vault_stairs_used() -> void:
	if travelling or in_cave:
		return
	_travel(_enter_vault)


func _enter_vault() -> void:
	if vault == null:
		vault = SunkenVault.new()
		vault.desert_quests = self
		level.add_child(vault)
		vault.global_position = SunkenVault.ORIGIN
	_go_underground(vault.get_arrival(), SunkenVault.VAULT_META, VAULT_TINT)
	QuestToast.show_updates(get_tree(), Quests.record_event("enter", "sunken_vault"))
	vault.populate()


func _exit_cave() -> void:
	_return_to_surface(SunkenVault.VAULT_META)


## The First Sting is dead: her hoard is left where she fell, and with her gone the brood loses its hold on
## the Sands, which secures the level just as felling the Scorpion Matriarch would.
func on_first_sting_slain(world_position: Vector2) -> void:
	level_controller.call("_spawn_treasure_chest", world_position + Vector2(0, 40))
	if not bool(level_controller.get("level_is_complete")):
		level_controller.call("_complete_current_level")


# --- Tracking --------------------------------------------------------------------------------------------

func _npc_position(npc_id: String) -> Vector2:
	match npc_id:
		"yusuf":
			return _region_center(YUSUF_REGION)
		"imani":
			return _region_center(RUINS_REGION) + IMANI_OFFSET
	return Vector2.INF


func _event_positions(quest_id: String, target: String) -> Array[Vector2]:
	var spots: Array[Vector2] = []
	match target:
		"malik_wreck", "caravan_ledger":
			spots.append(_region_center(WRECK_REGION))
		"yusuf":
			spots.append(_region_center(YUSUF_REGION))
		"qasr_anuhm", "sunken_vault", "venomcoil", "sunstone_shard", "sun_seal", "first_sting":
			spots.append(_region_center(RUINS_REGION))
		"cairn":
			spots = _unused_spots(quest_id, "grave", GRAVE_REGIONS)
		"spice_crate":
			spots = _unused_spots(quest_id, "spice_crate", CRATE_REGIONS)
		"obelisk":
			spots = _unused_spots(quest_id, "obelisk", OBELISK_REGIONS)
		"signal_flag":
			spots = _unused_spots(quest_id, "lookout", LOOKOUT_REGIONS)
		"old_well":
			spots = _unused_spots(quest_id, "old_well", WELL_REGIONS)
		"sunbloom":
			spots = _unused_spots(quest_id, "sunbloom", SUNBLOOM_REGIONS)
		"glasstail":
			spots.append(glasstail.global_position if is_instance_valid(glasstail) else _region_center(GLASSTAIL_REGION))
	return spots


## White salt crust over the sand of the western flats.
class SaltFlats extends Node2D:
	func _draw() -> void:
		var random := RandomNumberGenerator.new()
		random.seed = 4417
		for _index in 9:
			var spot := Vector2(random.randf_range(-420, 420), random.randf_range(-220, 220))
			var radius := random.randf_range(90.0, 190.0)
			draw_set_transform(spot, 0.0, Vector2(1.0, 0.45))
			SmoothDraw.disc(self, Vector2.ZERO, radius, Color(0.97, 0.95, 0.9, 0.35))
			SmoothDraw.disc(self, Vector2.ZERO, radius * 0.6, Color(1.0, 1.0, 0.98, 0.25))
			draw_set_transform(Vector2.ZERO)
		for _crack in 24:
			var start := Vector2(random.randf_range(-380, 380), random.randf_range(-190, 190))
			draw_line(start, start + Vector2(random.randf_range(-40, 40), random.randf_range(-14, 14)), Color(0.75, 0.7, 0.6, 0.35), 1.2, true)
