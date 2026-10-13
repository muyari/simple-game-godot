extends CharacterBody2D
class_name Wolf

signal died


const CHASE_SPEED = 110.0
const ATTACK_RANGE = 78.0
const ATTACK_DAMAGE = 20
const WINDUP_TIME = 0.35
const ATTACK_COOLDOWN = 0.9
const SWIPE_VISIBLE_TIME = 0.18
const ATTACK_ANIMATION_DURATION = WINDUP_TIME + SWIPE_VISIBLE_TIME
const FRAME_WIDTH = 150
const FRAME_HEIGHT = 100
const WALK_FRAME_DURATION = 0.15
const IDLE_FRAME_DURATION = 0.42
const MOVEMENT_FRAME_START = 2
const ATTACK_FRAME_START = 8
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
var stun_time_remaining := 0.0
var curse_time_remaining := 0.0
var curse_damage_multiplier := 1.0
var facing := Vector2.RIGHT
var animation_time := 0.0
var attack_animation_time_remaining := 0.0
var sprite_base_position := Vector2.ZERO


func _ready() -> void:
	add_to_group("enemies")
	sprite_base_position = sprite.position
	health = max_health
	health_bar.max_value = max_health
	health_bar.value = health
	target = get_node_or_null(target_path) as Player
	if target == null:
		push_error("Wolf could not find its player target at %s." % target_path)


func _process(delta: float) -> void:
	if stun_time_remaining > 0.0:
		stun_time_remaining = maxf(stun_time_remaining - delta, 0.0)
		if stun_time_remaining == 0.0 and health > 0.0:
			set_physics_process(true)
	if curse_time_remaining > 0.0:
		curse_time_remaining = maxf(curse_time_remaining - delta, 0.0)
		if curse_time_remaining == 0.0:
			curse_damage_multiplier = 1.0


func _physics_process(delta: float) -> void:
	attack_animation_time_remaining = maxf(
		attack_animation_time_remaining - delta,
		0.0
	)
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
				attack_animation_time_remaining = ATTACK_ANIMATION_DURATION
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

	var is_moving := velocity.length_squared() > 0.0 \
			and attack_animation_time_remaining == 0.0
	animation_time += delta
	var frame := int(animation_time / IDLE_FRAME_DURATION) % 2
	if attack_animation_time_remaining > 0.0:
		var progress := 1.0 - (
			attack_animation_time_remaining / ATTACK_ANIMATION_DURATION
		)
		var attack_frame_count := 2 if row == 1 or row == 2 else 4
		frame = ATTACK_FRAME_START + mini(
			int(progress * attack_frame_count),
			attack_frame_count - 1
		)
	elif is_moving:
		var movement_frame_count := 2 if row == 1 or row == 2 else 6
		var movement_frame := int(animation_time / WALK_FRAME_DURATION)
		movement_frame %= movement_frame_count
		frame = MOVEMENT_FRAME_START + movement_frame
	sprite.position = sprite_base_position
	if is_moving:
		sprite.position.y += sin(animation_time * TAU / (WALK_FRAME_DURATION * 2.0)) * 1.2
	sprite.region_rect = Rect2(
		frame * FRAME_WIDTH,
		row * FRAME_HEIGHT,
		FRAME_WIDTH,
		FRAME_HEIGHT
	)


func take_damage(amount: float) -> void:
	if health <= 0:
		return

	health = maxf(health - amount * curse_damage_multiplier, 0.0)
	health_bar.value = health
	if health == 0:
		died.emit()
		queue_free()


func apply_stun(duration: float) -> void:
	if health <= 0.0:
		return
	stun_time_remaining = maxf(stun_time_remaining, duration)
	velocity = Vector2.ZERO
	set_physics_process(false)


func apply_curse(duration: float, damage_multiplier: float) -> void:
	if health <= 0.0:
		return
	curse_time_remaining = maxf(curse_time_remaining, duration)
	curse_damage_multiplier = maxf(curse_damage_multiplier, damage_multiplier)


func take_percentage_damage(fraction: float) -> void:
	take_damage(max_health * clampf(fraction, 0.0, 1.0))
