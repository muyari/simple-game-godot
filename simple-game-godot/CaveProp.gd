extends Node2D
class_name CaveProp
## The Gloomhollow's furnishings, drawn smooth and softly lit like the hub props and standing on their
## node origin so they y-sort: glowing crystal clusters, stalagmites, luminous mushrooms and old bones.

enum Kind { CRYSTAL, STALAGMITE, MUSHROOMS, BONES }

const OUTLINE := Color(0.06, 0.05, 0.07)
const CRYSTAL := Color("#8fd8ff")
const CRYSTAL_DEEP := Color("#4a86c9")
const STONE := Color("#55505e")
const STONE_LIGHT := Color("#77707f")
const MUSHROOM := Color("#b48cff")
const STALK := Color("#d9d0e6")
const BONE := Color("#d8cfba")

var kind := Kind.CRYSTAL
var variant := 0
var time := 0.0
var phase := 0.0


func _ready() -> void:
	phase = randf() * TAU
	if kind == Kind.CRYSTAL:
		FireGlow.attach(self, Vector2(0, -18), 120.0, CRYSTAL, 0.45)
	elif kind == Kind.MUSHROOMS:
		FireGlow.attach(self, Vector2(0, -4), 60.0, MUSHROOM, 0.35)
	set_process(kind in [Kind.CRYSTAL, Kind.MUSHROOMS])
	if kind in [Kind.MUSHROOMS, Kind.BONES]:
		z_index = -1


func _process(delta: float) -> void:
	time += delta
	queue_redraw()


func _draw() -> void:
	match kind:
		Kind.CRYSTAL:
			_draw_crystal()
		Kind.STALAGMITE:
			_draw_stalagmite()
		Kind.MUSHROOMS:
			_draw_mushrooms()
		Kind.BONES:
			_draw_bones()


func _draw_crystal() -> void:
	SmoothDraw.shadow(self, Vector2(0, 1), Vector2(40, 10), 0.4)
	SmoothDraw.box(self, Rect2(-16, -8, 32, 8), STONE, 3.0, OUTLINE)
	var glow := 0.8 + 0.2 * sin(time * 2.0 + phase)
	var shards := [Vector3(-9, 26, -0.35), Vector3(0, 40 + variant * 6, 0.05), Vector3(9, 30, 0.4), Vector3(-15, 16, -0.7)]
	for shard: Vector3 in shards:
		var base := Vector2(shard.x, -6)
		var tip := base + Vector2(sin(shard.z), -cos(shard.z)) * shard.y
		var side := Vector2(cos(shard.z), sin(shard.z)) * 4.5
		var points := PackedVector2Array([base - side, tip - side * 0.25, tip, tip + side * 0.25, base + side])
		SmoothDraw.polygon(self, points, CRYSTAL_DEEP.lerp(CRYSTAL, glow), OUTLINE, 1.2)
		draw_line(base - side * 0.3, tip, Color(1, 1, 1, 0.5 * glow), 1.2, true)


func _draw_stalagmite() -> void:
	SmoothDraw.shadow(self, Vector2(-2, 1), Vector2(36, 9), 0.4)
	var height := 46.0 + variant * 10.0
	SmoothDraw.polygon(self, PackedVector2Array([Vector2(-15, 0), Vector2(-7, -height * 0.55), Vector2(-2, -height), Vector2(3, -height * 0.7), Vector2(15, 0)]), STONE, OUTLINE, 1.5)
	draw_line(Vector2(-6, -4), Vector2(-3, -height * 0.85), Color(STONE_LIGHT, 0.7), 2.0, true)
	for ring: float in [0.3, 0.55]:
		draw_line(Vector2(-12 + ring * 10.0, -height * ring), Vector2(10 - ring * 6.0, -height * ring + 2.0), Color(OUTLINE, 0.35), 1.0, true)


func _draw_mushrooms() -> void:
	var glow := 0.7 + 0.3 * sin(time * 2.6 + phase)
	for cap: Vector3 in [Vector3(-8, -10, 6), Vector3(3, -15, 7.5), Vector3(11, -7, 5)]:
		draw_line(Vector2(cap.x, 0), Vector2(cap.x, cap.y + 2.0), STALK, 2.5, true)
		var center := Vector2(cap.x, cap.y)
		draw_circle(center, cap.z * 1.9, Color(MUSHROOM, 0.12 * glow), true, -1.0, true)
		SmoothDraw.polygon(self, PackedVector2Array([center + Vector2(-cap.z, 2), center + Vector2(-cap.z * 0.6, -cap.z * 0.6), center + Vector2(0, -cap.z * 0.8), center + Vector2(cap.z * 0.6, -cap.z * 0.6), center + Vector2(cap.z, 2)]), MUSHROOM.lerp(Color.WHITE, 0.2 * glow), OUTLINE, 1.0)
		draw_circle(center + Vector2(-cap.z * 0.3, -cap.z * 0.3), 1.2, Color(1, 1, 1, 0.8), true, -1.0, true)


func _draw_bones() -> void:
	SmoothDraw.shadow(self, Vector2(0, 0), Vector2(40, 8), 0.3)
	var flip := -1.0 if variant == 1 else 1.0
	# A long bone, a rib or two and a small skull.
	draw_line(Vector2(-16 * flip, -2), Vector2(12 * flip, -6), OUTLINE, 5.0, true)
	draw_line(Vector2(-16 * flip, -2), Vector2(12 * flip, -6), BONE, 3.0, true)
	for end: Vector2 in [Vector2(-16 * flip, -2), Vector2(12 * flip, -6)]:
		draw_circle(end, 3.0, BONE, true, -1.0, true)
	for rib in 2:
		draw_arc(Vector2(4 * flip + rib * 6.0, 2), 6.0, PI, TAU, 10, BONE, 1.8, true)
	SmoothDraw.dome(self, Vector2(-20 * flip, 2), 4.5, BONE, OUTLINE)
	draw_circle(Vector2(-21.5 * flip, 1.5), 1.1, OUTLINE, true, -1.0, true)
