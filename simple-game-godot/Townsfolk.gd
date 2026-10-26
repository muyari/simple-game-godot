extends CharacterBody2D
class_name Townsfolk
## A villager going about her day: strolls between spots in her part of town, pauses to look about, and
## stops to face the player when they come close. The sheet has poses rather than walk cycles, so steps
## are a bob and sway on the front, back or side pose for the way she's heading.

const STEP_RATE := 9.0
const STEP_HEIGHT := 2.2
const GREET_DISTANCE := 70.0
const ARRIVE_DISTANCE := 6.0

@export var front_frames: Array[Texture2D] = []
@export var back_frame: Texture2D
@export var side_frames: Array[Texture2D] = []
## Which way the side poses face in the art; mirrored for the other way.
@export var side_faces_right := true
@export var speed := 34.0
## Where she wanders, in world pixels. Empty keeps her standing where she is.
@export var area := Rect2()
@export var pause_time := Vector2(1.5, 5.0)
@export var sprite_scale := 0.62

var player: Node2D
var sprite: Sprite2D
var target := Vector2.ZERO
var pause_left := 0.0
var walking := false
var time := 0.0
var heading := Vector2.DOWN
var stuck_time := 0.0


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_mask = 1
	sprite = Sprite2D.new()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE * sprite_scale
	sprite.texture = front_frames[0]
	sprite.offset = Vector2(0.0, -sprite.texture.get_height() * 0.5)
	add_child(sprite)
	var shape := CollisionShape2D.new()
	var capsule := CircleShape2D.new()
	capsule.radius = 8.0
	shape.shape = capsule
	shape.position = Vector2(0.0, -4.0)
	add_child(shape)
	SunShadow.attach(self, Vector2(0.0, -1.0), 30.0, false, TownDecor.GRASS_SHADOW)
	player = get_tree().current_scene.get_node_or_null("Player") as Node2D
	if player is PhysicsBody2D:
		add_collision_exception_with(player)
	time = randf() * 10.0
	pause_left = randf_range(0.2, pause_time.y)


func _physics_process(delta: float) -> void:
	time += delta
	var near_player := player != null and global_position.distance_to(player.global_position) < GREET_DISTANCE
	if near_player:
		# Stops for a chat, facing the player.
		walking = false
		velocity = Vector2.ZERO
		heading = (player.global_position - global_position).normalized()
	elif walking:
		var to_target := target - global_position
		if to_target.length() <= ARRIVE_DISTANCE:
			_stop()
		else:
			heading = to_target.normalized()
			velocity = heading * speed
			var before := global_position
			move_and_slide()
			# Walked into something: give up on this spot.
			stuck_time = stuck_time + delta if global_position.distance_to(before) < speed * delta * 0.3 else 0.0
			if stuck_time > 0.4:
				_stop()
	else:
		velocity = Vector2.ZERO
		pause_left -= delta
		if pause_left <= 0.0 and area.has_area():
			_start_walk()
	_animate()


func _start_walk() -> void:
	for _attempt in 8:
		var spot := Vector2(randf_range(area.position.x, area.end.x), randf_range(area.position.y, area.end.y))
		if spot.distance_to(global_position) > 40.0:
			target = spot
			walking = true
			stuck_time = 0.0
			return
	pause_left = 1.0


func _stop() -> void:
	walking = false
	velocity = Vector2.ZERO
	pause_left = randf_range(pause_time.x, pause_time.y)
	heading = Vector2.DOWN


func _animate() -> void:
	var sideways := absf(heading.x) > absf(heading.y) * 1.2
	var step := int(time * STEP_RATE / PI) % 2
	if sideways and not side_frames.is_empty():
		sprite.texture = side_frames[step % side_frames.size()] if walking else side_frames[0]
		sprite.flip_h = (heading.x > 0.0) != side_faces_right
	elif heading.y < 0.0 and back_frame != null and walking:
		sprite.texture = back_frame
		sprite.flip_h = step == 1
	else:
		# Facing the camera: alternate the two front poses slowly while standing, on each step while walking.
		var index := step if walking else int(time / 1.6) % front_frames.size()
		sprite.texture = front_frames[index % front_frames.size()]
		sprite.flip_h = false
	sprite.offset = Vector2(0.0, -sprite.texture.get_height() * 0.5)
	if walking:
		sprite.position = Vector2(sin(time * STEP_RATE * 0.5) * 0.8, -absf(sin(time * STEP_RATE)) * STEP_HEIGHT)
		sprite.rotation = sin(time * STEP_RATE) * 0.03
	else:
		sprite.position = Vector2.ZERO
		sprite.rotation = 0.0
