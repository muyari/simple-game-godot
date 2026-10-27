extends Area2D
class_name QuestObject
## Something out in a level that a quest has the player use. In the forest: an apple tree to pick, a
## moonpetal to gather, a wayfire to light, Rendel's axe to pull from its stump, Ilsa's journal, Perry's hat,
## the Gloomhollow's mouth or the gate of Oblath. In the Sands: Malik's strongbox, a fallen driver to raise a
## cairn over, a spice crate, an obelisk to copy, a lookout rock to flag, an old well to dig out, a sunbloom
## cactus, the stair down into the Sunken Vault and its way out, the Sunstone's shards and its seal. In the
## Ice Caves: the ice-cutters' sledge, a frosted runestone, the Rimekey on its altar, a frostpine deadfall, a
## vein of rime-ice, a rime-beacon, the ward-gate down into the Heartfrost Deep and its way out, a melt-rift
## and the Heartfrost itself. Drawn smooth and softly lit like the hub props, standing on its node origin so
## it y-sorts.
## Using it records a Quests event (see Quests.record_event); it is only usable while a quest wants it.

signal used(quest_object: QuestObject)

enum Kind {
	APPLES, MOONPETAL, WAYFIRE, AXE_STUMP, JOURNAL, CAVE_MOUTH, CAVE_EXIT, SHRINE, PERRYS_HAT, TOWN_GATE,
	STRONGBOX, GRAVE, SPICE_CRATE, OBELISK, SIGNAL_ROCK, OLD_WELL, SUNBLOOM, VAULT_STAIRS, VAULT_EXIT,
	SUN_SHARD, SUN_SEAL, CUTTERS_SLEDGE, RUNESTONE, RIMEKEY, KINDLING, RIME_VEIN, RIME_BEACON, WARD_GATE,
	DEEP_EXIT, MELT_RIFT, HEARTFROST,
}

const OUTLINE := Color(0.13, 0.08, 0.05)
const WOOD := Color("#8a5d33")
const WOOD_LIGHT := Color("#b48452")
const WOOD_DARK := Color("#5c3c22")
const STONE := Color("#8f8a7c")
const STONE_DARK := Color("#5e5a50")
const MOSS := Color("#5f8a3a")
const PETAL := Color("#dff3ff")
const PETAL_GLOW := Color("#9fe6ff")
const FLAME := Color("#ff7a1f")
const FLAME_CORE := Color("#ffe28a")
const STEEL := Color("#aab3ba")
const LEATHER := Color("#6b3f24")
## How a kind is used: the Quests event it records, its target and the prompt. DOORS travel instead, and
## SHRINE only talks (it carries a QuestTalker).
const USES := {
	Kind.APPLES: {"event": "collect", "target": "apple", "action": "Pick apples"},
	Kind.MOONPETAL: {"event": "collect", "target": "moonpetal", "action": "Gather"},
	Kind.WAYFIRE: {"event": "collect", "target": "wayfire", "action": "Light"},
	Kind.AXE_STUMP: {"event": "collect", "target": "rendels_axe", "action": "Take the axe", "item": "Rendel's Axe"},
	Kind.JOURNAL: {"event": "collect", "target": "ilsas_journal", "action": "Take the journal", "item": "Ilsa's Journal"},
	Kind.CAVE_MOUTH: {"event": "", "target": "", "action": "Enter the Gloomhollow"},
	Kind.CAVE_EXIT: {"event": "", "target": "", "action": "Leave the cave"},
	Kind.SHRINE: {"event": "", "target": "", "action": ""},
	Kind.PERRYS_HAT: {"event": "collect", "target": "perrys_hat", "action": "Take Perry's hat", "item": "Perry's Old Hat"},
	Kind.TOWN_GATE: {"event": "", "target": "", "action": "Enter Oblath"},
	Kind.STRONGBOX: {"event": "collect", "target": "caravan_ledger", "action": "Search the strongbox", "item": "Malik's Ledger"},
	Kind.GRAVE: {"event": "collect", "target": "cairn", "action": "Raise a cairn"},
	Kind.SPICE_CRATE: {"event": "collect", "target": "spice_crate", "action": "Salvage the crate", "item": "Spice Crate"},
	Kind.OBELISK: {"event": "collect", "target": "obelisk", "action": "Copy the inscription", "item": "Rubbing"},
	Kind.SIGNAL_ROCK: {"event": "collect", "target": "signal_flag", "action": "Raise a signal flag"},
	Kind.OLD_WELL: {"event": "collect", "target": "old_well", "action": "Dig out the well"},
	Kind.SUNBLOOM: {"event": "collect", "target": "sunbloom", "action": "Pick the sunbloom", "item": "Sunbloom"},
	Kind.VAULT_STAIRS: {"event": "", "target": "", "action": "Go down into the vault"},
	Kind.VAULT_EXIT: {"event": "", "target": "", "action": "Climb out of the vault"},
	Kind.SUN_SHARD: {"event": "collect", "target": "sunstone_shard", "action": "Take the shard", "item": "Sunstone Shard"},
	Kind.SUN_SEAL: {"event": "collect", "target": "sun_seal", "action": "Set the Sunstone"},
	Kind.CUTTERS_SLEDGE: {"event": "collect", "target": "cutters_tally", "action": "Search the sledge", "item": "Cutters' Tally-Book"},
	Kind.RUNESTONE: {"event": "collect", "target": "runestone", "action": "Clear the frost"},
	Kind.RIMEKEY: {"event": "collect", "target": "rimekey", "action": "Take the Rimekey", "item": "Wardens' Rimekey"},
	Kind.KINDLING: {"event": "collect", "target": "kindling", "action": "Gather kindling", "item": "Frostpine Kindling"},
	Kind.RIME_VEIN: {"event": "collect", "target": "rime_vein", "action": "Cut the rime-ice", "item": "Rime-Ice"},
	Kind.RIME_BEACON: {"event": "collect", "target": "rime_beacon", "action": "Light the beacon"},
	Kind.WARD_GATE: {"event": "", "target": "", "action": "Open the ward-gate"},
	Kind.DEEP_EXIT: {"event": "", "target": "", "action": "Climb out of the Deep"},
	Kind.MELT_RIFT: {"event": "collect", "target": "melt_rift", "action": "Seal the rift"},
	Kind.HEARTFROST: {"event": "collect", "target": "heartfrost", "action": "Set the Rimeward"},
}
const DOORS: Array[Kind] = [Kind.CAVE_MOUTH, Kind.CAVE_EXIT, Kind.TOWN_GATE, Kind.VAULT_STAIRS, Kind.VAULT_EXIT, Kind.WARD_GATE, Kind.DEEP_EXIT]
## Kinds that vanish once their quest has used them (picked up and carried off).
const TAKEN: Array[Kind] = [Kind.JOURNAL, Kind.PERRYS_HAT, Kind.SPICE_CRATE, Kind.SUN_SHARD, Kind.RIMEKEY]
const SANDSTONE := Color("#d7b07a")
const SANDSTONE_DARK := Color("#a37a4c")
const SAND := Color("#e2c48e")
const SUN_GOLD := Color("#ffcf5a")
const SPICE := Color("#c8492b")
const CACTUS := Color("#5f8a4a")
const WATER := Color("#3f86b8")
const FLAG := Color("#c23b2b")
const FELT := Color("#6b5a44")
const IRON := Color("#3d3936")
const LAMPLIGHT := Color("#ffd28a")
const ICE := Color("#bfe3f4")
const ICE_DEEP := Color("#5d97c4")
const RIME_GLOW := Color("#7fd0ff")
const SNOW := Color("#eef4f8")
const FROST_STONE := Color("#7d8a96")
const FROST_STONE_DARK := Color("#525d69")
const FROSTPINE := Color("#6e5a48")
const RIFT_FIRE := Color("#ff5a1f")

