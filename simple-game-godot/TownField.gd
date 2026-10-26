extends Node2D
class_name TownField
## A tilled plot drawn flat on the ground, smooth like the HUD: rounded soil beds with soft furrows and
## rows of crops (wheat that sways, cabbages or pumpkins) inside a grassy margin. Fully determined by
## `seed_value`.

enum Crop { WHEAT, CABBAGE, PUMPKIN }

const SOIL := Color("#5c4128")
const SOIL_DARK := Color("#432e1b")
const SOIL_LIGHT := Color("#75553a")
const MARGIN := Color(0.3, 0.42, 0.17, 0.55)
const WHEAT := Color("#ddba55")
const WHEAT_DARK := Color("#a8862e")
const LEAF := Color("#62a03c")
const LEAF_DARK := Color("#3f6e27")
const PUMPKIN := Color("#e38a2e")
const ROW_SPACING := 22.0

var size := Vector2(300, 180)
var crop := Crop.WHEAT
var seed_value := 0
var time := 0.0


func _ready() -> void:
	set_process(crop == Crop.WHEAT)


func _process(delta: float) -> void:
	time += delta
	queue_redraw()


func _draw() -> void:
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	var rect := Rect2(-size * 0.5, size)
	SmoothDraw.flat(self, rect.grow(7.0), MARGIN, 10.0)
	SmoothDraw.flat(self, rect, SOIL, 8.0)
	var y := rect.position.y + ROW_SPACING * 0.5
	while y < rect.end.y - 4.0:
		# A raised bed: light crest, dark furrow below.
		SmoothDraw.flat(self, Rect2(rect.position.x + 6, y - 4, rect.size.x - 12, 3), Color(SOIL_LIGHT, 0.8), 1.5)
		SmoothDraw.flat(self, Rect2(rect.position.x + 6, y + 4, rect.size.x - 12, 4), Color(SOIL_DARK, 0.85), 2.0)
		var x := rect.position.x + 12.0
		while x < rect.end.x - 8.0:
			var spot := Vector2(x + random.randf_range(-2, 2), y)
			match crop:
				Crop.WHEAT:
					_draw_wheat(spot, random)
				Crop.CABBAGE:
					SmoothDraw.dome(self, spot, 5.5 * random.randf_range(0.85, 1.15), LEAF, LEAF_DARK.darkened(0.3))
				Crop.PUMPKIN:
					if random.randf() < 0.45:
						_draw_pumpkin(spot, random)
					else:
						draw_circle(spot + Vector2(-3, 0), 3.0, LEAF_DARK, true, -1.0, true)
						draw_circle(spot + Vector2(3, -1), 3.0, LEAF, true, -1.0, true)
			x += 12.0 if crop == Crop.WHEAT else 18.0
		y += ROW_SPACING


func _draw_wheat(base: Vector2, random: RandomNumberGenerator) -> void:
	# Stalks lean in the wind; heads at the top.
	var sway := sin(time * 1.6 + base.x * 0.04 + base.y * 0.02) * 2.0
	for stalk in 3:
		var root := base + Vector2(stalk * 3.0 - 3.0, 2.0)
		var top := root + Vector2(sway + random.randf_range(-1, 1), -14.0 - random.randf_range(0, 4))
		draw_line(root, top, WHEAT_DARK, 1.2, true)
		draw_set_transform(top + Vector2(0, -2), (top - root).angle() + PI * 0.5, Vector2(1.0, 2.2))
		draw_circle(Vector2.ZERO, 1.6, WHEAT, true, -1.0, true)
		draw_set_transform(Vector2.ZERO)


func _draw_pumpkin(base: Vector2, random: RandomNumberGenerator) -> void:
	var radius := 7.0 * random.randf_range(0.8, 1.2)
	draw_set_transform(base, 0.0, Vector2(1.0, 0.78))
	SmoothDraw.dome(self, Vector2.ZERO, radius, PUMPKIN)
	draw_arc(Vector2.ZERO, radius * 0.55, PI * 0.6, PI * 1.4, 10, Color(PUMPKIN.darkened(0.3), 0.6), 1.0, true)
	draw_arc(Vector2.ZERO, radius * 0.55, -PI * 0.4, PI * 0.4, 10, Color(PUMPKIN.darkened(0.3), 0.6), 1.0, true)
	draw_set_transform(Vector2.ZERO)
	SmoothDraw.flat(self, Rect2(base + Vector2(-1, -radius * 0.78 - 3.0), Vector2(2, 4)), LEAF_DARK, 1.0)
