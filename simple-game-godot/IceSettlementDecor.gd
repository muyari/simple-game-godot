extends HubDecor
class_name IceSettlementDecor
## Rimehollow, a settlement dug into a frozen cavern above the Ice Caves: hide yurts and snow-block huts
## round a great hearth, a furrier's stall, fishing holes cut through the cavern's frozen pool, a hunters'
## corner where a crystalback yeti is being skinned, a quarry worked from the rubble of slain ice golems,
## and at the back of the cave the Sleeper, a cryohydra frozen in a wall of ice that the town was built
## around. A tunnel east leads down into the Ice Caves.

const ROCKS: Array[Dictionary] = [
	{"texture": preload("res://textures/ice_rock_a.png"), "scale": Vector2(0.9, 1.15)},
	{"texture": preload("res://textures/ice_rock_e.png"), "scale": Vector2(0.9, 1.15)},
	{"texture": preload("res://textures/ice_rock_h.png"), "scale": Vector2(0.9, 1.15)},
	{"texture": preload("res://textures/ice_rock_j.png"), "scale": Vector2(0.9, 1.15)},
	{"texture": preload("res://textures/ice_rock_pile_a.png"), "scale": Vector2(0.9, 1.15)},
	{"texture": preload("res://textures/ice_rock_pile_b.png"), "scale": Vector2(0.9, 1.15)},
]
const SPIRES: Array[Dictionary] = [
	{"texture": preload("res://textures/ice_stalagmite_a.png"), "scale": Vector2(1.0, 1.3)},
	{"texture": preload("res://textures/ice_stalagmite_b.png"), "scale": Vector2(1.0, 1.3)},
	{"texture": preload("res://textures/ice_stalagmite_c.png"), "scale": Vector2(1.0, 1.3)},
	{"texture": preload("res://textures/ice_crystals_a.png"), "scale": Vector2(0.9, 1.1)},
	{"texture": preload("res://textures/ice_crystals_b.png"), "scale": Vector2(0.9, 1.1)},
	{"texture": preload("res://textures/ice_spike_tall.png"), "scale": Vector2(1.0, 1.3)},
]
const DRIFTS: Array[Dictionary] = [
	{"texture": preload("res://textures/ice_drift_large.png"), "scale": Vector2(0.8, 1.0)},
	{"texture": preload("res://textures/ice_drift_wave.png"), "scale": Vector2(0.8, 1.0)},
	{"texture": preload("res://textures/ice_drift_round.png"), "scale": Vector2(0.8, 1.0)},
]
const LITTER: Array[Dictionary] = [
	{"texture": preload("res://textures/ice_snow_pile_a.png"), "scale": Vector2(0.55, 0.7)},
	{"texture": preload("res://textures/ice_snow_pile_c.png"), "scale": Vector2(0.55, 0.7)},
	{"texture": preload("res://textures/ice_snow_chunks_a.png"), "scale": Vector2(0.55, 0.7)},
	{"texture": preload("res://textures/ice_snow_chunks_b.png"), "scale": Vector2(0.5, 0.65)},
	{"texture": preload("res://textures/ice_drift_small.png"), "scale": Vector2(0.9, 1.2)},
	{"texture": preload("res://textures/ice_crystals_c.png"), "scale": Vector2(0.4, 0.5)},
]
const STUMPS: Array[Texture2D] = [
	preload("res://textures/ice_stump_a.png"),
	preload("res://textures/ice_stump_c.png"),
]
const PILLAR_ORNATE = preload("res://textures/ice_pillar_ornate.png")
const PILLAR_TWISTED = preload("res://textures/ice_pillar_twisted.png")
const ICE_BLOCK = preload("res://textures/ice_block.png")
const GOLEM_SHARD = preload("res://textures/ice_golem_shard.png")
const CRATES: Array[Texture2D] = [preload("res://textures/underworld_crate_a.png"), preload("res://textures/underworld_barrel_b.png")]
const HYDRA_ATLAS = preload("res://textures/ice_cryohydra_atlas.png")
const YETI_ATLAS = preload("res://textures/ice_yeti_atlas.png")
const GOLEM_ATLAS = preload("res://textures/ice_golem_atlas.png")

