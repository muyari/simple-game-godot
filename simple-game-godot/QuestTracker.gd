extends Control
class_name QuestTracker
## A gold arrow at the edge of the screen pointing toward the nearest place an active quest wants the
## player to go in the forest (see ForestQuests.get_tracked_target), labelled with the quest. The forest
## is endless and much alike, so this is how a site three regions away is found. Hidden once the spot is
## on screen; the quest's own "!" marker takes over from there.

## How far in from each screen edge the arrow keeps, clear of the HUD: the labels top left and the
## globes and skill bar along the bottom.
const EDGE_MARGINS := Rect2(70.0, 110.0, 70.0, 180.0)
const GOLD := Color("#ffd34d")
const OUTLINE := Color(0.13, 0.08, 0.05)

var label: Label
var target := {}
var arrow_position := Vector2.ZERO
var arrow_angle := 0.0
var time := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	label = Label.new()
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", GOLD)
	MenuStyle.outline_hud_label(label)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)


func _process(delta: float) -> void:
	time += delta
	target = {}
	var forest_quests := get_tree().get_first_node_in_group(ForestQuests.GROUP) as ForestQuests
	if forest_quests != null and is_instance_valid(forest_quests.player) and forest_quests.player.health > 0:
		target = forest_quests.get_tracked_target()
	var screen := get_viewport_rect().size
	var visible_target := false
	if not target.is_empty():
		var on_screen: Vector2 = get_viewport().get_canvas_transform() * Vector2(target["position"])
		var inner := Rect2(EDGE_MARGINS.position, screen - EDGE_MARGINS.position - EDGE_MARGINS.size)
		if inner.has_point(on_screen):
			target = {}
		else:
			visible_target = true
			var center := screen * 0.5
			var direction := (on_screen - center).normalized()
			arrow_angle = direction.angle()
			# Where the ray from the centre leaves the inner rectangle.
			var scale_x := (inner.size.x * 0.5) / maxf(absf(direction.x), 0.0001)
			var scale_y := (inner.size.y * 0.5) / maxf(absf(direction.y), 0.0001)
			arrow_position = center + direction * minf(scale_x, scale_y)
			label.text = target["label"]
			label.reset_size()
			var offset := -direction * 34.0 - label.size * 0.5
			label.position = (arrow_position + offset).clamp(Vector2(4, 4), screen - label.size - Vector2(4, 4))
	label.visible = visible_target
	queue_redraw()


func _draw() -> void:
	if target.is_empty():
		return
	var pulse := 1.0 + sin(time * 4.0) * 0.08
	var forward := Vector2.from_angle(arrow_angle)
	var side := forward.orthogonal()
	var tip := arrow_position + forward * 14.0 * pulse
	var points := PackedVector2Array([tip, arrow_position - forward * 8.0 + side * 11.0, arrow_position - forward * 3.0, arrow_position - forward * 8.0 - side * 11.0])
	draw_circle(arrow_position, 20.0, Color(GOLD, 0.16), true, -1.0, true)
	draw_colored_polygon(points, GOLD)
	var closed := points.duplicate()
	closed.append(points[0])
	draw_polyline(closed, OUTLINE, 2.0, true)