var kind := Kind.MOONPETAL
## Stable id for per-object quest flags, e.g. "moonpetal_2".
var object_id := ""
## The quest whose flags say whether this object has been used (e.g. a lit wayfire stays lit).
var quest_id := ""
## For doors: whether the door can be used right now.
var door_open := Callable()
## How far the TOWN_GATE's doors have swung open, 0 to 1.
var open_amount := 0.0
var player_nearby := false
var prompt: Label
var time := 0.0
var phase := 0.0
var sparkle: QuestMarker


func _ready() -> void:
	collision_layer = 0
	phase = randf() * TAU
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 72.0 if kind == Kind.TOWN_GATE else 56.0 if kind in [Kind.CAVE_MOUTH, Kind.APPLES, Kind.OBELISK, Kind.SIGNAL_ROCK, Kind.VAULT_STAIRS, Kind.SUN_SEAL, Kind.RUNESTONE, Kind.WARD_GATE, Kind.HEARTFROST] else 34.0
	shape.shape = circle
	shape.position = Vector2(0, -10)
	add_child(shape)
	prompt = Label.new()
	prompt.size = Vector2(180, 23)
	prompt.position = Vector2(-90, -_height() - 34.0)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_color_override("font_color", Color(1, 0.91, 0.68, 1))
	prompt.add_theme_color_override("font_outline_color", Color(0.08, 0.08, 0.07, 1))
	prompt.add_theme_constant_override("outline_size", 4)
	prompt.z_index = 30
	prompt.z_as_relative = false
	prompt.text = MenuStyle.interact_prompt(USES[kind]["action"])
	prompt.hide()
	add_child(prompt)
	# A gold "!" over things a quest is waiting on, so they stand out from the scenery.
	sparkle = QuestMarker.new()
	sparkle.position = Vector2(0, -_height() - 4.0)
	sparkle.z_index = 30
	sparkle.z_as_relative = false
	add_child(sparkle)
	if kind == Kind.WAYFIRE:
		FireGlow.attach(self, Vector2(0, -26), 110.0, Color("#ff9a3c"), 0.5).visible = false
	elif kind == Kind.MOONPETAL:
		FireGlow.attach(self, Vector2(0, -6), 60.0, PETAL_GLOW, 0.35)
	elif kind == Kind.CAVE_MOUTH:
		var cave_mouth := Sprite2D.new()
		cave_mouth.texture = preload("res://textures/forest_cavern.png")
		cave_mouth.scale = Vector2.ONE * 0.62
		cave_mouth.offset = Vector2(0, -cave_mouth.texture.get_height() * 0.5)
		cave_mouth.show_behind_parent = true
		add_child(cave_mouth)
	elif kind == Kind.TOWN_GATE:
		for side: float in [-1.0, 1.0]:
			FireGlow.attach(self, Vector2(side * 60.0, -86.0), 90.0, LAMPLIGHT, 0.4)
	elif kind == Kind.SUN_SHARD:
		FireGlow.attach(self, Vector2(0, -10), 80.0, SUN_GOLD, 0.45)
	elif kind == Kind.SUN_SEAL:
		FireGlow.attach(self, Vector2(0, -30), 220.0, SUN_GOLD, 0.6).visible = false
	elif kind == Kind.RIME_BEACON:
		FireGlow.attach(self, Vector2(0, -40), 120.0, RIME_GLOW, 0.5).visible = false
	elif kind == Kind.HEARTFROST:
		FireGlow.attach(self, Vector2(0, -40), 240.0, RIME_GLOW, 0.6).visible = false
	elif kind == Kind.MELT_RIFT:
		FireGlow.attach(self, Vector2(0, -6), 110.0, RIFT_FIRE, 0.5)
	elif kind == Kind.RIMEKEY:
		FireGlow.attach(self, Vector2(0, -24), 80.0, RIME_GLOW, 0.4)
	add_to_group("interactables")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	GameState.quest_changed.connect(_refresh.unbind(1))
	_refresh()


func _process(delta: float) -> void:
	time += delta
	queue_redraw()


func is_wanted() -> bool:
	var use: Dictionary = USES[kind]
	if kind in DOORS:
		return door_open.is_valid() and bool(door_open.call())
	if str(use["event"]).is_empty():
		return false
	return Quests.is_event_wanted(use["event"], use["target"], object_id)


## Whether this object's quest has already used it (picked, lit, taken).
func is_spent() -> bool:
	return not quest_id.is_empty() and Quests.is_object_used(quest_id, object_id)


func can_interact(_player: Player) -> bool:
	return player_nearby and is_wanted()


func interact(_player: Player) -> void:
	if not can_interact(_player):
		return
	var use: Dictionary = USES[kind]
	if not str(use["event"]).is_empty():
		var updates := Quests.record_event(use["event"], use["target"], object_id)
		QuestToast.show_updates(get_tree(), updates)
		if not updates.is_empty():
			Audio.play_sfx("item_pickup")
			PickupBurst.spawn(get_parent(), global_position + Vector2(0, -minf(_height(), 60.0)), _burst_color(), USES[kind].get("item", ""))
	used.emit(self)
	_refresh()


func _refresh() -> void:
	var wanted := is_wanted()
	sparkle.mode = QuestMarker.Mode.AVAILABLE if wanted and kind not in [Kind.CAVE_EXIT, Kind.VAULT_EXIT, Kind.DEEP_EXIT, Kind.SHRINE] else QuestMarker.Mode.HIDDEN
	prompt.visible = player_nearby and wanted
	# A lit wayfire or rime-beacon, a set Sunstone and a mended Heartfrost give off light; a sealed melt-rift
	# stops glowing.
	if kind in [Kind.WAYFIRE, Kind.SUN_SEAL, Kind.RIME_BEACON, Kind.HEARTFROST, Kind.MELT_RIFT]:
		for child in get_children():
			if child is FireGlow:
				child.visible = is_spent() != (kind == Kind.MELT_RIFT)
	if kind in TAKEN:
		visible = not is_spent()
	queue_redraw()


func _burst_color() -> Color:
	match kind:
		Kind.APPLES:
			return Color("#e04a3a")
		Kind.MOONPETAL:
			return PETAL_GLOW
		Kind.WAYFIRE:
			return FLAME
		Kind.SPICE_CRATE, Kind.SUNBLOOM:
			return SPICE
		Kind.OLD_WELL:
			return WATER
		Kind.GRAVE:
			return SANDSTONE
		Kind.KINDLING, Kind.CUTTERS_SLEDGE:
			return WOOD_LIGHT
		Kind.RUNESTONE, Kind.RIMEKEY, Kind.RIME_VEIN, Kind.RIME_BEACON, Kind.MELT_RIFT, Kind.HEARTFROST:
			return RIME_GLOW
	return Color("#ffd34d")


func _height() -> float:
	match kind:
		Kind.APPLES:
			return 150.0
		Kind.CAVE_MOUTH:
			return 150.0
		Kind.SHRINE:
			return 64.0
		Kind.WAYFIRE:
			return 52.0
		Kind.AXE_STUMP:
			return 40.0
		Kind.CAVE_EXIT:
			return 70.0
		Kind.TOWN_GATE:
			return 132.0
		Kind.STRONGBOX, Kind.GRAVE, Kind.SPICE_CRATE, Kind.OLD_WELL, Kind.SUN_SHARD:
			return 34.0
		Kind.SUN_SEAL:
			return 46.0
		Kind.SUNBLOOM:
			return 56.0
		Kind.VAULT_EXIT:
			return 70.0
		Kind.SIGNAL_ROCK:
			return 96.0
		Kind.VAULT_STAIRS:
			return 104.0
		Kind.OBELISK:
			return 132.0
		Kind.CUTTERS_SLEDGE, Kind.KINDLING, Kind.MELT_RIFT:
			return 34.0
		Kind.RIMEKEY:
			return 52.0
		Kind.RIME_VEIN:
			return 60.0
		Kind.RIME_BEACON:
			return 64.0
		Kind.DEEP_EXIT:
			return 70.0
		Kind.HEARTFROST:
			return 80.0
		Kind.RUNESTONE:
			return 96.0
		Kind.WARD_GATE:
			return 110.0
	return 24.0


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player_nearby = true
		_refresh()


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		player_nearby = false
		_refresh()


