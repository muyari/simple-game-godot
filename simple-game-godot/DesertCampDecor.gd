extends HubDecor
class_name DesertCampDecor
## Saltwind Camp, the caravan camp at the edge of the Sunscorch Sands: nomad tents round a cookfire, a
## trader's stall, an oasis under palms, a scout's lookout over the dunes, cairns for those the Sands
## took, and the wreck of the last caravan with the scorpion that stopped it. The trail east runs out
## between skull posts to the Sands.

const CACTI: Array[Dictionary] = [
	{"texture": preload("res://textures/desert_saguaro_classic_a.png"), "scale": Vector2(0.9, 1.1)},
	{"texture": preload("res://textures/desert_saguaro_classic_b.png"), "scale": Vector2(0.9, 1.1)},
	{"texture": preload("res://textures/desert_saguaro_m.png"), "scale": Vector2(0.9, 1.1)},
	{"texture": preload("res://textures/desert_saguaro_s.png"), "scale": Vector2(0.9, 1.1)},
	{"texture": preload("res://textures/desert_prickly_pear_tall.png"), "scale": Vector2(0.75, 0.9)},
	{"texture": preload("res://textures/desert_cactus_column_b.png"), "scale": Vector2(0.9, 1.1)},
	{"texture": preload("res://textures/desert_barrel_bloom_a.png"), "scale": Vector2(0.7, 0.85)},
	{"texture": preload("res://textures/desert_agave.png"), "scale": Vector2(0.8, 1.0)},
]
const ROCKS: Array[Dictionary] = [
	{"texture": preload("res://textures/desert_rock_pile_mid.png"), "scale": Vector2(0.9, 1.1)},
	{"texture": preload("res://textures/desert_rock_pile_low.png"), "scale": Vector2(0.9, 1.1)},
	{"texture": preload("res://textures/desert_boulders_pair.png"), "scale": Vector2(0.9, 1.1)},
	{"texture": preload("res://textures/desert_rock_heap_tall.png"), "scale": Vector2(0.85, 1.0)},
	{"texture": preload("res://textures/desert_hoodoo_a.png"), "scale": Vector2(1.0, 1.2)},
	{"texture": preload("res://textures/desert_spire_tall.png"), "scale": Vector2(1.0, 1.2)},
	{"texture": preload("res://textures/desert_sand_mound.png"), "scale": Vector2(1.4, 1.8)},
	{"texture": preload("res://textures/desert_sand_mound.png"), "scale": Vector2(1.4, 1.8)},
]
const BRUSH: Array[Dictionary] = [
	{"texture": preload("res://textures/desert_brush_a.png"), "scale": Vector2(0.55, 0.7)},
	{"texture": preload("res://textures/desert_brush_c.png"), "scale": Vector2(0.55, 0.7)},
	{"texture": preload("res://textures/desert_brush_f.png"), "scale": Vector2(0.55, 0.7)},
	{"texture": preload("res://textures/desert_dry_grass.png"), "scale": Vector2(0.4, 0.5)},
	{"texture": preload("res://textures/desert_tumbleweed_small.png"), "scale": Vector2(0.45, 0.55)},
	{"texture": preload("res://textures/desert_rocks_small.png"), "scale": Vector2(0.7, 0.9)},
	{"texture": preload("res://textures/desert_pebbles.png"), "scale": Vector2(0.7, 0.9)},
]
const LANDMARKS: Array[Texture2D] = [
	preload("res://textures/desert_cave_mesa.png"),
	preload("res://textures/desert_butte.png"),
	preload("res://textures/desert_cave_crag.png"),
	preload("res://textures/desert_arch_c.png"),
]
const CRATES: Array[Texture2D] = [
	preload("res://textures/underworld_crate_a.png"),
	preload("res://textures/underworld_crate_b.png"),
	preload("res://textures/underworld_barrel_a.png"),
	preload("res://textures/underworld_barrel_b.png"),
]
const RUIN_WALL = preload("res://textures/desert_ruin_wall.png")
const RUIN_PILLAR = preload("res://textures/desert_pillar_b.png")
const SCORPION_ATLAS = preload("res://textures/desert_scorpion_atlas.png")

