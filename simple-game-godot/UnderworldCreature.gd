extends IceCreature
class_name UnderworldCreature
## Underworld monsters animate like the ice ones (atlas rows, art facing right), cast warm sooty shadows
## and, instead of a death animation, char black and crumble away in a burst of embers.

const SOOT_SHADOW := Color(0.08, 0.02, 0.02, 0.45)
const CHARRED := Color(0.22, 0.12, 0.1)
const CRUMBLE_TIME := 0.55
const ASH_FADE := 0.7


func _ready() -> void:
	shadow_color = SOOT_SHADOW
	super._ready()


func _leave_remains() -> void:
	var level := get_parent()
	if level == null:
		return
	var remains := Ashes.new()
	remains.position = position
	var body := Sprite2D.new()
	body.texture = sprite.texture
	body.texture_filter = sprite.texture_filter
	body.region_enabled = true
	body.region_rect = sprite.region_rect
	body.flip_h = sprite.flip_h
	body.scale = sprite.scale
	body.modulate = sprite.modulate
	# Pivot on the feet so it slumps down onto the ground.
	var feet := get_feet_position()
	body.offset = (sprite_base_position - feet) / sprite.scale
	body.position = feet
	remains.body = body
	remains.add_child(body)
	level.add_child.call_deferred(remains)
	FireShockwave.spawn.call_deferred(level, global_position + feet, shadow_width * 0.8)


## What is left when an underworld monster dies: it chars, slumps and blows away as ash.
class Ashes extends Node2D:
	var body: Sprite2D
	var time := 0.0
	var base_scale := Vector2.ONE
	var base_color := Color.WHITE

	func _ready() -> void:
		base_scale = body.scale
		base_color = body.modulate

	func _process(delta: float) -> void:
		time += delta
		var char_progress := clampf(time / CRUMBLE_TIME, 0.0, 1.0)
		body.modulate = base_color.lerp(CHARRED, char_progress)
		body.scale = Vector2(base_scale.x * (1.0 + char_progress * 0.15), base_scale.y * (1.0 - char_progress * 0.45))
		if time > CRUMBLE_TIME:
			body.modulate.a = 1.0 - (time - CRUMBLE_TIME) / ASH_FADE
			if body.modulate.a <= 0.0:
				queue_free()
