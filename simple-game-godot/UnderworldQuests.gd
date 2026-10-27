extends LevelQuests
class_name UnderworldQuests
## The quest sites of the campaign's Underworld, its finale (see LevelQuests): the black rocks where Kael's
## patrol made its stand, the Cinder Pens where he's caged, the Founders' Chapel with Mother Ysolde and its
## three braziers, the burning bridge where Vharkul guards the Founders' Brand, the Black Gate down into the
## Cinder Throne, Old Smoulder's ash fields, the cinderlilies, the fallen soldiers, the brimstone vents and the
## landmarks for Ashgate's banners. Also runs the encounters (the hounds round Kael, Vharkul, Old Smoulder, and
## down in the Cinder Throne the forge-wardens and the Ember King) and the trip into and out of the throne room.

const HOUND_SCENE = preload("res://hellhound.tscn")
const FIEND_SCENE = preload("res://fire_fiend.tscn")

const STAND_REGION := Vector2i(3, 2)
const PENS_REGION := Vector2i(-4, 1)
const CHAPEL_REGION := Vector2i(-4, -3)
## North, west and east of the chapel.
const BRAZIER_REGIONS: Array[Vector2i] = [Vector2i(-4, -4), Vector2i(-5, -3), Vector2i(-3, -3)]
const BRIDGE_REGION := Vector2i(5, -1)
const GATE_REGION := Vector2i(0, -4)
const SMOULDER_REGION := Vector2i(-5, 4)
const CINDERLILY_REGIONS: Array[Vector2i] = [Vector2i(1, -1), Vector2i(-2, 2), Vector2i(2, -2), Vector2i(-1, 3), Vector2i(3, 0)]
const TOKEN_REGIONS: Array[Vector2i] = [Vector2i(2, 1), Vector2i(-1, -2), Vector2i(1, 3), Vector2i(-3, 0)]
const BRIMSTONE_REGIONS: Array[Vector2i] = [Vector2i(-2, -1), Vector2i(4, 2), Vector2i(0, 2), Vector2i(2, -3)]
## Pell's landmarks at the far north-east, south and west.
const BANNER_REGIONS: Array[Vector2i] = [Vector2i(5, -4), Vector2i(0, 5), Vector2i(-6, 0)]
## Ysolde at her chapel door, from the heart of the chapel.
const YSOLDE_OFFSET := Vector2(-40, 120)
## Vharkul's anvil and where he stands guard, from the middle of the burning bridge.
const ANVIL_OFFSET := Vector2(-180, 90)
const VHARKUL_OFFSET := Vector2(-40, 200)
## Places are found (Kael's stand, Kael, the chapel) when the player comes this close.
const STAND_FIND_DISTANCE := 320.0
const KAEL_FIND_DISTANCE := 300.0
const CHAPEL_FIND_DISTANCE := 460.0
const KAEL_GUARD_COUNT := 3
## The light in the throne room.
const THRONE_TINT := Color(0.74, 0.52, 0.5)
const CRAGS: Array[Texture2D] = [
	preload("res://textures/underworld_obsidian_crag_a.png"),
	preload("res://textures/underworld_obsidian_crag_b.png"),
	preload("res://textures/underworld_obsidian_cluster_a.png"),
]
const BONES: Array[Texture2D] = [
	preload("res://textures/underworld_bones_pile_a.png"),
	preload("res://textures/underworld_bones_pile_b.png"),
]
const CAGE = preload("res://textures/underworld_cage.png")
const CHAINS = preload("res://textures/underworld_chains_a.png")
const SHACKLES = preload("res://textures/underworld_shackles.png")
const CHAPEL_PILLARS: Array[Texture2D] = [
	preload("res://textures/underworld_pillar_gothic_a.png"),
	preload("res://textures/underworld_pillar_gothic_b.png"),
	preload("res://textures/underworld_column_broken.png"),
]
const CHAPEL_ALTAR = preload("res://textures/underworld_altar_candles.png")
const GATE_ARCH = preload("res://textures/underworld_arch_demon.png")
const GARGOYLES: Array[Texture2D] = [
	preload("res://textures/underworld_gargoyle_a.png"),
	preload("res://textures/underworld_gargoyle_b.png"),
]

