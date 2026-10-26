extends RefCounted
class_name SmoothDraw
## Anti-aliased drawing helpers for hand-drawn scenery, in the same smooth, softly lit style as the HUD
## globes: rounded bevelled boxes, domed discs and soft drop shadows.

static var _boxes := {}


## A rounded box with a dark outline, lit from the top-left: a pale bevel along the top and a shaded lip
## along the bottom.
static func box(canvas: CanvasItem, rect: Rect2, color: Color, radius := 2.0, outline := Color(0.13, 0.08, 0.05), outline_width := 1.0) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var r := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	canvas.draw_style_box(_style(color, r, outline, outline_width), rect.grow(outline_width))
	var bevel := minf(rect.size.y * 0.35, 3.0)
	if bevel >= 1.0 and rect.size.x > 2.0:
		canvas.draw_style_box(_style(Color(color.lightened(0.35), 0.55), minf(r, bevel), Color(0, 0, 0, 0), 0.0), Rect2(rect.position + Vector2(0.5, 0.5), Vector2(rect.size.x - 1.0, bevel)))
		canvas.draw_style_box(_style(Color(color.darkened(0.35), 0.5), minf(r, bevel), Color(0, 0, 0, 0), 0.0), Rect2(Vector2(rect.position.x + 0.5, rect.end.y - bevel - 0.5), Vector2(rect.size.x - 1.0, bevel)))


## A flat rounded box with no shading.
static func flat(canvas: CanvasItem, rect: Rect2, color: Color, radius := 2.0) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	canvas.draw_style_box(_style(color, minf(radius, minf(rect.size.x, rect.size.y) * 0.5), Color(0, 0, 0, 0), 0.0), rect)


## A disc that looks domed: outline, base colour, a soft lit crown and a small highlight.
static func dome(canvas: CanvasItem, center: Vector2, radius: float, color: Color, outline := Color(0.13, 0.08, 0.05)) -> void:
	canvas.draw_circle(center, radius + 1.0, outline, true, -1.0, true)
	canvas.draw_circle(center, radius, color.darkened(0.15), true, -1.0, true)
	canvas.draw_circle(center + Vector2(-radius * 0.15, -radius * 0.18), radius * 0.72, color, true, -1.0, true)
	canvas.draw_circle(center + Vector2(-radius * 0.35, -radius * 0.38), radius * 0.22, Color(color.lightened(0.5), 0.8), true, -1.0, true)


## A soft shadow on the ground: stacked flattened ellipses fading out from the middle.
static func shadow(canvas: CanvasItem, center: Vector2, size: Vector2, strength := 0.22) -> void:
	# Built as polygons rather than with draw_set_transform, which would clobber the caller's transform.
	for layer in 4:
		var t := 1.0 - layer * 0.22
		var points := PackedVector2Array()
		for step in 24:
			var angle := TAU * step / 24.0
			points.append(center + Vector2(cos(angle) * size.x, sin(angle) * size.y) * 0.5 * t)
		canvas.draw_colored_polygon(points, Color(0.02, 0.07, 0.02, strength * 0.3))


## A filled polygon with an anti-aliased outline, which also smooths its edge.
static func polygon(canvas: CanvasItem, points: PackedVector2Array, color: Color, outline := Color(0.13, 0.08, 0.05), outline_width := 1.5) -> void:
	canvas.draw_colored_polygon(points, color)
	var closed := points.duplicate()
	closed.append(points[0])
	canvas.draw_polyline(closed, outline, outline_width, true)


static func _style(color: Color, radius: float, border: Color, border_width: float) -> StyleBoxFlat:
	var key := "%s|%.1f|%s|%.1f" % [color.to_html(), radius, border.to_html(), border_width]
	if _boxes.has(key):
		return _boxes[key]
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(int(ceilf(radius)))
	style.corner_detail = 6
	style.anti_aliasing = true
	style.anti_aliasing_size = 0.8
	if border_width > 0.0:
		style.border_color = border
		style.set_border_width_all(int(ceilf(border_width)))
		style.border_blend = false
	_boxes[key] = style
	return style
