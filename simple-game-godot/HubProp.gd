extends Node2D
class_name HubProp
## The furniture of the regional hubs, drawn smooth and softly lit like the HUD and standing on their
## node origin so they y-sort with everything else. Saltwind Camp's nomad tents, market stalls, palms,
## oasis and wrecked wagon; Rimehollow's hide yurts, igloos, drying racks, fishing holes and the ice that
## holds the frozen hydra; Ashgate Outpost's palisades, watchtower, barricades, cots for the wounded and
## the smith's forge. Several take `broken` and `burning` for the outpost under siege.

enum Kind {
	TENT, STALL, CAMPFIRE, JARS, RUG, BANNER, PALM, OASIS, WAGON_WRECK, CAIRN, LOOKOUT, SKULL_POLE,
	YURT, IGLOO, BRAZIER, DRYING_RACK, FISHING_HOLE, SLED, TOTEM, ICE_BACK, ICE_FRONT,
	ARMY_TENT, PALISADE, PALISADE_POST, WATCHTOWER, BARRICADE, COT, WEAPON_RACK, DEBRIS, FORGE, GRAVE,
}

const OUTLINE := Color(0.13, 0.08, 0.05)
const WOOD := Color("#8a5d33")
const WOOD_LIGHT := Color("#b48452")
const WOOD_DARK := Color("#5c3c22")
const CHAR := Color("#2b211c")
const IRON := Color("#3d3936")
const STEEL := Color("#9aa3ab")
const CLAY := Color("#b86a3c")
const BONE := Color("#e8dfc9")
const CANVAS := Color("#cbb38a")
const STONE := Color("#9b9184")
const FUR := Color("#ece6dc")
const SNOW := Color("#f2f6fb")
const ICE := Color("#9fd3ee")
const WATER := Color("#2f6596")
const LEAF := Color("#4f8a3a")
const FLAME := Color("#ff7a1f")
const FLAME_CORE := Color("#ffe28a")

var kind := Kind.TENT
## Main colour (canvas, cloth, banner, pelt), and a second one for stripes and trim.
var tint := Color("#a4472f")
var alt := Color("#e3c98f")
var flip := false
## Width (palisades, barricades, rugs, the oasis) or a variant's size, in local pixels.
var length := 0.0
var height := 0.0
var variant := 0
var broken := false
var burning := false
var time := 0.0
var phase := 0.0
var random := RandomNumberGenerator.new()


func _ready() -> void:
	phase = randf() * TAU
	random.seed = int(absf(global_position.x) * 13.0 + absf(global_position.y) * 7.0) + variant
	if flip:
		scale.x = -absf(scale.x)
	match kind:
		Kind.CAMPFIRE:
			FireGlow.attach(self, Vector2(0.0, -8.0), 150.0, Color("#ff9a3c"), 0.55)
		Kind.BRAZIER:
			FireGlow.attach(self, Vector2(0.0, -30.0), 130.0, Color("#ffa04a"), 0.5)
		Kind.FORGE:
			FireGlow.attach(self, Vector2(0.0, -16.0), 120.0, Color("#ff7a2a"), 0.5)
		Kind.DEBRIS:
			FireGlow.attach(self, Vector2(0.0, -10.0), 140.0, Color("#ff6a1f"), 0.6)
		Kind.TOTEM:
			FireGlow.attach(self, Vector2(0.0, -62.0), 70.0, Color("#8fe0ff"), 0.35)
		Kind.WATCHTOWER, Kind.PALISADE, Kind.ARMY_TENT:
			if burning:
				FireGlow.attach(self, Vector2(0.0, -50.0), 130.0, Color("#ff6a1f"), 0.5)
	set_process(kind in [
		Kind.CAMPFIRE, Kind.BANNER, Kind.PALM, Kind.OASIS, Kind.BRAZIER, Kind.FISHING_HOLE, Kind.TOTEM,
		Kind.DEBRIS, Kind.FORGE,
	] or burning)


func _process(delta: float) -> void:
	time += delta
	queue_redraw()


func _draw() -> void:
	random.seed = int(absf(position.x) * 13.0 + absf(position.y) * 7.0) + variant
	match kind:
		Kind.TENT: _draw_tent()
		Kind.STALL: _draw_stall()
		Kind.CAMPFIRE: _draw_campfire()
		Kind.JARS: _draw_jars()
		Kind.RUG: _draw_rug()
		Kind.BANNER: _draw_banner()
		Kind.PALM: _draw_palm()
		Kind.OASIS: _draw_oasis()
		Kind.WAGON_WRECK: _draw_wagon_wreck()
		Kind.CAIRN: _draw_cairn()
		Kind.LOOKOUT: _draw_lookout()
		Kind.SKULL_POLE: _draw_skull_pole()
		Kind.YURT: _draw_yurt()
		Kind.IGLOO: _draw_igloo()
		Kind.BRAZIER: _draw_brazier()
		Kind.DRYING_RACK: _draw_drying_rack()
		Kind.FISHING_HOLE: _draw_fishing_hole()
		Kind.SLED: _draw_sled()
		Kind.TOTEM: _draw_totem()
		Kind.ICE_BACK: _draw_ice(false)
		Kind.ICE_FRONT: _draw_ice(true)
		Kind.ARMY_TENT: _draw_army_tent()
		Kind.PALISADE: _draw_palisade()
		Kind.PALISADE_POST: _draw_palisade_post()
		Kind.WATCHTOWER: _draw_watchtower()
		Kind.BARRICADE: _draw_barricade()
		Kind.COT: _draw_cot()
		Kind.WEAPON_RACK: _draw_weapon_rack()
		Kind.DEBRIS: _draw_debris()
		Kind.FORGE: _draw_forge()
		Kind.GRAVE: _draw_grave()


# --- Shared pieces -------------------------------------------------------------------------------------

func _flame(base: Vector2, width: float, flame_height: float, seed_phase := 0.0) -> void:
	var t := time + phase + seed_phase
	var sway := sin(t * 9.0) * width * 0.18 + sin(t * 5.3) * width * 0.12
	var stretch := 1.0 + 0.12 * sin(t * 11.0)
	var h := flame_height * stretch
	draw_colored_polygon(PackedVector2Array([
		base + Vector2(-width, 0), base + Vector2(-width * 0.75, -h * 0.4), base + Vector2(-width * 0.2 + sway * 0.5, -h * 0.7),
		base + Vector2(sway, -h), base + Vector2(width * 0.35 + sway * 0.5, -h * 0.62), base + Vector2(width * 0.8, -h * 0.35),
		base + Vector2(width, 0),
	]), Color(FLAME, 0.92))
	draw_colored_polygon(PackedVector2Array([
		base + Vector2(-width * 0.55, 0), base + Vector2(-width * 0.2, -h * 0.45), base + Vector2(sway * 0.6, -h * 0.68),
		base + Vector2(width * 0.3, -h * 0.4), base + Vector2(width * 0.55, 0),
	]), FLAME_CORE)


func _log(from: Vector2, to: Vector2, thickness: float, color: Color) -> void:
	draw_line(from, to, OUTLINE, thickness + 2.0, true)
	draw_line(from, to, color, thickness, true)
	var along := (to - from).normalized()
	var side := Vector2(-along.y, along.x) * thickness * 0.22
	draw_line(from + side, to + side, Color(color.lightened(0.3), 0.6), thickness * 0.3, true)


func _stone(center: Vector2, radius: float, color := STONE) -> void:
	SmoothDraw.dome(self, center, radius, color, OUTLINE)