var kael: HubFolk
var kael_site := Vector2.ZERO
var kael_guards: Array[Wolf] = []
var stand_site := Vector2.INF
var chapel_site := Vector2.INF
var bridge_site := Vector2.INF
var smoulder_site := Vector2.INF
var vharkul: Wolf
var smoulder: Wolf
var throne: CinderThrone


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(player) or player.health <= 0 or in_cave:
		return
	_find_places()
	_update_kael()


## Places a quest asks the player to find are found by walking up to them.
func _find_places() -> void:
	if stand_site != Vector2.INF and GameState.get_quest_state(Quests.LOST_PATROL) == Quests.STATE_ACCEPTED \
			and player.global_position.distance_to(stand_site) < STAND_FIND_DISTANCE:
		QuestToast.show_updates(get_tree(), Quests.record_event("find", "last_stand"))
	if chapel_site != Vector2.INF and GameState.get_quest_state(Quests.WHAT_THE_IMP_KNOWS) == "imp_talked" \
			and player.global_position.distance_to(chapel_site) < CHAPEL_FIND_DISTANCE:
		QuestToast.show_updates(get_tree(), Quests.record_event("find", "founders_chapel"))


# --- Building sites --------------------------------------------------------------------------------------

func populate_region(region: Vector2i, region_center: Vector2) -> void:
	if region == STAND_REGION:
		_build_last_stand(region_center)
	elif region == PENS_REGION:
		_build_pens(region_center)
	elif region == CHAPEL_REGION:
		_build_chapel(region_center)
	elif region == BRIDGE_REGION:
		_build_bridge(region_center)
	elif region == GATE_REGION:
		_build_black_gate(region_center)
	elif region == SMOULDER_REGION:
		_build_ash_fields(region_center)
	_add_scattered(region, region_center, BRAZIER_REGIONS, QuestObject.Kind.FOUNDERS_BRAZIER, "founders_brazier", Quests.FOUNDERS_EMBERS, 14.0)
	_add_scattered(region, region_center, CINDERLILY_REGIONS, QuestObject.Kind.CINDERLILY, "cinderlily", Quests.BALM_FOR_THE_BURNED, 0.0)
	_add_scattered(region, region_center, TOKEN_REGIONS, QuestObject.Kind.FALLEN_SOLDIER, "soldier_token", Quests.NAMES_IN_THE_ASH, 0.0)
	_add_scattered(region, region_center, BRIMSTONE_REGIONS, QuestObject.Kind.BRIMSTONE, "brimstone", Quests.BRIMSTONE_FOR_THE_FORGE, 22.0)
	_add_scattered(region, region_center, BANNER_REGIONS, QuestObject.Kind.ASHGATE_BANNER, "ashgate_banner", Quests.ASHGATE_BANNERS, 28.0)


## The object of this kind that stands in region, if it's one of regions: "<prefix>_<index>", at the
## index's scatter offset.
func _add_scattered(region: Vector2i, region_center: Vector2, regions: Array[Vector2i], kind: QuestObject.Kind, prefix: String, quest_id: String, collision_radius: float) -> void:
	var index := regions.find(region)
	if index < 0:
		return
	# Room round it, so the region's crags and pillars don't stand in front of it.
	var footprint := Vector2(collision_radius * 2.5 + 40.0, collision_radius * 1.2 + 30.0)
	_add_object(kind, region_center + SCATTER_OFFSETS[index % SCATTER_OFFSETS.size()], "%s_%d" % [prefix, index], quest_id, footprint, collision_radius)