const HEARTH := Vector2(600, 370)
const SLEEPER := Vector2(620, 150)
const TUNNEL := Vector2(1235, 470)
const SKINS := [Color("#e8c4a8"), Color("#c99a6e"), Color("#d6a985"), Color("#f0d2bc")]
const FURS := [Color("#6b4f3a"), Color("#8c6a4a"), Color("#4a5a6a"), Color("#5e4a3e")]


func build() -> void:
	shadow_color = IceCreature.SHADOW_COLOR
	paint_ground(4)
	_lay_ground()
	_build_hearth()
	_build_sleeper()
	_build_dwellings()
	_build_fishing()
	_build_hunters()
	_build_quarry()
	_build_tunnel()
	_build_folk()
	_build_cave()


func _lay_ground() -> void:
	# The cavern floor: packed snow inside the rock walls, the frozen pool and trodden ice paths.
	patch(bounds.get_center() + Vector2(0, 10), bounds.size * 0.5 + Vector2(70, 60), 2, -9, 0.06)
	patch(HEARTH + Vector2(0, 20), Vector2(150, 80), 3, -8, 0.1)
	patch(Vector2(420, 850), Vector2(230, 85), 3, -8, 0.12)
	trail(PackedVector2Array([HEARTH + Vector2(120, 40), Vector2(900, 450), TUNNEL + Vector2(40, 0)]), 46.0, 3)
	trail(PackedVector2Array([HEARTH + Vector2(0, 60), Vector2(560, 650), Vector2(440, 790)]), 34.0, 3)
	trail(PackedVector2Array([HEARTH + Vector2(0, -50), SLEEPER + Vector2(0, 60)]), 34.0, 3)


func _build_hearth() -> void:
	prop(HubProp.Kind.CAMPFIRE, HEARTH, {"variant": 1, "scale": 1.5}, 18.0)
	smoke(HEARTH + Vector2(0, -48), 10)
	for spot: Vector2 in [HEARTH + Vector2(-120, 50), HEARTH + Vector2(120, 50)]:
		prop(HubProp.Kind.BRAZIER, spot, {"scale": 1.2}, 8.0)
	for spot: Vector2 in [HEARTH + Vector2(-70, 26), HEARTH + Vector2(70, 26)]:
		prop(HubProp.Kind.RUG, spot, {"length": 50.0, "tint": Color("#8c6a4a"), "alt": Color("#e8e0d0"), "z_index": -7})
	var vendor := level.get_node_or_null("Vendor") as Node2D
	if vendor != null:
		folk(Vector2(0, -30), {
			"display_name": "Brannoc", "headwear": HubFolk.Headwear.FUR_HOOD, "beard": true,
			"clothes": FURS[0], "hair": Color("#a8642e"), "skin": SKINS[0],
		}, vendor)
		var stall := HubProp.new()
		stall.kind = HubProp.Kind.STALL
		stall.tint = Color("#6b4f3a")
		stall.alt = Color("#e8e0d0")
		stall.scale = Vector2.ONE * 1.25
		vendor.add_child.call_deferred(stall)
		solid(CRATES[0], vendor.position + Vector2(-76, -30), 0.8, 9.0)
		prop(HubProp.Kind.SLED, vendor.position + Vector2(84, 8), {"scale": 1.2}, 10.0)