## A soft ellipse, for pools, holes and rugs seen from above.
func _ellipse(center: Vector2, size: Vector2, color: Color, steps := 32) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in steps:
		var angle := TAU * index / steps
		points.append(center + Vector2(cos(angle) * size.x, sin(angle) * size.y))
	draw_colored_polygon(points, color)
	return points


func _scorch(rect: Rect2, count: int) -> void:
	for index in count:
		var spot := rect.position + Vector2(random.randf() * rect.size.x, random.randf() * rect.size.y)
		SmoothDraw.disc(self, spot, random.randf_range(3.0, 7.0), Color(CHAR, 0.55))


func _rope(from: Vector2, to: Vector2) -> void:
	draw_line(from, to, Color(0.3, 0.22, 0.14, 0.8), 1.0, true)
	SmoothDraw.box(self, Rect2(to.x - 1.0, to.y - 4.0, 2.0, 4.0), WOOD_DARK, 0.5)


# --- Saltwind Camp -------------------------------------------------------------------------------------

## A long, low nomad tent: a striped canopy sagging between its poles over an open front.
func _draw_tent() -> void:
	SmoothDraw.shadow(self, Vector2(-6, 2), Vector2(120, 20), 0.3)
	var wall := tint.darkened(0.25)
	SmoothDraw.polygon(self, PackedVector2Array([Vector2(-44, 0), Vector2(-44, -28), Vector2(44, -28), Vector2(44, 0)]), wall, OUTLINE, 1.5)
	# The open front: shade inside, a rug and cushions.
	draw_colored_polygon(PackedVector2Array([Vector2(-18, 0), Vector2(-16, -26), Vector2(16, -26), Vector2(18, 0)]), Color("#2a1810"))
	SmoothDraw.flat(self, Rect2(-15, -7, 30, 7), alt.darkened(0.1), 2.0)
	draw_line(Vector2(-13, -4), Vector2(13, -4), Color(tint, 0.8), 1.0, true)
	SmoothDraw.dome(self, Vector2(-8, -9), 3.5, alt)
	# Canopy, peaked at each pole.
	var canopy := PackedVector2Array([
		Vector2(-50, -26), Vector2(-24, -46), Vector2(0, -39), Vector2(24, -46), Vector2(50, -26), Vector2(0, -24),
	])
	SmoothDraw.polygon(self, canopy, tint, OUTLINE, 1.5)
	for band: float in [0.35, 0.7]:
		draw_polyline(PackedVector2Array([
			Vector2(-50 + band * 8.0, -26 - band * 6.0), Vector2(-24, -46 + band * 14.0), Vector2(0, -39 + band * 10.0),
			Vector2(24, -46 + band * 14.0), Vector2(50 - band * 8.0, -26 - band * 6.0),
		]), alt, 2.2, true)
	for pole_x: float in [-24.0, 24.0]:
		draw_line(Vector2(pole_x, -24), Vector2(pole_x, -50), WOOD_DARK, 2.0, true)
		_rope(Vector2(pole_x, -46), Vector2(pole_x * 2.5, 4))
	# Flaps tied back either side of the opening.
	for side: float in [-1.0, 1.0]:
		SmoothDraw.polygon(self, PackedVector2Array([Vector2(side * 16, -26), Vector2(side * 24, -26), Vector2(side * 20, -4)]), tint.lightened(0.1), OUTLINE, 1.0)


## A trader's stall: a table of wares under a striped, scalloped awning.
func _draw_stall() -> void:
	SmoothDraw.shadow(self, Vector2(-4, 2), Vector2(100, 16), 0.3)
	for post_x: float in [-38.0, 38.0]:
		SmoothDraw.box(self, Rect2(post_x - 2, -58, 4, 58), WOOD_DARK, 1.5)
	SmoothDraw.box(self, Rect2(-40, -22, 80, 6), WOOD_LIGHT, 2.0)
	SmoothDraw.box(self, Rect2(-38, -16, 76, 16), WOOD, 2.0)
	draw_line(Vector2(-36, -8), Vector2(36, -8), Color(WOOD_DARK, 0.6), 1.0, true)
	# Wares: bolts of cloth, pots, a basket of dates, a lamp.
	SmoothDraw.box(self, Rect2(-34, -30, 14, 8), Color("#3f6fa3"), 3.0)
	SmoothDraw.box(self, Rect2(-30, -36, 12, 7), Color("#c9a13f"), 3.0)
	for index in 3:
		SmoothDraw.dome(self, Vector2(-8 + index * 8, -26), 4.0, CLAY.lightened(index * 0.1))
	SmoothDraw.box(self, Rect2(16, -29, 14, 7), Color("#7a5530"), 2.0)
	for index in 4:
		SmoothDraw.disc(self, Vector2(18 + index * 3, -30), 1.8, Color("#5a2e1a"))
	# Awning.
	var stripes := 8
	for index in stripes:
		var x0 := -46.0 + 92.0 * index / stripes
		var x1 := -46.0 + 92.0 * (index + 1) / stripes
		draw_colored_polygon(PackedVector2Array([
			Vector2(x0 * 0.9, -62), Vector2(x1 * 0.9, -62), Vector2(x1, -50), Vector2(x0, -50),
		]), tint if index % 2 == 0 else alt)
		SmoothDraw.disc(self, Vector2((x0 + x1) * 0.5, -50), (x1 - x0) * 0.5, tint if index % 2 == 0 else alt)
	draw_polyline(PackedVector2Array([Vector2(-41.4, -62), Vector2(41.4, -62), Vector2(46, -50)]), OUTLINE, 1.2, true)
	draw_line(Vector2(-41.4, -62), Vector2(-46, -50), OUTLINE, 1.2, true)


func _draw_campfire() -> void:
	SmoothDraw.shadow(self, Vector2(0, 0), Vector2(40, 12), 0.25)
	draw_set_transform(Vector2(0, -3), 0.0, Vector2(1.0, 0.42))
	SmoothDraw.disc(self, Vector2.ZERO, 13.0, Color("#2a1d16"))
	SmoothDraw.disc(self, Vector2.ZERO, 9.0, Color("#ff8a3a", 0.5))
	draw_set_transform(Vector2.ZERO)
	for index in 9:
		var angle := TAU * index / 9.0
		_stone(Vector2(cos(angle) * 16.0, -3.0 + sin(angle) * 6.5), 3.6, STONE.darkened(0.1 if index % 2 else 0.0))
	_log(Vector2(-10, -2), Vector2(9, -8), 4.0, WOOD_DARK)
	_log(Vector2(10, -2), Vector2(-8, -9), 4.0, WOOD)
	_flame(Vector2(0, -5), 8.0, 20.0)
	_flame(Vector2(-4, -5), 4.0, 11.0, 1.7)
	if variant == 1:
		# A pot hung on a tripod over the flames.
		for leg: Vector2 in [Vector2(-14, 0), Vector2(14, 0), Vector2(2, -6)]:
			draw_line(leg, Vector2(0, -32), WOOD_DARK, 2.0, true)
		draw_line(Vector2(0, -32), Vector2(0, -22), IRON, 1.0, true)
		SmoothDraw.polygon(self, PackedVector2Array([Vector2(-7, -22), Vector2(7, -22), Vector2(5, -14), Vector2(-5, -14)]), IRON, OUTLINE, 1.2)


