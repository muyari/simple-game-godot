extends CharacterBody2D
class_name Wolf

signal died


const CHASE_SPEED = 110.0
const ATTACK_RANGE = 78.0
const ATTACK_DAMAGE = 20
const WINDUP_TIME = 0.35
const ATTACK_COOLDOWN = 0.9
const SWIPE_VISIBLE_TIME = 0.18
const FRAME_SIZE = 64
const WALK_FRAME_DURATION = 0.15
const MAX_HEALTH = 3.0

enum State { CHASING, WINDING_UP, COOLDOWN }

@export var target_path: NodePath = NodePath("../Player")

@onready var swipe: Line2D = $Swipe
@onready var sprite: Sprite2D = $Sprite2D
@onready var health_bar: ProgressBar = $HealthBar

var target: Player
@export var max_health: float = MAX_HEALTH
@export var attack_damage: int = ATTACK_DAMAGE
@export_range(1, 10000, 1) var experience_reward := 15

var health: float
var state := State.CHASING
var state_timer := 0.0
var swipe_timer := 0.0
var facing := Vector2.RIGHT
var animation_time := 0.0


func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	health_bar.max_value = max_health
	health_bar.value = health
	target = get_node_or_null(target_path) as Player
	if target == null:
		push_error("Wolf could not find its player target at %s." % target_path)


func _physics_process(delta: float) -> void:
	if swipe_timer > 0.0:
		swipe_timer -= delta
		if swipe_timer <= 0.0:
			swipe.hide()

	if target == null or not is_instance_valid(target):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var to_target := target.global_position - global_position
	match state:
		State.CHASING:
			if to_target.length() <= ATTACK_RANGE:
				state = State.WINDING_UP
				state_timer = WINDUP_TIME
				velocity = Vector2.ZERO
			else:
				facing = _cardinal_direction(to_target)
				velocity = to_target.normalized() * CHASE_SPEED
		State.WINDING_UP:
			velocity = Vector2.ZERO
			facing = _cardinal_direction(to_target)
			state_timer -= delta
			if state_timer <= 0.0:
				if to_target.length() <= ATTACK_RANGE:
					target.take_damage(attack_damage)
					swipe.rotation = facing.angle()
					swipe.show()
					swipe_timer = SWIPE_VISIBLE_TIME
				state = State.COOLDOWN
				state_timer = ATTACK_COOLDOWN
		State.COOLDOWN:
			velocity = Vector2.ZERO
			state_timer -= delta
			if state_timer <= 0.0:
				state = State.CHASING

	_update_sprite(delta)
	move_and_slide()


func _cardinal_direction(direction: Vector2) -> Vector2:
	if absf(direction.x) > absf(direction.y):
		return Vector2.RIGHT if direction.x > 0.0 else Vector2.LEFT
	return Vector2.DOWN if direction.y > 0.0 else Vector2.UP


func _update_sprite(delta: float) -> void:
	var row := 0
	if facing == Vector2.LEFT:
		row = 1
	elif facing == Vector2.RIGHT:
		row = 2
	elif facing == Vector2.UP:
		row = 3

	var frame := 0
	if state == State.CHASING and velocity.length_squared() > 0.0:
		animation_time += delta
		frame = 1 + (int(animation_time / WALK_FRAME_DURATION) % 3)
	else:
		animation_time = 0.0
	sprite.region_rect = Rect2(frame * FRAME_SIZE, row * FRAME_SIZE, FRAME_SIZE, FRAME_SIZE)


func take_damage(amount: float) -> void:
	if health <= 0:
		return

	health = maxf(health - amount, 0.0)
	health_bar.value = health
	if health == 0:
		died.emit()
		queue_free()


func take_percentage_damage(fraction: float) -> void:
	take_damage(max_health * clampf(fraction, 0.0, 1.0))
