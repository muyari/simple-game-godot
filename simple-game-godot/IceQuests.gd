extends LevelQuests
class_name IceQuests
## The quest sites of the campaign's Ice Caves (see LevelQuests): the ice-cutters' abandoned camp, the blue
## crevasse where Sven hides from the wraiths, the ruins of the Wardhall with Runa's camp, its three runestones
## and the ward-gate down into the Heartfrost Deep, the frozen falls where Hrimgar guards the Rimekey,
## Grimhide's glacier, the frostpine deadfalls, the veins of rime-ice and Ylva's three rime-beacons at the far
## ends of the caves. Also runs the encounters (the wraiths round Sven, Hrimgar, Grimhide, and down in the
## Deep the rift imps and the Rime Mother) and the trip into and out of the Deep.

const WRAITH_SCENE = preload("res://frostbound_wraith.tscn")
const YETI_SCENE = preload("res://crystalback_yeti.tscn")

const CUTTERS_REGION := Vector2i(2, 3)
const SVEN_REGION := Vector2i(-4, 2)
const WARDHALL_REGION := Vector2i(-4, -3)
## North, west and south of the Wardhall.
const RUNESTONE_REGIONS: Array[Vector2i] = [Vector2i(-4, -4), Vector2i(-5, -3), Vector2i(-4, -2)]
const FALLS_REGION := Vector2i(5, -1)
const GRIMHIDE_REGION := Vector2i(5, 4)
const KINDLING_REGIONS: Array[Vector2i] = [Vector2i(1, -1), Vector2i(-2, 1), Vector2i(3, -2), Vector2i(-1, 3), Vector2i(2, 1)]
const VEIN_REGIONS: Array[Vector2i] = [Vector2i(-2, -2), Vector2i(3, 0), Vector2i(0, -3), Vector2i(-3, 0)]
## Ylva's beacons at the far north, south-west and east.
const BEACON_REGIONS: Array[Vector2i] = [Vector2i(0, -5), Vector2i(-5, 4), Vector2i(6, 2)]
## Runa's camp, from the heart of the Wardhall.
const RUNA_OFFSET := Vector2(-330, 130)
## The Rimekey's altar and where Hrimgar stands guard, from the foot of the frozen falls.
const RIMEKEY_OFFSET := Vector2(0, 70)
const HRIMGAR_OFFSET := Vector2(0, 200)
## Places are found (the cutters' camp, Sven, the Wardhall) when the player comes this close.
const CAMP_FIND_DISTANCE := 320.0
const SVEN_FIND_DISTANCE := 300.0
const WARDHALL_FIND_DISTANCE := 460.0
const SVEN_GUARD_COUNT := 3
## The light in the Deep.
const DEEP_TINT := Color(0.62, 0.74, 0.9)
const ICE_BLOCK = preload("res://textures/ice_block.png")
const CRATES: Array[Texture2D] = [preload("res://textures/underworld_crate_a.png"), preload("res://textures/underworld_barrel_b.png")]
const BLUE_ROCKS: Array[Texture2D] = [
	preload("res://textures/ice_rock_a.png"),
	preload("res://textures/ice_rock_e.png"),
	preload("res://textures/ice_stalagmite_b.png"),
]
const WARD_PILLARS: Array[Texture2D] = [
	preload("res://textures/ice_pillar_ornate.png"),
	preload("res://textures/ice_pillar_twisted.png"),
	preload("res://textures/ice_pillar_slim.png"),
]

var sven: HubFolk
var sven_site := Vector2.ZERO
var sven_guards: Array[Wolf] = []
var camp_site := Vector2.INF
var wardhall_site := Vector2.INF
var falls_site := Vector2.INF
var grimhide_site := Vector2.INF
var hrimgar: Wolf
var grimhide: Wolf
var deep: HeartfrostDeep


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(player) or player.health <= 0 or in_cave:
		return
	_find_places()
	_update_sven()