func _draw_jars() -> void:
	SmoothDraw.shadow(self, Vector2(-2, 1), Vector2(40, 9), 0.3)
	var spots := [Vector2(-10, 0), Vector2(9, 0), Vector2(0, 3)]
	var sizes := [1.0, 0.8, 0.65]
	for index in spots.size():
		var base: Vector2 = spots[index]
		var s: float = sizes[index]
		var color := CLAY.darkened(index * 0.08)
		SmoothDraw.polygon(self, PackedVector2Array([
			base + Vector2(-4, 0) * s, base + Vector2(-9, -8) * s, base + Vector2(-8, -16) * s, base + Vector2(-3.5, -20) * s,
			base + Vector2(-4, -24) * s, base + Vector2(4, -24) * s, base + Vector2(3.5, -20) * s, base + Vector2(8, -16) * s,
			base + Vector2(9, -8) * s, base + Vector2(4, 0) * s,
		]), color, OUTLINE, 1.2)
		draw_line(base + Vector2(-8, -12) * s, base + Vector2(8, -12) * s, Color(alt, 0.7), 1.5, true)
		SmoothDraw.disc(self, base + Vector2(-4, -15) * s, 2.0 * s, Color(color.lightened(0.4), 0.6))


func _draw_rug() -> void:
	var w := length if length > 0.0 else 60.0
	var h := w * 0.45
	var rect := Rect2(-w * 0.5, -h * 0.5, w, h)
	SmoothDraw.flat(self, rect.grow(1.5), Color(OUTLINE, 0.6), 3.0)
	SmoothDraw.flat(self, rect, tint, 3.0)
	SmoothDraw.flat(self, rect.grow(-4.0), alt, 2.0)
	SmoothDraw.flat(self, rect.grow(-7.0), tint.darkened(0.2), 2.0)
	for index in 3:
		var c := Vector2(-w * 0.25 + index * w * 0.25, 0)
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, -h * 0.22), c + Vector2(w * 0.08, 0), c + Vector2(0, h * 0.22), c + Vector2(-w * 0.08, 0)]), alt)
	for side: float in [-1.0, 1.0]:
		for index in 6:
			var y := -h * 0.4 + index * h * 0.16
			draw_line(Vector2(side * w * 0.5, y), Vector2(side * (w * 0.5 + 4.0), y), alt.darkened(0.2), 1.0, true)


func _draw_banner() -> void:
	var pole_height := height if height > 0.0 else 72.0
	SmoothDraw.shadow(self, Vector2(-2, 1), Vector2(14, 5), 0.3)
	SmoothDraw.box(self, Rect2(-1.5, -pole_height, 3, pole_height), WOOD_DARK, 1.5)
	SmoothDraw.dome(self, Vector2(0, -pole_height - 2), 2.5, alt)
	var points := PackedVector2Array()
	var top := -pole_height + 4.0
	var flag_length := 30.0
	var drop := 14.0
	var steps := 8
	for index in steps + 1:
		var u := float(index) / steps
		var wave := sin(time * 3.2 + phase - u * 4.0) * 2.5 * u
		points.append(Vector2(2 + u * flag_length, top + wave + u * 2.0))
	for index in range(steps, -1, -1):
		var u := float(index) / steps
		var wave := sin(time * 3.2 + phase - u * 4.0) * 2.5 * u
		var bottom := top + drop - u * 6.0
		if variant == 1:
			# Torn and singed.
			bottom -= (2.0 + 3.0 * sin(u * 23.0)) * u
		points.append(Vector2(2 + u * flag_length, bottom + wave))
	SmoothDraw.polygon(self, points, tint, OUTLINE, 1.2)
	var stripe := PackedVector2Array()
	for index in steps + 1:
		var u := float(index) / steps
		var wave := sin(time * 3.2 + phase - u * 4.0) * 2.5 * u
		stripe.append(Vector2(2 + u * flag_length, top + drop * 0.45 + wave - u * 2.0))
	draw_polyline(stripe, alt, 2.0, true)


func _draw_palm() -> void:
	var trunk_height := height if height > 0.0 else 84.0
	SmoothDraw.shadow(self, Vector2(-14, 2), Vector2(60, 14), 0.25)
	var sway := sin(time * 0.9 + phase) * 1.5
	var lean := 14.0 * (1.0 if variant % 2 == 0 else -1.0)
	var crown := Vector2(lean + sway, -trunk_height)
	var segments := 9
	var previous := Vector2.ZERO
	for index in range(1, segments + 1):
		var u := float(index) / segments
		var point := Vector2(lean * u * u + sway * u, -trunk_height * u)
		var width := lerpf(6.5, 4.0, u)
		draw_line(previous, point, OUTLINE, width + 2.0, true)
		draw_line(previous, point, Color("#8a6a45"), width, true)
		draw_line(previous + Vector2(-width * 0.25, 0), point + Vector2(-width * 0.25, 0), Color("#a98457"), width * 0.35, true)
		draw_line(point + Vector2(-width * 0.5, 0), point + Vector2(width * 0.5, 1.5), Color("#5e4429"), 1.0, true)
		previous = point
	# Fronds arching out of the crown and drooping, back ones darker.
	for layer in 2:
		var color := LEAF.darkened(0.25) if layer == 0 else LEAF
		for index in 6:
			var angle := -PI + PI * (index + 0.5 * layer) / 5.5 + sin(time * 1.3 + phase + index) * 0.04
			var reach := 32.0 - layer * 4.0
			var direction := Vector2(cos(angle), sin(angle) * 0.45)
			var spine := PackedVector2Array()
			for step in 7:
				var u := step / 6.0
				# Rises out of the crown, then falls away under its own weight.
				spine.append(crown + direction * reach * u + Vector2(0.0, -10.0 * u + 26.0 * u * u))
			# A tapering leaf: widest a third of the way out, drawn as overlapping strokes.
			for pass_index in 2:
				for step in spine.size() - 1:
					var u := (step + 0.5) / 6.0
					var width := 8.0 * sin(PI * clampf(u * 0.9 + 0.1, 0.0, 1.0)) + 1.0
					draw_line(spine[step], spine[step + 1], OUTLINE if pass_index == 0 else color, width + (2.0 if pass_index == 0 else 0.0), true)
			draw_polyline(spine, Color(color.darkened(0.35), 0.8), 1.0, true)
	for index in 3:
		SmoothDraw.dome(self, crown + Vector2(-4 + index * 4, 3), 2.6, Color("#6b4a22"))


func _draw_oasis() -> void:
	var r := length if length > 0.0 else 90.0
	_ellipse(Vector2.ZERO, Vector2(r + 10.0, (r + 10.0) * 0.45), Color("#c9a35c"))
	_ellipse(Vector2.ZERO, Vector2(r + 3.0, (r + 3.0) * 0.45), Color("#6f8a4a", 0.8))
	_ellipse(Vector2.ZERO, Vector2(r, r * 0.45), WATER.lightened(0.1))
	_ellipse(Vector2(-r * 0.05, -r * 0.03), Vector2(r * 0.85, r * 0.36), WATER.lightened(0.25))
	_ellipse(Vector2(-r * 0.3, -r * 0.12), Vector2(r * 0.3, r * 0.07), Color(1, 1, 1, 0.18))
	# Slow rings spreading across the water.
	for index in 2:
		var t := fmod(time * 0.35 + index * 0.5 + phase, 1.0)
		var c := Vector2(r * (0.3 - index * 0.5), r * 0.05)
		var ring := PackedVector2Array()
		for step in 25:
			var angle := TAU * step / 24.0
			ring.append(c + Vector2(cos(angle) * 6.0, sin(angle) * 2.6) * (1.0 + t * 3.0))
		draw_polyline(ring, Color(1, 1, 1, 0.35 * (1.0 - t)), 1.0, true)
	# Reeds along the bank.
	for index in 14:
		var angle := random.randf_range(0.15, PI - 0.15) * (1.0 if index % 3 else -1.0)
		var base := Vector2(cos(angle) * (r + 2.0), sin(angle) * (r + 2.0) * 0.45)
		for blade in 3:
			var tip := base + Vector2((blade - 1) * 2.5 + sin(time * 1.2 + index) * 0.8, -9.0 - blade * 2.0)
			draw_line(base, tip, LEAF.darkened(0.1 * blade), 1.2, true)