# --- Drawing ---------------------------------------------------------------------------------------------

func _draw() -> void:
	match kind:
		Kind.MOONPETAL:
			_draw_moonpetal()
		Kind.WAYFIRE:
			_draw_wayfire()
		Kind.AXE_STUMP:
			_draw_axe_stump()
		Kind.JOURNAL:
			_draw_journal()
		Kind.CAVE_EXIT:
			_draw_cave_exit()
		Kind.SHRINE:
			_draw_shrine()
		Kind.PERRYS_HAT:
			_draw_perrys_hat()
		Kind.TOWN_GATE:
			_draw_town_gate()
		Kind.STRONGBOX:
			_draw_strongbox()
		Kind.GRAVE:
			_draw_grave()
		Kind.SPICE_CRATE:
			_draw_spice_crate()
		Kind.OBELISK:
			_draw_obelisk()
		Kind.SIGNAL_ROCK:
			_draw_signal_rock()
		Kind.OLD_WELL:
			_draw_old_well()
		Kind.SUNBLOOM:
			_draw_sunbloom()
		Kind.VAULT_STAIRS:
			_draw_vault_stairs()
		Kind.VAULT_EXIT:
			_draw_cave_exit()
		Kind.SUN_SHARD:
			_draw_sun_shard()
		Kind.SUN_SEAL:
			_draw_sun_seal()
		Kind.CUTTERS_SLEDGE:
			_draw_cutters_sledge()
		Kind.RUNESTONE:
			_draw_runestone()
		Kind.RIMEKEY:
			_draw_rimekey()
		Kind.KINDLING:
			_draw_kindling()
		Kind.RIME_VEIN:
			_draw_rime_vein()
		Kind.RIME_BEACON:
			_draw_rime_beacon()
		Kind.WARD_GATE:
			_draw_ward_gate()
		Kind.DEEP_EXIT:
			_draw_cave_exit()
		Kind.MELT_RIFT:
			_draw_melt_rift()
		Kind.HEARTFROST:
			_draw_heartfrost()


func _draw_moonpetal() -> void:
	SmoothDraw.shadow(self, Vector2(0, 1), Vector2(26, 7))
	# Leaves, then three stems; the blooms glow and breathe unless they've been gathered.
	for side: float in [-1.0, 1.0]:
		SmoothDraw.polygon(self, PackedVector2Array([Vector2(0, -1), Vector2(side * 11.0, -6), Vector2(side * 14.0, -2), Vector2(side * 4.0, 0)]), MOSS, OUTLINE, 1.0)
	if is_spent():
		for stem_x: float in [-4.0, 1.0, 5.0]:
			draw_line(Vector2(stem_x * 0.5, 0), Vector2(stem_x, -9), MOSS.darkened(0.2), 1.5, true)
		return
	var pulse := 0.75 + 0.25 * sin(time * 2.4 + phase)
	for bloom: Vector3 in [Vector3(-5, -16, 4.5), Vector3(2, -21, 5.0), Vector3(7, -13, 4.0)]:
		var center := Vector2(bloom.x, bloom.y)
		draw_line(Vector2(bloom.x * 0.4, 0), center, MOSS.darkened(0.15), 1.5, true)
		draw_circle(center, bloom.z * 2.2, Color(PETAL_GLOW, 0.18 * pulse), true, -1.0, true)
		for petal in 5:
			var angle := TAU * petal / 5.0 + phase
			draw_circle(center + Vector2(cos(angle), sin(angle)) * bloom.z * 0.55, bloom.z * 0.55, PETAL, true, -1.0, true)
		draw_circle(center, bloom.z * 0.35, Color("#fff4b8"), true, -1.0, true)


func _draw_wayfire() -> void:
	SmoothDraw.shadow(self, Vector2(-2, 1), Vector2(40, 10))
	# A stone pillar with an iron bowl on top.
	SmoothDraw.box(self, Rect2(-12, -8, 24, 8), STONE_DARK, 3.0)
	SmoothDraw.box(self, Rect2(-8, -34, 16, 27), STONE, 3.0)
	for row: float in [-26.0, -17.0]:
		draw_line(Vector2(-6, row), Vector2(6, row), Color(STONE_DARK, 0.6), 1.0, true)
	SmoothDraw.box(self, Rect2(-5, -30, 4, 6), MOSS, 2.0)
	SmoothDraw.polygon(self, PackedVector2Array([Vector2(-15, -40), Vector2(15, -40), Vector2(10, -33), Vector2(-10, -33)]), Color("#3d3936"), OUTLINE, 1.5)
	if not is_spent():
		# Cold ash and a curl of nothing.
		draw_circle(Vector2(-4, -41), 3.0, Color("#6a6460"), true, -1.0, true)
		draw_circle(Vector2(3, -41), 3.5, Color("#57524d"), true, -1.0, true)
		return
	var flicker := sin(time * 11.0 + phase) * 1.5
	SmoothDraw.polygon(self, PackedVector2Array([Vector2(-11, -40), Vector2(-5, -54 - flicker), Vector2(0, -47), Vector2(4, -60 + flicker), Vector2(11, -40)]), FLAME, Color(FLAME.darkened(0.3), 0.8), 1.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-5, -40), Vector2(0, -51 - flicker * 0.5), Vector2(5, -40)]), FLAME_CORE)


func _draw_axe_stump() -> void:
	SmoothDraw.shadow(self, Vector2(-2, 2), Vector2(50, 12))
	# A broad felled stump with its rings showing, wood chips round its foot.
	SmoothDraw.box(self, Rect2(-20, -18, 40, 18), WOOD, 5.0)
	draw_set_transform(Vector2(0, -18), 0.0, Vector2(1.0, 0.38))
	draw_circle(Vector2.ZERO, 21.0, OUTLINE, true, -1.0, true)
	draw_circle(Vector2.ZERO, 20.0, WOOD_LIGHT, true, -1.0, true)
	for ring: float in [15.0, 10.0, 5.0]:
		draw_arc(Vector2.ZERO, ring, 0.0, TAU, 28, Color(WOOD, 0.8), 1.2, true)
	draw_set_transform(Vector2.ZERO)
	for chip: Vector2 in [Vector2(-26, 2), Vector2(24, 0), Vector2(-14, 5), Vector2(15, 6), Vector2(30, 5)]:
		SmoothDraw.flat(self, Rect2(chip, Vector2(5, 2.5)), WOOD_LIGHT.lightened(0.15), 1.0)
	if is_spent():
		draw_line(Vector2(3, -19), Vector2(8, -15), Color(OUTLINE, 0.7), 1.5, true)
		return
	# Rendel's axe, bitten deep into the stump.
	draw_line(Vector2(-12, -42), Vector2(5, -19), OUTLINE, 5.0, true)
	draw_line(Vector2(-12, -42), Vector2(5, -19), WOOD_LIGHT.lightened(0.1), 3.0, true)
	SmoothDraw.polygon(self, PackedVector2Array([Vector2(1, -25), Vector2(11, -27), Vector2(13, -17), Vector2(5, -18)]), STEEL, OUTLINE, 1.5)
	draw_line(Vector2(12, -26), Vector2(13, -18), Color.WHITE.lerp(STEEL, 0.4), 1.0, true)