## Places a quest asks the player to find are found by walking up to them.
func _find_places() -> void:
	if camp_site != Vector2.INF and GameState.get_quest_state(Quests.LOST_ICE_CUTTERS) == Quests.STATE_ACCEPTED \
			and player.global_position.distance_to(camp_site) < CAMP_FIND_DISTANCE:
		QuestToast.show_updates(get_tree(), Quests.record_event("find", "cutters_camp"))
	if wardhall_site != Vector2.INF and GameState.get_quest_state(Quests.WARDENS_OF_THE_RIME) == Quests.STATE_ACCEPTED \
			and player.global_position.distance_to(wardhall_site) < WARDHALL_FIND_DISTANCE:
		QuestToast.show_updates(get_tree(), Quests.record_event("find", "wardhall"))


# --- Building sites --------------------------------------------------------------------------------------

func populate_region(region: Vector2i, region_center: Vector2) -> void:
	if region == CUTTERS_REGION:
		_build_cutters_camp(region_center)
	elif region == SVEN_REGION:
		_build_crevasse(region_center)
	elif region == WARDHALL_REGION:
		_build_wardhall(region_center)
	elif region == FALLS_REGION:
		_build_falls(region_center)
	elif region == GRIMHIDE_REGION:
		_build_glacier(region_center)
	_add_scattered(region, region_center, RUNESTONE_REGIONS, QuestObject.Kind.RUNESTONE, "runestone", Quests.RUNES_UNDER_THE_FROST, 18.0)
	_add_scattered(region, region_center, KINDLING_REGIONS, QuestObject.Kind.KINDLING, "kindling", Quests.HEARTH_KINDLING, 0.0)
	_add_scattered(region, region_center, VEIN_REGIONS, QuestObject.Kind.RIME_VEIN, "rime_vein", Quests.RIME_ICE, 24.0)
	_add_scattered(region, region_center, BEACON_REGIONS, QuestObject.Kind.RIME_BEACON, "rime_beacon", Quests.LIGHTS_IN_THE_DEEP, 16.0)


## The object of this kind that stands in region, if it's one of regions: "<prefix>_<index>", at the
## index's scatter offset.
func _add_scattered(region: Vector2i, region_center: Vector2, regions: Array[Vector2i], kind: QuestObject.Kind, prefix: String, quest_id: String, collision_radius: float) -> void:
	var index := regions.find(region)
	if index < 0:
		return
	# Room round it, so the region's tall rocks and spires don't stand in front of it.
	var footprint := Vector2(collision_radius * 2.5 + 40.0, collision_radius * 1.2 + 30.0)
	_add_object(kind, region_center + SCATTER_OFFSETS[index % SCATTER_OFFSETS.size()], "%s_%d" % [prefix, index], quest_id, footprint, collision_radius)


## The ice-cutters' last camp: their loaded sledge, a slumped tent and stacked blocks of heartfrost ice.
func _build_cutters_camp(center: Vector2) -> void:
	camp_site = center
	_claim(center, Vector2(200, 90))
	_hub_prop(HubProp.Kind.TENT, center + Vector2(-110, -30), {"tint": Color("#8c6a4a"), "alt": Color("#e8e0d0")}, 30.0)
	_hub_prop(HubProp.Kind.SLED, center + Vector2(140, -20), {"tint": Color("#6b4f3a"), "scale": 1.1}, 12.0)
	for spot: Vector2 in [Vector2(-40, -50), Vector2(-20, -54), Vector2(-30, -66), Vector2(150, 50), Vector2(170, 46)]:
		_sprite(ICE_BLOCK, center + spot, 0.3, 0.0)
	for entry: Array in [[Vector2(-150, 40), 0], [Vector2(-128, 56), 1]]:
		_sprite(CRATES[entry[1]], center + entry[0], 0.7, 9.0)
	_add_object(QuestObject.Kind.CUTTERS_SLEDGE, center + Vector2(40, 40), "cutters_sledge", Quests.LOST_ICE_CUTTERS)


