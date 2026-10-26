extends Area2D
class_name ItemPickup
## A piece of gear lying on the ground. It hops out of the monster, then floats over a pool of light in its
## rarity's colour; Rare and better also send up a beam so they can be spotted from across the screen.

signal collected

const OUTLINE := Color("#14110d")
const FULL_COLOR := Color("#ff6b5a")
const FULL_MESSAGE_TIME := 1.5
const ICON_HEIGHT := 20.0
## Icons are drawn on a ~24 px grid and scaled up so they stay readable on a phone screen.
const ICON_SCALE := 1.3
## Per rarity (Common, Uncommon, Rare, Epic, Legendary, Quest).
const SPARKLE_COUNTS := [0, 2, 3, 5, 7, 4]
const BEAM_HEIGHTS := [0.0, 0.0, 52.0, 80.0, 120.0, 64.0]

var item: ItemData
## Where the monster that dropped this stood, relative to where it lands. Zero (e.g. a drop restored from
## a save) skips the hop.
var drop_offset := Vector2.ZERO

var drop_age := LootFx.DROP_TIME
var time := 0.0
var full_message_timer := 0.0
var rarity := ItemData.Rarity.COMMON
var rarity_color := Color.WHITE
var icon_shape := PackedVector2Array()
var icon_outline := PackedVector2Array()
var icon_rotation := 0.0

@onready var item_name_label: Label = $ItemName
@onready var screen_notifier: VisibleOnScreenNotifier2D = $ScreenNotifier


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if item == null:
		push_error("ItemPickup requires an ItemData resource.")
		set_deferred("monitoring", false)
		return

	add_to_group("level_drops")
	rarity = item.get_rarity()
	rarity_color = item.get_rarity_color()
	icon_shape = _slot_shape(item.equipment_slot)
	icon_outline = icon_shape.duplicate()
	if not icon_outline.is_empty():
		icon_outline.append(icon_outline[0])
	icon_rotation = -PI / 4.0 if item.equipment_slot == "Weapon" else 0.0
	# Out of step with its neighbours so a pile of drops doesn't pulse in unison.
	time = randf() * TAU

	item_name_label.text = item.display_name
	item_name_label.add_theme_color_override("font_color", rarity_color)
	if drop_offset != Vector2.ZERO:
		drop_age = 0.0
		item_name_label.hide()


func _process(delta: float) -> void:
	time += delta
	if full_message_timer > 0.0:
		full_message_timer -= delta
		if full_message_timer <= 0.0:
			item_name_label.text = item.display_name
			item_name_label.add_theme_color_override("font_color", rarity_color)
	if drop_age < LootFx.DROP_TIME:
		drop_age += delta
		if drop_age >= LootFx.DROP_TIME:
			_land()
		queue_redraw()
	elif screen_notifier.is_on_screen():
		queue_redraw()


func is_landed() -> bool:
	return drop_age >= LootFx.DROP_TIME


func _land() -> void:
	item_name_label.show()
	# Anyone already standing on the landing spot picks it up now; body_entered won't fire again for them.
	for body in get_overlapping_bodies():
		_on_body_entered(body)


func _on_body_entered(body: Node2D) -> void:
	if not body is Player or not is_landed() or item == null:
		return

	var player := body as Player
	if player.try_add_item(item):
		remove_from_group("level_drops")
		Audio.play_sfx("item_pickup")
		PickupBurst.spawn(get_parent(), global_position, rarity_color, item.display_name, 6 + rarity * 2)
		collected.emit()
		queue_free()
	else:
		item_name_label.text = "Inventory Full"
		item_name_label.add_theme_color_override("font_color", FULL_COLOR)
		full_message_timer = FULL_MESSAGE_TIME


