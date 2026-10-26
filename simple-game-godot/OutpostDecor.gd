extends HubDecor
class_name OutpostDecor
## Ashgate Outpost, the last fort before the Underworld, half-wrecked and under siege: its north palisade
## smashed open where the demons broke through, barricades and soldiers holding the gap, a watchtower
## burning, tents collapsed, the wounded laid out on cots, fresh graves, a captured imp in a cage and the
## quartermaster's forge still going. Hellfire falls beyond the walls; through the breach lies the
## Underworld.

const SOOT_SHADOW := Color(0.08, 0.02, 0.02, 0.45)
const WALL_TOP := 40.0
const WALL_BOTTOM := 990.0
const WALL_LEFT := -52.0
const WALL_RIGHT := 1212.0
const BREACH := Vector2(580, 10)
const HEARTH := Vector2(340, 520)

const CRAGS: Array[Dictionary] = [
	{"texture": preload("res://textures/underworld_obsidian_crag_a.png"), "scale": Vector2(0.85, 1.05)},
	{"texture": preload("res://textures/underworld_obsidian_crag_b.png"), "scale": Vector2(0.85, 1.05)},
	{"texture": preload("res://textures/underworld_obsidian_cluster_a.png"), "scale": Vector2(0.85, 1.05)},
	{"texture": preload("res://textures/underworld_obsidian_spire_a.png"), "scale": Vector2(0.9, 1.1)},
	{"texture": preload("res://textures/underworld_obsidian_spire_c.png"), "scale": Vector2(0.9, 1.1)},
	{"texture": preload("res://textures/underworld_obsidian_boulder.png"), "scale": Vector2(0.9, 1.1)},
]
const BONES: Array[Dictionary] = [
	{"texture": preload("res://textures/underworld_bones_pile_a.png"), "scale": Vector2(0.75, 0.9)},
	{"texture": preload("res://textures/underworld_bones_pile_b.png"), "scale": Vector2(0.6, 0.75)},
	{"texture": preload("res://textures/underworld_obsidian_nub_a.png"), "scale": Vector2(0.9, 1.1)},
	{"texture": preload("res://textures/underworld_obsidian_rock_flat.png"), "scale": Vector2(0.8, 1.0)},
]
const LAVA_RING = preload("res://textures/underworld_decal_lava_ring.png")
const DEMON_GATE = preload("res://textures/underworld_arch_demon.png")
const CAGE = preload("res://textures/underworld_cage.png")
const CRATES: Array[Texture2D] = [
	preload("res://textures/underworld_crate_a.png"),
	preload("res://textures/underworld_crate_b.png"),
	preload("res://textures/underworld_barrel_a.png"),
	preload("res://textures/underworld_barrel_b.png"),
]
const HOUND_ATLAS = preload("res://textures/underworld_hound_atlas.png")
const IMP_ATLAS = preload("res://textures/underworld_imp_atlas.png")
const SKINS := [Color("#e0b48c"), Color("#c99a6e"), Color("#a7744c"), Color("#f0d2bc")]
const ASHGATE_RED := Color("#7a1f1f")
const ASHGATE_GOLD := Color("#d9b46a")
const TABARD := Color("#6e2424")
const MAIL_PANTS := Color("#4a4a52")


func build() -> void:
	shadow_color = SOOT_SHADOW
	paint_ground(5)
	_lay_ground()
	_build_walls()
	_build_breach()
	_build_camp()
	_build_infirmary_and_graves()
	_build_forge()
	_build_folk()
	_build_surroundings()
	var siege := SiegeFire.new()
	siege.target_area = Rect2(bounds.position.x - 320, bounds.position.y - 420, bounds.size.x + 640, 330)
	siege.safe_area = Rect2(BREACH - Vector2(110, 140), Vector2(220, 200))
	level.add_child.call_deferred(siege)


func _lay_ground() -> void:
	# Flagstones in the yard, scarred by fire; the earth outside is ash and glowing fissures.
	_ground_polygon(PackedVector2Array([Vector2(WALL_LEFT, WALL_TOP - 10.0), Vector2(WALL_RIGHT, WALL_TOP - 10.0), Vector2(WALL_RIGHT, WALL_BOTTOM), Vector2(WALL_LEFT, WALL_BOTTOM)]), 6, -9)
	for entry in [[Vector2(300, 330), Vector2(80, 40)], [Vector2(880, 300), Vector2(110, 50)], [Vector2(600, 140), Vector2(150, 70)], [Vector2(1010, 560), Vector2(90, 45)]]:
		patch(entry[0], entry[1], 5, -8, 0.25)