## The Sleeper: a cryohydra frozen mid-roar inside a wall of clear ice, the reason Rimehollow is here.
func _build_sleeper() -> void:
	var tomb := StaticBody2D.new()
	tomb.collision_mask = 0
	tomb.position = SLEEPER
	var back := HubProp.new()
	back.kind = HubProp.Kind.ICE_BACK
	back.length = 270.0
	back.height = 150.0
	tomb.add_child(back)
	var hydra := monster_frame(HYDRA_ATLAS, Vector2i(266, 98), Vector2i(1, 2), Vector2(4, -6), 1.25)
	hydra.modulate = Color(0.72, 0.86, 1.0, 0.92)
	tomb.add_child(hydra)
	var front := HubProp.new()
	front.kind = HubProp.Kind.ICE_FRONT
	front.length = 270.0
	front.height = 150.0
	tomb.add_child(front)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	# Solid right back to the cave wall, so nobody wanders in behind the ice.
	rect.size = Vector2(290, 200)
	shape.shape = rect
	shape.position = Vector2(10, -100)
	tomb.add_child(shape)
	level.add_child.call_deferred(tomb)
	taken.append(Rect2(SLEEPER - Vector2(150, 160), Vector2(320, 170)))
	FireGlow.attach(tomb, Vector2(0, -70), 220.0, Color("#7fd0ff"), 0.25)
	for side: float in [-1.0, 1.0]:
		prop(HubProp.Kind.TOTEM, SLEEPER + Vector2(side * 175, 30), {"scale": 1.3}, 7.0)
		solid(PILLAR_TWISTED, SLEEPER + Vector2(side * 225, 10), 0.75, 12.0, side > 0.0)


func _build_dwellings() -> void:
	var yurts := [[Vector2(180, 230), FURS[0]], [Vector2(1010, 250), FURS[3]], [Vector2(970, 700), FURS[1]]]
	for entry in yurts:
		prop(HubProp.Kind.YURT, entry[0], {"tint": entry[1], "alt": Color("#c9a76a"), "scale": 1.45}, 0.0, Vector2(80, 26))
	for spot: Vector2 in [Vector2(110, 470), Vector2(330, 620), Vector2(770, 790), Vector2(1130, 340)]:
		prop(HubProp.Kind.IGLOO, spot, {"scale": 1.35}, 0.0, Vector2(70, 26))
	for spot: Vector2 in [Vector2(260, 260), Vector2(1080, 280), Vector2(200, 500)]:
		solid(CRATES[random.randi() % CRATES.size()], spot, 0.8, 9.0)
	prop(HubProp.Kind.BRAZIER, Vector2(880, 250), {"scale": 1.1}, 8.0)
	prop(HubProp.Kind.SLED, Vector2(260, 700), {"scale": 1.2}, 10.0)


func _build_fishing() -> void:
	for spot: Vector2 in [Vector2(350, 852), Vector2(470, 842)]:
		prop(HubProp.Kind.FISHING_HOLE, spot, {"z_index": -7, "scale": 1.2})
	prop(HubProp.Kind.DRYING_RACK, Vector2(610, 885), {"variant": 1, "scale": 1.2}, 0.0, Vector2(60, 14))


func _build_hunters() -> void:
	for spot: Vector2 in [Vector2(80, 650), Vector2(210, 650)]:
		prop(HubProp.Kind.DRYING_RACK, spot, {"tint": Color("#eef2f6"), "scale": 1.25}, 0.0, Vector2(64, 14))
	# A crystalback yeti brought down and dragged home, half skinned.
	var yeti := monster_frame(YETI_ATLAS, Vector2i(202, 115), Vector2i(3, 4), Vector2(150, 790), 0.9, true)
	SunShadow.attach(yeti, Vector2(0, -6), 150.0, true, shadow_color)
	level.add_child.call_deferred(yeti)
	taken.append(Rect2(Vector2(70, 740), Vector2(160, 60)))


func _build_quarry() -> void:
	# What's left of slain ice golems, worked for building ice.
	for entry in [[Vector2(1150, 800), 1.15, false], [Vector2(1060, 880), 0.9, true]]:
		var rubble := monster_frame(GOLEM_ATLAS, Vector2i(164, 102), Vector2i(5, 5), entry[0], entry[1], entry[2])
		SunShadow.attach(rubble, Vector2(0, -4), 120.0, true, shadow_color)
		level.add_child.call_deferred(rubble)
		taken.append(Rect2(entry[0] - Vector2(70, 50), Vector2(140, 60)))
	for spot: Vector2 in [Vector2(990, 790), Vector2(1010, 812), Vector2(970, 816)]:
		place(ICE_BLOCK, spot, 0.3)
	for spot: Vector2 in [Vector2(1090, 760), Vector2(1200, 860), Vector2(1015, 860)]:
		place(GOLEM_SHARD, spot, 1.0, random.randf() < 0.5, false)


