extends UnderworldCreature
class_name Imp
## Quick, cackling pests. Scurries in and jabs with its trident; from a little further out it darts
## forward to close the gap.

const SPEED_FACTOR := 1.05
const JAB_RANGE := 70.0
const JAB_WINDUP := 0.34
const JAB_RECOVERY := 0.42
const JAB_DAMAGE := 15
const DART_MIN_RANGE := 150.0
const DART_MAX_RANGE := 280.0
const DART_SPEED := 430.0
const DART_TIME := 0.28
const DART_COOLDOWN := 3.2

enum ImpMode { CHASING, JABBING, DARTING }

var imp_mode := ImpMode.CHASING
var mode_time := 0.0
var dart_cooldown := 1.0
var dart_direction := Vector2.RIGHT
var jab_done := false


func _ready() -> void:
	max_health = 16.0
	attack_damage = JAB_DAMAGE
	experience_reward = 22
	super._ready()


func _physics_process(delta: float) -> void:
	var action_delta := get_action_delta(delta)
	dart_cooldown = maxf(dart_cooldown - action_delta, 0.0)
	if target == null or not is_instance_valid(target):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var to_target := target.global_position - global_position
	var distance := to_target.length()
	match imp_mode:
		ImpMode.CHASING:
			facing = _cardinal_direction(to_target)
			if distance <= JAB_RANGE:
				_start(ImpMode.JABBING)
			elif dart_cooldown == 0.0 and distance >= DART_MIN_RANGE and distance <= DART_MAX_RANGE:
				_start(ImpMode.DARTING)
				dart_direction = to_target.normalized()
			else:
				velocity = to_target.normalized() * CHASE_SPEED * SPEED_FACTOR * get_speed_multiplier()
		ImpMode.JABBING:
			mode_time += action_delta
			velocity = Vector2.ZERO
			show_action_progress("attack", mode_time / JAB_WINDUP)
			if not jab_done and mode_time >= JAB_WINDUP:
				jab_done = true
				if distance <= JAB_RANGE + 12.0:
					deal_damage(JAB_DAMAGE)
			if mode_time >= JAB_WINDUP + JAB_RECOVERY:
				_finish()
		ImpMode.DARTING:
			mode_time += action_delta
			show_action("attack", 2)
			velocity = dart_direction * DART_SPEED * get_speed_multiplier()
			if mode_time >= DART_TIME or distance <= JAB_RANGE:
				dart_cooldown = DART_COOLDOWN
				_start(ImpMode.JABBING)

	_update_sprite(delta)
	move_and_slide()


func _start(mode: ImpMode) -> void:
	imp_mode = mode
	mode_time = 0.0
	jab_done = false
	velocity = Vector2.ZERO


func _finish() -> void:
	imp_mode = ImpMode.CHASING
	clear_action()