const CAMPFIRE := Vector2(600, 350)
const OASIS := Vector2(230, 80)
const EXIT := Vector2(1270, 470)
const SKINS := [Color("#c99a6e"), Color("#a7744c"), Color("#8a5a3a"), Color("#e0b48c")]
## Residents with quests to give or take (see Quests), by display name, and their quest npc ids.
const TALKERS := {
	"Caravan Master Idris": "idris", "Old Hamid": "hamid", "Farah": "farah", "Nadja": "nadja",
	"Scout Tarek": "tarek", "Leila": "leila", "Jamal": "jamal", "Samir": "samir", "Camp Guard": "saltwind_guard",
	"Yusuf": "yusuf", "Torsten": "torsten",
}
## Where Torsten's sledge waits for the road north (Quests.NORTH_TO_RIMEHOLLOW).
const TORSTEN_SPOT := Vector2(700, 560)


func build() -> void:
	paint_ground(0)
	_lay_trails()
	_build_center()
	_build_tents()
	_build_oasis()
	_build_lookout_and_exit()
	_build_wreck_and_cairns()
	_build_folk()
	_build_surroundings()


func _lay_trails() -> void:
	patch(Vector2(600, 375), Vector2(175, 100), 1, -8, 0.1)
	trail(PackedVector2Array([Vector2(60, 440), Vector2(380, 430), Vector2(600, 430), Vector2(900, 455), Vector2(1310, 470)]), 54.0, 1)
	trail(PackedVector2Array([Vector2(560, 330), Vector2(430, 240), Vector2(320, 160)]), 40.0, 1)
	trail(PackedVector2Array([Vector2(600, 450), Vector2(570, 700), Vector2(520, 930)]), 40.0, 1)
	trail(PackedVector2Array([Vector2(900, 455), Vector2(980, 700), Vector2(1010, 820)]), 34.0, 1)


func _build_center() -> void:
	prop(HubProp.Kind.CAMPFIRE, CAMPFIRE, {"variant": 1, "scale": 1.35}, 18.0)
	smoke(CAMPFIRE + Vector2(0, -40), 8)
	for spot: Vector2 in [CAMPFIRE + Vector2(-78, 18), CAMPFIRE + Vector2(76, 18), CAMPFIRE + Vector2(0, -52)]:
		prop(HubProp.Kind.RUG, spot, {"length": 60.0, "tint": Color("#8f2f24"), "alt": Color("#e0b85a"), "z_index": -7})
	for spot: Vector2 in [Vector2(475, 245), Vector2(735, 245)]:
		prop(HubProp.Kind.BANNER, spot, {"tint": Color("#a4472f") if spot.x < 600 else Color("#3f5f8a"), "alt": Color("#e3c98f"), "height": 92.0}, 4.0)
	# The trader's stall stands in the Vendor node; wares stacked round it.
	var vendor := level.get_node_or_null("Vendor") as Node2D
	if vendor != null:
		folk(Vector2(0, -30), {
			"display_name": "Yusra", "robe": true, "headwear": HubFolk.Headwear.TURBAN,
			"clothes": Color("#3f6fa3"), "trim": Color("#e3c98f"), "skin": SKINS[1],
		}, vendor)
		var stall := HubProp.new()
		stall.kind = HubProp.Kind.STALL
		stall.tint = Color("#b5462f")
		stall.alt = Color("#f1e3c0")
		stall.scale = Vector2.ONE * 1.25
		vendor.add_child.call_deferred(stall)
		var spot := vendor.position
		prop(HubProp.Kind.JARS, spot + Vector2(-80, 4), {"scale": 1.2}, 10.0)
		prop(HubProp.Kind.JARS, spot + Vector2(80, 2), {"variant": 1, "scale": 1.2}, 10.0)
		solid(CRATES[0], spot + Vector2(-74, -34), 0.8, 9.0)
		solid(CRATES[2], spot + Vector2(72, -32), 0.8, 9.0)