func _draw_wagon_wreck() -> void:
	SmoothDraw.shadow(self, Vector2(-4, 2), Vector2(90, 18), 0.3)
	# The wheel that came off, lying in the sand.
	draw_set_transform(Vector2(30, -2), 0.0, Vector2(1.0, 0.45))
	draw_arc(Vector2.ZERO, 12.0, 0, TAU, 32, OUTLINE, 4.0, true)
	draw_arc(Vector2.ZERO, 12.0, 0, TAU, 32, WOOD, 2.5, true)
	for index in 4:
		var angle := PI * index / 4.0 + 0.3
		draw_line(Vector2(cos(angle), sin(angle)) * 11.0, -Vector2(cos(angle), sin(angle)) * 11.0, WOOD_DARK, 1.5, true)
	draw_set_transform(Vector2.ZERO)
	# The bed, tipped onto its broken axle.
	draw_set_transform(Vector2(-6, -10), -0.16, Vector2.ONE)
	SmoothDraw.box(self, Rect2(-30, -14, 54, 16), WOOD, 2.0)
	for index in 3:
		draw_line(Vector2(-28 + index * 18, -13), Vector2(-28 + index * 18, 1), Color(WOOD_DARK, 0.7), 1.0, true)
	SmoothDraw.polygon(self, PackedVector2Array([Vector2(-28, -14), Vector2(-20, -30), Vector2(10, -32), Vector2(22, -14)]), CANVAS.darkened(0.1), OUTLINE, 1.2)
	draw_line(Vector2(-16, -27), Vector2(-4, -15), Color(CHAR, 0.6), 1.5, true)
	draw_set_transform(Vector2.ZERO)
	var wheel := Vector2(-26, -6)
	draw_arc(wheel, 9.0, 0, TAU, 28, OUTLINE, 4.0, true)
	draw_arc(wheel, 9.0, 0, TAU, 28, WOOD_DARK, 2.5, true)
	for index in 3:
		var angle := PI * index / 3.0
		draw_line(wheel + Vector2(cos(angle), sin(angle)) * 8.0, wheel - Vector2(cos(angle), sin(angle)) * 8.0, WOOD_DARK, 1.5, true)
	# Spilled sacks and a split crate.
	SmoothDraw.box(self, Rect2(4, -9, 12, 9), Color("#cdb88f"), 4.0)
	SmoothDraw.box(self, Rect2(-46, -7, 11, 7), Color("#cdb88f"), 3.5)
	_log(Vector2(10, 2), Vector2(24, -3), 2.5, WOOD_LIGHT)


func _draw_cairn() -> void:
	SmoothDraw.shadow(self, Vector2(-2, 1), Vector2(30, 8), 0.3)
	_stone(Vector2(-6, -4), 6.0)
	_stone(Vector2(6, -4), 5.5, STONE.darkened(0.08))
	_stone(Vector2(0, -12), 5.0, STONE.lightened(0.05))
	_stone(Vector2(1, -19), 3.6)
	# A marker stick with a strip of cloth stirring in the wind.
	draw_line(Vector2(8, -6), Vector2(10, -32), WOOD_DARK, 1.6, true)
	var flutter := sin(time * 3.0 + phase) * 2.0
	draw_colored_polygon(PackedVector2Array([Vector2(10, -31), Vector2(20, -29 + flutter), Vector2(10, -26)]), tint)


## A raised wooden platform for the camp's scout to watch the dunes from.
func _draw_lookout() -> void:
	SmoothDraw.shadow(self, Vector2(-6, 2), Vector2(56, 14), 0.3)
	for leg_x: float in [-18.0, 18.0]:
		SmoothDraw.box(self, Rect2(leg_x - 2.5, -66, 5, 66), WOOD_DARK, 1.5)
	_log(Vector2(-17, -8), Vector2(17, -44), 2.0, WOOD)
	_log(Vector2(17, -8), Vector2(-17, -44), 2.0, WOOD)
	SmoothDraw.box(self, Rect2(-24, -70, 48, 7), WOOD_LIGHT, 2.0)
	for rail_x: float in [-22.0, -7.0, 8.0, 21.0]:
		draw_line(Vector2(rail_x, -70), Vector2(rail_x, -82), WOOD_DARK, 2.0, true)
	draw_line(Vector2(-23, -81), Vector2(22, -81), WOOD, 2.0, true)
	# A sun shade over it.
	SmoothDraw.polygon(self, PackedVector2Array([Vector2(-28, -96), Vector2(28, -96), Vector2(24, -88), Vector2(-24, -88)]), tint, OUTLINE, 1.2)
	for pole_x: float in [-22.0, 21.0]:
		draw_line(Vector2(pole_x, -82), Vector2(pole_x, -90), WOOD_DARK, 1.6, true)


func _draw_skull_pole() -> void:
	SmoothDraw.shadow(self, Vector2(-2, 1), Vector2(14, 5), 0.3)
	SmoothDraw.box(self, Rect2(-1.5, -52, 3, 52), WOOD_DARK, 1.5)
	# A sun-bleached horned skull: a warning to whatever comes out of the dunes.
	for side: float in [-1.0, 1.0]:
		draw_polyline(PackedVector2Array([Vector2(side * 5, -56), Vector2(side * 13, -60), Vector2(side * 17, -68)]), OUTLINE, 4.0, true)
		draw_polyline(PackedVector2Array([Vector2(side * 5, -56), Vector2(side * 13, -60), Vector2(side * 17, -68)]), BONE.darkened(0.1), 2.4, true)
	SmoothDraw.polygon(self, PackedVector2Array([Vector2(-7, -60), Vector2(7, -60), Vector2(5, -50), Vector2(2.5, -44), Vector2(-2.5, -44), Vector2(-5, -50)]), BONE, OUTLINE, 1.2)
	for side: float in [-1.0, 1.0]:
		SmoothDraw.disc(self, Vector2(side * 3, -55), 1.6, OUTLINE)
	for index in 3:
		draw_line(Vector2(-4 + index * 4, -38), Vector2(-4 + index * 4, -30), alt, 1.5, true)


# --- Rimehollow ----------------------------------------------------------------------------------------

