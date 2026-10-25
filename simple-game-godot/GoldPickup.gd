extends Area2D
class_name GoldPickup
## Coins on the ground. They hop out of the monster and settle into a spinning coin over a pile that grows
## with the amount.

signal collected

## Monster modifiers multiply gold (Treasure Bound triples it), so a drop can be worth more than a roll's 1-3.
const MAX_AMOUNT := 99
const GOLD := Color("#f5bd33")
const GOLD_LIGHT := Color("#ffe07a")
const GOLD_DARK := Color("#9c6a14")
const OUTLINE := Color("#3a2608")
const GLOW := Color(1.0, 0.82, 0.3)
const COIN_RADIUS := 6.5
const PILE_SPREAD := 1.2
## Coins lying under the spinning one, bottom first; a drop shows more of them the more it is worth.
const PILE := [
	Vector2(-5, 0), Vector2(5, 0), Vector2(0, -2), Vector2(-9, -1), Vector2(9, -1), Vector2(-3, -4), Vector2(4, -4)
]

@export_range(1, 99, 1) var amount := 1
## Where the monster that dropped this stood, relative to where it lands. Zero skips the hop.
var drop_offset := Vector2.ZERO

var drop_age := LootFx.DROP_TIME
var time := 0.0
var pile_size := 0

@onready var amount_label: Label = $Amount
@onready var screen_notifier: VisibleOnScreenNotifier2D = $ScreenNotifier


func _ready() -> void:
	if amount < 1 or amount > MAX_AMOUNT:
		push_error("Gold pickup amount must be between 1 and %d." % MAX_AMOUNT)
		set_deferred("monitoring", false)
		return

	add_to_group("level_drops")
	amount_label.text = "+%d" % amount
	pile_size = mini(amount - 1, 2) if amount <= 3 else mini(PILE.size(), 3 + floori(amount / 3.0))
	time = randf() * TAU
	body_entered.connect(_on_body_entered)
	if drop_offset != Vector2.ZERO:
		drop_age = 0.0
		amount_label.hide()


func _process(delta: float) -> void:
	time += delta
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
	amount_label.show()
	for body in get_overlapping_bodies():
		_on_body_entered(body)


func _on_body_entered(body: Node2D) -> void:
	if not body is Player or not is_landed() or not is_in_group("level_drops"):
		return

	remove_from_group("level_drops")
	PickupBurst.spawn(get_parent(), global_position, GOLD_LIGHT, "+%d gold" % amount, 5 + pile_size)
	collected.emit()
	GameState.add_gold(amount)
	queue_free()


func _draw() -> void:
	var progress := clampf(drop_age / LootFx.DROP_TIME, 0.0, 1.0)
	var hop := LootFx.hop_offset(drop_offset, progress)
	var settle := clampf((progress - 0.6) / 0.4, 0.0, 1.0)
	var pulse := 0.8 + sin(time * 3.0) * 0.2

	var shadow_size := clampf(1.0 + hop.y / 60.0, 0.4, 1.0)
	GroundShadows.draw_soft_ellipse(self, Vector2(hop.x, 2.0), Vector2(26.0, 8.0) * shadow_size)
	if settle > 0.0:
		var glow_scale := 1.0 + pile_size * 0.08
		LootFx.draw_ground_glow(self, Vector2(0.0, 1.0), Vector2(18.0, 7.0) * glow_scale, GLOW, pulse * settle * 0.8)
		for index in pile_size:
			_draw_flat_coin(PILE[index] * PILE_SPREAD)

	# The top coin stands on edge and spins.
	var bob := sin(time * 2.6) * 1.5 * settle
	var spin := absf(cos(time * 3.2))
	_draw_standing_coin(hop + Vector2(0.0, -11.0 + bob), maxf(spin, 0.12))
	LootFx.draw_rising_sparkles(self, hop + Vector2(0.0, -6.0), Vector2(12.0, 22.0), 1 + mini(pile_size, 3), time, GLOW)


func _draw_flat_coin(center: Vector2) -> void:
	draw_set_transform(center, 0.0, Vector2(1.0, 0.5))
	draw_circle(Vector2(0.0, 1.5), COIN_RADIUS + 1.0, OUTLINE)
	draw_circle(Vector2(0.0, 1.5), COIN_RADIUS, GOLD_DARK)
	draw_circle(Vector2.ZERO, COIN_RADIUS, GOLD)
	draw_circle(Vector2(-1.0, -1.0), COIN_RADIUS * 0.45, GOLD_LIGHT)
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_standing_coin(center: Vector2, width: float) -> void:
	draw_set_transform(center, 0.0, Vector2(width, 1.0))
	draw_circle(Vector2.ZERO, COIN_RADIUS + 1.5, OUTLINE)
	draw_circle(Vector2.ZERO, COIN_RADIUS + 0.5, GOLD_DARK)
	draw_circle(Vector2.ZERO, COIN_RADIUS - 0.5, GOLD)
	draw_rect(Rect2(-1.0, -3.0, 2.0, 6.0), GOLD_DARK)
	draw_set_transform_matrix(Transform2D.IDENTITY)
	# The face catches the light as it turns toward the camera.
	if width > 0.85:
		LootFx.draw_sparkle(self, center + Vector2(-2.5, -3.0), 3.0 * (width - 0.85) / 0.15, Color(Color.WHITE, 0.9))