## The blue crevasse: a long crack in the cave floor ringed with ice rock, with Sven wedged at its edge.
func _build_crevasse(center: Vector2) -> void:
	sven_site = center
	_claim(center, Vector2(190, 90))
	var crack := Crevasse.new()
	crack.position = center + Vector2(0, 30)
	crack.z_index = -7
	level.add_child.call_deferred(crack)
	for entry: Array in [[Vector2(-140, -40), 0], [Vector2(130, -50), 1], [Vector2(-50, -90), 2], [Vector2(160, 40), 0]]:
		_sprite(BLUE_ROCKS[entry[1]], center + entry[0], 0.7, 22.0, entry[0].x > 0.0)
	sven = _folk(center + Vector2(20, -12), {
		"display_name": "Sven", "body_scale": 1.0, "pose": HubFolk.Pose.SIT, "headwear": HubFolk.Headwear.FUR_HOOD,
		"skin": Color("#e8c4a8"), "clothes": Color("#4a5a6a"), "trim": Color("#9fd3ee"), "pants": Color("#3e3a36"),
	})
	QuestTalker.attach(sven, "sven", 64.0)
	_refresh_sven.call_deferred()


## The Wardhall: a ring of carved ice pillars round the ward-gate down into the Heartfrost Deep, with fallen
## blocks among them and Runa's camp on the western edge.
func _build_wardhall(center: Vector2) -> void:
	wardhall_site = center
	_claim(center, Vector2(330, 160))
	for index in 8:
		var angle := TAU * index / 8.0 + 0.3
		var spot := center + Vector2(cos(angle) * 250.0, sin(angle) * 120.0)
		if spot.distance_to(center + RUNA_OFFSET) < 110.0:
			continue
		_sprite(WARD_PILLARS[index % WARD_PILLARS.size()], spot, 0.9, 14.0)
	for spot: Vector2 in [Vector2(120, 100), Vector2(-60, 140), Vector2(220, 20), Vector2(-170, -130), Vector2(160, -140)]:
		_sprite(ICE_BLOCK, center + spot, 0.4, 0.0)
	var gate := _add_object(QuestObject.Kind.WARD_GATE, center, "ward_gate", "")
	gate.door_open = func() -> bool:
		return Quests.is_quest_active(Quests.HEARTFROST_DEEP) or Quests.is_quest_active(Quests.RIME_MOTHER)
	gate.used.connect(_on_ward_gate_used.unbind(1))
	var camp := center + RUNA_OFFSET
	_hub_prop(HubProp.Kind.YURT, camp + Vector2(-70, -40), {"tint": Color("#5e4a3e"), "alt": Color("#c9a76a"), "scale": 1.1}, 34.0)
	_hub_prop(HubProp.Kind.BRAZIER, camp + Vector2(56, 10), {}, 8.0)
	_hub_prop(HubProp.Kind.RUG, camp + Vector2(10, 40), {"length": 60.0, "tint": Color("#8c6a4a"), "alt": Color("#e8e0d0"), "z_index": -7}, 0.0)
	_sprite(ICE_BLOCK, camp + Vector2(-130, 26), 0.32, 0.0)
	var runa := _folk(camp + Vector2(-4, 46), {
		"display_name": "Runa the Runecarver", "headwear": HubFolk.Headwear.FUR_HOOD, "held": HubFolk.Held.HAMMER, "body_scale": 1.2,
		"skin": Color("#d6a985"), "clothes": Color("#6b4f3a"), "trim": Color("#9fd3ee"), "hair": Color("#b8743a"), "rest_facing": 1.0,
		"lines": ["Every rune is a promise somebody made.", "Mind the pillars. The Wardens carved them by hand. With very cold hands."],
	})
	QuestTalker.attach(runa, "runa", 78.0)