func _draw() -> void:
	if item == null:
		return
	var progress := clampf(drop_age / LootFx.DROP_TIME, 0.0, 1.0)
	var hop := LootFx.hop_offset(drop_offset, progress)
	var pulse := 0.8 + sin(time * 3.0) * 0.2
	# The ground effects grow in as the drop touches down.
	var settle := clampf((progress - 0.6) / 0.4, 0.0, 1.0)

	var shadow_size := clampf(1.0 + hop.y / 60.0, 0.4, 1.0)
	GroundShadows.draw_soft_ellipse(self, Vector2(hop.x, 2.0), Vector2(28.0, 9.0) * shadow_size)
	if settle > 0.0:
		var glow_scale := 1.0 + rarity * 0.1
		LootFx.draw_ground_glow(self, Vector2(0.0, 1.0), Vector2(22.0, 8.0) * glow_scale, rarity_color, pulse * settle * (0.7 + rarity * 0.1))
		var beam_height: float = BEAM_HEIGHTS[rarity]
		if beam_height > 0.0:
			LootFx.draw_light_beam(self, Vector2(0.0, 2.0), 16.0 + rarity * 2.0, beam_height * settle, rarity_color, pulse * settle)

	var bob := sin(time * 2.4) * 2.5 * settle
	var icon_center := hop + Vector2(0.0, -ICON_HEIGHT + bob)
	if rarity >= ItemData.Rarity.EPIC or rarity == ItemData.Rarity.QUEST:
		_draw_halo(icon_center, pulse * settle)
	_draw_icon(icon_center)
	LootFx.draw_rising_sparkles(self, icon_center + Vector2(0.0, 6.0), Vector2(14.0, 34.0), SPARKLE_COUNTS[rarity], time, rarity_color)


## A slowly turning ring of light behind Epic and better gear.
func _draw_halo(center: Vector2, strength: float) -> void:
	if strength <= 0.0:
		return
	draw_circle(center, 20.0, Color(rarity_color, 0.18 * strength))
	const DASHES := 6
	for dash in DASHES:
		var start := time * 0.9 + TAU * dash / DASHES
		draw_arc(center, 21.0, start, start + 0.6, 6, Color(rarity_color.lightened(0.3), 0.7 * strength), 1.5)


func _draw_icon(center: Vector2) -> void:
	var fill := item.icon_color
	match item.equipment_slot:
		"Ring":
			draw_set_transform(center, 0.0, Vector2.ONE * ICON_SCALE)
			_draw_ring(Vector2.ZERO, fill)
		"Amulet":
			draw_set_transform(center, 0.0, Vector2.ONE * ICON_SCALE)
			_draw_amulet(Vector2.ZERO, fill)
		_:
			draw_set_transform(center, icon_rotation, Vector2.ONE * ICON_SCALE * 1.18)
			draw_colored_polygon(icon_shape, Color(rarity_color, 0.45))
			draw_set_transform(center, icon_rotation, Vector2.ONE * ICON_SCALE)
			draw_colored_polygon(icon_shape, fill)
			draw_polyline(icon_outline, OUTLINE, 2.0)
			_draw_slot_details(fill)
	draw_set_transform_matrix(Transform2D.IDENTITY)
	# A glint across the top so every icon reads as polished metal.
	var glint := fposmod(time * 0.5, 2.0)
	if glint < 1.0:
		LootFx.draw_sparkle(self, center + Vector2(-8.0 + glint * 16.0, -10.0), 2.5 * sin(glint * PI), Color(Color.WHITE, sin(glint * PI)))


## Extra lines drawn over a slot's silhouette, in the icon's own space.
func _draw_slot_details(fill: Color) -> void:
	var shade := fill.darkened(0.35)
	var shine := fill.lightened(0.4)
	match item.equipment_slot:
		"Weapon":
			draw_line(Vector2(0.0, -13.0), Vector2(0.0, 3.0), shine, 1.0)
			draw_rect(Rect2(-7.0, 3.0, 14.0, 3.0), rarity_color.darkened(0.1))
			draw_rect(Rect2(-7.0, 3.0, 14.0, 3.0), OUTLINE, false, 1.0)
			draw_rect(Rect2(-1.5, 6.0, 3.0, 6.0), shade)
			draw_circle(Vector2(0.0, 13.5), 2.4, rarity_color)
		"Helm":
			draw_rect(Rect2(-7.0, -2.0, 14.0, 2.5), OUTLINE)
			draw_rect(Rect2(-1.2, -2.0, 2.4, 7.0), shade)
			draw_line(Vector2(-6.0, -8.0), Vector2(-1.0, -11.0), shine, 1.0)
		"Chest":
			draw_line(Vector2(0.0, -7.0), Vector2(0.0, 10.0), shade, 1.0)
			draw_line(Vector2(-7.0, 2.0), Vector2(7.0, 2.0), shade, 1.0)
			draw_line(Vector2(-10.0, -8.0), Vector2(-5.0, -10.0), shine, 1.0)
		"Legs":
			draw_rect(Rect2(-8.0, -10.0, 16.0, 3.0), rarity_color.darkened(0.15))
		"Gloves":
			draw_rect(Rect2(-6.0, 6.0, 12.0, 4.0), shade)
		"Boots":
			draw_rect(Rect2(-6.0, 7.0, 17.0, 3.0), shade)
			draw_line(Vector2(-5.0, -10.0), Vector2(-5.0, 5.0), shine, 1.0)
		_:
			# A bundle tied with a strap in the rarity's colour (quest items and anything unrecognised).
			draw_line(Vector2(0.0, -7.0), Vector2(0.0, 7.0), rarity_color, 2.0)
			draw_line(Vector2(-9.0, 0.0), Vector2(9.0, 0.0), rarity_color, 2.0)


