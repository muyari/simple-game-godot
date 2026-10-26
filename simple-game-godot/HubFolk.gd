extends CharacterBody2D
class_name HubFolk
## A resident of one of the regional hubs, drawn smooth and softly lit like the HUD rather than from a
## sheet, so each camp can dress its people for its own climate: robes and turbans in the desert, furs in
## the ice caves, mail and bandages at the besieged outpost. Stands, sits or strolls about an area, turns
## to face the player, and says one of its lines in a speech bubble when the player comes close.

enum Headwear { HAIR, HOOD, TURBAN, FUR_HOOD, HELMET, BANDANA, BALD }
enum Held { NONE, SPEAR, STAFF, ROD, HAMMER, TORCH, BOWL, SWORD, LANTERN, SCROLL }
enum Pose { STAND, SIT }

const OUTLINE := Color(0.13, 0.08, 0.05)
const STEEL := Color("#9aa3ab")
const WOOD := Color("#7a5230")
const TALK_DISTANCE := 84.0
const LINE_TIME := 6.0
const STEP_RATE := 9.0
const ARRIVE_DISTANCE := 6.0

var display_name := ""
var lines: Array[String] = []
var skin := Color("#c99a6e")
var clothes := Color("#8a4a2e")
var trim := Color("#d9b46a")
var pants := Color("#4a3a2a")
var hair := Color("#2a1c12")
var robe := false
var armored := false
var beard := false
var bandaged := false
var headwear := Headwear.HAIR
var held := Held.NONE
var pose := Pose.STAND
## Where they wander, in world pixels. Empty keeps them where they stand.
var area := Rect2()
var speed := 30.0
var body_scale := 1.15
## Which way they face when no one is about: 1 right, -1 left.
var rest_facing := 1.0

var player: Node2D
var time := 0.0
var facing := 1.0
var walking := false
var target := Vector2.ZERO
var pause_left := 0.0
var stuck_time := 0.0
var line_index := -1
var line_time := 0.0
var talking := false
var bubble: PanelContainer
var bubble_name: Label
var bubble_line: Label
## Whoever is nearest the player does the talking, so neighbours don't speak over each other.
static var _speaker: HubFolk


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 8.0
	shape.shape = circle
	shape.position = Vector2(0.0, -4.0)
	add_child(shape)
	# The hub's Player is a sibling, or a sibling of the stall or post this resident stands in.
	var hub := get_parent()
	while hub != null and not hub.has_node("Player"):
		hub = hub.get_parent()
	player = hub.get_node("Player") as Node2D if hub != null else null
	if player is PhysicsBody2D:
		add_collision_exception_with(player)
	time = randf() * 10.0
	facing = rest_facing
	pause_left = randf_range(0.5, 4.0)
	line_index = randi() % maxi(lines.size(), 1) - 1
	if held in [Held.TORCH, Held.LANTERN]:
		FireGlow.attach(self, Vector2(10.0, -40.0 if held == Held.TORCH else -16.0) * body_scale, 70.0, Color("#ffc46b"), 0.3)
	_build_bubble()


func _physics_process(delta: float) -> void:
	time += delta
	var distance := global_position.distance_to(player.global_position) if player != null else INF
	var near := distance < TALK_DISTANCE
	if near and not lines.is_empty() and (not is_instance_valid(_speaker) or _speaker == self \
			or distance < _speaker.global_position.distance_to(player.global_position) - 6.0):
		_speaker = self
	elif not near and _speaker == self:
		_speaker = null
	if near:
		walking = false
		velocity = Vector2.ZERO
		if absf(player.global_position.x - global_position.x) > 4.0:
			facing = signf(player.global_position.x - global_position.x)
	elif walking:
		var to_target := target - global_position
		if to_target.length() <= ARRIVE_DISTANCE:
			_stop()
		else:
			velocity = to_target.normalized() * speed
			if absf(velocity.x) > 2.0:
				facing = signf(velocity.x)
			var before := global_position
			move_and_slide()
			stuck_time = stuck_time + delta if global_position.distance_to(before) < speed * delta * 0.3 else 0.0
			if stuck_time > 0.4:
				_stop()
	else:
		pause_left -= delta
		if pause_left <= 0.0 and area.has_area() and pose == Pose.STAND:
			_start_walk()
	_update_bubble(near and _speaker == self, delta)
	queue_redraw()


