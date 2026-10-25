extends RefCounted
class_name LootFx
## Drawing helpers shared by gold and gear drops. Everything is plain canvas drawing (no shaders or
## GPU particles) so drops look the same on the desktop renderer and on Android's compatibility renderer.

## How long a fresh drop spends hopping out of the monster before it can be picked up.
const DROP_TIME := 0.55
const HOP_HEIGHT := 34.0
const BOUNCE_HEIGHT := 6.0
const ELLIPSE_STEPS := 20


## Where a dropping item is drawn relative to where it will land, `progress` running 0..1: an arc out of
## `from_offset` (the monster, relative to the landing spot) and one small bounce on touching down.
static func hop_offset(from_offset: Vector2, progress: float) -> Vector2:
	progress = clampf(progress, 0.0, 1.0)
	const ARC_SHARE := 0.75
	if progress < ARC_SHARE:
		var arc := progress / ARC_SHARE
		var travel := 1.0 - pow(1.0 - arc, 2.0)
		return from_offset * (1.0 - travel) + Vector2(0.0, -sin(arc * PI) * HOP_HEIGHT)
	var bounce := (progress - ARC_SHARE) / (1.0 - ARC_SHARE)
	return Vector2(0.0, -sin(bounce * PI) * BOUNCE_HEIGHT)


static func ellipse_points(center: Vector2, radii: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	points.resize(ELLIPSE_STEPS)
	for step in ELLIPSE_STEPS:
		var angle := TAU * step / ELLIPSE_STEPS
		points[step] = center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y)
	return points


## A pool of light on the ground, brightest in the middle.
static func draw_ground_glow(canvas: CanvasItem, center: Vector2, radii: Vector2, color: Color, strength: float) -> void:
	for layer in 3:
		var layer_scale := 1.0 - layer * 0.28
		canvas.draw_colored_polygon(ellipse_points(center, radii * layer_scale), Color(color, strength * 0.26))


## A column of light rising from the drop so good loot can be spotted from across the screen.
static func draw_light_beam(canvas: CanvasItem, base: Vector2, width: float, height: float, color: Color, strength: float) -> void:
	for layer in 2:
		var half_width := width * (0.5 if layer == 0 else 0.22)
		var alpha := strength * (0.3 if layer == 0 else 0.5)
		var points := PackedVector2Array([
			base + Vector2(-half_width, 0.0),
			base + Vector2(half_width, 0.0),
			base + Vector2(half_width * 0.6, -height),
			base + Vector2(-half_width * 0.6, -height)
		])
		var colors := PackedColorArray([
			Color(color, alpha),
			Color(color, alpha),
			Color(color, 0.0),
			Color(color, 0.0)
		])
		canvas.draw_polygon(points, colors)


## A four-pointed twinkle.
static func draw_sparkle(canvas: CanvasItem, center: Vector2, size: float, color: Color) -> void:
	if size <= 0.2 or color.a <= 0.01:
		return
	canvas.draw_line(center + Vector2(-size, 0.0), center + Vector2(size, 0.0), color, 1.0)
	canvas.draw_line(center + Vector2(0.0, -size), center + Vector2(0.0, size), color, 1.0)
	canvas.draw_rect(Rect2(center - Vector2.ONE * 0.75, Vector2.ONE * 1.5), Color(Color.WHITE, color.a))


## Twinkles drifting up around a drop. Positions come from the time and the index, so nothing is allocated
## per frame.
static func draw_rising_sparkles(
	canvas: CanvasItem,
	center: Vector2,
	spread: Vector2,
	count: int,
	time: float,
	color: Color
) -> void:
	for index in count:
		var cycle := fposmod(time * 0.55 + index * 0.618, 1.0)
		var column := sin(index * 12.9898) * 0.5
		var sway := sin(time * 2.0 + index * 1.7) * 2.0
		var point := center + Vector2(column * spread.x * 2.0 + sway, spread.y * 0.5 - cycle * spread.y)
		var fade := sin(cycle * PI)
		draw_sparkle(canvas, point, 1.5 + fade * 2.0, Color(color.lightened(0.35), fade))