func _build_tunnel() -> void:
	# The way down: a dark passage through the cave wall, flanked by carved pillars.
	for layer in 5:
		var t := 1.0 - layer * 0.17
		var mouth := Polygon2D.new()
		var points := PackedVector2Array()
		for index in 32:
			var angle := TAU * index / 32.0
			points.append(TUNNEL + Vector2(150 + (1.0 - t) * 40.0, 0) + Vector2(cos(angle) * 160.0, sin(angle) * 66.0) * t)
		mouth.polygon = points
		mouth.antialiased = true
		mouth.color = Color(0.02, 0.04, 0.07, 0.3)
		mouth.z_index = -7
		level.add_child.call_deferred(mouth)
	for side: float in [-1.0, 1.0]:
		solid(PILLAR_ORNATE, TUNNEL + Vector2(-60, side * 78 + 12), 0.8, 12.0, side > 0.0)
	prop(HubProp.Kind.TOTEM, TUNNEL + Vector2(-110, -70), {"scale": 1.2}, 7.0)


func _build_folk() -> void:
	# Torsten, home from Saltwind with the player (Quests.NORTH_TO_RIMEHOLLOW). He rides in with them, so
	# he's here as soon as the quest is under way: arriving completes it (TownUI).
	if GameState.get_quest_state(Quests.NORTH_TO_RIMEHOLLOW) != Quests.STATE_AVAILABLE:
		var torsten := folk(HEARTH + Vector2(160, 96), {
			"display_name": "Torsten", "headwear": HubFolk.Headwear.FUR_HOOD, "beard": true, "body_scale": 1.25,
			"clothes": Color("#7a5a3e"), "trim": Color("#e8e0d0"), "hair": Color("#d0a060"), "skin": SKINS[3],
			"rest_facing": -1.0,
			"lines": ["Ahh. Cold at last.", "Warm your hands at the hearth. Then go and see Elder Sigrun."],
		})
		QuestTalker.attach(torsten, "torsten", 80.0)
	folk(SLEEPER + Vector2(0, 80), {
		"display_name": "Elder Sigrun", "headwear": HubFolk.Headwear.FUR_HOOD, "robe": true, "held": HubFolk.Held.STAFF,
		"clothes": FURS[2], "trim": Color("#9fd3ee"), "skin": SKINS[3],
		"lines": [
			"We call it the Sleeper. Our grandmothers found it frozen here and built Rimehollow around it.",
			"The ice is thinning. Some nights I hear it breathe.",
			"Its kin still roam the caves below. Pray they don't remember it.",
		],
	})
	folk(HEARTH + Vector2(-72, 40), {
		"display_name": "Hearthkeeper Ingrid", "pose": HubFolk.Pose.SIT, "headwear": HubFolk.Headwear.FUR_HOOD,
		"clothes": FURS[1], "skin": SKINS[1], "rest_facing": 1.0,
		"lines": ["Warm your hands, traveller. The fire never goes out in Rimehollow. It can't.", "Below, the cold gets into your bones and stays."],
	})
	folk(HEARTH + Vector2(0, 86), {
		"display_name": "Headman Ulf", "headwear": HubFolk.Headwear.FUR_HOOD, "beard": true, "held": HubFolk.Held.SPEAR,
		"clothes": FURS[3], "hair": Color("#c9b49a"), "skin": SKINS[0],
		"lines": [
			"Rimehollow welcomes anyone who can carry a blade and keep their head.",
			"The tunnel east goes down into the Ice Caves. Wraiths, yetis, worse.",
			"If you see something in the deep ice watching you, don't stop to look back.",
		],
	})
	folk(Vector2(305, 846), {
		"display_name": "Kari", "pose": HubFolk.Pose.SIT, "held": HubFolk.Held.ROD, "headwear": HubFolk.Headwear.FUR_HOOD,
		"clothes": FURS[2], "skin": SKINS[2], "rest_facing": 1.0,
		"lines": ["Hush. You'll scare the fish.", "They bite better when the Sleeper is quiet."],
	})
	folk(Vector2(515, 836), {
		"display_name": "Old Bodvar", "pose": HubFolk.Pose.SIT, "held": HubFolk.Held.ROD, "beard": true,
		"clothes": FURS[0], "hair": Color("#e6e1d8"), "skin": SKINS[0], "rest_facing": -1.0,
		"lines": ["Forty winters I've fished this hole. Never once caught anything that wasn't blue.", "Something big swims under the ice. Too big for my line."],
	})
	folk(Vector2(230, 780), {
		"display_name": "Orm the Hunter", "headwear": HubFolk.Headwear.FUR_HOOD, "held": HubFolk.Held.SPEAR,
		"clothes": FURS[1], "skin": SKINS[1], "rest_facing": -1.0,
		"lines": [
			"Crystalback yeti. Took six of us to bring it down. One didn't get up.",
			"Their hide keeps out the deep cold. Their temper doesn't keep at all.",
		],
	})
	folk(Vector2(1060, 780), {
		"display_name": "Halvard", "headwear": HubFolk.Headwear.BANDANA, "held": HubFolk.Held.HAMMER, "beard": true,
		"clothes": FURS[3], "trim": Color("#9fd3ee"), "skin": SKINS[2], "area": Rect2(980, 760, 120, 60), "speed": 22.0,
		"lines": ["We quarry what's left of the golems. Best building ice there is.", "Sometimes a block twitches. You just hit it again."],
	})
	folk(TUNNEL + Vector2(-110, 6), {
		"display_name": "Watcher Ylva", "headwear": HubFolk.Headwear.HELMET, "held": HubFolk.Held.TORCH,
		"clothes": FURS[2], "armored": true, "skin": SKINS[3], "rest_facing": 1.0,
		"lines": [
			"The tunnel runs down into the Ice Caves proper. Wraiths drift up it when the wind turns.",
			"Keep a torch lit and keep moving. The cold kills the ones who stop.",
		],
	})
	folk(Vector2(700, 560), {
		"display_name": "Little Asa", "body_scale": 0.8, "headwear": HubFolk.Headwear.FUR_HOOD,
		"clothes": Color("#9b4231"), "skin": SKINS[3], "area": Rect2(450, 480, 420, 240), "speed": 44.0,
		"lines": ["Ma says if I go near the Sleeper it'll eat me.", "I touched the ice once. It was warm."],
	})