func _start_walk() -> void:
	for _attempt in 8:
		var spot := Vector2(randf_range(area.position.x, area.end.x), randf_range(area.position.y, area.end.y))
		if spot.distance_to(global_position) > 40.0:
			target = spot
			walking = true
			stuck_time = 0.0
			return
	pause_left = 1.0


func _stop() -> void:
	walking = false
	velocity = Vector2.ZERO
	pause_left = randf_range(2.0, 6.0)


# --- Speech --------------------------------------------------------------------------------------------

func _build_bubble() -> void:
	bubble = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.05, 0.04, 0.82)
	style.border_color = Color(0.62, 0.49, 0.29, 0.9)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 5.0
	bubble.add_theme_stylebox_override("panel", style)
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble.z_index = 40
	bubble.z_as_relative = false
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble.add_child(column)
	bubble_name = Label.new()
	bubble_name.text = display_name
	bubble_name.add_theme_font_size_override("font_size", 11)
	bubble_name.add_theme_color_override("font_color", Color("#e8ca86"))
	column.add_child(bubble_name)
	bubble_line = Label.new()
	bubble_line.add_theme_font_size_override("font_size", 12)
	bubble_line.add_theme_color_override("font_color", Color("#f3ead8"))
	bubble_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble_line.custom_minimum_size.x = 190.0
	column.add_child(bubble_line)
	bubble.modulate.a = 0.0
	bubble.hide()
	add_child(bubble)


func _update_bubble(near: bool, delta: float) -> void:
	if lines.is_empty():
		return
	if near and not talking:
		talking = true
		_next_line()
	elif not near:
		talking = false
	if talking:
		line_time += delta
		if line_time > LINE_TIME and lines.size() > 1:
			_next_line()
	bubble.modulate.a = move_toward(bubble.modulate.a, 1.0 if talking else 0.0, delta * 5.0)
	bubble.visible = bubble.modulate.a > 0.01
	if bubble.visible:
		bubble.reset_size()
		var head_top := (-64.0 if pose == Pose.STAND else -54.0) * body_scale
		bubble.position = Vector2(-bubble.size.x * 0.5, head_top - bubble.size.y)


func _next_line() -> void:
	line_index = (line_index + 1) % lines.size()
	bubble_line.text = lines[line_index]
	line_time = 0.0


# --- Drawing -------------------------------------------------------------------------------------------

func _draw() -> void:
	SmoothDraw.shadow(self, Vector2(-2.0, 0.0), Vector2(24.0, 7.0) * body_scale, 0.35)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1.0) * body_scale)
	var step := sin(time * STEP_RATE) if walking else 0.0
	var breath := sin(time * 2.1) * 0.4
	var lift := 8.0 if pose == Pose.SIT else 0.0
	_draw_legs(step)
	var top := -31.0 + lift - breath
	if held in [Held.SPEAR, Held.STAFF, Held.TORCH]:
		_draw_pole(top)
	_draw_body(top, lift)
	_draw_arms(top, step)
	_draw_head(Vector2(0.0, top - 7.5 - absf(step) * 0.6))
	if held not in [Held.SPEAR, Held.STAFF, Held.TORCH]:
		_draw_held(top)
	draw_set_transform(Vector2.ZERO)