func _draw_yurt() -> void:
	SmoothDraw.shadow(self, Vector2(-4, 2), Vector2(96, 20), 0.3)
	var w := 38.0
	var wall_top := -22.0
	SmoothDraw.box(self, Rect2(-w, wall_top, w * 2, -wall_top), tint.darkened(0.12), 4.0)
	var roof := PackedVector2Array()
	for index in 17:
		var u := float(index) / 16.0
		roof.append(Vector2(lerpf(-w - 3, w + 3, u), wall_top + 1 - sin(u * PI) * 26.0))
	SmoothDraw.polygon(self, roof, tint, OUTLINE, 1.5)
	# Seams in the hides, a band lashed round them and snow lying on the roof.
	for index in 5:
		var x := -w + 8.0 + index * (w * 2 - 16.0) / 4.0
		draw_line(Vector2(x, wall_top), Vector2(x * 0.5, wall_top - 22.0 + absf(x) * 0.25), Color(tint.darkened(0.35), 0.6), 1.0, true)
	draw_line(Vector2(-w, -10), Vector2(w, -10), alt, 2.0, true)
	var snow := PackedVector2Array()
	for index in 11:
		var u := float(index) / 10.0
		snow.append(Vector2(lerpf(-w * 0.75, w * 0.75, u), wall_top - 4 - sin(lerpf(0.15, 0.85, u) * PI) * 26.0))
	for index in range(10, -1, -1):
		var u := float(index) / 10.0
		snow.append(Vector2(lerpf(-w * 0.6, w * 0.6, u), wall_top + 2 - sin(lerpf(0.2, 0.8, u) * PI) * 20.0 + sin(u * 17.0) * 1.5))
	draw_colored_polygon(snow, SNOW)
	# Poles out of the smoke hole.
	for pole: float in [-5.0, 0.0, 5.0]:
		draw_line(Vector2(pole * 0.6, wall_top - 24.0), Vector2(pole * 1.4, wall_top - 34.0), WOOD_DARK, 1.6, true)
	# A doorway hung with a fur.
	SmoothDraw.box(self, Rect2(-9, -20, 18, 20), Color("#2a1e18"), 3.0)
	SmoothDraw.polygon(self, PackedVector2Array([Vector2(-9, -20), Vector2(9, -20), Vector2(9, -6), Vector2(2, -2), Vector2(-9, -9)]), FUR.darkened(0.15), OUTLINE, 1.0)


func _draw_igloo() -> void:
	SmoothDraw.shadow(self, Vector2(-4, 2), Vector2(86, 18), 0.25)
	var w := 36.0
	var h := 34.0
	var dome := PackedVector2Array()
	for index in 21:
		var u := float(index) / 20.0
		dome.append(Vector2(lerpf(-w, w, u), -sin(u * PI) * h))
	SmoothDraw.polygon(self, dome, Color("#dcecf6"), Color("#4c6a86"), 1.5)
	# Courses of snow blocks, staggered.
	for row in 3:
		var y := -8.0 - row * 9.0
		var half := w * sqrt(maxf(1.0 - pow(-y / h, 2.0), 0.0))
		draw_line(Vector2(-half + 1, y), Vector2(half - 1, y), Color("#9dbad1"), 1.0, true)
		var count := 6 - row
		for index in count:
			var x := -half + (index + (0.5 if row % 2 else 0.0)) * half * 2.0 / count
			draw_line(Vector2(x, y), Vector2(x, y + 9.0), Color("#9dbad1"), 1.0, true)
	SmoothDraw.disc(self, Vector2(-12, -26), 7.0, Color(1, 1, 1, 0.35))
	# Entrance tunnel.
	var tunnel := PackedVector2Array()
	for index in 13:
		var u := float(index) / 12.0
		tunnel.append(Vector2(lerpf(-12, 12, u) + 6.0, 2.0 - sin(u * PI) * 16.0))
	SmoothDraw.polygon(self, tunnel, Color("#e6f1f8"), Color("#4c6a86"), 1.2)
	var door := PackedVector2Array()
	for index in 11:
		var u := float(index) / 10.0
		door.append(Vector2(lerpf(-6, 6, u) + 6.0, 2.0 - sin(u * PI) * 10.0))
	draw_colored_polygon(door, Color("#1d2a38"))


func _draw_brazier() -> void:
	SmoothDraw.shadow(self, Vector2(-2, 1), Vector2(26, 7), 0.3)
	for leg: float in [-9.0, 9.0, 0.0]:
		draw_line(Vector2(leg, 0), Vector2(leg * 0.4, -22), IRON, 2.2, true)
	SmoothDraw.polygon(self, PackedVector2Array([Vector2(-13, -30), Vector2(13, -30), Vector2(8, -21), Vector2(-8, -21)]), IRON, OUTLINE, 1.2)
	draw_line(Vector2(-12, -28), Vector2(12, -28), Color(1.0, 0.55, 0.2, 0.8), 1.5, true)
	_flame(Vector2(0, -30), 9.0, 18.0)
	_flame(Vector2(4, -30), 4.0, 10.0, 2.1)


func _draw_drying_rack() -> void:
	SmoothDraw.shadow(self, Vector2(-3, 1), Vector2(64, 10), 0.3)
	for post_x: float in [-26.0, 26.0]:
		_log(Vector2(post_x, 0), Vector2(post_x, -56), 3.5, WOOD_DARK)
	_log(Vector2(-30, -52), Vector2(30, -54), 3.0, WOOD)
	if variant == 1:
		# Fish strung up to freeze-dry.
		for index in 6:
			var x := -20.0 + index * 8.0
			draw_line(Vector2(x, -52), Vector2(x, -46), Color(0.3, 0.22, 0.14), 1.0, true)
			SmoothDraw.polygon(self, PackedVector2Array([Vector2(x - 2, -46), Vector2(x + 2, -46), Vector2(x + 1.5, -32), Vector2(x, -29), Vector2(x - 1.5, -32)]), Color("#8fa6b8"), OUTLINE, 1.0)
		return
	# A great white pelt stretched on the frame: the camp's trophy from the yetis.
	var pelt := PackedVector2Array()
	var steps := 14
	for index in steps + 1:
		var u := float(index) / steps
		pelt.append(Vector2(lerpf(-22, 22, u), -51 + sin(u * 31.0) * 1.2))
	for index in range(steps, -1, -1):
		var u := float(index) / steps
		var ragged := 3.0 * sin(u * 23.0 + 1.0) + 2.0 * sin(u * 41.0)
		pelt.append(Vector2(lerpf(-20, 20, u) * (1.0 - 0.15 * sin(u * PI)), -14 + ragged - sin(u * PI) * 3.0))
	SmoothDraw.polygon(self, pelt, tint, Color("#5f6f80"), 1.4)
	for index in 7:
		var x := -16.0 + index * 5.5
		draw_line(Vector2(x, -46), Vector2(x + 1.5, -24), Color(tint.darkened(0.15), 0.7), 1.0, true)
	for side: float in [-1.0, 1.0]:
		SmoothDraw.dome(self, Vector2(side * 21, -18), 3.0, tint.darkened(0.08))


func _draw_fishing_hole() -> void:
	_ellipse(Vector2.ZERO, Vector2(20, 8.5), Color("#cfe6f3"))
	_ellipse(Vector2.ZERO, Vector2(16, 6.5), Color("#16324a"))
	_ellipse(Vector2(-3, -1), Vector2(10, 3.5), Color("#22486a"))
	var t := fmod(time * 0.5 + phase, 1.0)
	var ring := PackedVector2Array()
	for step in 25:
		var angle := TAU * step / 24.0
		ring.append(Vector2(cos(angle) * 3.0, sin(angle) * 1.2) * (1.0 + t * 3.0) + Vector2(4, 0))
	draw_polyline(ring, Color(1, 1, 1, 0.4 * (1.0 - t)), 1.0, true)
	# Chunks of ice cut out of it, stacked by the edge.
	for spot: Vector2 in [Vector2(-24, 2), Vector2(22, -4)]:
		SmoothDraw.box(self, Rect2(spot.x - 4, spot.y - 5, 8, 6), ICE.lightened(0.3), 1.5, Color("#4c6a86"))