func _draw_journal() -> void:
	SmoothDraw.shadow(self, Vector2(0, 1), Vector2(34, 9))
	# A flat stone with the journal on it, its ribbon trailing.
	SmoothDraw.box(self, Rect2(-17, -9, 34, 9), STONE_DARK, 4.0)
	SmoothDraw.box(self, Rect2(-10, -15, 20, 7), LEATHER, 2.0)
	SmoothDraw.flat(self, Rect2(-8.5, -14, 17, 2), Color("#e9dcc0"), 1.0)
	draw_line(Vector2(2, -9), Vector2(5, -3), Color("#a8323a"), 1.5, true)
	var pulse := 0.5 + 0.5 * sin(time * 3.0 + phase)
	draw_circle(Vector2(0, -12), 14.0, Color(1.0, 0.86, 0.4, 0.08 + 0.08 * pulse), true, -1.0, true)


func _draw_cave_exit() -> void:
	# A shaft of daylight falling through the cave's mouth.
	var sway := sin(time * 0.8 + phase) * 2.0
	draw_colored_polygon(PackedVector2Array([Vector2(-18 + sway, -120), Vector2(18 + sway, -120), Vector2(40, 6), Vector2(-40, 6)]), Color(1.0, 0.96, 0.8, 0.14))
	draw_colored_polygon(PackedVector2Array([Vector2(-8 + sway, -120), Vector2(8 + sway, -120), Vector2(22, 4), Vector2(-22, 4)]), Color(1.0, 0.97, 0.85, 0.14))
	draw_set_transform(Vector2(0, 0), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 40.0, Color(1.0, 0.95, 0.75, 0.16), true, -1.0, true)
	draw_set_transform(Vector2.ZERO)


func _draw_shrine() -> void:
	SmoothDraw.shadow(self, Vector2(-3, 2), Vector2(64, 14))
	SmoothDraw.box(self, Rect2(-28, -10, 56, 10), STONE_DARK, 3.0)
	SmoothDraw.box(self, Rect2(-20, -54, 40, 45), STONE, 6.0)
	# Peaked cap and the carved torch-bearer.
	SmoothDraw.polygon(self, PackedVector2Array([Vector2(-25, -52), Vector2(0, -68), Vector2(25, -52)]), STONE_DARK, OUTLINE, 2.0)
	draw_line(Vector2(0, -44), Vector2(0, -22), Color(STONE_DARK.darkened(0.3), 0.9), 2.0, true)
	draw_circle(Vector2(0, -47), 3.0, Color(STONE_DARK.darkened(0.3), 0.9), true, -1.0, true)
	draw_line(Vector2(0, -36), Vector2(7, -42), Color(STONE_DARK.darkened(0.3), 0.9), 1.5, true)
	var lit := Quests.is_completed(Quests.WAYFIRES)
	var warmth := 0.55 + 0.25 * sin(time * 3.0 + phase) if lit else 0.0
	draw_circle(Vector2(7, -44), 2.5, Color(FLAME_CORE, warmth) if lit else Color(STONE_DARK.darkened(0.3), 0.9), true, -1.0, true)
	# Moss creeping over the stone, and white flowers once the fires burn.
	for blob: Vector3 in [Vector3(-17, -50, 5), Vector3(-19, -18, 6), Vector3(16, -12, 5), Vector3(18, -42, 4), Vector3(-8, -60, 4)]:
		draw_circle(Vector2(blob.x, blob.y), blob.z, Color(MOSS, 0.9), true, -1.0, true)
	if lit:
		for flower: Vector2 in [Vector2(-22, -4), Vector2(-12, 2), Vector2(14, 1), Vector2(25, -3)]:
			draw_circle(flower, 2.0, Color("#f6f3e6"), true, -1.0, true)


func _draw_perrys_hat() -> void:
	SmoothDraw.shadow(self, Vector2(0, 1), Vector2(30, 7))
	# Knocked off at the pit's edge and lying crooked: a floppy brim, the dented crown, its patch and hole.
	draw_set_transform(Vector2(0, -3), -0.18, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, 14.0, OUTLINE, true, -1.0, true)
	draw_circle(Vector2.ZERO, 13.0, FELT.darkened(0.12), true, -1.0, true)
	draw_set_transform(Vector2.ZERO)
	SmoothDraw.polygon(self, PackedVector2Array([
		Vector2(-8, -3), Vector2(-7, -12), Vector2(-2, -10), Vector2(1, -13), Vector2(7, -11), Vector2(8, -4),
	]), FELT, OUTLINE, 1.0)
	draw_line(Vector2(-8, -5), Vector2(8, -5.5), FELT.darkened(0.35), 1.8, true)
	SmoothDraw.flat(self, Rect2(-6, -10, 4, 3.5), WOOD_LIGHT, 0.8)
	draw_circle(Vector2(3.5, -10.5), 1.6, OUTLINE, true, -1.0, true)