## The black rocks where Kael's patrol held for a night: a ring of crags, bones and dead hounds, and the
## patrol's standard still standing in the middle.
func _build_last_stand(center: Vector2) -> void:
	stand_site = center
	_claim(center, Vector2(200, 100))
	for entry: Array in [[Vector2(-150, -40), 0], [Vector2(140, -50), 1], [Vector2(-40, -100), 2], [Vector2(170, 50), 0]]:
		_sprite(CRAGS[entry[1]], center + entry[0], 0.8, 22.0, entry[0].x > 0.0)
	for spot: Vector2 in [Vector2(-90, 60), Vector2(80, 70), Vector2(-160, 30)]:
		_sprite(BONES[absi(int(spot.x)) % 2], center + spot, 0.6, 0.0)
	_add_object(QuestObject.Kind.KAELS_STANDARD, center + Vector2(20, 10), "kaels_standard", Quests.LOST_PATROL, Vector2.ZERO, 6.0)


## The Cinder Pens: iron cages and chains in the ash, with Kael slumped in the biggest of them.
func _build_pens(center: Vector2) -> void:
	kael_site = center
	_claim(center, Vector2(200, 100))
	for spot: Vector2 in [Vector2(-140, -30), Vector2(130, -40), Vector2(-60, 70), Vector2(150, 60)]:
		_sprite(CAGE, center + spot, 0.75, 18.0, spot.x > 0.0)
	for spot: Vector2 in [Vector2(-90, -70), Vector2(70, 90)]:
		_sprite(CHAINS, center + spot, 0.7, 0.0)
	_sprite(SHACKLES, center + Vector2(-20, 60), 0.7, 0.0)
	kael = _folk(center + Vector2(10, -10), {
		"display_name": "Lieutenant Kael", "pose": HubFolk.Pose.SIT, "armored": true, "bandaged": true,
		"headwear": HubFolk.Headwear.HAIR, "hair": Color("#3a2a20"), "skin": Color("#c99a6e"),
		"clothes": Color("#6e2424"), "trim": Color("#d9b46a"), "pants": Color("#4a4a52"),
	})
	QuestTalker.attach(kael, "kael", 62.0)
	_refresh_kael.call_deferred()


## The Founders' Chapel: gothic pillars round an altar of candles that Ysolde has kept lit for forty years.
func _build_chapel(center: Vector2) -> void:
	chapel_site = center
	_claim(center, Vector2(300, 150))
	for index in 7:
		var angle := TAU * index / 7.0 - PI * 0.5
		var spot := center + Vector2(cos(angle) * 230.0, sin(angle) * 110.0)
		if spot.distance_to(center + YSOLDE_OFFSET) < 110.0:
			continue
		_sprite(CHAPEL_PILLARS[index % CHAPEL_PILLARS.size()], spot, 0.9, 14.0)
	_sprite(CHAPEL_ALTAR, center + Vector2(0, -30), 0.9, 22.0)
	_hub_prop(HubProp.Kind.RUG, center + Vector2(0, 40), {"length": 90.0, "tint": Color("#7a1f1f"), "alt": Color("#d9b46a"), "z_index": -7}, 0.0)
	var ysolde := _folk(center + YSOLDE_OFFSET, {
		"display_name": "Mother Ysolde", "robe": true, "headwear": HubFolk.Headwear.HOOD, "held": HubFolk.Held.STAFF,
		"body_scale": 0.95, "skin": Color("#e0b48c"), "clothes": Color("#5e5652"), "trim": Color("#d9b46a"), "rest_facing": 1.0,
		"lines": ["Forty years down here. The heat stopped bothering me after the first ten.", "Mind the candles. They're older than Ashgate."],
	})
	QuestTalker.attach(ysolde, "ysolde", 64.0)


