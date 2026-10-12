extends Wolf

const CHASE_SPEED_WRAITH = 142.0
const SCREAM_RANGE = 205.0
const SCREAM_COOLDOWN = 1.8
const SCREAM_DAMAGE = 8
const SCREAM_CHILL_DURATION = 2.5

var scream_cooldown_remaining := 0.4


func _ready() -> void:
	max_health = 7.0
	attack_damage = SCREAM_DAMAGE
	super._ready()
	collision_layer = 2
	collision_mask = 0
	sprite.modulate = Color("#c6f2ff")


func _physics_process(delta: float) -> void:
	scream_cooldown_remaining = maxf(scream_cooldown_remaining - delta, 0.0)
	if target == null or not is_instance_valid(target):
		velocity = Vector2.ZERO
		return

	var to_target := target.global_position - global_position
	if to_target.length() <= SCREAM_RANGE:
		velocity = Vector2.ZERO
		facing = _cardinal_direction(to_target)
		if scream_cooldown_remaining <= 0.0:
			target.take_damage(SCREAM_DAMAGE)
			target.apply_chill(SCREAM_CHILL_DURATION, 0.48)
			scream_cooldown_remaining = SCREAM_COOLDOWN
			sprite.scale = Vector2(1.2, 1.2)
		else:
			sprite.scale = sprite.scale.move_toward(Vector2.ONE, delta * 1.8)
	else:
		facing = _cardinal_direction(to_target)
		velocity = to_target.normalized() * CHASE_SPEED_WRAITH

	_update_sprite(delta)
	move_and_slide()