## Oblath's south gate: two lantern-hung gateposts under a lintel with the town's sign, and a pair of
## iron-banded doors that swing in (open_amount) to the warm light of the town.
func _draw_town_gate() -> void:
	SmoothDraw.shadow(self, Vector2(-4, 2), Vector2(170, 18), 0.3)
	draw_rect(Rect2(-57, -78, 114, 78), Color(0.1, 0.07, 0.05))
	if open_amount > 0.0:
		draw_rect(Rect2(-57, -78, 114, 78), Color(LAMPLIGHT, 0.55 * open_amount))
	for side: float in [-1.0, 1.0]:
		var leaf_width := 57.0 * (1.0 - 0.82 * open_amount)
		var hinge := side * 57.0
		var leaf := Rect2(minf(hinge, hinge - side * leaf_width), -76, leaf_width, 76)
		SmoothDraw.box(self, leaf, WOOD.darkened(0.08), 1.5)
		var planks := int(leaf_width / 9.0)
		for plank in range(1, planks + 1):
			var x := leaf.position.x + leaf_width * plank / float(planks + 1)
			draw_line(Vector2(x, -74), Vector2(x, -2), Color(WOOD_DARK, 0.7), 1.0, true)
		for band_y: float in [-62.0, -18.0]:
			SmoothDraw.flat(self, Rect2(leaf.position.x + 1.0, band_y, leaf_width - 2.0, 4.0), IRON, 1.0)
		if open_amount < 0.5:
			draw_arc(Vector2(side * -8.0, -40.0), 3.5, 0.0, TAU, 14, IRON, 1.6, true)
	for side: float in [-1.0, 1.0]:
		SmoothDraw.box(self, Rect2(side * 66.0 - 10.0, -100, 20, 100), WOOD_DARK, 3.0)
		draw_line(Vector2(side * 66.0 - 5.0, -96), Vector2(side * 66.0 - 5.0, -4), Color(WOOD_LIGHT, 0.4), 1.5, true)
		SmoothDraw.polygon(self, PackedVector2Array([Vector2(side * 66.0 - 12.0, -98), Vector2(side * 66.0, -112), Vector2(side * 66.0 + 12.0, -98)]), WOOD, OUTLINE, 1.0)
		# A lantern on the post's inner face.
		var lantern := Vector2(side * 50.0, -82.0)
		draw_line(Vector2(side * 56.0, -92.0), lantern + Vector2(0, -6), IRON, 1.5, true)
		SmoothDraw.box(self, Rect2(lantern + Vector2(-4, -6), Vector2(8, 11)), IRON, 1.5)
		var flicker := 0.8 + 0.2 * sin(time * 9.0 + phase + side)
		SmoothDraw.flat(self, Rect2(lantern + Vector2(-2.5, -4), Vector2(5, 7)), Color(LAMPLIGHT, flicker), 1.0)
	SmoothDraw.box(self, Rect2(-80, -104, 160, 10), WOOD, 2.0)
	SmoothDraw.box(self, Rect2(-36, -124, 72, 19), WOOD_LIGHT, 3.0)
	var font := ThemeDB.fallback_font
	var text_width := font.get_string_size("OBLATH", HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	draw_string(font, Vector2(-text_width * 0.5, -110), "OBLATH", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, WOOD_DARK.darkened(0.3))


# --- The Sunscorch Sands ---------------------------------------------------------------------------------

## Malik's iron-bound strongbox, thrown from his wagon and half buried; its lid hangs open once searched.
func _draw_strongbox() -> void:
	SmoothDraw.shadow(self, Vector2(-2, 1), Vector2(40, 10))
	draw_set_transform(Vector2(0, -1), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 24.0, Color(SAND, 0.9), true, -1.0, true)
	draw_set_transform(Vector2.ZERO)
	SmoothDraw.box(self, Rect2(-15, -16, 30, 16), WOOD_DARK, 2.0)
	for band_x: float in [-9.0, 7.0]:
		SmoothDraw.flat(self, Rect2(band_x, -16, 3, 16), IRON, 0.5)
	if is_spent():
		SmoothDraw.polygon(self, PackedVector2Array([Vector2(-15, -16), Vector2(15, -16), Vector2(12, -28), Vector2(-13, -27)]), WOOD.darkened(0.15), OUTLINE, 1.2)
		draw_rect(Rect2(-13, -17, 26, 3), Color(0.08, 0.06, 0.04))
		return
	SmoothDraw.box(self, Rect2(-16, -22, 32, 7), WOOD, 2.0)
	SmoothDraw.flat(self, Rect2(-2.5, -18, 5, 6), SUN_GOLD.darkened(0.3), 1.0)
	# A corner of paper caught under the lid.
	SmoothDraw.polygon(self, PackedVector2Array([Vector2(6, -16), Vector2(13, -14), Vector2(11, -10)]), Color("#e9dcc0"), OUTLINE, 0.8)


## A fallen driver's mound in the sand, a blue scarf snagged on a broken spear beside it; a cairn once raised.
func _draw_grave() -> void:
	SmoothDraw.shadow(self, Vector2(0, 1), Vector2(46, 11))
	if is_spent():
		for stone: Vector3 in [Vector3(-12, -5, 8), Vector3(0, -6, 9), Vector3(12, -5, 8), Vector3(-6, -15, 7), Vector3(7, -15, 7), Vector3(0, -24, 6)]:
			SmoothDraw.dome(self, Vector2(stone.x, stone.y), stone.z, SANDSTONE.darkened(0.08 + absf(stone.x) * 0.006))
		draw_line(Vector2(14, -2), Vector2(18, -30), WOOD_DARK, 2.0, true)
		SmoothDraw.polygon(self, PackedVector2Array([Vector2(18, -30), Vector2(30, -27), Vector2(18, -23)]), Color("#3f6fae"), OUTLINE, 0.8)
		return
	draw_set_transform(Vector2(0, -3), 0.0, Vector2(1.0, 0.32))
	draw_circle(Vector2.ZERO, 26.0, OUTLINE, true, -1.0, true)
	draw_circle(Vector2.ZERO, 25.0, SAND.darkened(0.06), true, -1.0, true)
	draw_set_transform(Vector2.ZERO)
	for stone: Vector3 in [Vector3(-26, 2, 4), Vector3(24, 3, 5), Vector3(-18, 6, 3)]:
		SmoothDraw.dome(self, Vector2(stone.x, stone.y), stone.z, SANDSTONE)
	draw_line(Vector2(10, -4), Vector2(24, -22), WOOD_DARK, 2.0, true)
	var flutter := sin(time * 4.0 + phase) * 2.0
	SmoothDraw.polygon(self, PackedVector2Array([Vector2(22, -20), Vector2(34, -17 + flutter), Vector2(22, -14)]), Color("#3f6fae"), OUTLINE, 0.8)


## A spice crate from Malik's cargo, half sunk in a dune, red spice spilling from a split board.
func _draw_spice_crate() -> void:
	SmoothDraw.shadow(self, Vector2(-2, 1), Vector2(40, 10))
	SmoothDraw.box(self, Rect2(-15, -24, 30, 24), WOOD_LIGHT, 2.0)
	for plank_y: float in [-16.0, -8.0]:
		draw_line(Vector2(-14, plank_y), Vector2(14, plank_y), Color(WOOD_DARK, 0.7), 1.0, true)
	draw_line(Vector2(-14, -23), Vector2(14, -1), Color(WOOD_DARK, 0.6), 1.5, true)
	draw_set_transform(Vector2(6, -1), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 14.0, SPICE, true, -1.0, true)
	draw_set_transform(Vector2.ZERO)
	SmoothDraw.polygon(self, PackedVector2Array([Vector2(-26, 2), Vector2(-14, -8), Vector2(-4, -3), Vector2(-20, 4)]), SAND, Color(SANDSTONE_DARK, 0.5), 1.0)


## A sandstone obelisk carved with a sun-disc over a coiled tail; the carving shines gold once copied.
func _draw_obelisk() -> void:
	SmoothDraw.shadow(self, Vector2(-4, 2), Vector2(70, 14))
	SmoothDraw.box(self, Rect2(-24, -12, 48, 12), SANDSTONE_DARK, 2.0)
	SmoothDraw.polygon(self, PackedVector2Array([Vector2(-15, -12), Vector2(15, -12), Vector2(10, -112), Vector2(0, -126), Vector2(-10, -112)]), SANDSTONE, OUTLINE, 1.5)
	draw_line(Vector2(5, -14), Vector2(3, -110), Color(SANDSTONE_DARK, 0.5), 3.0, true)
	var carving := Color(SUN_GOLD, 0.6 + 0.3 * sin(time * 2.0 + phase)) if is_spent() else SANDSTONE_DARK.darkened(0.2)
	draw_arc(Vector2(0, -88), 7.0, 0.0, TAU, 20, carving, 2.0, true)
	for ray in 8:
		var direction := Vector2.from_angle(TAU * ray / 8.0)
		draw_line(Vector2(0, -88) + direction * 9.0, Vector2(0, -88) + direction * 13.0, carving, 1.5, true)
	draw_arc(Vector2(0, -52), 6.0, PI * 0.2, PI * 1.9, 14, carving, 2.0, true)
	draw_line(Vector2(5, -55), Vector2(2, -66), carving, 2.0, true)
	draw_line(Vector2(-5, -36), Vector2(5, -36), carving, 1.5, true)
	draw_line(Vector2(-4, -30), Vector2(4, -30), carving, 1.5, true)
	SmoothDraw.polygon(self, PackedVector2Array([Vector2(-30, 2), Vector2(-20, -10), Vector2(-6, -6), Vector2(4, 3)]), SAND, Color(SANDSTONE_DARK, 0.4), 1.0)


## A tall red rock at the edge of the Sands, an old scouts' lookout; a red flag flies from it once raised.
func _draw_signal_rock() -> void:
	SmoothDraw.shadow(self, Vector2(-4, 2), Vector2(80, 16))
	var rock := Color("#b0643c")
	SmoothDraw.polygon(self, PackedVector2Array([
		Vector2(-34, 0), Vector2(-30, -40), Vector2(-20, -74), Vector2(-6, -86), Vector2(12, -80), Vector2(24, -52),
		Vector2(30, -20), Vector2(34, 0),
	]), rock, OUTLINE, 1.5)
	draw_line(Vector2(-26, -40), Vector2(22, -46), Color(rock.darkened(0.3), 0.7), 2.0, true)
	draw_line(Vector2(-28, -18), Vector2(28, -22), Color(rock.darkened(0.3), 0.7), 2.0, true)
	draw_line(Vector2(6, -84), Vector2(-14, -70), Color(rock.lightened(0.25), 0.6), 3.0, true)
	if not is_spent():
		return
	draw_line(Vector2(0, -84), Vector2(0, -124), WOOD_DARK, 2.5, true)
	var wave := sin(time * 5.0 + phase) * 3.0
	SmoothDraw.polygon(self, PackedVector2Array([
		Vector2(1, -123), Vector2(14, -120 + wave), Vector2(26, -118 - wave * 0.5), Vector2(14, -110 + wave), Vector2(1, -107),
	]), FLAG, OUTLINE, 1.0)


## One of Qasr Anuhm's old wells: a ring of carved stone choked with sand, or brimming with water once dug out.
func _draw_old_well() -> void:
	SmoothDraw.shadow(self, Vector2(0, 2), Vector2(50, 12))
	draw_set_transform(Vector2(0, -6), 0.0, Vector2(1.0, 0.42))
	draw_circle(Vector2.ZERO, 26.0, OUTLINE, true, -1.0, true)
	draw_circle(Vector2.ZERO, 25.0, SANDSTONE, true, -1.0, true)
	draw_circle(Vector2.ZERO, 18.0, SANDSTONE_DARK, true, -1.0, true)
	if is_spent():
		draw_circle(Vector2.ZERO, 16.0, WATER, true, -1.0, true)
		var ripple := fmod(time * 0.6 + phase, 1.0)
		draw_arc(Vector2.ZERO, 4.0 + ripple * 11.0, 0.0, TAU, 24, Color(1, 1, 1, 0.5 * (1.0 - ripple)), 1.5, true)
	else:
		draw_circle(Vector2(2, 2), 16.0, SAND, true, -1.0, true)
	draw_set_transform(Vector2.ZERO)
	SmoothDraw.box(self, Rect2(-26, -8, 52, 8), SANDSTONE, 3.0)
	for notch: float in [-14.0, 0.0, 14.0]:
		draw_line(Vector2(notch, -7), Vector2(notch, -1), Color(SANDSTONE_DARK, 0.7), 1.0, true)
	if not is_spent():
		SmoothDraw.polygon(self, PackedVector2Array([Vector2(-10, -6), Vector2(4, -16), Vector2(18, -8), Vector2(22, 0), Vector2(-6, 0)]), SAND, Color(SANDSTONE_DARK, 0.4), 1.0)


## A flowering barrel cactus crowned with fat red sunbloom fruit; just the cactus once picked.
func _draw_sunbloom() -> void:
	SmoothDraw.shadow(self, Vector2(0, 1), Vector2(36, 9))
	for lobe: Vector3 in [Vector3(-10, -12, 11), Vector3(10, -12, 11), Vector3(0, -20, 15)]:
		SmoothDraw.dome(self, Vector2(lobe.x, lobe.y), lobe.z, CACTUS.darkened(absf(lobe.x) * 0.012))
	for rib: float in [-6.0, 0.0, 6.0]:
		draw_line(Vector2(rib, -32), Vector2(rib * 1.3, -8), Color(CACTUS.darkened(0.35), 0.7), 1.0, true)
	for spine: Vector2 in [Vector2(-14, -18), Vector2(13, -20), Vector2(-4, -30), Vector2(7, -10)]:
		draw_line(spine, spine + Vector2(2, -3), Color("#f3ead2"), 1.0, true)
	if is_spent():
		return
	var pulse := 0.85 + 0.15 * sin(time * 2.0 + phase)
	for fruit: Vector2 in [Vector2(-6, -36), Vector2(4, -38), Vector2(0, -44)]:
		draw_circle(fruit, 5.5, OUTLINE, true, -1.0, true)
		draw_circle(fruit, 4.6, SPICE.lightened(0.1 * pulse), true, -1.0, true)
		draw_circle(fruit + Vector2(-1.5, -1.5), 1.4, Color(1, 0.8, 0.6, 0.8), true, -1.0, true)


## The broken stair down into the Sunken Vault, between two pillars under a cracked lintel.
func _draw_vault_stairs() -> void:
	SmoothDraw.shadow(self, Vector2(-4, 2), Vector2(130, 18), 0.3)
	draw_rect(Rect2(-40, -60, 80, 60), Color(0.07, 0.05, 0.04))
	for step in 5:
		var inset := step * 3.0
		SmoothDraw.flat(self, Rect2(-38 + inset, -10.0 - step * 10.0, 76 - inset * 2.0, 5), SANDSTONE_DARK.darkened(0.25 + step * 0.12), 1.0)
	for side: float in [-1.0, 1.0]:
		SmoothDraw.box(self, Rect2(side * 50.0 - 10.0, -88, 20, 88), SANDSTONE, 2.0)
		draw_line(Vector2(side * 50.0 - 4.0, -84), Vector2(side * 50.0 - 4.0, -4), Color(SANDSTONE_DARK, 0.5), 2.0, true)
	SmoothDraw.polygon(self, PackedVector2Array([Vector2(-66, -86), Vector2(66, -92), Vector2(64, -102), Vector2(-64, -98)]), SANDSTONE, OUTLINE, 1.5)
	draw_line(Vector2(6, -100), Vector2(12, -88), OUTLINE, 1.5, true)
	draw_arc(Vector2(0, -95), 4.0, 0.0, TAU, 14, SANDSTONE_DARK.darkened(0.2), 1.5, true)
	if is_wanted():
		# A faint golden warmth breathing up out of the dark.
		var breath := 0.5 + 0.5 * sin(time * 1.5 + phase)
		draw_rect(Rect2(-36, -58, 72, 56), Color(SUN_GOLD, 0.05 + 0.05 * breath))


## A splinter of the cracked Sunstone, glowing faintly where it fell.
func _draw_sun_shard() -> void:
	var pulse := 0.6 + 0.4 * sin(time * 3.0 + phase)
	draw_circle(Vector2(0, -8), 16.0, Color(SUN_GOLD, 0.12 * pulse), true, -1.0, true)
	SmoothDraw.polygon(self, PackedVector2Array([Vector2(-7, 0), Vector2(-4, -16), Vector2(3, -22), Vector2(8, -6), Vector2(4, 0)]), Color("#f3e3b0"), OUTLINE, 1.2)
	draw_line(Vector2(-3, -14), Vector2(4, -4), Color(SUN_GOLD, 0.8 * pulse), 1.5, true)


## The seal-dais at the heart of the vault: a round stone platform round the sun-disc socket, cracked and
## empty until the mended Sunstone blazes in it.
func _draw_sun_seal() -> void:
	SmoothDraw.shadow(self, Vector2(0, 2), Vector2(110, 22), 0.3)
	draw_set_transform(Vector2(0, -8), 0.0, Vector2(1.0, 0.38))
	draw_circle(Vector2.ZERO, 54.0, OUTLINE, true, -1.0, true)
	draw_circle(Vector2.ZERO, 53.0, SANDSTONE_DARK, true, -1.0, true)
	draw_circle(Vector2.ZERO, 44.0, SANDSTONE, true, -1.0, true)
	for ray in 12:
		var direction := Vector2.from_angle(TAU * ray / 12.0)
		draw_line(direction * 26.0, direction * 42.0, Color(SANDSTONE_DARK, 0.7), 2.0, true)
	draw_set_transform(Vector2.ZERO)
	SmoothDraw.box(self, Rect2(-14, -36, 28, 22), SANDSTONE_DARK, 3.0)
	if is_spent():
		var blaze := 0.75 + 0.25 * sin(time * 2.5 + phase)
		draw_circle(Vector2(0, -42), 22.0, Color(SUN_GOLD, 0.2 * blaze), true, -1.0, true)
		draw_circle(Vector2(0, -42), 11.0, OUTLINE, true, -1.0, true)
		draw_circle(Vector2(0, -42), 10.0, SUN_GOLD.lerp(Color.WHITE, 0.3 * blaze), true, -1.0, true)
		for ray in 8:
			var direction := Vector2.from_angle(TAU * ray / 8.0 + time * 0.3)
			draw_line(Vector2(0, -42) + direction * 13.0, Vector2(0, -42) + direction * (19.0 + 3.0 * blaze), Color(SUN_GOLD, 0.8), 2.0, true)
		return
	# The empty socket, and the crack Malik's pick left across the dais.
	draw_circle(Vector2(0, -42), 10.0, OUTLINE, true, -1.0, true)
	draw_circle(Vector2(0, -42), 8.5, Color(0.12, 0.08, 0.05), true, -1.0, true)
	draw_polyline(PackedVector2Array([Vector2(-36, -6), Vector2(-20, -12), Vector2(-12, -6), Vector2(4, -14)]), OUTLINE, 1.5, true)


# --- The Ice Caves ---------------------------------------------------------------------------------------

## The ice-cutters' sledge, left loaded with blue blocks, a saw across them and the tally-book under a strap.
func _draw_cutters_sledge() -> void:
	SmoothDraw.shadow(self, Vector2(-2, 1), Vector2(64, 12))
	for runner_y: float in [-2.0, 4.0]:
		draw_polyline(PackedVector2Array([Vector2(-30, runner_y), Vector2(24, runner_y), Vector2(31, runner_y - 6)]), WOOD_DARK, 2.0, true)
	SmoothDraw.box(self, Rect2(-28, -10, 52, 8), WOOD, 2.0)
	for block: Rect2 in [Rect2(-24, -24, 15, 14), Rect2(-8, -24, 15, 14), Rect2(8, -22, 13, 12), Rect2(-16, -36, 15, 12)]:
		SmoothDraw.box(self, block, ICE, 2.0, Color(ICE_DEEP, 0.9))
		draw_line(block.position + Vector2(3, 3), block.position + Vector2(7, 3), Color(1, 1, 1, 0.7), 1.0, true)
	# The two-man saw lying across the load.
	draw_line(Vector2(-30, -27), Vector2(22, -33), STEEL, 2.5, true)
	for handle: Vector2 in [Vector2(-32, -27), Vector2(24, -33)]:
		SmoothDraw.flat(self, Rect2(handle - Vector2(2, 4), Vector2(4, 8)), WOOD_DARK, 1.0)
	if not is_spent():
		SmoothDraw.box(self, Rect2(4, -9, 12, 7), LEATHER, 1.0)
		draw_line(Vector2(10, -11), Vector2(10, -1), Color(OUTLINE, 0.8), 1.0, true)


## A Rimewarden runestone, crusted over with fresh frost until cleared, then its runes glowing blue.
func _draw_runestone() -> void:
	SmoothDraw.shadow(self, Vector2(-4, 2), Vector2(60, 13))
	SmoothDraw.polygon(self, PackedVector2Array([
		Vector2(-20, 0), Vector2(-22, -50), Vector2(-14, -82), Vector2(4, -90), Vector2(18, -76), Vector2(22, -40), Vector2(20, 0),
	]), FROST_STONE, OUTLINE, 1.5)
	draw_line(Vector2(12, -80), Vector2(16, -6), Color(FROST_STONE_DARK, 0.6), 3.0, true)
	if not is_spent():
		# Thick rime over the face, and icicles hanging from its shoulder.
		SmoothDraw.polygon(self, PackedVector2Array([
			Vector2(-21, -12), Vector2(-22, -52), Vector2(-14, -80), Vector2(4, -88), Vector2(17, -74), Vector2(20, -34), Vector2(16, -8),
		]), Color(SNOW, 0.92), Color(ICE_DEEP, 0.5), 1.0)
		for icicle: float in [-14.0, -4.0, 8.0]:
			draw_colored_polygon(PackedVector2Array([Vector2(icicle - 3, -10), Vector2(icicle + 3, -10), Vector2(icicle, 2)]), ICE)
		return
	var glow := Color(RIME_GLOW, 0.65 + 0.3 * sin(time * 2.0 + phase))
	for row in 4:
		var y := -74.0 + row * 16.0
		draw_line(Vector2(-6, y), Vector2(-6, y + 10), glow, 2.0, true)
		draw_line(Vector2(-6, y + 2), Vector2(2, y + 6), glow, 2.0, true)
		draw_line(Vector2(6, y), Vector2(10, y + 8), glow, 2.0, true)


## The Wardens' Rimekey, a rod of clear ice that never melts, lying on a little altar at the foot of the falls.
func _draw_rimekey() -> void:
	SmoothDraw.shadow(self, Vector2(0, 1), Vector2(40, 10))
	SmoothDraw.box(self, Rect2(-16, -16, 32, 16), FROST_STONE_DARK, 3.0)
	SmoothDraw.box(self, Rect2(-19, -20, 38, 6), FROST_STONE, 2.0)
	var pulse := 0.6 + 0.4 * sin(time * 2.6 + phase)
	draw_circle(Vector2(0, -26), 16.0, Color(RIME_GLOW, 0.12 * pulse), true, -1.0, true)
	draw_line(Vector2(-12, -23), Vector2(12, -29), OUTLINE, 5.0, true)
	draw_line(Vector2(-12, -23), Vector2(12, -29), ICE.lightened(0.2), 3.0, true)
	draw_line(Vector2(-6, -25), Vector2(6, -28), Color(RIME_GLOW, pulse), 1.0, true)
	for tooth: float in [8.0, 12.0]:
		draw_line(Vector2(tooth, -28), Vector2(tooth + 1, -22), ICE, 2.0, true)


## A fallen frostpine, its trunk crusted with ice; broken-off and bare once its kindling is gathered.
func _draw_kindling() -> void:
	SmoothDraw.shadow(self, Vector2(0, 1), Vector2(70, 11))
	SmoothDraw.polygon(self, PackedVector2Array([Vector2(-34, -4), Vector2(-30, -14), Vector2(32, -10), Vector2(34, -1), Vector2(-30, 2)]), FROSTPINE, OUTLINE, 1.2)
	draw_set_transform(Vector2(-32, -6), 0.0, Vector2(0.45, 1.0))
	draw_circle(Vector2.ZERO, 9.0, WOOD_LIGHT, true, -1.0, true)
	draw_arc(Vector2.ZERO, 5.0, 0.0, TAU, 16, Color(WOOD, 0.8), 1.0, true)
	draw_set_transform(Vector2.ZERO)
	# Snow along the top of the trunk.
	draw_polyline(PackedVector2Array([Vector2(-28, -14), Vector2(-10, -15), Vector2(10, -13), Vector2(30, -11)]), SNOW, 3.0, true)
	if is_spent():
		return
	for branch: Array in [[Vector2(-14, -13), Vector2(-20, -30)], [Vector2(2, -13), Vector2(8, -32)], [Vector2(18, -11), Vector2(14, -26)]]:
		draw_line(branch[0], branch[1], OUTLINE, 3.5, true)
		draw_line(branch[0], branch[1], FROSTPINE.lightened(0.15), 2.0, true)
		draw_circle(branch[1], 2.5, SNOW, true, -1.0, true)


## A shoulder of cave rock with a seam of hard blue rime-ice running through it; chipped out once cut.
func _draw_rime_vein() -> void:
	SmoothDraw.shadow(self, Vector2(-3, 2), Vector2(64, 13))
	SmoothDraw.polygon(self, PackedVector2Array([
		Vector2(-30, 0), Vector2(-28, -32), Vector2(-14, -54), Vector2(8, -58), Vector2(26, -40), Vector2(30, 0),
	]), FROST_STONE_DARK, OUTLINE, 1.5)
	draw_line(Vector2(-18, -48), Vector2(4, -54), Color(FROST_STONE, 0.7), 3.0, true)
	var seam := PackedVector2Array([Vector2(-24, -8), Vector2(-10, -22), Vector2(2, -18), Vector2(14, -34), Vector2(24, -30)])
	if is_spent():
		draw_polyline(seam, Color(0.1, 0.12, 0.16), 6.0, true)
		return
	draw_polyline(seam, OUTLINE, 8.0, true)
	draw_polyline(seam, ICE_DEEP, 6.0, true)
	draw_polyline(seam, Color(RIME_GLOW, 0.5 + 0.3 * sin(time * 2.2 + phase)), 2.0, true)


## An old watchers' beacon: a cairn of frosted stone under an iron bowl, burning cold blue once lit.
func _draw_rime_beacon() -> void:
	SmoothDraw.shadow(self, Vector2(-2, 1), Vector2(46, 11))
	for stone: Vector3 in [Vector3(-11, -6, 9), Vector3(10, -6, 9), Vector3(0, -8, 10), Vector3(-6, -20, 8), Vector3(6, -20, 8), Vector3(0, -30, 7)]:
		SmoothDraw.dome(self, Vector2(stone.x, stone.y), stone.z, FROST_STONE.darkened(absf(stone.x) * 0.01))
	SmoothDraw.polygon(self, PackedVector2Array([Vector2(-14, -42), Vector2(14, -42), Vector2(9, -35), Vector2(-9, -35)]), IRON, OUTLINE, 1.5)
	if not is_spent():
		draw_polyline(PackedVector2Array([Vector2(-12, -42), Vector2(0, -44), Vector2(12, -42)]), SNOW, 2.0, true)
		return
	var flicker := sin(time * 9.0 + phase) * 1.5
	SmoothDraw.polygon(self, PackedVector2Array([Vector2(-10, -42), Vector2(-4, -55 - flicker), Vector2(0, -49), Vector2(4, -61 + flicker), Vector2(10, -42)]), RIME_GLOW, Color(ICE_DEEP, 0.8), 1.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-4, -42), Vector2(0, -52 - flicker * 0.5), Vector2(4, -42)]), Color.WHITE.lerp(RIME_GLOW, 0.3))