func _build_walls() -> void:
	# North wall, smashed open in the middle; the rest burning in places.
	var north := [
		[-52.0, 128.0, false, false], [128.0, 296.0, false, false], [296.0, 452.0, true, true],
		[708.0, 870.0, true, false], [870.0, 1040.0, false, true], [1040.0, 1212.0, false, false],
	]
	for run in north:
		var width: float = run[1] - run[0]
		prop(HubProp.Kind.PALISADE, Vector2((run[0] + run[1]) * 0.5, WALL_TOP), {"length": width, "broken": run[2], "burning": run[3]}, 0.0, Vector2(width, 20))
	for run in [[-52.0, 380.0], [380.0, 780.0], [780.0, 1212.0]]:
		var width: float = run[1] - run[0]
		prop(HubProp.Kind.PALISADE, Vector2((run[0] + run[1]) * 0.5, WALL_BOTTOM), {"length": width}, 0.0, Vector2(width, 20))
	# Side walls, a log at a time so each y-sorts on its own; the east side took a battering.
	var y := WALL_TOP + 12.0
	var index := 0
	while y < WALL_BOTTOM:
		prop(HubProp.Kind.PALISADE_POST, Vector2(WALL_LEFT, y), {"variant": index})
		prop(HubProp.Kind.PALISADE_POST, Vector2(WALL_RIGHT, y), {"variant": index + 500, "broken": y < 300.0 and index % 3 == 0})
		y += 9.0
		index += 1


## Where the demons broke in: splintered stumps, burning timbers, their dead, and the glow of the
## Underworld beyond.
func _build_breach() -> void:
	place(LAVA_RING, BREACH + Vector2(0, 40), 1.4, false, false).z_index = -7
	prop(HubProp.Kind.DEBRIS, BREACH + Vector2(-130, 44), {"scale": 1.3}, 14.0)
	prop(HubProp.Kind.DEBRIS, BREACH + Vector2(140, 52), {"scale": 1.2, "variant": 1}, 12.0)
	smoke(BREACH + Vector2(-130, 10), 12, true)
	place(DEMON_GATE, BREACH + Vector2(0, -230), 1.5, false, false)
	# The fallen: hellhounds and imps cut down in the gap, and the yard's own dead already taken away.
	for entry in [[HOUND_ATLAS, Vector2i(156, 61), Vector2(470, 120), true], [HOUND_ATLAS, Vector2i(156, 61), Vector2(720, 90), false], [IMP_ATLAS, Vector2i(140, 72), Vector2(650, 150), true], [IMP_ATLAS, Vector2i(140, 72), Vector2(520, -30), false]]:
		var body := monster_frame(entry[0], entry[1], Vector2i(0, 0), entry[2], 0.85, entry[3])
		body.flip_v = true
		body.rotation = 0.25 if entry[3] else -0.25
		body.modulate = Color(0.55, 0.42, 0.4)
		level.add_child.call_deferred(body)
	for spot: Vector2 in [Vector2(430, 80), Vector2(760, 140), Vector2(600, -60)]:
		place(BONES[random.randi() % 2]["texture"], spot, 0.7, random.randf() < 0.5, false)
	# Barricades across the gap, with a passage left open in the middle.
	prop(HubProp.Kind.BARRICADE, Vector2(420, 200), {"length": 150.0, "scale": 1.15}, 0.0, Vector2(150, 18))
	prop(HubProp.Kind.BARRICADE, Vector2(745, 200), {"length": 150.0, "scale": 1.15}, 0.0, Vector2(150, 18))
	for x: float in [470.0, 690.0]:
		prop(HubProp.Kind.BANNER, Vector2(x, 280), {"tint": ASHGATE_RED, "alt": ASHGATE_GOLD, "variant": 1, "height": 90.0}, 4.0)