func _draw_sled() -> void:
	SmoothDraw.shadow(self, Vector2(-3, 1), Vector2(60, 10), 0.3)
	draw_polyline(PackedVector2Array([Vector2(-26, 0), Vector2(22, 0), Vector2(28, -4), Vector2(29, -9)]), OUTLINE, 3.0, true)
	draw_polyline(PackedVector2Array([Vector2(-26, 0), Vector2(22, 0), Vector2(28, -4), Vector2(29, -9)]), WOOD_LIGHT, 1.8, true)
	for x: float in [-18.0, 0.0, 16.0]:
		draw_line(Vector2(x, 0), Vector2(x, -6), WOOD_DARK, 2.0, true)
	SmoothDraw.box(self, Rect2(-26, -10, 48, 5), WOOD, 1.5)
	SmoothDraw.box(self, Rect2(-22, -20, 18, 10), Color("#8c6a4a"), 4.0)
	SmoothDraw.box(self, Rect2(-4, -18, 14, 8), FUR, 3.5)
	draw_line(Vector2(-24, -14), Vector2(12, -16), Color(0.3, 0.22, 0.14), 1.0, true)


## A carved post, crowned with a shard of glowing ice.
func _draw_totem() -> void:
	SmoothDraw.shadow(self, Vector2(-2, 1), Vector2(22, 7), 0.3)
	SmoothDraw.box(self, Rect2(-7, -52, 14, 52), WOOD_DARK, 3.0)
	for index in 3:
		var y := -46.0 + index * 16.0
		SmoothDraw.box(self, Rect2(-8, y, 16, 12), WOOD.darkened(index * 0.08), 3.0)
		for side: float in [-1.0, 1.0]:
			SmoothDraw.disc(self, Vector2(side * 3.0, y + 4.0), 1.5, Color("#c9e9f7") if index == 0 else OUTLINE)
		draw_line(Vector2(-3, y + 8.5), Vector2(3, y + 8.5), OUTLINE, 1.2, true)
	var glow := 0.75 + 0.25 * sin(time * 2.0 + phase)
	SmoothDraw.polygon(self, PackedVector2Array([Vector2(-5, -52), Vector2(0, -74), Vector2(5, -52)]), Color("#9fe3ff") * Color(1, 1, 1, glow), Color("#3b6c8c"), 1.2)
	draw_line(Vector2(-1, -56), Vector2(0, -70), Color(1, 1, 1, 0.7 * glow), 1.0, true)


## A block of clear ice, drawn in two halves so a frozen creature can sit between them.
func _draw_ice(front: bool) -> void:
	var w := length if length > 0.0 else 140.0
	var h := height if height > 0.0 else 120.0
	var depth := 18.0
	var face := Rect2(-w * 0.5, -h, w, h - depth * 0.3)
	if not front:
		SmoothDraw.shadow(self, Vector2(-8, 2), Vector2(w * 1.25, 30), 0.35)
		# Top face and the back wall, seen through the front.
		draw_colored_polygon(PackedVector2Array([
			face.position, face.position + Vector2(depth, -depth * 0.6),
			Vector2(face.end.x + depth, face.position.y - depth * 0.6), Vector2(face.end.x, face.position.y),
		]), Color("#d8f1ff"))
		draw_colored_polygon(PackedVector2Array([
			Vector2(face.end.x, face.position.y), Vector2(face.end.x + depth, face.position.y - depth * 0.6),
			Vector2(face.end.x + depth, face.end.y - depth * 0.6), face.end,
		]), Color("#7fb6d6"))
		SmoothDraw.flat(self, face, Color(0.55, 0.78, 0.92, 0.55), 6.0)
		return
	SmoothDraw.flat(self, face, Color(0.75, 0.9, 1.0, 0.28), 6.0)
	draw_polyline(PackedVector2Array([face.position, Vector2(face.end.x, face.position.y), face.end, Vector2(face.position.x, face.end.y), face.position]), Color("#4c7c9e"), 2.0, true)
	draw_line(face.position, face.position + Vector2(depth, -depth * 0.6), Color("#4c7c9e"), 1.5, true)
	draw_line(Vector2(face.end.x, face.position.y), Vector2(face.end.x + depth, face.position.y - depth * 0.6), Color("#4c7c9e"), 1.5, true)
	draw_line(Vector2(face.end.x + depth, face.position.y - depth * 0.6), Vector2(face.end.x + depth, face.end.y - depth * 0.6), Color("#4c7c9e"), 1.5, true)
	draw_line(face.end, Vector2(face.end.x + depth, face.end.y - depth * 0.6), Color("#4c7c9e"), 1.5, true)
	# Glints and fractures in the glass.
	draw_colored_polygon(PackedVector2Array([face.position + Vector2(8, 6), face.position + Vector2(30, 6), face.position + Vector2(10, h * 0.55)]), Color(1, 1, 1, 0.25))
	draw_line(face.position + Vector2(w * 0.7, 10), face.position + Vector2(w * 0.85, h * 0.45), Color(1, 1, 1, 0.45), 1.5, true)
	draw_polyline(PackedVector2Array([face.position + Vector2(w * 0.2, h * 0.7), face.position + Vector2(w * 0.32, h * 0.6), face.position + Vector2(w * 0.3, h * 0.5), face.position + Vector2(w * 0.42, h * 0.42)]), Color(1, 1, 1, 0.4), 1.0, true)
	# Snow banked against the foot of it.
	var bank := PackedVector2Array()
	for index in 13:
		var u := float(index) / 12.0
		bank.append(Vector2(lerpf(-w * 0.58, w * 0.58 + depth, u), face.end.y + 2.0 - sin(u * PI) * 10.0 - sin(u * 19.0) * 2.0))
	bank.append(Vector2(w * 0.58 + depth, face.end.y + 4.0))
	bank.append(Vector2(-w * 0.58, face.end.y + 4.0))
	draw_colored_polygon(bank, SNOW)


# --- Ashgate Outpost -----------------------------------------------------------------------------------

func _draw_army_tent() -> void:
	SmoothDraw.shadow(self, Vector2(6, 2), Vector2(100, 18), 0.3)
	var canvas := tint.darkened(0.3) if burning or broken else tint
	if broken:
		# Collapsed: the ridge pole snapped and the canvas slumped and torn.
		_log(Vector2(-14, -2), Vector2(4, -40), 2.5, WOOD_DARK)
		_log(Vector2(4, -40), Vector2(18, -50), 2.5, WOOD_DARK)
		SmoothDraw.polygon(self, PackedVector2Array([
			Vector2(-38, 0), Vector2(-30, -12), Vector2(-14, -22), Vector2(2, -34), Vector2(12, -22), Vector2(30, -18),
			Vector2(50, -10), Vector2(64, -2), Vector2(40, 2),
		]), canvas, OUTLINE, 1.5)
		draw_polyline(PackedVector2Array([Vector2(-22, -6), Vector2(-8, -18), Vector2(2, -30)]), Color(canvas.darkened(0.3), 0.8), 1.5, true)
		draw_polyline(PackedVector2Array([Vector2(8, -6), Vector2(14, -18), Vector2(28, -14)]), Color(canvas.darkened(0.3), 0.8), 1.5, true)
		_scorch(Rect2(-24, -24, 74, 20), 7)
		draw_colored_polygon(PackedVector2Array([Vector2(18, -14), Vector2(30, -15), Vector2(26, -6)]), Color("#1d1512"))
		return
	# The side of the roof, running back and to the right.
	SmoothDraw.polygon(self, PackedVector2Array([Vector2(0, -48), Vector2(34, -54), Vector2(66, -6), Vector2(32, 0)]), canvas.darkened(0.12), OUTLINE, 1.5)
	SmoothDraw.polygon(self, PackedVector2Array([Vector2(-32, 0), Vector2(0, -48), Vector2(32, 0)]), canvas, OUTLINE, 1.5)
	draw_colored_polygon(PackedVector2Array([Vector2(-11, 0), Vector2(0, -26), Vector2(11, 0)]), Color("#1d1512"))
	draw_colored_polygon(PackedVector2Array([Vector2(0, -26), Vector2(11, 0), Vector2(16, 0)]), canvas.lightened(0.15))
	draw_line(Vector2(0, -48), Vector2(0, -56), WOOD_DARK, 2.0, true)
	_rope(Vector2(0, -50), Vector2(-40, 4))
	if burning:
		_scorch(Rect2(-20, -36, 70, 30), 7)
		_flame(Vector2(18, -40), 9.0, 22.0)
		_flame(Vector2(38, -30), 6.0, 15.0, 1.3)


