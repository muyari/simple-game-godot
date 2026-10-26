extends Area2D
class_name QuestObject
## Something out in the forest that a quest has the player use: an apple tree to pick, a moonpetal to
## gather, a wayfire to light, Rendel's axe to pull from its stump, Ilsa's journal, Perry's hat, the
## Gloomhollow's mouth or the gate of Oblath. Drawn smooth and softly lit like the hub props, standing on its
## node origin so it y-sorts.
## Using it records a Quests event (see Quests.record_event); it is only usable while a quest wants it.

signal used(quest_object: QuestObject)

enum Kind { APPLES, MOONPETAL, WAYFIRE, AXE_STUMP, JOURNAL, CAVE_MOUTH, CAVE_EXIT, SHRINE, PERRYS_HAT, TOWN_GATE }

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
}
const DOORS: Array[Kind] = [Kind.CAVE_MOUTH, Kind.CAVE_EXIT, Kind.TOWN_GATE]
const FELT := Color("#6b5a44")
const IRON := Color("#3d3936")
const LAMPLIGHT := Color("#ffd28a")

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
	circle.radius = 72.0 if kind == Kind.TOWN_GATE else 56.0 if kind in [Kind.CAVE_MOUTH, Kind.APPLES] else 34.0
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
	sparkle.mode = QuestMarker.Mode.AVAILABLE if wanted and kind not in [Kind.CAVE_EXIT, Kind.SHRINE] else QuestMarker.Mode.HIDDEN
	prompt.visible = player_nearby and wanted
	if kind == Kind.WAYFIRE:
		for child in get_children():
			if child is FireGlow:
				child.visible = is_spent()
	if kind in [Kind.JOURNAL, Kind.PERRYS_HAT]:
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