func _build_camp() -> void:
	prop(HubProp.Kind.WATCHTOWER, Vector2(1080, 170), {"broken": true, "burning": true, "scale": 1.25}, 0.0, Vector2(56, 22))
	smoke(Vector2(1060, 0), 14, true)
	prop(HubProp.Kind.WATCHTOWER, Vector2(70, 880), {"scale": 1.2}, 0.0, Vector2(56, 22))
	for entry in [[Vector2(150, 330), false, false], [Vector2(150, 560), false, false], [Vector2(930, 380), true, false], [Vector2(980, 600), false, true]]:
		prop(HubProp.Kind.ARMY_TENT, entry[0], {"tint": Color("#b8a888"), "broken": entry[1], "burning": entry[2], "scale": 1.35}, 0.0, Vector2(90, 26))
	smoke(Vector2(1010, 540), 10, true)
	prop(HubProp.Kind.CAMPFIRE, HEARTH, {"scale": 1.3}, 16.0)
	prop(HubProp.Kind.BRAZIER, Vector2(500, 330), {"scale": 1.2}, 8.0)
	prop(HubProp.Kind.BRAZIER, Vector2(660, 330), {"scale": 1.2}, 8.0)
	for spot: Vector2 in [Vector2(260, 420), Vector2(276, 436), Vector2(820, 470), Vector2(1100, 760), Vector2(1118, 778), Vector2(240, 260)]:
		solid(CRATES[random.randi() % CRATES.size()], spot, 0.8, 9.0)
	# A captured imp, rattling the bars of its cage.
	var cage := Node2D.new()
	cage.position = Vector2(820, 300)
	var imp := monster_frame(IMP_ATLAS, Vector2i(140, 72), Vector2i(1, 2), Vector2(0, -12), 0.6)
	cage.add_child(imp)
	var bars := sprite(CAGE, 0.75)
	SunShadow.attach(bars, Vector2(0, -2), 70.0, true, shadow_color)
	cage.add_child(bars)
	var body := _body(cage.position)
	_circle_shape(body, 18.0)
	level.add_child.call_deferred(body)
	level.add_child.call_deferred(cage)


func _build_infirmary_and_graves() -> void:
	prop(HubProp.Kind.ARMY_TENT, Vector2(250, 720), {"tint": Color("#e0d8c8"), "scale": 1.3}, 0.0, Vector2(90, 26))
	for index in 4:
		prop(HubProp.Kind.COT, Vector2(120 + (index % 2) * 90, 800 + (index / 2) * 70), {"tint": [Color("#6e2424"), Color("#4a5a6a")][index % 2], "scale": 1.2}, 0.0, Vector2(56, 14))
	prop(HubProp.Kind.BRAZIER, Vector2(330, 840), {}, 8.0)
	for row in 2:
		for column in 4:
			prop(HubProp.Kind.GRAVE, Vector2(900 + column * 62, 850 + row * 64), {"variant": (row + column) % 2, "scale": 1.15}, 9.0)


func _build_forge() -> void:
	var vendor := level.get_node_or_null("Vendor") as Node2D
	if vendor == null:
		return
	var forge := HubProp.new()
	forge.kind = HubProp.Kind.FORGE
	forge.position = Vector2(14, -4)
	forge.scale = Vector2.ONE * 1.3
	vendor.add_child.call_deferred(forge)
	smoke(vendor.position + Vector2(0, -86), 8, true)
	folk(Vector2(-58, 8), {
		"display_name": "Quartermaster Bruna", "armored": true, "held": HubFolk.Held.HAMMER, "headwear": HubFolk.Headwear.BANDANA,
		"clothes": TABARD, "trim": ASHGATE_GOLD, "pants": MAIL_PANTS, "hair": Color("#7a3a1e"), "skin": SKINS[1], "rest_facing": 1.0,
	}, vendor)
	for offset: Vector2 in [Vector2(-130, 0), Vector2(120, -6)]:
		prop(HubProp.Kind.WEAPON_RACK, vendor.position + offset, {"tint": ASHGATE_RED, "scale": 1.2}, 0.0, Vector2(46, 12))


func _soldier(base: Vector2, settings: Dictionary) -> HubFolk:
	var gear := {
		"armored": true, "headwear": HubFolk.Headwear.HELMET, "clothes": TABARD, "trim": ASHGATE_GOLD,
		"pants": MAIL_PANTS, "skin": SKINS[random.randi() % SKINS.size()],
	}
	gear.merge(settings, true)
	return folk(base, gear)