## The burning bridge in the far east: an obsidian span over a lava river, where Vharkul guards his anvil.
func _build_bridge(center: Vector2) -> void:
	bridge_site = center
	# The river a stretch at a time (a claim is all or nothing), so no scenery stands in the lava. Claims keep
	# their own clearance from each other, hence the spacing.
	for y: float in [-210.0, 0.0, 210.0]:
		_claim(center + Vector2(0, y + 80.0), Vector2(220, 80))
	_claim(center + ANVIL_OFFSET + Vector2(0, 30), Vector2(60, 30))
	var bridge := BurningBridge.new()
	bridge.position = center
	bridge.z_index = -7
	level.add_child.call_deferred(bridge)
	_add_object(QuestObject.Kind.FOUNDERS_BRAND, center + ANVIL_OFFSET, "founders_brand", Quests.EMBER_HERALD, Vector2.ZERO, 12.0)
	_spawn_vharkul.call_deferred()


## The Black Gate in the north: a demon-carved arch flanked by gargoyles over the gate down into the throne.
func _build_black_gate(center: Vector2) -> void:
	_claim(center, Vector2(220, 120))
	_sprite(GATE_ARCH, center + Vector2(0, -120), 1.3, 0.0)
	for side: float in [-1.0, 1.0]:
		_sprite(GARGOYLES[0 if side < 0.0 else 1], center + Vector2(side * 150.0, 20.0), 0.9, 18.0, side > 0.0)
	var gate := _add_object(QuestObject.Kind.BLACK_GATE, center, "black_gate", "", Vector2.ZERO, 0.0)
	gate.door_open = func() -> bool:
		return Quests.is_quest_active(Quests.BLACK_GATE) or Quests.is_quest_active(Quests.EMBER_KING)
	gate.used.connect(_on_black_gate_used.unbind(1))


## The ash fields in the far south-west, grey drifts over cooling lava, where Old Smoulder runs the packs.
func _build_ash_fields(center: Vector2) -> void:
	smoulder_site = center
	var fields := AshFields.new()
	fields.position = center
	fields.z_index = -7
	level.add_child.call_deferred(fields)
	_claim(center, Vector2(60, 30))
	_spawn_smoulder.call_deferred()


func _spawn_vharkul() -> void:
	if bridge_site == Vector2.INF or is_instance_valid(vharkul) or GameState.get_quest_state(Quests.EMBER_HERALD) != Quests.STATE_ACCEPTED:
		return
	vharkul = spawn_quest_monster(FIEND_SCENE, bridge_site + VHARKUL_OFFSET, {
		"name": "Vharkul, the Ember Herald", "scale": 1.6, "health": 9.0, "damage": 1.4, "experience": 320,
		"tint": Color(1.15, 0.85, 0.7),
	}, func() -> Array[Dictionary]: return Quests.record_event("kill", "vharkul"))
	vharkul.stagger_immune = true
	for side: float in [-1.0, 1.0]:
		spawn_quest_monster(HOUND_SCENE, bridge_site + VHARKUL_OFFSET + Vector2(side * 170.0, 40.0), {
			"name": "Herald's Hound", "health": 1.5, "experience": 32,
		}, Callable())


func _spawn_smoulder() -> void:
	if smoulder_site == Vector2.INF or is_instance_valid(smoulder) or GameState.get_quest_state(Quests.SMOULDER_BOUNTY) != Quests.STATE_ACCEPTED:
		return
	smoulder = spawn_quest_monster(HOUND_SCENE, smoulder_site, {
		"name": "Old Smoulder", "scale": 1.7, "health": 8.0, "damage": 1.4, "experience": 280,
		"tint": Color(1.2, 0.7, 0.5),
	}, func() -> Array[Dictionary]: return Quests.record_event("kill", "smoulder"))
	smoulder.stagger_immune = true


# --- Kael ------------------------------------------------------------------------------------------------

func _update_kael() -> void:
	if not is_instance_valid(kael) or not kael.is_inside_tree():
		return
	var quest_state := GameState.get_quest_state(Quests.CINDER_PENS)
	var near := player.global_position.distance_to(kael_site) < KAEL_FIND_DISTANCE
	if quest_state == Quests.STATE_ACCEPTED and near:
		QuestToast.show_updates(get_tree(), Quests.record_event("find", "kael"))
	elif quest_state == "kael_found" and near and kael_guards.is_empty():
		_spawn_kael_guards()


