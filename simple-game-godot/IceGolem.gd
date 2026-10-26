extends IceCreature
## Lumbers after the player. Up close it slams the ground, hitting everything around it; further out it
## hurls chunks of ice.

const FROST_SHARD_SCENE = preload("res://FrostShard.tscn")
const CHUNK_TEXTURE = preload("res://textures/ice_golem_shard.png")
const SPEED_FACTOR = 0.48
const SMASH_RANGE = 90.0
const SMASH_RADIUS = 115.0
## Arms raised, then crouched to slam; the slam lands at the end of the wind-up.
const SMASH_RAISE_TIME = 0.3
const SMASH_WINDUP = 0.75
const SMASH_RECOVERY = 0.65
const SMASH_DAMAGE = 24
const SMASH_KNOCKBACK = 380.0
const THROW_MIN_RANGE = 150.0
const THROW_RANGE = 430.0
const THROW_WINDUP = 0.55
const THROW_RECOVERY = 0.4
const THROW_COOLDOWN = 3.4
const THROW_DAMAGE = 12

enum GolemMode { WALKING, SMASHING, THROWING }

var golem_mode := GolemMode.WALKING
var mode_time := 0.0
var throw_cooldown := 1.5
var action_done := false


func _ready() -> void:
	max_health = 26.0
	attack_damage = SMASH_DAMAGE
	experience_reward = 30
	super._ready()


func _physics_process(delta: float) -> void:
	var action_delta := get_action_delta(delta)
	throw_cooldown = maxf(throw_cooldown - action_delta, 0.0)
	if target == null or not is_instance_valid(target):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var to_target := target.global_position - global_position
	var distance := to_target.length()
	match golem_mode:
		GolemMode.WALKING:
			facing = _cardinal_direction(to_target)
			if distance <= SMASH_RANGE:
				_start(GolemMode.SMASHING)
			elif throw_cooldown == 0.0 and distance >= THROW_MIN_RANGE and distance <= THROW_RANGE:
				_start(GolemMode.THROWING)
			else:
				velocity = to_target.normalized() * CHASE_SPEED * SPEED_FACTOR * get_speed_multiplier()
		GolemMode.SMASHING:
			mode_time += action_delta
			_update_smash()
		GolemMode.THROWING:
			mode_time += action_delta
			_update_throw(to_target)

	_update_sprite(delta)
	move_and_slide()


func _start(mode: GolemMode) -> void:
	golem_mode = mode
	mode_time = 0.0
	action_done = false
	velocity = Vector2.ZERO


func _finish() -> void:
	golem_mode = GolemMode.WALKING
	clear_action()


func _update_smash() -> void:
	if mode_time < SMASH_RAISE_TIME:
		show_action("smash", 3)
	elif mode_time < SMASH_WINDUP:
		show_action("smash", 0)
	elif mode_time < SMASH_WINDUP + 0.15:
		show_action("smash", 1)
	else:
		show_action("smash", 2)
	if not action_done and mode_time >= SMASH_WINDUP:
		action_done = true
		_slam()
	if mode_time >= SMASH_WINDUP + SMASH_RECOVERY:
		_finish()


func _slam() -> void:
	IceShockwave.spawn(get_parent(), global_position + get_feet_position(), SMASH_RADIUS)
	var to_target := target.global_position - global_position
	if to_target.length() > SMASH_RADIUS:
		return
	deal_damage(SMASH_DAMAGE)
	target.apply_chill(1.2, 0.6)
	var push := to_target.normalized() if not to_target.is_zero_approx() else facing
	target.apply_knockback(push, SMASH_KNOCKBACK)


func _update_throw(to_target: Vector2) -> void:
	if not action_done:
		facing = _cardinal_direction(to_target)
	show_action("throw", 0 if mode_time < THROW_WINDUP else 1)
	if not action_done and mode_time >= THROW_WINDUP:
		action_done = true
		throw_cooldown = THROW_COOLDOWN
		_throw_chunk(to_target.normalized())
	if mode_time >= THROW_WINDUP + THROW_RECOVERY:
		_finish()


func _throw_chunk(direction: Vector2) -> void:
	if direction.is_zero_approx():
		direction = facing
	var chunk := FROST_SHARD_SCENE.instantiate() as FrostShard
	if chunk == null:
		push_error("The FrostShard scene root must use the FrostShard script.")
		return
	chunk.texture = CHUNK_TEXTURE
	chunk.damage = get_outgoing_damage(THROW_DAMAGE)
	chunk.chill_duration = 1.0
	chunk.source_monster = self
	chunk.direction = direction
	get_tree().current_scene.add_child(chunk)
	# Leaves the golem's hand, about chest height.
	chunk.global_position = global_position + Vector2(0.0, -30.0) + direction * 34.0


## A heavy blow breaks off a slam or throw that hasn't landed yet.
func _interrupt_attack() -> void:
	if golem_mode != GolemMode.WALKING and not action_done:
		_finish()