## The ward-gate in the heart of the Wardhall: two ice pillars under a rune-cut lintel, sealed with a sheet
## of frost that clears while the Rimekey can open it.
func _draw_ward_gate() -> void:
	SmoothDraw.shadow(self, Vector2(-4, 2), Vector2(130, 18), 0.3)
	draw_rect(Rect2(-40, -70, 80, 70), Color(0.04, 0.07, 0.1))
	for step in 4:
		var inset := step * 4.0
		SmoothDraw.flat(self, Rect2(-38 + inset, -10.0 - step * 12.0, 76 - inset * 2.0, 5), ICE_DEEP.darkened(0.3 + step * 0.12), 1.0)
	var open := is_wanted()
	if not open:
		draw_rect(Rect2(-40, -70, 80, 70), Color(ICE, 0.45))
	for side: float in [-1.0, 1.0]:
		SmoothDraw.box(self, Rect2(side * 50.0 - 10.0, -96, 20, 96), ICE, 2.0, Color(ICE_DEEP, 0.9))
		draw_line(Vector2(side * 50.0 - 4.0, -92), Vector2(side * 50.0 - 4.0, -4), Color(1, 1, 1, 0.45), 2.0, true)
	SmoothDraw.polygon(self, PackedVector2Array([Vector2(-66, -94), Vector2(66, -98), Vector2(64, -110), Vector2(-64, -106)]), FROST_STONE, OUTLINE, 1.5)
	var rune := Color(RIME_GLOW, 0.5 + 0.4 * sin(time * 1.8 + phase)) if open else FROST_STONE_DARK
	for mark: float in [-36.0, -12.0, 12.0, 36.0]:
		draw_line(Vector2(mark, -107), Vector2(mark, -98), rune, 1.5, true)
		draw_line(Vector2(mark, -105), Vector2(mark + 5, -101), rune, 1.5, true)
	if open:
		draw_rect(Rect2(-36, -66, 72, 62), Color(RIME_GLOW, 0.06 + 0.05 * sin(time * 1.5 + phase)))