## The frozen falls in the far east, where the Rimekey lies on its altar and Hrimgar walks while it's guarded.
func _build_falls(center: Vector2) -> void:
	falls_site = center
	_claim(center + Vector2(0, 40), Vector2(240, 150))
	var falls := FrozenFalls.new()
	falls.position = center
	level.add_child.call_deferred(falls)
	_add_object(QuestObject.Kind.RIMEKEY, center + RIMEKEY_OFFSET, "rimekey", Quests.PALE_WARDEN)
	_spawn_hrimgar.call_deferred()


## The glacier in the far south-east, pale blue ice under the snow, where Grimhide hunts while the bounty stands.
func _build_glacier(center: Vector2) -> void:
	grimhide_site = center
	var glacier := Glacier.new()
	glacier.position = center
	glacier.z_index = -7
	level.add_child.call_deferred(glacier)
	_claim(center, Vector2(60, 30))
	_spawn_grimhide.call_deferred()


func _spawn_hrimgar() -> void:
	if falls_site == Vector2.INF or is_instance_valid(hrimgar) or GameState.get_quest_state(Quests.PALE_WARDEN) != Quests.STATE_ACCEPTED:
		return
	hrimgar = spawn_quest_monster(WRAITH_SCENE, falls_site + HRIMGAR_OFFSET, {
		"name": "Hrimgar, the Pale Warden", "scale": 1.7, "health": 10.0, "damage": 1.45, "experience": 260,
		"tint": Color(0.8, 0.9, 1.15),
	}, func() -> Array[Dictionary]: return Quests.record_event("kill", "hrimgar"))
	hrimgar.stagger_immune = true
	for side: float in [-1.0, 1.0]:
		spawn_quest_monster(WRAITH_SCENE, falls_site + HRIMGAR_OFFSET + Vector2(side * 170.0, 40.0), {
			"name": "Warden's Shade", "health": 1.5, "experience": 30,
		}, Callable())


func _spawn_grimhide() -> void:
	if grimhide_site == Vector2.INF or is_instance_valid(grimhide) or GameState.get_quest_state(Quests.GRIMHIDE_BOUNTY) != Quests.STATE_ACCEPTED:
		return
	grimhide = spawn_quest_monster(YETI_SCENE, grimhide_site, {
		"name": "Grimhide", "scale": 1.6, "health": 8.0, "damage": 1.4, "experience": 240,
		"tint": Color(0.82, 0.82, 0.9),
	}, func() -> Array[Dictionary]: return Quests.record_event("kill", "grimhide"))
	grimhide.stagger_immune = true


# --- Sven ------------------------------------------------------------------------------------------------

func _update_sven() -> void:
	if not is_instance_valid(sven) or not sven.is_inside_tree():
		return
	var quest_state := GameState.get_quest_state(Quests.FROZEN_IN_PLACE)
	var near := player.global_position.distance_to(sven_site) < SVEN_FIND_DISTANCE
	if quest_state == Quests.STATE_ACCEPTED and near:
		QuestToast.show_updates(get_tree(), Quests.record_event("find", "sven"))
	elif quest_state == "sven_found" and near and sven_guards.is_empty():
		_spawn_sven_guards()


func _spawn_sven_guards() -> void:
	for index in SVEN_GUARD_COUNT:
		var angle := TAU * index / SVEN_GUARD_COUNT + 0.9
		var guard := spawn_quest_monster(WRAITH_SCENE, sven_site + Vector2(cos(angle), sin(angle) * 0.6) * 150.0, {
			"name": "Hollow Wraith", "health": 1.4, "experience": 30,
		}, _on_sven_guard_died)
		guard.alert()
		sven_guards.append(guard)


func _on_sven_guard_died() -> Array[Dictionary]:
	sven_guards = sven_guards.filter(func(guard: Wolf) -> bool: return is_instance_valid(guard) and guard.health > 0.0)
	if not sven_guards.is_empty():
		return []
	return Quests.record_event("rescue", "sven")