func _build_tents() -> void:
	var tents := [
		[Vector2(170, 250), Color("#a4472f"), Color("#e3c98f")],
		[Vector2(240, 600), Color("#3f5f8a"), Color("#e8d6a8")],
		[Vector2(980, 240), Color("#6b3f6e"), Color("#e3c98f")],
		[Vector2(1060, 620), Color("#8a6a3a"), Color("#d8c39a")],
		[Vector2(410, 720), Color("#9c3b2c"), Color("#e8d6a8")],
		[Vector2(790, 730), Color("#2f5d5a"), Color("#e3c98f")],
	]
	for entry in tents:
		var base: Vector2 = entry[0]
		prop(HubProp.Kind.TENT, base, {"tint": entry[1], "alt": entry[2], "scale": 1.45}, 0.0, Vector2(92, 30))
		if random.randf() < 0.7:
			prop(HubProp.Kind.JARS, base + Vector2(84 * (1 if random.randf() < 0.5 else -1), 14), {"scale": 1.2}, 10.0)
		if random.randf() < 0.5:
			solid(CRATES[random.randi() % CRATES.size()], base + Vector2(-82, 18), 0.8, 9.0)


func _build_oasis() -> void:
	prop(HubProp.Kind.OASIS, OASIS, {"length": 100.0, "z_index": -7})
	var water := StaticBody2D.new()
	water.collision_mask = 0
	var shape := CollisionPolygon2D.new()
	var points := PackedVector2Array()
	for index in 24:
		var angle := TAU * index / 24.0
		points.append(OASIS + Vector2(cos(angle) * 100.0, sin(angle) * 45.0))
	shape.polygon = points
	water.add_child(shape)
	level.add_child.call_deferred(water)
	taken.append(Rect2(OASIS - Vector2(120, 60), Vector2(240, 120)))
	for entry in [[Vector2(100, 100), 92.0, 0], [Vector2(370, 70), 80.0, 1], [Vector2(190, 18), 100.0, 1], [Vector2(320, 140), 70.0, 0], [Vector2(40, 40), 86.0, 1]]:
		prop(HubProp.Kind.PALM, entry[0], {"height": entry[1], "variant": entry[2], "scale": 1.25}, 6.0)
	prop(HubProp.Kind.JARS, Vector2(380, 126), {}, 10.0)


func _build_lookout_and_exit() -> void:
	prop(HubProp.Kind.LOOKOUT, Vector2(1150, 170), {"tint": Color("#c9a76a"), "scale": 1.35}, 0.0, Vector2(46, 14))
	for y: float in [405.0, 540.0]:
		prop(HubProp.Kind.SKULL_POLE, Vector2(EXIT.x - 80, y), {"alt": Color("#a4472f"), "scale": 1.3}, 4.0)
	var sign := TownProp.new()
	sign.kind = TownProp.Kind.SIGNPOST
	sign.position = Vector2(1130, 420)
	level.add_child.call_deferred(sign)
	# The ruin the trail runs past on its way out: the edge of the city the Sands swallowed.
	solid(RUIN_WALL, Vector2(1150, 330), 1.0, 30.0)
	solid(RUIN_PILLAR, Vector2(1240, 680), 1.0, 10.0)
	place(preload("res://textures/desert_rubble_low.png"), Vector2(1190, 700), 0.9)


func _build_wreck_and_cairns() -> void:
	prop(HubProp.Kind.WAGON_WRECK, Vector2(1010, 860), {"scale": 1.4}, 0.0, Vector2(76, 18))
	# The scorpion that stopped the caravan, on its back in the sand.
	var carcass := monster_frame(SCORPION_ATLAS, Vector2i(80, 82), Vector2i(9, 0), Vector2(900, 900), 1.2, true)
	carcass.flip_v = true
	carcass.modulate = Color(0.62, 0.52, 0.46)
	carcass.rotation = 0.35
	SunShadow.attach(carcass, Vector2(0, -4), 80.0, true, shadow_color)
	level.add_child.call_deferred(carcass)
	for entry in [[Vector2(-10, 850), Color("#a4472f")], [Vector2(40, 900), Color("#3f5f8a")], [Vector2(100, 860), Color("#e3c98f")], [Vector2(-40, 910), Color("#6b3f6e")]]:
		prop(HubProp.Kind.CAIRN, entry[0], {"tint": entry[1], "scale": 1.3}, 9.0)


## A resident (see HubDecor.folk), who can be talked to about quests if TALKERS names them.
func folk(base: Vector2, settings := {}, parent: Node = null) -> HubFolk:
	var person := super(base, settings, parent)
	var npc_id: String = TALKERS.get(settings.get("display_name", ""), "")
	if not npc_id.is_empty():
		var head := 74.0 * person.body_scale / 1.15 * (0.75 if person.pose == HubFolk.Pose.SIT else 1.0)
		QuestTalker.attach(person, npc_id, head)
	return person