## A crack in the floor of the Deep, glowing with the Underworld's heat and breathing steam; frozen white
## once sealed.
func _draw_melt_rift() -> void:
	SmoothDraw.shadow(self, Vector2(0, 1), Vector2(70, 14))
	var crack := PackedVector2Array([Vector2(-32, 2), Vector2(-18, -6), Vector2(-6, -1), Vector2(6, -8), Vector2(20, -3), Vector2(32, -9)])
	draw_polyline(crack, OUTLINE, 9.0, true)
	if is_spent():
		draw_polyline(crack, ICE, 6.0, true)
		draw_polyline(crack, Color(1, 1, 1, 0.6), 2.0, true)
		return
	var heat := 0.75 + 0.25 * sin(time * 4.0 + phase)
	draw_polyline(crack, RIFT_FIRE.darkened(0.2), 6.0, true)
	draw_polyline(crack, FLAME_CORE.lerp(RIFT_FIRE, 1.0 - heat), 2.5, true)
	# Steam curling up off it.
	for puff in 3:
		var rise := fmod(time * 0.5 + phase + puff * 0.33, 1.0)
		draw_circle(Vector2(-16 + puff * 16 + sin(rise * 6.0) * 3.0, -8 - rise * 40.0), 4.0 + rise * 6.0, Color(1, 1, 1, 0.22 * (1.0 - rise)), true, -1.0, true)


