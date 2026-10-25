extends VBoxContainer
class_name TargetHealthBar
## A large health bar at the top of the screen for the selected monster, with its name and what each of its
## modifiers does. Clicking (or tapping) a monster selects it; clicking another switches to that one. On
## touch screens, hitting a monster selects it too. The bar stays up until the selected monster dies.

const WIDTH := 460.0
const TOP_MARGIN := 18.0
const BAR_HEIGHT := 26.0
const FILL := Color("#7a0c12")
const FILL_LOW := Color("#b3161c")
const BACK := Color(0.12, 0.02, 0.02, 0.88)
const BORDER := Color("#2a0507")
## Below this fraction of health the fill brightens and pulses, and the frame glows red.
const LOW_HEALTH := 0.25
## Extra screen pixels around a monster's sprite that still count as clicking it.
const CLICK_PADDING := 6.0

var player: Player
var touch_mode := false
## The monster the player picked. It stays selected while it's alive, even while hidden (e.g. burrowed).
var selected: Wolf
var last_hit_seen: Wolf
var target: Wolf
var bar: ProgressBar
var fill_style: StyleBoxFlat
var frame: HealthBarFrame
var name_label: Label
var modifier_text: RichTextLabel
var pulse_time := 0.0


static func create(for_player: Player) -> TargetHealthBar:
	var target_bar := TargetHealthBar.new()
	target_bar.player = for_player
	target_bar.touch_mode = TouchControls.is_supported()
	return target_bar


func _ready() -> void:
	# GameUI keeps running while menus pause the game; this should freeze and hide with the world.
	process_mode = Node.PROCESS_MODE_PAUSABLE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	offset_left = -WIDTH * 0.5
	offset_right = WIDTH * 0.5
	offset_top = TOP_MARGIN
	# Room for the frame, which draws outside the bar.
	add_theme_constant_override("separation", 10)
	_build_bar()
	_build_modifier_text()
	hide()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED:
		hide()


## Runs before the player's click-to-move and leaves the click unhandled, so clicking a monster both
## selects it and moves toward it as before.
func _input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return
	if player == null or not is_instance_valid(player):
		return
	# A click on a HUD button over a monster is for the button.
	if get_viewport().gui_get_hovered_control() != null:
		return
	var clicked := _monster_at(player.get_global_mouse_position())
	if clicked != null:
		selected = clicked


func _process(delta: float) -> void:
	var next_target := _find_target()
	if next_target != target:
		target = next_target
		if target != null:
			_show_modifiers(target.modifier_ids)
	if target == null:
		hide()
		return
	pulse_time += delta
	_update_health()
	show()


func _find_target() -> Wolf:
	if player == null or not is_instance_valid(player) or player.health <= 0:
		return null
	if touch_mode and Wolf.last_hit != last_hit_seen:
		last_hit_seen = Wolf.last_hit
		if is_instance_valid(last_hit_seen):
			selected = last_hit_seen
	if not is_instance_valid(selected) or selected.health <= 0.0:
		selected = null
		return null
	return selected if _is_targetable(selected) else null


func _monster_at(point: Vector2) -> Wolf:
	var best: Wolf = null
	var best_distance := INF
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Wolf
		if enemy == null or not _is_targetable(enemy):
			continue
		var sprite := enemy.sprite
		var padding := CLICK_PADDING / maxf(sprite.global_transform.get_scale().x, 0.01)
		if not sprite.get_rect().grow(padding).has_point(sprite.to_local(point)):
			continue
		# Overlapping sprites: the monster whose body is closest to the click wins.
		var distance := enemy.global_position.distance_squared_to(point)
		if distance < best_distance:
			best = enemy
			best_distance = distance
	return best


static func _is_targetable(enemy: Wolf) -> bool:
	# Burrowed or otherwise hidden monsters can't be inspected.
	return enemy.health > 0.0 and enemy.is_inside_tree() and enemy.sprite.is_visible_in_tree()


func _update_health() -> void:
	var fraction := clampf(target.health / maxf(target.max_health, 0.001), 0.0, 1.0)
	bar.max_value = target.max_health
	bar.value = target.health
	if fraction <= LOW_HEALTH:
		var pulse := 0.5 + sin(pulse_time * 8.0) * 0.5
		fill_style.bg_color = FILL.lerp(FILL_LOW, pulse)
		frame.danger = pulse * 0.6
	else:
		fill_style.bg_color = FILL
		frame.danger = 0.0
	name_label.text = target.monster_name


func _show_modifiers(modifier_ids: Array[String]) -> void:
	if modifier_ids.is_empty():
		name_label.add_theme_color_override("font_color", MenuStyle.TEXT)
		modifier_text.hide()
		return
	var name_color := Wolf.MULTI_MODIFIER_LABEL_COLOR if modifier_ids.size() > 1 else Wolf.MODIFIER_LABEL_COLOR
	name_label.add_theme_color_override("font_color", name_color)
	var lines: PackedStringArray = []
	for modifier_id in modifier_ids:
		lines.append("[color=#%s]%s[/color]  [color=#%s]%s[/color]" % [
			name_color.to_html(false),
			MonsterModifiers.get_display_name(modifier_id),
			MenuStyle.TEXT.to_html(false),
			MonsterModifiers.get_description(modifier_id)
		])
	modifier_text.text = "[center]%s[/center]" % "\n".join(lines)
	modifier_text.show()


func _build_bar() -> void:
	bar = ProgressBar.new()
	bar.custom_minimum_size = Vector2(WIDTH, BAR_HEIGHT)
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var back := StyleBoxFlat.new()
	back.bg_color = BACK
	back.border_color = BORDER
	back.set_border_width_all(2)
	# Corners of half the height give the bar its long oval shape.
	back.set_corner_radius_all(ceili(BAR_HEIGHT * 0.5))
	back.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	back.shadow_size = 4
	bar.add_theme_stylebox_override("background", back)
	fill_style = StyleBoxFlat.new()
	fill_style.bg_color = FILL
	fill_style.border_color = Color(1.0, 0.45, 0.4, 0.22)
	fill_style.border_width_top = 2
	fill_style.set_corner_radius_all(ceili(BAR_HEIGHT * 0.5) - 2)
	fill_style.set_expand_margin_all(-2.0)
	bar.add_theme_stylebox_override("fill", fill_style)
	add_child(bar)

	frame = HealthBarFrame.new()
	bar.add_child(frame)

	name_label = Label.new()
	name_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	name_label.offset_left = 18.0
	name_label.offset_right = -18.0
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.add_theme_color_override("font_color", MenuStyle.TEXT)
	MenuStyle.outline_hud_label(name_label)
	bar.add_child(name_label)


func _build_modifier_text() -> void:
	modifier_text = RichTextLabel.new()
	modifier_text.bbcode_enabled = true
	modifier_text.fit_content = true
	modifier_text.scroll_active = false
	modifier_text.autowrap_mode = TextServer.AUTOWRAP_OFF
	modifier_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	modifier_text.add_theme_font_size_override("normal_font_size", 13)
	modifier_text.add_theme_constant_override("outline_size", 4)
	modifier_text.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.04, 0.9))
	modifier_text.hide()
	add_child(modifier_text)