func _spawn_kael_guards() -> void:
	for index in KAEL_GUARD_COUNT:
		var angle := TAU * index / KAEL_GUARD_COUNT + 0.9
		var guard := spawn_quest_monster(HOUND_SCENE, kael_site + Vector2(cos(angle), sin(angle) * 0.6) * 150.0, {
			"name": "Pen Hound", "health": 1.4, "experience": 32,
		}, _on_kael_guard_died)
		guard.alert()
		kael_guards.append(guard)


func _on_kael_guard_died() -> Array[Dictionary]:
	kael_guards = kael_guards.filter(func(guard: Wolf) -> bool: return is_instance_valid(guard) and guard.health > 0.0)
	if not kael_guards.is_empty():
		return []
	return Quests.record_event("rescue", "kael")


func _refresh_kael() -> void:
	if not is_instance_valid(kael):
		return
	var quest_state := GameState.get_quest_state(Quests.CINDER_PENS)
	if quest_state in [Quests.STATE_ACCEPTED, "kael_found", "kael_safe"]:
		kael.show()
		kael.process_mode = Node.PROCESS_MODE_INHERIT
	elif quest_state == "kael_home" and kael.visible:
		# Off he goes, leading his survivors back toward the breach.
		kael.pose = HubFolk.Pose.STAND
		var tween := kael.create_tween()
		tween.tween_property(kael, "global_position", kael.global_position + Vector2(300, 80), 3.0)
		tween.parallel().tween_property(kael, "modulate:a", 0.0, 3.0)
		tween.tween_callback(kael.hide)
	else:
		kael.hide()
		kael.process_mode = Node.PROCESS_MODE_DISABLED


func _on_quest_changed(quest_id: String) -> void:
	if quest_id == Quests.CINDER_PENS:
		_refresh_kael()
	elif quest_id == Quests.EMBER_HERALD:
		# Ysolde gives this one out here, so the bridge may already be built.
		_spawn_vharkul()
	elif quest_id in [Quests.BLACK_GATE, Quests.EMBER_KING] and in_cave and throne != null:
		# Clearing the wardens or setting the Brand brings on what comes next.
		throne.populate()


# --- The Cinder Throne -----------------------------------------------------------------------------------

func _on_black_gate_used() -> void:
	if travelling or in_cave:
		return
	_travel(_enter_throne)


func _enter_throne() -> void:
	if throne == null:
		throne = CinderThrone.new()
		throne.underworld_quests = self
		level.add_child(throne)
		throne.global_position = CinderThrone.ORIGIN
	_go_underground(throne.get_arrival(), CinderThrone.THRONE_META, THRONE_TINT)
	QuestToast.show_updates(get_tree(), Quests.record_event("enter", "cinder_throne"))
	throne.populate()


func _exit_cave() -> void:
	_return_to_surface(CinderThrone.THRONE_META)


## The Ember King is dead: his hoard is left where he fell, and with the Emberseal whole the Underworld's
## fire goes out, which secures the level - and with it the campaign - just as felling the Archdemon would.
func on_ember_king_slain(world_position: Vector2) -> void:
	level_controller.call("_spawn_treasure_chest", world_position + Vector2(0, 40))
	if not bool(level_controller.get("level_is_complete")):
		level_controller.call("_complete_current_level")


# --- Tracking --------------------------------------------------------------------------------------------

func _npc_position(npc_id: String) -> Vector2:
	match npc_id:
		"kael":
			return _region_center(PENS_REGION)
		"ysolde":
			return _region_center(CHAPEL_REGION) + YSOLDE_OFFSET
	return Vector2.INF


