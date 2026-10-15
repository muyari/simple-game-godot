extends Wolf
class_name DesertCreature
## Desert monsters animate from a single strip of frames drawn facing left; the sprite is mirrored when
## the monster faces right and keeps its last side while moving straight up or down.

## Size of one frame in the strip, in texture pixels.
@export var frame_size := Vector2i(80, 82)
@export var idle_frames := PackedInt32Array([0])
@export var move_frames := PackedInt32Array([0])
## Played across the attack wind-up and strike, evenly spaced.
@export var attack_frames := PackedInt32Array([0])
@export var idle_frame_duration := 0.3
@export var move_frame_duration := 0.1
## Vertical bob while moving, in pixels.
@export var move_bob := 1.5

var facing_left := true


func _ready() -> void:
	super._ready()
	# A sun shadow under the art's feet (the bottom of the frame).
	var feet := sprite.position + Vector2(0.0, frame_size.y * sprite.scale.y * 0.5 - 3.0)
	SunShadow.attach(self, feet, frame_size.x * sprite.scale.x * 0.8, false)


func _update_sprite(delta: float) -> void:
	animation_time += delta
	if facing.x != 0.0:
		facing_left = facing.x < 0.0
	sprite.flip_h = not facing_left
	sprite.position = sprite_base_position
	var is_moving := velocity.length_squared() > 0.0 \
			and attack_animation_time_remaining == 0.0
	var frame := _pick_frame(is_moving)
	sprite.region_rect = Rect2(frame * frame_size.x, 0, frame_size.x, frame_size.y)


func _pick_frame(is_moving: bool) -> int:
	if attack_animation_time_remaining > 0.0:
		var progress := 1.0 - attack_animation_time_remaining / ATTACK_ANIMATION_DURATION
		return _frame_at(attack_frames, progress)
	if is_moving:
		sprite.position.y -= absf(sin(animation_time * PI / move_frame_duration)) * move_bob
		return move_frames[int(animation_time / move_frame_duration) % move_frames.size()]
	return idle_frames[int(animation_time / idle_frame_duration) % idle_frames.size()]


## The frame a fraction (0 to 1) of the way through a sequence.
func _frame_at(frames: PackedInt32Array, progress: float) -> int:
	return frames[clampi(int(progress * frames.size()), 0, frames.size() - 1)]