## A run of sharpened logs `length` wide. Broken runs have logs snapped off or knocked flat.
func _draw_palisade() -> void:
	var w := length if length > 0.0 else 120.0
	var count := int(ceilf(w / 10.0))
	var x0 := -w * 0.5
	SmoothDraw.shadow(self, Vector2(-6, 2), Vector2(w + 20.0, 14), 0.3)
	var logs := []
	for index in count:
		var x := x0 + 5.0 + index * 10.0
		var log_height := 58.0 + random.randf_range(-4.0, 4.0)
		var snapped := false
		if broken and random.randf() < 0.55:
			log_height = random.randf_range(12.0, 34.0)
			snapped = true
		logs.append([x, log_height, snapped, random.randf()])
	for index in range(1, 3):
		var beam_y := -14.0 - index * 18.0
		var beam_from := x0
		var beam_to := x0 + w
		_log(Vector2(beam_from, beam_y + 1.0), Vector2(beam_to, beam_y - 1.0), 3.0, WOOD_DARK)
	for entry in logs:
		var x: float = entry[0]
		var log_height: float = entry[1]
		var color := WOOD.darkened(0.1 + entry[3] * 0.15)
		if burning:
			color = color.lerp(CHAR, 0.45)
		SmoothDraw.box(self, Rect2(x - 4.5, -log_height, 9, log_height), color, 2.5)
		draw_line(Vector2(x - 1.5, -log_height + 4), Vector2(x - 1.5, -2), Color(color.lightened(0.25), 0.5), 1.0, true)
		if entry[2]:
			# A splintered stump.
			draw_colored_polygon(PackedVector2Array([Vector2(x - 4.5, -log_height), Vector2(x - 2, -log_height - 5), Vector2(x, -log_height - 1), Vector2(x + 2.5, -log_height - 6), Vector2(x + 4.5, -log_height)]), WOOD_LIGHT)
		else:
			SmoothDraw.polygon(self, PackedVector2Array([Vector2(x - 4.5, -log_height + 1), Vector2(x, -log_height - 8), Vector2(x + 4.5, -log_height + 1)]), color.lightened(0.1), OUTLINE, 1.0)
	if burning:
		for index in 3:
			var entry: Array = logs[(index * 5 + 2) % logs.size()]
			_flame(Vector2(entry[0], -entry[1] - 2.0), 6.0, 14.0, index * 1.7)


## One log of a palisade running away from us (the side walls), so each y-sorts on its own. Thick and
## close-set, so a run of them reads as a wall rather than a row of poles.
func _draw_palisade_post() -> void:
	var log_height := 58.0 + random.randf_range(-4.0, 4.0)
	var color := WOOD.darkened(0.1 + random.randf() * 0.15)
	if broken:
		log_height = random.randf_range(14.0, 30.0)
	SmoothDraw.shadow(self, Vector2(-5, 1), Vector2(24, 7), 0.3)
	SmoothDraw.box(self, Rect2(-8, -log_height, 16, log_height), color, 4.0)
	draw_line(Vector2(-4, -log_height + 4), Vector2(-4, -2), Color(color.lightened(0.25), 0.5), 2.0, true)
	if broken:
		draw_colored_polygon(PackedVector2Array([Vector2(-8, -log_height), Vector2(-3, -log_height - 6), Vector2(1, -log_height), Vector2(5, -log_height - 5), Vector2(8, -log_height)]), WOOD_LIGHT)
	else:
		SmoothDraw.polygon(self, PackedVector2Array([Vector2(-8, -log_height + 2), Vector2(0, -log_height - 10), Vector2(8, -log_height + 2)]), color.lightened(0.1), OUTLINE, 1.0)
	draw_line(Vector2(-8, -34), Vector2(8, -31), WOOD_DARK, 2.5, true)
	draw_line(Vector2(-8, -14), Vector2(8, -11), WOOD_DARK, 2.5, true)


func _draw_watchtower() -> void:
	SmoothDraw.shadow(self, Vector2(-10, 2), Vector2(80, 18), 0.32)
	var lean := -0.1 if broken else 0.0
	for leg_x: float in [-20.0, 20.0]:
		var top := Vector2(leg_x * 0.75 + lean * 110.0, -108)
		if broken and leg_x > 0.0:
			# Snapped leg, propped up on rubble.
			_log(Vector2(leg_x, 0), Vector2(leg_x - 2, -46), 5.0, WOOD_DARK)
			_log(Vector2(leg_x - 2, -50), top, 5.0, WOOD_DARK)
			draw_colored_polygon(PackedVector2Array([Vector2(leg_x - 6, -46), Vector2(leg_x + 4, -52), Vector2(leg_x + 2, -44)]), WOOD_LIGHT)
		else:
			_log(Vector2(leg_x, 0), top, 5.0, WOOD_DARK)
	_log(Vector2(-19, -14), Vector2(16 + lean * 40.0, -58), 2.5, WOOD)
	_log(Vector2(19, -14), Vector2(-16 + lean * 40.0, -58), 2.5, WOOD)
	draw_set_transform(Vector2(lean * 110.0, -108), lean, Vector2.ONE)
	SmoothDraw.box(self, Rect2(-24, -6, 48, 8), WOOD_LIGHT, 2.0)
	SmoothDraw.box(self, Rect2(-22, -26, 44, 20), WOOD.darkened(0.15) if not burning else WOOD.lerp(CHAR, 0.5), 2.5)
	for index in 4:
		draw_line(Vector2(-20 + index * 13, -24), Vector2(-20 + index * 13, -7), Color(WOOD_DARK, 0.7), 1.0, true)
	if broken:
		# The roof caved in to one side.
		SmoothDraw.polygon(self, PackedVector2Array([Vector2(-30, -24), Vector2(-6, -40), Vector2(26, -22), Vector2(10, -20)]), Color("#6b4a3a").darkened(0.2), OUTLINE, 1.5)
		_scorch(Rect2(-20, -26, 40, 20), 4)
	else:
		SmoothDraw.polygon(self, PackedVector2Array([Vector2(-28, -26), Vector2(0, -46), Vector2(28, -26)]), Color("#6b4a3a"), OUTLINE, 1.5)
	if burning:
		_flame(Vector2(-6, -26), 10.0, 24.0)
		_flame(Vector2(12, -24), 7.0, 16.0, 2.3)
	draw_set_transform(Vector2.ZERO)


## Cheval de frise: a beam bristling with crossed, sharpened stakes, facing the breach.
func _draw_barricade() -> void:
	var w := length if length > 0.0 else 90.0
	SmoothDraw.shadow(self, Vector2(-4, 2), Vector2(w + 16.0, 12), 0.3)
	var count := int(w / 18.0)
	for index in count + 1:
		var x := -w * 0.5 + index * w / maxf(count, 1)
		for side: float in [-1.0, 1.0]:
			var tip := Vector2(x + side * 14.0, -30.0)
			_log(Vector2(x - side * 10.0, 0), tip, 3.0, WOOD.darkened(0.1 if side > 0 else 0.2))
			draw_colored_polygon(PackedVector2Array([tip + Vector2(-2, 2), tip + Vector2(side * 4.0, -5), tip + Vector2(2, 2)]), WOOD_LIGHT)
	_log(Vector2(-w * 0.5 - 4.0, -14), Vector2(w * 0.5 + 4.0, -15), 6.0, WOOD_DARK)