func _build_folk() -> void:
	# Yusuf, safe in camp once he's walked back from the red rocks (Quests.VOICE_IN_THE_DUNES).
	if GameState.get_quest_state(Quests.VOICE_IN_THE_DUNES) in ["yusuf_home", Quests.STATE_COMPLETED]:
		folk(CAMPFIRE + Vector2(150, 96), {
			"display_name": "Yusuf", "body_scale": 0.92, "headwear": HubFolk.Headwear.BANDANA,
			"clothes": Color("#c9a13f"), "trim": Color("#8a3b2c"), "pants": Color("#6e5032"), "skin": SKINS[1],
			"area": Rect2(720, 430, 140, 60), "speed": 30.0,
			"lines": ["I check the camels twice a night now.", "Malik said there was gold. There's never gold."],
		})
	# Torsten and his sledge, from the First Sting's fall until he's taken the player north.
	if Quests.is_unlocked(Quests.NORTH_TO_RIMEHOLLOW) and not Quests.is_completed(Quests.NORTH_TO_RIMEHOLLOW):
		prop(HubProp.Kind.SLED, TORSTEN_SPOT + Vector2(70, 0), {"tint": Color("#8c6a4a"), "scale": 1.2}, 16.0)
		folk(TORSTEN_SPOT, {
			"display_name": "Torsten", "headwear": HubFolk.Headwear.FUR_HOOD, "beard": true, "body_scale": 1.25,
			"clothes": Color("#7a5a3e"), "trim": Color("#e8e0d0"), "hair": Color("#d0a060"), "skin": SKINS[3],
			"rest_facing": -1.0,
			"lines": ["How do you people LIVE here?", "In Rimehollow, we'd call this weather a fever."],
		})
	folk(CAMPFIRE + Vector2(0, 74), {
		"display_name": "Caravan Master Idris", "robe": true, "beard": true, "headwear": HubFolk.Headwear.TURBAN,
		"held": HubFolk.Held.STAFF, "clothes": Color("#6e3b2a"), "trim": Color("#e8d6a8"), "hair": Color("#3a2a20"), "skin": SKINS[0],
		"lines": [
			"Welcome to Saltwind, stranger. Water first, questions after.",
			"The Sunscorch Sands lie east, past the skull posts. Go no further than your waterskin.",
			"Three caravans set out this season. One came back, and that one was empty.",
		],
	})
	# Rashid, home from fetching the player out of Oblath (Quests.ROAD_TO_SALTWIND). He rides in with the
	# player, so he's here as soon as the quest is under way: arriving completes it (TownUI).
	if GameState.get_quest_state(Quests.ROAD_TO_SALTWIND) != Quests.STATE_AVAILABLE:
		var rashid := folk(CAMPFIRE + Vector2(-120, 96), {
			"display_name": "Rashid", "robe": true, "beard": true, "headwear": HubFolk.Headwear.TURBAN,
			"held": HubFolk.Held.STAFF, "clothes": Color("#b0703a"), "trim": Color("#e8d6a8"), "skin": SKINS[1],
			"rest_facing": 1.0,
			"lines": ["Water first, friend. Then scorpions.", "The grey one still bites. She likes you, though."],
		})
		QuestTalker.attach(rashid, "rashid", 74.0)
	folk(CAMPFIRE + Vector2(-74, 26), {
		"display_name": "Old Hamid", "pose": HubFolk.Pose.SIT, "robe": true, "beard": true,
		"clothes": Color("#8a7a5a"), "trim": Color("#c9a76a"), "hair": Color("#d8d2c4"), "skin": SKINS[2], "rest_facing": 1.0,
		"lines": [
			"The ruins out there were a city once. The sand ate it in a single season.",
			"Something old sleeps under the Sands. The scorpions are only its children.",
		],
	})
	folk(CAMPFIRE + Vector2(74, 26), {
		"display_name": "Farah", "pose": HubFolk.Pose.SIT, "headwear": HubFolk.Headwear.HOOD, "robe": true,
		"held": HubFolk.Held.BOWL, "clothes": Color("#9c3b2c"), "trim": Color("#e0b85a"), "skin": SKINS[3], "rest_facing": -1.0,
		"lines": ["Eat something. Out there you won't get the chance.", "Mind the pot, it's been on since sunrise."],
	})
	folk(OASIS + Vector2(140, 66), {
		"display_name": "Nadja", "headwear": HubFolk.Headwear.HOOD, "robe": true, "held": HubFolk.Held.BOWL,
		"clothes": Color("#2f5d5a"), "trim": Color("#d8c39a"), "skin": SKINS[1], "rest_facing": -1.0,
		"lines": [
			"The oasis is all that keeps this camp alive. Drink, but don't waste it.",
			"Something has been drinking from it at night. Something with too many legs.",
		],
	})
	folk(Vector2(1110, 210), {
		"display_name": "Scout Tarek", "headwear": HubFolk.Headwear.BANDANA, "held": HubFolk.Held.SPEAR,
		"clothes": Color("#8a6a3a"), "trim": Color("#a4472f"), "pants": Color("#5a4630"), "skin": SKINS[2],
		"area": Rect2(1060, 190, 120, 60), "speed": 24.0,
		"lines": [
			"Scorpions the size of carts past those dunes. They bury themselves and wait.",
			"If you see the sand move against the wind, run.",
		],
	})
	folk(Vector2(60, 820), {
		"display_name": "Leila", "headwear": HubFolk.Headwear.HOOD, "robe": true,
		"clothes": Color("#3a3340"), "trim": Color("#6b5a70"), "skin": SKINS[3], "rest_facing": -1.0,
		"lines": [
			"My brother rode with the southern caravan. They found only his camel.",
			"We pile the stones high so the wind can't take them too.",
		],
	})
	folk(Vector2(960, 820), {
		"display_name": "Jamal", "headwear": HubFolk.Headwear.TURBAN, "held": HubFolk.Held.HAMMER,
		"clothes": Color("#a7744c"), "trim": Color("#e8d6a8"), "skin": SKINS[0], "area": Rect2(930, 790, 90, 50), "speed": 20.0,
		"lines": [
			"See that brute on its back? It tipped a wagon with one claw.",
			"I'm saving what I can of the cargo. Not much the sand hasn't already claimed.",
		],
	})
	folk(Vector2(700, 470), {
		"display_name": "Samir", "body_scale": 0.8, "clothes": Color("#c9a13f"), "pants": Color("#6e3b2a"),
		"skin": SKINS[1], "area": Rect2(460, 420, 380, 220), "speed": 46.0,
		"lines": ["Are you going into the Sands? Bring me back a scorpion tail!", "Tarek says I'm too small to keep watch. I'm not."],
	})
	folk(Vector2(860, 380), {
		"display_name": "Camp Guard", "headwear": HubFolk.Headwear.TURBAN, "held": HubFolk.Held.SPEAR,
		"clothes": Color("#5a4630"), "trim": Color("#3f5f8a"), "skin": SKINS[2], "area": Rect2(820, 380, 300, 150), "speed": 26.0,
		"lines": ["Keep to the trail when you head out. The dunes shift.", "Quiet night. Too quiet."],
	})


func _build_surroundings() -> void:
	# Dunes, cacti and rock ringing the camp, with a few great landforms on the horizon.
	ring(ROCKS + CACTI + CACTI + BRUSH, 420.0, 64.0, 0.45)
	for entry in [[Vector2(-380, 120), 0], [Vector2(1560, 160), 1], [Vector2(-300, 1120), 2], [Vector2(1500, 1080), 3], [Vector2(640, -300), 1]]:
		place(LANDMARKS[entry[1]], entry[0], 1.1)
	# A few cacti and rocks inside the edge, and dry brush between everything.
	for spot: Vector2 in [Vector2(-60, 300), Vector2(-50, 640), Vector2(1270, 260), Vector2(1260, 820), Vector2(700, -30), Vector2(860, 920), Vector2(300, 920)]:
		var piece: Dictionary = CACTI[random.randi() % CACTI.size()]
		solid(piece["texture"], spot, 1.0, 10.0, random.randf() < 0.5)
	var busy: Array[Rect2] = [
		Rect2(400, 260, 420, 230), Rect2(0, 400, 1300, 70), Rect2(1200, 400, 120, 160), Rect2(OASIS - Vector2(140, 80), Vector2(280, 170)),
	]
	scatter(BRUSH, 46, busy)
