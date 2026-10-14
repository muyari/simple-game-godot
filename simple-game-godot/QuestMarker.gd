@tool
extends Node2D
class_name QuestMarker
## Pixel-art quest marker: gold "!" = quest available, grey "?" = in progress, gold "?" = ready to hand in.

enum Mode { HIDDEN, AVAILABLE, IN_PROGRESS, TURN_IN }

const OUTLINE := Color("#2a1a10")
const GOLD := Color("#ffd34d")
const GOLD_SHADE := Color("#c98a1b")
const SILVER := Color("#c9ced6")
const SILVER_SHADE := Color("#7f8794")

@export var mode := Mode.AVAILABLE:
	set(value):
		mode = value
		visible = mode != Mode.HIDDEN
		queue_redraw()

var animation_time := 0.0


func _process(delta: float) -> void:
	if mode == Mode.HIDDEN:
		return
	animation_time += delta
	queue_redraw()


const PIXEL := 2.5
const EXCLAMATION := [
	".##.",
	".##.",
	".##.",
	".##.",
	".##.",
	"....",
	".##.",
]
const QUESTION := [
	".####.",
	"##..##",
	"....##",
	"...##.",
	"..##..",
	"......",
	"..##..",
]


func _draw() -> void:
	var bob := roundf(sin(animation_time * 3.0) * 2.0)
	if mode == Mode.AVAILABLE:
		var pulse := 0.18 + sin(animation_time * 4.0) * 0.06
		draw_circle(Vector2(0, -9 + bob), 13.0, Color(GOLD, pulse))
		_draw_glyph(EXCLAMATION, bob, GOLD, GOLD_SHADE)
	elif mode == Mode.IN_PROGRESS:
		_draw_glyph(QUESTION, bob, SILVER, SILVER_SHADE)
	elif mode == Mode.TURN_IN:
		var pulse := 0.18 + sin(animation_time * 4.0) * 0.06
		draw_circle(Vector2(0, -9 + bob), 13.0, Color(GOLD, pulse))
		_draw_glyph(QUESTION, bob, GOLD, GOLD_SHADE)


## Draws a pixel glyph whose bottom edge sits at y = 0: an outline pass, then the fill with a shaded lower edge.
func _draw_glyph(rows: Array, bob: float, fill: Color, shade: Color) -> void:
	var width: int = rows[0].length()
	var origin := Vector2(-width * PIXEL / 2.0, -rows.size() * PIXEL + bob)
	for pass_index in 2:
		for row in rows.size():
			for column in width:
				if rows[row][column] != "#":
					continue
				var cell := Rect2(origin + Vector2(column, row) * PIXEL, Vector2.ONE * PIXEL)
				if pass_index == 0:
					draw_rect(cell.grow(1.0), OUTLINE)
					continue
				var below_empty: bool = row == rows.size() - 1 or rows[row + 1][column] != "#"
				draw_rect(cell, shade if below_empty else fill)