func _draw_legs(step: float) -> void:
	var boot := pants.darkened(0.45)
	if pose == Pose.SIT:
		# Knees toward us, feet on the ground.
		for side: float in [-1.0, 1.0]:
			SmoothDraw.box(self, Rect2(side * 4.0 - 3.0, -9.0, 6.0, 7.0), pants, 2.5)
			SmoothDraw.box(self, Rect2(side * 4.0 - 3.0, -3.0, 6.0, 3.0), boot, 1.5)
		return
	for side: float in [-1.0, 1.0]:
		var raise := maxf(step * side, 0.0) * 2.5
		var leg := Rect2(side * 3.0 - 2.5, -14.0, 5.0, 14.0 - raise)
		if not robe:
			SmoothDraw.box(self, leg, pants, 2.0)
		SmoothDraw.box(self, Rect2(leg.position.x - 0.5, leg.end.y - 3.5, 6.0, 3.5), boot, 1.5)


func _draw_body(top: float, lift: float) -> void:
	var hem := -3.0 if robe else -13.0
	hem = minf(hem + lift * 0.4, -2.0)
	if robe:
		var points := PackedVector2Array([
			Vector2(-7.5, top), Vector2(7.5, top), Vector2(10.5, hem), Vector2(0.0, hem + 1.0), Vector2(-10.5, hem),
		])
		SmoothDraw.polygon(self, points, clothes, OUTLINE, 1.2)
		draw_colored_polygon(PackedVector2Array([Vector2(-10.0, hem - 3.0), Vector2(10.0, hem - 3.0), Vector2(10.5, hem), Vector2(0.0, hem + 1.0), Vector2(-10.5, hem)]), trim)
		draw_line(Vector2(-3.5, top + 1.0), Vector2(-5.0, hem - 3.0), Color(clothes.darkened(0.3), 0.6), 1.0, true)
		draw_line(Vector2(3.0, top + 1.0), Vector2(4.5, hem - 3.0), Color(clothes.lightened(0.2), 0.5), 1.0, true)
	else:
		SmoothDraw.box(self, Rect2(-8.0, top, 16.0, hem - top + 2.0), clothes, 3.0)
	# Sash or belt.
	SmoothDraw.flat(self, Rect2(-8.0, top + 13.0, 16.0, 3.0), trim.darkened(0.25) if robe else Color("#3a2a1c"), 1.0)
	if armored:
		SmoothDraw.box(self, Rect2(-6.5, top + 1.0, 13.0, 11.0), STEEL, 3.0)
		draw_line(Vector2(0.0, top + 2.0), Vector2(0.0, top + 11.0), Color(STEEL.darkened(0.35), 0.7), 1.0, true)
	if bandaged:
		draw_line(Vector2(-7.5, top + 4.0), Vector2(7.5, top + 9.0), Color("#efe6d2"), 3.0, true)
		draw_circle(Vector2(2.0, top + 6.5), 1.6, Color("#a83226"), true, -1.0, true)


func _draw_arms(top: float, step: float) -> void:
	var sleeve := clothes.darkened(0.12)
	for side: float in [-1.0, 1.0]:
		var swing := -step * side * 2.0
		var arm := Rect2(side * 9.5 - 2.0, top + 1.0 + swing * 0.3, 4.0, 13.0)
		SmoothDraw.box(self, arm, STEEL if armored else sleeve, 2.0)
		if armored:
			SmoothDraw.dome(self, Vector2(side * 8.5, top + 1.5), 3.5, STEEL)
		draw_circle(Vector2(side * 9.5, arm.end.y + 0.5), 2.3, skin, true, -1.0, true)


