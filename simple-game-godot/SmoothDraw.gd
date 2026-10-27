extends RefCounted
class_name SmoothDraw
## Anti-aliased drawing helpers for hand-drawn scenery, in the same smooth, softly lit style as the HUD
## globes: rounded bevelled boxes, domed discs and soft drop shadows.

static var _disc: CanvasTexture
## The disc texture's radius in texels; its mipmaps keep the edge about a screen pixel soft at any size.
const DISC_RADIUS := 128
## draw_circle()'s anti-aliasing feathers out past the radius, so its circles read about this much bigger (in
## local units, at any zoom); disc() matches it so small circles (eyes, wheat heads) keep their size.
const AA_GROWTH := 0.35


## Whether an animated drawing is on screen (or within `margin` screen pixels of it) and worth redrawing.
## Filled shapes (circles, polygons, rounded boxes) cost the renderer far more than lines and rects, so
## scenery that redraws every frame should skip it while out of view.
static func is_on_screen(item: CanvasItem, margin := 200.0) -> bool:
	return item.get_viewport_rect().grow(margin).has_point(item.get_global_transform_with_canvas().origin)


## A rounded box with a dark outline, lit from the top-left: a pale bevel along the top and a shaded lip
## along the bottom.
static func box(canvas: CanvasItem, rect: Rect2, color: Color, radius := 2.0, outline := Color(0.13, 0.08, 0.05), outline_width := 1.0) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var r := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	# The outline is the box grown by its width, with the fill's corners rounded that much less.
	if outline.a > 0.0 and outline_width > 0.0:
		rounded_rect(canvas, rect.grow(outline_width), r, outline)
	rounded_rect(canvas, rect, maxf(r - outline_width, 0.0), color)
	var bevel := minf(rect.size.y * 0.35, 3.0)
	if bevel >= 1.0 and rect.size.x > 2.0:
		rounded_rect(canvas, Rect2(rect.position + Vector2(0.5, 0.5), Vector2(rect.size.x - 1.0, bevel)), minf(r, bevel), Color(color.lightened(0.35), 0.55))
		rounded_rect(canvas, Rect2(Vector2(rect.position.x + 0.5, rect.end.y - bevel - 0.5), Vector2(rect.size.x - 1.0, bevel)), minf(r, bevel), Color(color.darkened(0.35), 0.5))


## A flat rounded box with no shading.
static func flat(canvas: CanvasItem, rect: Rect2, color: Color, radius := 2.0) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	rounded_rect(canvas, rect, radius, color)


## A disc that looks domed: outline, base colour, a soft lit crown and a small highlight.
static func dome(canvas: CanvasItem, center: Vector2, radius: float, color: Color, outline := Color(0.13, 0.08, 0.05)) -> void:
	disc(canvas, center, radius + 1.0, outline)
	disc(canvas, center, radius, color.darkened(0.15))
	disc(canvas, center + Vector2(-radius * 0.15, -radius * 0.18), radius * 0.72, color)
	disc(canvas, center + Vector2(-radius * 0.35, -radius * 0.38), radius * 0.22, Color(color.lightened(0.5), 0.8))


## A soft shadow on the ground: stacked flattened ellipses fading out from the middle.
static func shadow(canvas: CanvasItem, center: Vector2, size: Vector2, strength := 0.22) -> void:
	for layer in 4:
		ellipse(canvas, center, size * 0.5 * (1.0 - layer * 0.22), Color(0.02, 0.07, 0.02, strength * 0.3))


## A filled anti-aliased circle, like draw_circle(center, radius, color, true, -1.0, true) but drawn as a
## textured rect. Filled shapes are rebuilt as new geometry every time a canvas item redraws, which made
## animated scenery (the hubs' townsfolk and props, Oblath's wheat field) cost tens of milliseconds a
## frame; textured rects batch and cost next to nothing.
static func disc(canvas: CanvasItem, center: Vector2, radius: float, color: Color) -> void:
	ellipse(canvas, center, Vector2.ONE * (radius + AA_GROWTH), color)


## A filled anti-aliased axis-aligned ellipse with half-size `radii`, drawn like disc().
static func ellipse(canvas: CanvasItem, center: Vector2, radii: Vector2, color: Color) -> void:
	if radii.x <= 0.0 or radii.y <= 0.0:
		return
	canvas.draw_texture_rect(_disc_texture(), Rect2(center - radii, radii * 2.0), false, color)


static func _disc_texture() -> CanvasTexture:
	if _disc == null:
		var size := DISC_RADIUS * 2
		var image := Image.create(size, size, false, Image.FORMAT_LA8)
		var middle := Vector2(DISC_RADIUS, DISC_RADIUS)
		for y in size:
			for x in size:
				var coverage := clampf(DISC_RADIUS - Vector2(x + 0.5, y + 0.5).distance_to(middle), 0.0, 1.0)
				image.set_pixel(x, y, Color(1.0, 1.0, 1.0, coverage))
		image.generate_mipmaps()
		_disc = CanvasTexture.new()
		_disc.diffuse_texture = ImageTexture.create_from_image(image)
		# Its own filter, so it stays smooth whatever the canvas item drawing it uses.
		# Anisotropic, so discs squashed into ellipses (wheat heads) aren't blurred across their width.
		_disc.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return _disc


## A filled rounded rect with anti-aliased edges, cut from the disc texture in nine pieces that don't
## overlap (so translucent colours stay even): its quarters for the corners, its edges stretched along
## the sides and its middle for the rest. Like disc(), far cheaper than a rounded StyleBoxFlat.
static func rounded_rect(canvas: CanvasItem, rect: Rect2, radius: float, color: Color) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var r := clampf(radius, 0.0, minf(rect.size.x, rect.size.y) * 0.5)
	if r <= 0.0:
		canvas.draw_rect(rect, color)
		return
	var texture := _disc_texture()
	var xs: Array[float] = [rect.position.x, rect.position.x + r, rect.end.x - r, rect.end.x]
	var ys: Array[float] = [rect.position.y, rect.position.y + r, rect.end.y - r, rect.end.y]
	# Where those bands come from in the texture; the middle band is a sliver through its centre.
	var uvs: Array[float] = [0.0, DISC_RADIUS - 1.0, DISC_RADIUS + 1.0, DISC_RADIUS * 2.0]
	for row in 3:
		for column in 3:
			var piece := Rect2(xs[column], ys[row], xs[column + 1] - xs[column], ys[row + 1] - ys[row])
			if piece.size.x <= 0.0 or piece.size.y <= 0.0:
				continue
			var source := Rect2(uvs[column], uvs[row], uvs[column + 1] - uvs[column], uvs[row + 1] - uvs[row])
			canvas.draw_texture_rect_region(texture, piece, source, color)


## A filled polygon with an anti-aliased outline, which also smooths its edge.
static func polygon(canvas: CanvasItem, points: PackedVector2Array, color: Color, outline := Color(0.13, 0.08, 0.05), outline_width := 1.5) -> void:
	canvas.draw_colored_polygon(points, color)
	var closed := points.duplicate()
	closed.append(points[0])
	canvas.draw_polyline(closed, outline, outline_width, true)