func _refresh_sven() -> void:
	if not is_instance_valid(sven):
		return
	var quest_state := GameState.get_quest_state(Quests.FROZEN_IN_PLACE)
	if quest_state in [Quests.STATE_ACCEPTED, "sven_found", "sven_safe"]:
		sven.show()
		sven.process_mode = Node.PROCESS_MODE_INHERIT
	elif quest_state == "sven_home" and sven.visible:
		# Off he limps, back toward Rimehollow.
		sven.pose = HubFolk.Pose.STAND
		var tween := sven.create_tween()
		tween.tween_property(sven, "global_position", sven.global_position + Vector2(280, -90), 3.0)
		tween.parallel().tween_property(sven, "modulate:a", 0.0, 3.0)
		tween.tween_callback(sven.hide)
	else:
		sven.hide()
		sven.process_mode = Node.PROCESS_MODE_DISABLED


func _on_quest_changed(quest_id: String) -> void:
	if quest_id == Quests.FROZEN_IN_PLACE:
		_refresh_sven()
	elif quest_id == Quests.PALE_WARDEN:
		# Runa gives this one out here, so the falls may already be built.
		_spawn_hrimgar()
	elif quest_id in [Quests.HEARTFROST_DEEP, Quests.RIME_MOTHER] and in_cave and deep != null:
		# Clearing the imps or setting the Rimeward brings on what comes next.
		deep.populate()


# --- The Heartfrost Deep ---------------------------------------------------------------------------------

func _on_ward_gate_used() -> void:
	if travelling or in_cave:
		return
	_travel(_enter_deep)


func _enter_deep() -> void:
	if deep == null:
		deep = HeartfrostDeep.new()
		deep.ice_quests = self
		level.add_child(deep)
		deep.global_position = HeartfrostDeep.ORIGIN
	_go_underground(deep.get_arrival(), HeartfrostDeep.DEEP_META, DEEP_TINT)
	QuestToast.show_updates(get_tree(), Quests.record_event("enter", "heartfrost_deep"))
	deep.populate()


func _exit_cave() -> void:
	_return_to_surface(HeartfrostDeep.DEEP_META)


## The Rime Mother is dead: her hoard is left where she fell, and with the Heartfrost whole the caves fall
## quiet, which secures the level just as felling the Cryohydra would.
func on_rime_mother_slain(world_position: Vector2) -> void:
	level_controller.call("_spawn_treasure_chest", world_position + Vector2(0, 40))
	if not bool(level_controller.get("level_is_complete")):
		level_controller.call("_complete_current_level")


# --- Tracking --------------------------------------------------------------------------------------------

func _npc_position(npc_id: String) -> Vector2:
	match npc_id:
		"sven":
			return _region_center(SVEN_REGION)
		"runa":
			return _region_center(WARDHALL_REGION) + RUNA_OFFSET
	return Vector2.INF


func _event_positions(quest_id: String, target: String) -> Array[Vector2]:
	var spots: Array[Vector2] = []
	match target:
		"cutters_camp", "cutters_tally":
			spots.append(_region_center(CUTTERS_REGION))
		"sven":
			spots.append(_region_center(SVEN_REGION))
		"wardhall", "heartfrost_deep", "rift_imps", "melt_rift", "heartfrost", "rime_mother":
			spots.append(_region_center(WARDHALL_REGION))
		"hrimgar":
			spots.append(hrimgar.global_position if is_instance_valid(hrimgar) else _region_center(FALLS_REGION) + HRIMGAR_OFFSET)
		"rimekey":
			spots.append(_region_center(FALLS_REGION) + RIMEKEY_OFFSET)
		"runestone":
			spots = _unused_spots(quest_id, "runestone", RUNESTONE_REGIONS)
		"kindling":
			spots = _unused_spots(quest_id, "kindling", KINDLING_REGIONS)
		"rime_vein":
			spots = _unused_spots(quest_id, "rime_vein", VEIN_REGIONS)
		"rime_beacon":
			spots = _unused_spots(quest_id, "rime_beacon", BEACON_REGIONS)
		"grimhide":
			spots.append(grimhide.global_position if is_instance_valid(grimhide) else _region_center(GRIMHIDE_REGION))
	return spots