func _build_cave() -> void:
	# Rock and ice close in round the settlement; drifts lie against the walls.
	var tunnel_way: Array[Rect2] = [Rect2(TUNNEL.x - 20, TUNNEL.y - 70, 520, 140)]
	ring(ROCKS + ROCKS + SPIRES, 380.0, 62.0, 0.75, tunnel_way)
	for spot: Vector2 in [Vector2(-30, 150), Vector2(-20, 330), Vector2(-30, 880), Vector2(1240, 160), Vector2(1240, 640), Vector2(900, -20), Vector2(330, -20), Vector2(900, 920)]:
		var piece: Dictionary = SPIRES[random.randi() % SPIRES.size()]
		solid(piece["texture"], spot, 1.1, 12.0, random.randf() < 0.5)
	for spot: Vector2 in [Vector2(40, 120), Vector2(1200, 760)]:
		solid(STUMPS[random.randi() % STUMPS.size()], spot, 0.8, 14.0)
	var busy: Array[Rect2] = [
		Rect2(HEARTH - Vector2(170, 90), Vector2(340, 200)), Rect2(SLEEPER - Vector2(170, 170), Vector2(340, 240)),
		Rect2(250, 780, 380, 130), Rect2(800, 410, 480, 120),
	]
	scatter(LITTER, 40, busy)