## A field cot with a wounded soldier laid on it.
func _draw_cot() -> void:
	SmoothDraw.shadow(self, Vector2(-2, 1), Vector2(56, 10), 0.3)
	for leg_x: float in [-20.0, 20.0]:
		draw_line(Vector2(leg_x - 2, 0), Vector2(leg_x + 2, -8), WOOD_DARK, 2.0, true)
		draw_line(Vector2(leg_x + 2, 0), Vector2(leg_x - 2, -8), WOOD_DARK, 2.0, true)
	SmoothDraw.box(self, Rect2(-24, -12, 48, 5), CANVAS, 2.0)
	SmoothDraw.box(self, Rect2(-24, -16, 10, 5), Color("#e7dfcc"), 2.5)
	SmoothDraw.dome(self, Vector2(-17, -18), 5.0, Color("#c99a6e"))
	draw_line(Vector2(-22, -20), Vector2(-12, -21), Color("#efe6d2"), 2.2, true)
	SmoothDraw.disc(self, Vector2(-15, -21), 1.2, Color("#a83226"))
	# Blanket over him, rising and falling as he breathes.
	var breath := sin(time * 1.8 + phase) * 0.6
	SmoothDraw.polygon(self, PackedVector2Array([Vector2(-12, -12), Vector2(-11, -19 - breath), Vector2(4, -18 - breath), Vector2(22, -15), Vector2(23, -11)]), tint, OUTLINE, 1.2)
	draw_line(Vector2(-10, -16 - breath), Vector2(20, -14), Color(tint.lightened(0.25), 0.6), 1.0, true)


func _draw_weapon_rack() -> void:
	SmoothDraw.shadow(self, Vector2(-3, 1), Vector2(46, 9), 0.3)
	for post_x: float in [-18.0, 18.0]:
		SmoothDraw.box(self, Rect2(post_x - 2, -40, 4, 40), WOOD_DARK, 1.5)
	SmoothDraw.box(self, Rect2(-21, -36, 42, 4), WOOD, 1.5)
	SmoothDraw.box(self, Rect2(-21, -10, 42, 4), WOOD, 1.5)
	for index in 4:
		var x := -12.0 + index * 8.0
		draw_line(Vector2(x, -6), Vector2(x + 1.5, -50), OUTLINE, 2.8, true)
		draw_line(Vector2(x, -6), Vector2(x + 1.5, -50), WOOD_LIGHT, 1.5, true)
		SmoothDraw.polygon(self, PackedVector2Array([Vector2(x - 0.5, -50), Vector2(x + 1.5, -58), Vector2(x + 3.5, -50)]), STEEL, OUTLINE, 1.0)
	SmoothDraw.dome(self, Vector2(22, -18), 8.0, tint)
	SmoothDraw.dome(self, Vector2(22, -18), 3.0, STEEL)


## A heap of smashed timbers and stone, still burning.
func _draw_debris() -> void:
	SmoothDraw.shadow(self, Vector2(-3, 1), Vector2(64, 14), 0.35)
	_stone(Vector2(-16, -4), 6.0, STONE.darkened(0.3))
	_stone(Vector2(14, -3), 5.0, STONE.darkened(0.25))
	_log(Vector2(-24, -2), Vector2(18, -14), 4.0, WOOD.lerp(CHAR, 0.5))
	_log(Vector2(22, -1), Vector2(-12, -18), 3.5, WOOD.lerp(CHAR, 0.35))
	_log(Vector2(-6, 0), Vector2(6, -22), 3.0, CHAR)
	SmoothDraw.disc(self, Vector2(0, -6), 6.0, Color(1.0, 0.45, 0.1, 0.55))
	if variant != 1:
		_flame(Vector2(-4, -8), 9.0, 22.0)
		_flame(Vector2(9, -8), 5.0, 13.0, 1.9)


## The quartermaster's forge: a stone hearth glowing with coals, a chimney and an anvil.
func _draw_forge() -> void:
	SmoothDraw.shadow(self, Vector2(-4, 2), Vector2(80, 16), 0.32)
	SmoothDraw.box(self, Rect2(-30, -30, 40, 30), STONE.darkened(0.15), 4.0)
	for row in 3:
		draw_line(Vector2(-28, -22 + row * 9), Vector2(8, -22 + row * 9), Color(STONE.darkened(0.45), 0.5), 1.0, true)
	SmoothDraw.box(self, Rect2(-20, -62, 16, 34), STONE.darkened(0.25), 3.0)
	var glow := 0.75 + 0.25 * sin(time * 3.0 + phase)
	SmoothDraw.flat(self, Rect2(-22, -20, 24, 10), Color(0.12, 0.05, 0.03), 3.0)
	SmoothDraw.flat(self, Rect2(-20, -17, 20, 6), Color(1.0, 0.45 * glow + 0.15, 0.1, 1.0), 2.0)
	_flame(Vector2(-10, -18), 6.0, 9.0)
	# Anvil on its stump.
	SmoothDraw.box(self, Rect2(16, -14, 12, 14), WOOD_DARK, 2.0)
	SmoothDraw.polygon(self, PackedVector2Array([Vector2(12, -22), Vector2(32, -22), Vector2(36, -19), Vector2(28, -17), Vector2(26, -14), Vector2(18, -14), Vector2(16, -17)]), IRON, OUTLINE, 1.2)
	draw_line(Vector2(13, -21), Vector2(31, -21), Color(STEEL, 0.6), 1.0, true)


func _draw_grave() -> void:
	SmoothDraw.shadow(self, Vector2(-2, 1), Vector2(36, 8), 0.3)
	var mound := PackedVector2Array()
	for index in 13:
		var u := float(index) / 12.0
		mound.append(Vector2(lerpf(-16, 16, u), -sin(u * PI) * 7.0))
	SmoothDraw.polygon(self, mound, Color("#4a3a30"), OUTLINE, 1.0)
	if variant == 1:
		# A sword driven into the earth, a helmet hung on its hilt.
		draw_line(Vector2(0, -4), Vector2(0, -34), OUTLINE, 3.4, true)
		draw_line(Vector2(0, -4), Vector2(0, -34), STEEL, 2.0, true)
		draw_line(Vector2(-5, -28), Vector2(5, -28), Color("#6d5332"), 2.4, true)
		# The helmet hung on the hilt: a dented cap with its brim.
		var helm := PackedVector2Array()
		for index in 13:
			var angle := PI + PI * index / 12.0
			helm.append(Vector2(0, -27) + Vector2(cos(angle) * 8.0, sin(angle) * 8.5))
		SmoothDraw.polygon(self, helm, STEEL.darkened(0.15), OUTLINE, 1.2)
		draw_line(Vector2(-9.5, -27), Vector2(9.5, -27), STEEL.darkened(0.4), 2.2, true)
		draw_line(Vector2(-3, -32), Vector2(-1, -34), Color(1, 1, 1, 0.5), 1.0, true)
		return
	_log(Vector2(0, -3), Vector2(0, -32), 3.0, WOOD)
	_log(Vector2(-8, -24), Vector2(8, -24), 3.0, WOOD)