## The blue crevasse: a jagged crack in the cave floor, dark at the bottom and blue at the lips.
class Crevasse extends Node2D:
	func _draw() -> void:
		var outer := PackedVector2Array([
			Vector2(-230, 10), Vector2(-150, -14), Vector2(-80, -6), Vector2(-10, -30), Vector2(70, -16), Vector2(150, -34),
			Vector2(240, -18), Vector2(160, 6), Vector2(80, 14), Vector2(0, 4), Vector2(-90, 22), Vector2(-160, 16),
		])
		draw_colored_polygon(outer, Color("#7fb6dc"))
		var inner := PackedVector2Array()
		for point in outer:
			inner.append(point * Vector2(0.9, 0.45) + Vector2(0, -6))
		draw_colored_polygon(inner, Color("#0f1d2c"))
		draw_polyline(outer + PackedVector2Array([outer[0]]), Color("#d6eefa"), 2.0, true)


## The frozen falls: a cliff of dark rock with a waterfall stopped dead in mid-tumble, and the pool at its
## foot frozen white. Solid along its base.
class FrozenFalls extends StaticBody2D:
	func _ready() -> void:
		collision_mask = 0
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(420, 60)
		shape.shape = rect
		shape.position = Vector2(0, -30)
		add_child(shape)

	func _draw() -> void:
		draw_colored_polygon(PackedVector2Array([
			Vector2(-230, 0), Vector2(-240, -120), Vector2(-180, -230), Vector2(-60, -270), Vector2(70, -262),
			Vector2(190, -220), Vector2(240, -110), Vector2(230, 0),
		]), Color("#3c4652"))
		draw_colored_polygon(PackedVector2Array([Vector2(-150, -40), Vector2(-120, -200), Vector2(-40, -240), Vector2(-60, -60)]), Color("#4e5a68"))
		# The waterfall, frozen in pale ribbons, and its pool.
		for ribbon in 5:
			var x := -60.0 + ribbon * 30.0
			draw_colored_polygon(PackedVector2Array([
				Vector2(x - 12, -250), Vector2(x + 12, -250), Vector2(x + 16 + ribbon % 2 * 4, 0), Vector2(x - 16, 0),
			]), Color("#cfeaf7").darkened(ribbon % 2 * 0.08))
			draw_line(Vector2(x - 4, -240), Vector2(x - 6, -10), Color(1, 1, 1, 0.55), 2.0, true)
		draw_set_transform(Vector2(0, 20), 0.0, Vector2(1.0, 0.32))
		draw_circle(Vector2.ZERO, 170.0, Color("#bfe3f4"), true, -1.0, true)
		draw_circle(Vector2.ZERO, 120.0, Color("#e4f4fb"), true, -1.0, true)
		draw_set_transform(Vector2.ZERO)


## Pale blue glacier ice showing through the snow of the south-eastern caves.
class Glacier extends Node2D:
	func _draw() -> void:
		var random := RandomNumberGenerator.new()
		random.seed = 9031
		for _index in 8:
			var spot := Vector2(random.randf_range(-420, 420), random.randf_range(-220, 220))
			var radius := random.randf_range(90.0, 180.0)
			draw_set_transform(spot, 0.0, Vector2(1.0, 0.45))
			draw_circle(Vector2.ZERO, radius, Color(0.62, 0.82, 0.95, 0.35), true, -1.0, true)
			draw_circle(Vector2.ZERO, radius * 0.6, Color(0.75, 0.9, 1.0, 0.25), true, -1.0, true)
			draw_set_transform(Vector2.ZERO)
		for _crack in 22:
			var start := Vector2(random.randf_range(-380, 380), random.randf_range(-190, 190))
			draw_line(start, start + Vector2(random.randf_range(-40, 40), random.randf_range(-14, 14)), Color(0.35, 0.55, 0.72, 0.45), 1.2, true)
