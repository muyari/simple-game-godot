extends UnderworldCreature
class_name Hellhound
## Runs its prey down. Within pouncing distance it crouches, then leaps, biting whatever it lands on and
## leaving smouldering embers where it took off. Up close it snaps.

const SPEED_FACTOR := 1.3
const BITE_RANGE := 72.0
const BITE_WINDUP := 0.3
const BITE_RECOVERY := 0.5
const BITE_DAMAGE := 14
const POUNCE_MIN_RANGE := 120.0
const POUNCE_RANGE := 250.0
const POUNCE_WINDUP := 0.45
const POUNCE_SPEED := 560.0
const POUNCE_TIME := 0.34
const POUNCE_RECOVERY := 0.75
const POUNCE_DAMAGE := 22
const POUNCE_COOLDOWN := 2.6
const POUNCE_HIT_RANGE := 48.0

enum HoundMode { RUNNING, BITING, CROUCHING, POUNCING, RECOVERING }

var hound_mode := HoundMode.RUNNING
var mode_time := 0.0
var pounce_cooldown := 0.8
var pounce_direction := Vector2.RIGHT
var hit_done := false


func _ready() -> void:
	max_health = 22.0
	attack_damage = POUNCE_DAMAGE
	experience_reward = 26
	super._ready()
	# Embers smoulder on its back.
	FireGlow.attach(self, Vector2(0.0, -8.0), 46.0, Color("#ff5a1a"), 0.3)


func _physics_process(delta: float) -> void:
	var action_delta := get_action_delta(delta)
	pounce_cooldown = maxf(pounce_cooldown - action_delta, 0.0)
	if target == null or not is_instance_valid(target):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var to_target := target.global_position - global_position
	var distance := to_target.length()
	match hound_mode:
		HoundMode.RUNNING:
			facing = _cardinal_direction(to_target)
			if distance <= BITE_RANGE:
				_start(HoundMode.BITING)
			elif pounce_cooldown == 0.0 and distance >= POUNCE_MIN_RANGE and distance <= POUNCE_RANGE:
				_start(HoundMode.CROUCHING)
				pounce_direction = to_target.normalized()
			else:
				velocity = to_target.normalized() * CHASE_SPEED * SPEED_FACTOR * get_speed_multiplier()
		HoundMode.BITING:
			mode_time += action_delta
			show_action_progress("attack", mode_time / (BITE_WINDUP + BITE_RECOVERY))
			if not hit_done and mode_time >= BITE_WINDUP:
				hit_done = true
				if distance <= BITE_RANGE + 12.0:
					deal_damage(BITE_DAMAGE)
			if mode_time >= BITE_WINDUP + BITE_RECOVERY:
				_finish()
		HoundMode.CROUCHING:
			mode_time += action_delta
			# Keeps its eyes on the prey while it gathers itself.
			pounce_direction = to_target.normalized()
			if pounce_direction.x != 0.0:
				facing = Vector2(signf(pounce_direction.x), 0.0)
			show_action("attack", 0)
			if mode_time >= POUNCE_WINDUP:
				FireShockwave.spawn(get_parent(), global_position, 30.0)
				_start(HoundMode.POUNCING)
		HoundMode.POUNCING:
			mode_time += action_delta
			show_action("attack", 3)
			velocity = pounce_direction * POUNCE_SPEED * get_speed_multiplier()
			if not hit_done and distance <= POUNCE_HIT_RANGE:
				hit_done = true
				deal_damage(POUNCE_DAMAGE)
				target.apply_knockback(pounce_direction, 260.0)
			if mode_time >= POUNCE_TIME:
				pounce_cooldown = POUNCE_COOLDOWN
				_start(HoundMode.RECOVERING)
		HoundMode.RECOVERING:
			mode_time += action_delta
			show_action("attack", 5)
			if mode_time >= POUNCE_RECOVERY:
				_finish()

	_update_sprite(delta)
	move_and_slide()


func _start(mode: HoundMode) -> void:
	hound_mode = mode
	mode_time = 0.0
	hit_done = false
	velocity = Vector2.ZERO


func _finish() -> void:
	hound_mode = HoundMode.RUNNING
	clear_action()
