extends Wolf
class_name IceCreature
## Ice monsters animate from an atlas with one row per animation. Every cell is the same size with the
## feet at its bottom centre, and the art faces right: the sprite is mirrored when the monster faces left
## and keeps its last side while moving straight up or down. Hits flash the hurt pose, and on death the
## death animation plays out where the monster fell.

const SHADOW_COLOR := Color(0.16, 0.27, 0.45, 0.32)
const HURT_TIME := 0.24
const DEATH_FRAME_DURATION := 0.13
## How long the last death frame stays before fading, and the fade itself, in seconds.
const REMAINS_HOLD := 1.4
const REMAINS_FADE := 0.8

## Size of one atlas cell, in texture pixels.
@export var frame_size := Vector2i(160, 100)
## Animation name -> Vector2i(row, frame count). Expects at least "idle", "walk" and "death".
@export var animations := {}
@export var idle_frame_duration := 0.28
@export var walk_frame_duration := 0.12
## Walk frames from this index on are drawn side-on and used when moving mostly sideways; the earlier
## ones face the camera. -1 plays every walk frame in every direction.
@export var side_walk_start := -1
## Ground shadow colour; cold blue on snow by default.
@export var shadow_color := SHADOW_COLOR
## Width of the ground shadow, in local pixels.
@export var shadow_width := 60.0

var facing_left := false
var hurt_time_remaining := 0.0
## While set, the sprite holds column `action_column` of this animation instead of idling or walking.
var action_animation := ""
var action_column := 0


func _ready() -> void:
	super._ready()
	SunShadow.attach(self, get_feet_position(), shadow_width, false, shadow_color)
	died.connect(_leave_remains)


## The point under the art's feet, in local coordinates.
func get_feet_position() -> Vector2:
	return sprite.position + Vector2(0.0, (frame_size.y * 0.5 - 2.0) * sprite.scale.y)


func take_damage(amount: float) -> void:
	var health_before := health
	super.take_damage(amount)
	if health > 0.0 and health < health_before:
		hurt_time_remaining = HURT_TIME


## Shows one frame of an action (an attack or the like) until clear_action() is called.
func show_action(animation_name: String, column: int) -> void:
	action_animation = animation_name
	var frames: Vector2i = animations[animation_name]
	action_column = clampi(column, 0, frames.y - 1)


## Shows the frame `progress` (0 to 1) of the way through an action's animation.
func show_action_progress(animation_name: String, progress: float) -> void:
	var frames: Vector2i = animations[animation_name]
	show_action(animation_name, int(clampf(progress, 0.0, 0.999) * frames.y))


func clear_action() -> void:
	action_animation = ""


func _update_sprite(delta: float) -> void:
	animation_time += delta
	hurt_time_remaining = maxf(hurt_time_remaining - delta, 0.0)
	if facing.x != 0.0:
		facing_left = facing.x < 0.0
	sprite.flip_h = facing_left
	sprite.position = sprite_base_position
	var frame := _pick_frame(velocity.length_squared() > 0.0)
	sprite.region_rect = Rect2(Vector2(frame * frame_size), Vector2(frame_size))


## The atlas cell (column, row) to show this frame.
func _pick_frame(is_moving: bool) -> Vector2i:
	if action_animation != "":
		return Vector2i(action_column, animations[action_animation].x)
	if hurt_time_remaining > 0.0 and animations.has("hurt"):
		var hurt: Vector2i = animations["hurt"]
		var progress := 1.0 - hurt_time_remaining / HURT_TIME
		return Vector2i(mini(int(progress * hurt.y), hurt.y - 1), hurt.x)
	if is_moving:
		return _walk_frame()
	var idle: Vector2i = animations["idle"]
	return Vector2i(int(animation_time / idle_frame_duration) % idle.y, idle.x)


func _walk_frame() -> Vector2i:
	var walk: Vector2i = animations["walk"]
	var first := 0
	var count := walk.y
	if side_walk_start > 0:
		if absf(velocity.x) > absf(velocity.y):
			first = side_walk_start
			count = walk.y - side_walk_start
		else:
			count = side_walk_start
	return Vector2i(first + int(animation_time / walk_frame_duration) % count, walk.x)


func _leave_remains() -> void:
	var level := get_parent()
	if level == null or not animations.has("death"):
		return
	var remains := Remains.new()
	remains.frames = animations["death"]
	remains.frame_size = frame_size
	remains.position = position
	var body := Sprite2D.new()
	body.texture = sprite.texture
	body.texture_filter = sprite.texture_filter
	body.region_enabled = true
	body.flip_h = sprite.flip_h
	body.position = sprite_base_position
	body.scale = sprite.scale
	body.modulate = sprite.modulate
	remains.body = body
	remains.add_child(body)
	level.add_child.call_deferred(remains)


## The death animation, left behind in the level when the monster itself is freed.
class Remains extends Node2D:
	var body: Sprite2D
	var frames := Vector2i.ZERO
	var frame_size := Vector2i.ZERO
	var time := 0.0

	func _ready() -> void:
		_process(0.0)

	func _process(delta: float) -> void:
		time += delta
		var column := mini(int(time / DEATH_FRAME_DURATION), frames.y - 1)
		body.region_rect = Rect2(Vector2(column * frame_size.x, frames.x * frame_size.y), Vector2(frame_size))
		var fade_start := frames.y * DEATH_FRAME_DURATION + REMAINS_HOLD
		if time > fade_start:
			modulate.a = 1.0 - (time - fade_start) / REMAINS_FADE
			if modulate.a <= 0.0:
				queue_free()