func _build_folk() -> void:
	_soldier(BREACH + Vector2(0, 250), {
		"display_name": "Captain Aldric", "held": HubFolk.Held.SWORD, "beard": true, "hair": Color("#5a4630"), "rest_facing": 1.0,
		"lines": [
			"Hold the line! ...Ah, a fresh blade. Good. We need every one.",
			"The breach opened three nights ago. They've come through it every night since.",
			"Ashgate was built to keep the Underworld shut. Now it's all that stands in its doorway.",
		],
	})
	_soldier(Vector2(410, 236), {
		"display_name": "Sergeant Holt", "held": HubFolk.Held.SPEAR, "rest_facing": 1.0,
		"lines": ["They come with the ash storms. Watch the sky.", "If the hounds get past the stakes, aim for the legs."],
	})
	_soldier(Vector2(760, 236), {
		"display_name": "Pikeman Wren", "held": HubFolk.Held.SPEAR, "rest_facing": -1.0,
		"lines": ["I haven't slept in two days. Neither have the hounds.", "Every time the fire falls, I count. Never past nine."],
	})
	_soldier(Vector2(560, 760), {
		"display_name": "Patrol", "held": HubFolk.Held.TORCH, "area": Rect2(420, 640, 360, 220), "speed": 28.0,
		"lines": ["Keep your blade drawn inside the walls too.", "Quiet nights are the bad ones."],
	})
	folk(HEARTH + Vector2(-60, 22), {
		"display_name": "Corporal Fenn", "pose": HubFolk.Pose.SIT, "bandaged": true, "headwear": HubFolk.Headwear.BALD,
		"clothes": TABARD, "pants": MAIL_PANTS, "skin": SKINS[0], "rest_facing": 1.0,
		"lines": ["I saw it. Behind the gate. A shape taller than the tower.", "Don't go through the breach alone. Nobody comes back alone."],
	})
	folk(HEARTH + Vector2(60, 22), {
		"display_name": "Recruit Pell", "pose": HubFolk.Pose.SIT, "held": HubFolk.Held.BOWL, "headwear": HubFolk.Headwear.HAIR,
		"clothes": Color("#5a4630"), "skin": SKINS[3], "rest_facing": -1.0,
		"lines": ["They told me Ashgate was a quiet posting.", "The stew tastes of ash. Everything does now."],
	})
	folk(Vector2(320, 790), {
		"display_name": "Sister Maren", "robe": true, "headwear": HubFolk.Headwear.HOOD, "held": HubFolk.Held.BOWL,
		"clothes": Color("#d9d2c2"), "trim": Color("#a83226"), "skin": SKINS[3], "area": Rect2(100, 770, 260, 120), "speed": 22.0,
		"lines": ["Mind the wounded. Burns from fiend-fire don't close.", "Bring back anything that heals. We've run out of everything else."],
	})
	folk(Vector2(870, 900), {
		"display_name": "Tomas", "held": HubFolk.Held.HAMMER, "headwear": HubFolk.Headwear.HOOD, "clothes": Color("#3a3340"),
		"skin": SKINS[2], "rest_facing": 1.0,
		"lines": ["Twelve this week. I've stopped carving names. I just remember them.", "Dig deep, they say. The things below don't stay buried."],
	})
	folk(Vector2(870, 330), {
		"display_name": "Interrogator Vey", "robe": true, "headwear": HubFolk.Headwear.HOOD, "held": HubFolk.Held.SCROLL,
		"clothes": Color("#2b2430"), "trim": ASHGATE_RED, "skin": SKINS[3], "rest_facing": -1.0,
		"lines": ["The imp talks, if you can stand to listen. It says its master is waking.", "Don't get close to the bars. It bites, and then it laughs."],
	})


func _build_surroundings() -> void:
	var breach_way: Array[Rect2] = [Rect2(BREACH.x - 120, BREACH.y - 300, 240, 330)]
	ring(CRAGS + BONES, 400.0, 66.0, 0.4, breach_way)
	for spot: Vector2 in [Vector2(-300, 300), Vector2(1450, 500), Vector2(200, -280), Vector2(980, -260), Vector2(600, 1260)]:
		place(LAVA_RING, spot, 1.2, false, false).z_index = -7
	var busy: Array[Rect2] = [Rect2(380, 160, 420, 520), Rect2(60, 680, 340, 260), Rect2(860, 820, 300, 160), Rect2(HEARTH - Vector2(100, 60), Vector2(200, 100))]
	scatter(BONES, 10, busy)