func _draw_head(center: Vector2) -> void:
	var r := 6.5
	if headwear in [Headwear.HOOD, Headwear.FUR_HOOD]:
		var hood := clothes.darkened(0.1) if headwear == Headwear.HOOD else Color("#8c6a4a")
		draw_circle(center + Vector2(0.0, 0.5), r + 2.5, OUTLINE, true, -1.0, true)
		draw_circle(center + Vector2(0.0, 0.5), r + 1.8, hood, true, -1.0, true)
	draw_rect(Rect2(center.x - 2.0, center.y + 4.0, 4.0, 4.0), skin.darkened(0.15))
	SmoothDraw.dome(self, center, r, skin)
	if bandaged and headwear == Headwear.BALD:
		draw_line(center + Vector2(-6.5, -2.5), center + Vector2(6.5, -3.5), Color("#efe6d2"), 2.5, true)
	# Eyes, glancing the way they face.
	for side: float in [-1.0, 1.0]:
		draw_circle(center + Vector2(side * 2.3 + 0.8, 0.3), 0.9, OUTLINE, true, -1.0, true)
	if beard:
		SmoothDraw.polygon(self, PackedVector2Array([
			center + Vector2(-5.5, 1.5), center + Vector2(5.5, 1.5), center + Vector2(3.5, 7.0),
			center + Vector2(0.0, 9.0), center + Vector2(-3.5, 7.0),
		]), hair, OUTLINE, 1.0)
	match headwear:
		Headwear.HAIR:
			_draw_cap(center, r + 0.6, hair, 0.35)
		Headwear.BANDANA:
			_draw_cap(center, r + 0.6, hair, 0.35)
			SmoothDraw.flat(self, Rect2(center.x - 6.8, center.y - 4.5, 13.6, 2.6), trim, 1.0)
			draw_line(center + Vector2(-6.5, -3.0), center + Vector2(-10.0, 1.0), trim, 1.6, true)
		Headwear.HOOD:
			_draw_cap(center, r + 1.6, clothes.darkened(0.1), 0.15)
		Headwear.FUR_HOOD:
			_draw_cap(center, r + 1.6, Color("#8c6a4a"), 0.15)
			for index in 9:
				var angle := PI + PI * index / 8.0
				draw_circle(center + Vector2(cos(angle), sin(angle) * 1.05) * (r + 1.2), 2.2, Color("#ece6dc"), true, -1.0, true)
		Headwear.TURBAN:
			SmoothDraw.box(self, Rect2(center.x - 7.5, center.y - 9.5, 15.0, 7.5), trim, 3.5)
			draw_line(center + Vector2(-6.5, -6.0), center + Vector2(6.0, -8.5), Color(trim.darkened(0.25), 0.8), 1.0, true)
			draw_line(center + Vector2(-6.5, -4.0), center + Vector2(6.5, -6.0), Color(trim.darkened(0.25), 0.8), 1.0, true)
		Headwear.HELMET:
			_draw_cap(center, r + 1.0, STEEL, 0.2)
			draw_line(center + Vector2(0.8, -2.0), center + Vector2(0.8, 2.0), STEEL.darkened(0.3), 1.6, true)
			SmoothDraw.flat(self, Rect2(center.x - 7.5, center.y - 2.5, 15.0, 1.8), STEEL.darkened(0.25), 0.8)


## Hair or a hat covering the top of the head, down to `depth` of the way below its middle.
func _draw_cap(center: Vector2, radius: float, color: Color, depth: float) -> void:
	var points := PackedVector2Array()
	var steps := 16
	for index in steps + 1:
		var angle := PI - depth + (PI + depth * 2.0) * index / steps
		points.append(center + Vector2(cos(angle), sin(angle)) * radius + Vector2(0.0, -0.5))
	SmoothDraw.polygon(self, points, color, OUTLINE, 1.0)
	draw_circle(center + Vector2(-radius * 0.35, -radius * 0.55), radius * 0.25, Color(color.lightened(0.35), 0.6), true, -1.0, true)