func _event_positions(quest_id: String, target: String) -> Array[Vector2]:
	var spots: Array[Vector2] = []
	match target:
		"last_stand", "kaels_dispatch":
			spots.append(_region_center(STAND_REGION))
		"kael":
			spots.append(_region_center(PENS_REGION))
		"founders_chapel":
			spots.append(_region_center(CHAPEL_REGION))
		"vharkul":
			spots.append(vharkul.global_position if is_instance_valid(vharkul) else _region_center(BRIDGE_REGION) + VHARKUL_OFFSET)
		"founders_brand":
			spots.append(_region_center(BRIDGE_REGION) + ANVIL_OFFSET)
		"cinder_throne", "forge_wardens", "soul_forge", "emberseal", "azkareth":
			spots.append(_region_center(GATE_REGION))
		"founders_brazier":
			spots = _unused_spots(quest_id, "founders_brazier", BRAZIER_REGIONS)
		"cinderlily":
			spots = _unused_spots(quest_id, "cinderlily", CINDERLILY_REGIONS)
		"soldier_token":
			spots = _unused_spots(quest_id, "soldier_token", TOKEN_REGIONS)
		"brimstone":
			spots = _unused_spots(quest_id, "brimstone", BRIMSTONE_REGIONS)
		"ashgate_banner":
			spots = _unused_spots(quest_id, "ashgate_banner", BANNER_REGIONS)
		"smoulder":
			spots.append(smoulder.global_position if is_instance_valid(smoulder) else _region_center(SMOULDER_REGION))
	return spots


## The burning bridge: a river of lava running north to south, crossed by a span of black obsidian slabs.
class BurningBridge extends Node2D:
	var time := 0.0

	func _process(delta: float) -> void:
		time += delta
		queue_redraw()

	func _draw() -> void:
		var river := PackedVector2Array()
		var bank := PackedVector2Array()
		for step in 11:
			var y := -300.0 + step * 60.0
			river.append(Vector2(-70.0 + sin(step * 0.9) * 30.0, y))
			bank.append(Vector2(70.0 + sin(step * 0.9 + 0.6) * 30.0, y))
		bank.reverse()
		var outline := river + bank
		draw_colored_polygon(outline, Color("#ff5a1f"))
		var heat := 0.5 + 0.5 * sin(time * 1.6)
		draw_polyline(river + PackedVector2Array([river[0]]), Color("#2a1210"), 6.0, true)
		draw_polyline(bank, Color("#2a1210"), 6.0, true)
		for vein in 5:
			var y := -280.0 + vein * 110.0 + fmod(time * 30.0, 110.0)
			draw_line(Vector2(-40, y), Vector2(40, y + 18), Color(1.0, 0.85, 0.4, 0.35 + 0.25 * heat), 3.0, true)
		# The span: obsidian slabs laid across the river, a gap where one fell in.
		for slab in 7:
			if slab == 4:
				continue
			var x := -150.0 + slab * 50.0
			draw_rect(Rect2(x, -26, 44, 52), Color("#2a2228"))
			draw_rect(Rect2(x + 2, -24, 40, 6), Color("#4a3c44"))


## Grey ash drifts over cooling lava in the south-west, glowing faintly in the cracks.
class AshFields extends Node2D:
	func _draw() -> void:
		var random := RandomNumberGenerator.new()
		random.seed = 7717
		for _index in 9:
			var spot := Vector2(random.randf_range(-420, 420), random.randf_range(-220, 220))
			var radius := random.randf_range(90.0, 180.0)
			draw_set_transform(spot, 0.0, Vector2(1.0, 0.45))
			SmoothDraw.disc(self, Vector2.ZERO, radius, Color(0.55, 0.5, 0.48, 0.35))
			SmoothDraw.disc(self, Vector2.ZERO, radius * 0.6, Color(0.66, 0.6, 0.57, 0.25))
			draw_set_transform(Vector2.ZERO)
		for _crack in 24:
			var start := Vector2(random.randf_range(-380, 380), random.randf_range(-190, 190))
			draw_line(start, start + Vector2(random.randf_range(-40, 40), random.randf_range(-14, 14)), Color(1.0, 0.4, 0.15, 0.4), 1.4, true)