## The Heartfrost: a frozen spring welling up from the floor of the Deep as great crystals of blue ice,
## cracked through and dim until the Rimeward is set at its heart and it blazes whole.
func _draw_heartfrost() -> void:
	SmoothDraw.shadow(self, Vector2(0, 2), Vector2(130, 24), 0.3)
	draw_set_transform(Vector2(0, -6), 0.0, Vector2(1.0, 0.38))
	draw_circle(Vector2.ZERO, 62.0, OUTLINE, true, -1.0, true)
	draw_circle(Vector2.ZERO, 61.0, ICE_DEEP, true, -1.0, true)
	draw_circle(Vector2.ZERO, 48.0, ICE, true, -1.0, true)
	draw_set_transform(Vector2.ZERO)
	var whole := is_spent()
	var crystal := ICE.lightened(0.15) if whole else ICE.darkened(0.12)
	for shard: Array in [[Vector2(-24, -8), 14.0, 54.0], [Vector2(22, -8), 12.0, 46.0], [Vector2(0, -10), 18.0, 78.0]]:
		var base: Vector2 = shard[0]
		var half: float = shard[1]
		var height: float = shard[2]
		SmoothDraw.polygon(self, PackedVector2Array([
			base + Vector2(-half, 0), base + Vector2(-half * 0.7, -height * 0.8), base + Vector2(0, -height),
			base + Vector2(half * 0.7, -height * 0.8), base + Vector2(half, 0),
		]), crystal, Color(ICE_DEEP.darkened(0.3), 0.9), 1.5)
		draw_line(base + Vector2(-half * 0.3, -4), base + Vector2(-half * 0.2, -height * 0.75), Color(1, 1, 1, 0.5), 1.5, true)
	if whole:
		var blaze := 0.75 + 0.25 * sin(time * 2.2 + phase)
		draw_circle(Vector2(0, -44), 24.0, Color(RIME_GLOW, 0.25 * blaze), true, -1.0, true)
		draw_circle(Vector2(0, -44), 9.0, Color.WHITE.lerp(RIME_GLOW, 0.4 * blaze), true, -1.0, true)
		return
	# The cracks Hrimgar left, and the empty hollow where the Rimeward belongs.
	draw_polyline(PackedVector2Array([Vector2(-6, -82), Vector2(2, -64), Vector2(-4, -50), Vector2(6, -30), Vector2(0, -12)]), OUTLINE, 1.5, true)
	draw_polyline(PackedVector2Array([Vector2(-30, -50), Vector2(-22, -36), Vector2(-26, -20)]), OUTLINE, 1.2, true)
	draw_circle(Vector2(0, -44), 8.0, OUTLINE, true, -1.0, true)
	draw_circle(Vector2(0, -44), 6.5, Color(0.05, 0.08, 0.12), true, -1.0, true)