## Long things held upright at the side: spears, staffs and torches.
func _draw_pole(top: float) -> void:
	var x := 10.5
	var tip_y := top - 22.0
	draw_line(Vector2(x, 1.0), Vector2(x, tip_y), OUTLINE, 3.2, true)
	draw_line(Vector2(x, 0.5), Vector2(x, tip_y + 0.5), WOOD, 1.8, true)
	match held:
		Held.SPEAR:
			SmoothDraw.polygon(self, PackedVector2Array([Vector2(x - 2.5, tip_y), Vector2(x, tip_y - 9.0), Vector2(x + 2.5, tip_y)]), STEEL, OUTLINE, 1.0)
		Held.STAFF:
			SmoothDraw.dome(self, Vector2(x, tip_y - 2.0), 3.0, trim)
		Held.TORCH:
			SmoothDraw.box(self, Rect2(x - 2.0, tip_y - 1.0, 4.0, 4.0), Color("#4a3322"), 1.0)
			_draw_flame(Vector2(x, tip_y - 1.0), 4.0, 9.0)


func _draw_held(top: float) -> void:
	var hand := Vector2(9.5, top + 15.0)
	match held:
		Held.ROD:
			var tip := Vector2(30.0, top - 14.0)
			draw_line(hand, tip, OUTLINE, 2.4, true)
			draw_line(hand, tip, WOOD.lightened(0.2), 1.2, true)
			var bob := sin(time * 1.8) * 1.2
			draw_line(tip, Vector2(34.0, 8.0 + bob), Color(0.9, 0.9, 0.95, 0.7), 0.8, true)
		Held.HAMMER:
			draw_line(hand, hand + Vector2(4.0, 10.0), WOOD, 2.2, true)
			SmoothDraw.box(self, Rect2(hand.x + 0.5, hand.y + 8.0, 8.0, 5.0), Color("#5a5f66"), 1.5)
		Held.BOWL:
			SmoothDraw.polygon(self, PackedVector2Array([Vector2(-7, top + 12), Vector2(7, top + 12), Vector2(4.5, top + 17), Vector2(-4.5, top + 17)]), Color("#a8673b"), OUTLINE, 1.0)
		Held.SWORD:
			draw_line(hand, hand + Vector2(1.0, 16.0), OUTLINE, 3.4, true)
			draw_line(hand, hand + Vector2(1.0, 16.0), STEEL.lightened(0.2), 2.0, true)
			draw_line(hand + Vector2(-3.0, 0.5), hand + Vector2(3.0, 0.5), Color("#6d5332"), 2.0, true)
		Held.LANTERN:
			var swing := sin(time * 1.5) * 1.0
			var lantern := Rect2(hand.x - 3.0 + swing, hand.y + 3.0, 6.0, 7.0)
			draw_line(hand, lantern.get_center() - Vector2(0, 3.5), OUTLINE, 1.0, true)
			SmoothDraw.box(self, lantern, Color("#3d3936"), 1.5)
			SmoothDraw.flat(self, lantern.grow(-1.3), Color("#ffe3a3"), 1.0)
		Held.SCROLL:
			SmoothDraw.box(self, Rect2(-6.0, top + 11.0, 12.0, 6.0), Color("#efe2c0"), 2.0)
			draw_line(Vector2(-4.0, top + 13.0), Vector2(4.0, top + 13.0), Color(OUTLINE, 0.5), 0.8, true)


func _draw_flame(base: Vector2, width: float, height: float) -> void:
	var flicker := sin(time * 13.0) * 0.8 + sin(time * 7.3) * 0.6
	var outer := PackedVector2Array([base + Vector2(-width, 0), base + Vector2(-width * 0.5, -height * 0.55), base + Vector2(flicker, -height - absf(flicker)), base + Vector2(width * 0.5, -height * 0.5), base + Vector2(width, 0)])
	draw_colored_polygon(outer, Color("#ff7a1f"))
	var inner := PackedVector2Array([base + Vector2(-width * 0.5, 0), base + Vector2(flicker * 0.5, -height * 0.6), base + Vector2(width * 0.5, 0)])
	draw_colored_polygon(inner, Color("#ffe28a"))
