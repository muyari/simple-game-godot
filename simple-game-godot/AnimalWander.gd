extends CharacterBody2D

@export var walk_frames: Array[Texture2D] = []
@export var idle_frames: Array[Texture2D] = []
@export var walk_faces_right := true
@export var idle_faces_right := true
@export var speed := 30.0
@export var wander_radius := 120.0
@export var frame_time := 0.18
@export var idle_time := Vector2(1.5, 4.0)
@export var walk_time := Vector2(1.0, 3.0)

@onready var _sprite: Sprite2D = $Sprite2D

var _home := Vector2.ZERO
var _direction := Vector2.ZERO
var _timer := 0.0
var _frame_clock := 0.0
var _frame := 0
var _facing_right := true
var _walking := false


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_home = global_position
	_start_idle()


func _physics_process(delta: float) -> void:
	_timer -= delta
	if _walking:
		velocity = _direction * speed
		move_and_slide()
		if get_slide_collision_count() > 0 or _timer <= 0.0:
			_start_idle()
	elif _timer <= 0.0:
		_start_walk()
	_animate(delta)


func _start_idle() -> void:
	_walking = false
	velocity = Vector2.ZERO
	_timer = randf_range(idle_time.x, idle_time.y)
	_frame = 0


func _start_walk() -> void:
	_walking = true
	_timer = randf_range(walk_time.x, walk_time.y)
	var angle := randf() * TAU
	_direction = Vector2.from_angle(angle)
	if global_position.distance_to(_home) > wander_radius:
		_direction = (_home - global_position).normalized().rotated(randf_range(-0.5, 0.5))
	if absf(_direction.x) > 0.1:
		_facing_right = _direction.x > 0.0
	_frame = 0


func _animate(delta: float) -> void:
	var frames := walk_frames if _walking else idle_frames
	if frames.is_empty():
		return
	_frame_clock += delta
	if _frame_clock >= frame_time:
		_frame_clock = 0.0
		_frame = (_frame + 1) % frames.size()
	_frame = mini(_frame, frames.size() - 1)
	var texture := frames[_frame]
	_sprite.texture = texture
	_sprite.offset = Vector2(0, -texture.get_height() / 2.0)
	var faces_right := walk_faces_right if _walking else idle_faces_right
	_sprite.flip_h = _facing_right != faces_right