func _draw_ring(center: Vector2, fill: Color) -> void:
	draw_arc(center + Vector2(0.0, 2.0), 8.0, 0.0, TAU, 20, Color(rarity_color, 0.45), 7.0)
	draw_arc(center + Vector2(0.0, 2.0), 8.0, 0.0, TAU, 20, OUTLINE, 5.0)
	draw_arc(center + Vector2(0.0, 2.0), 8.0, 0.0, TAU, 20, fill, 3.0)
	_draw_gem(center + Vector2(0.0, -6.0), 4.5)


func _draw_amulet(center: Vector2, fill: Color) -> void:
	var chain := PackedVector2Array([center + Vector2(-8.0, -12.0), center + Vector2(0.0, 0.0), center + Vector2(8.0, -12.0)])
	draw_polyline(chain, OUTLINE, 3.0)
	draw_polyline(chain, fill.lightened(0.2), 1.5)
	draw_circle(center + Vector2(0.0, 6.0), 7.0, OUTLINE)
	draw_circle(center + Vector2(0.0, 6.0), 6.0, fill)
	_draw_gem(center + Vector2(0.0, 6.0), 3.5)


func _draw_gem(center: Vector2, size: float) -> void:
	var gem := PackedVector2Array([
		center + Vector2(0.0, -size),
		center + Vector2(size, 0.0),
		center + Vector2(0.0, size),
		center + Vector2(-size, 0.0)
	])
	draw_colored_polygon(gem, rarity_color)
	gem.append(gem[0])
	draw_polyline(gem, OUTLINE, 1.0)
	draw_line(center + Vector2(-size * 0.4, -size * 0.2), center + Vector2(0.0, -size * 0.6), Color.WHITE, 1.0)


## The silhouette of each equipment slot, roughly 24 px across and centred on the origin.
static func _slot_shape(slot: String) -> PackedVector2Array:
	match slot:
		"Weapon":
			return PackedVector2Array([
				Vector2(0, -16), Vector2(2.5, -13), Vector2(2.5, 4), Vector2(-2.5, 4), Vector2(-2.5, -13)
			])
		"Helm":
			return PackedVector2Array([
				Vector2(-10, 6), Vector2(-10, -3), Vector2(-7, -9), Vector2(-2, -12), Vector2(2, -12),
				Vector2(7, -9), Vector2(10, -3), Vector2(10, 6), Vector2(5, 8), Vector2(-5, 8)
			])
		"Chest":
			return PackedVector2Array([
				Vector2(-11, -9), Vector2(-5, -11), Vector2(-3, -8), Vector2(3, -8), Vector2(5, -11),
				Vector2(11, -9), Vector2(12, -1), Vector2(8, 0), Vector2(8, 11), Vector2(-8, 11),
				Vector2(-8, 0), Vector2(-12, -1)
			])
		"Legs":
			return PackedVector2Array([
				Vector2(-8, -10), Vector2(8, -10), Vector2(9, 11), Vector2(3, 11), Vector2(1, -2),
				Vector2(-1, -2), Vector2(-3, 11), Vector2(-9, 11)
			])
		"Gloves":
			return PackedVector2Array([
				Vector2(-6, 10), Vector2(-6, 0), Vector2(-10, -5), Vector2(-8, -7), Vector2(-5, -4),
				Vector2(-5, -10), Vector2(-2, -11), Vector2(0, -9), Vector2(2, -11), Vector2(5, -10),
				Vector2(7, -6), Vector2(6, 10)
			])
		"Boots":
			return PackedVector2Array([
				Vector2(-6, -11), Vector2(2, -11), Vector2(2, 3), Vector2(9, 5), Vector2(11, 10), Vector2(-6, 10)
			])
		_:
			return PackedVector2Array([
				Vector2(-9, -7), Vector2(9, -7), Vector2(10, 7), Vector2(-10, 7)
			])
