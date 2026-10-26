extends Area2D
class_name TreasureChest

signal opened

const OUTLINE := Color("#2a1a10")
const WOOD_DARK := Color("#5c3b22")
const WOOD := Color("#8a5a2b")
const WOOD_LIGHT := Color("#b07d48")
const METAL := Color("#c9a24a")
const METAL_DARK := Color("#7d6224")
const INTERIOR := Color("#1d120a")
const LID_INSIDE := Color("#4a2f1b")
const GLOW := Color(1.0, 0.86, 0.4)

@onready var prompt: Label = $Prompt

var is_open := false
var loot_rolled := false
var loot: Array[ItemData] = []
var player_nearby := false
var animation_time := 0.0


func _ready() -> void:
	add_to_group("interactables")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	prompt.hide()


func _process(delta: float) -> void:
	animation_time += delta
	queue_redraw()


func can_interact(_player: Player) -> bool:
	return player_nearby and has_loot_left()


func has_loot_left() -> bool:
	return not loot_rolled or not loot.is_empty()


func interact(_player: Player) -> void:
	if not can_interact(_player):
		return
	is_open = true
	Audio.play_sfx("chest_open")
	opened.emit()
	update_prompt()


## Call after taking items so the prompt disappears once the chest is empty.
func update_prompt() -> void:
	prompt.text = MenuStyle.interact_prompt("Loot" if is_open else "Open")
	prompt.visible = player_nearby and has_loot_left()


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player_nearby = true
		update_prompt()


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		player_nearby = false
		prompt.hide()


func _draw() -> void:
	GroundShadows.draw_soft_ellipse(self, Vector2(0, 1), Vector2(46, 10))
	if is_open:
		_draw_open()
	else:
		_draw_closed()


func _draw_closed() -> void:
	# A gentle glint and bob so the chest reads as something to interact with.
	var bob := roundf(sin(animation_time * 3.0) * 1.0)
	_draw_body(bob)
	var lid := Rect2(-18, -32 + bob, 36, 13)
	draw_rect(lid.grow(1.0), OUTLINE)
	draw_rect(lid, WOOD)
	draw_rect(Rect2(lid.position, Vector2(lid.size.x, 2)), WOOD_LIGHT)
	draw_rect(Rect2(lid.position.x, lid.end.y - 2, lid.size.x, 2), WOOD_DARK)
	_draw_bands(lid)
	# Lock plate.
	draw_rect(Rect2(-4, -22 + bob, 8, 8), OUTLINE)
	draw_rect(Rect2(-3, -21 + bob, 6, 6), METAL)
	draw_rect(Rect2(-1, -19 + bob, 2, 3), OUTLINE)

	var twinkle := maxf(sin(animation_time * 2.2), 0.0)
	if twinkle > 0.0:
		var spark := Vector2(11, -33 + bob)
		var spark_color := Color(GLOW, twinkle)
		draw_line(spark + Vector2(-3, 0), spark + Vector2(3, 0), spark_color, 1.0)
		draw_line(spark + Vector2(0, -3), spark + Vector2(0, 3), spark_color, 1.0)


func _draw_open() -> void:
	var has_loot := not loot.is_empty()
	var glow_strength := 0.35 + sin(animation_time * 2.5) * 0.08
	if has_loot:
		draw_circle(Vector2(0, -24), 22.0, Color(GLOW, glow_strength * 0.35))
	# Lid tipped back on its hinge: we see its inner face, attached to the back of the body.
	var lid := Rect2(-18, -33, 36, 13)
	draw_rect(lid.grow(1.0), OUTLINE)
	draw_rect(lid, WOOD)
	draw_rect(lid.grow(-2.0), LID_INSIDE)
	draw_rect(Rect2(lid.position.x + 2, lid.position.y + 2, lid.size.x - 4, 1), WOOD_DARK)
	for band_x in [-13.0, 9.0]:
		draw_rect(Rect2(band_x, lid.position.y, 3, 2), METAL)
	_draw_body(0.0)
	# The open mouth of the chest, with treasure while there's loot left.
	var mouth := Rect2(-16, -20, 32, 6)
	draw_rect(mouth, INTERIOR)
	if has_loot:
		for coin_x in [-12.0, -7.0, -2.0, 3.0, 8.0]:
			draw_rect(Rect2(coin_x, mouth.position.y + 2 + absf(coin_x) * 0.1, 4, 3), METAL)
			draw_rect(Rect2(coin_x, mouth.position.y + 2 + absf(coin_x) * 0.1, 4, 1), Color(GLOW, 0.9))
	draw_rect(Rect2(mouth.position.x, mouth.end.y, mouth.size.x, 1), OUTLINE)


func _draw_body(bob: float) -> void:
	var body := Rect2(-17, -20 + bob, 34, 20)
	draw_rect(body.grow(1.0), OUTLINE)
	draw_rect(body, WOOD)
	for plank_y in [-14.0, -8.0]:
		draw_rect(Rect2(body.position.x, plank_y + bob, body.size.x, 1), WOOD_DARK)
	draw_rect(Rect2(body.position.x, body.end.y - 2, body.size.x, 2), WOOD_DARK)
	draw_rect(Rect2(body.position, Vector2(2, body.size.y)), WOOD_LIGHT)
	_draw_bands(body)


func _draw_bands(area: Rect2) -> void:
	for band_x in [-13.0, 9.0]:
		draw_rect(Rect2(band_x, area.position.y, 4, area.size.y), METAL_DARK)
		draw_rect(Rect2(band_x, area.position.y, 3, area.size.y), METAL)
