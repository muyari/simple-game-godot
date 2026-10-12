extends Wolf

const FROST_SHARD_SCENE = preload("res://FrostShard.tscn")
const FROST_TRAIL_SCENE = preload("res://FrostTrail.tscn")
const SERPENT_SPEED = 165.0
const SPIT_RANGE = 390.0
const SPIT_COOLDOWN = 2.2
const BURROW_RANGE = 310.0
const BURROW_COOLDOWN = 5.2
const BURROW_DURATION = 0.95
const EMERGE_DAMAGE = 17
const TRAIL_INTERVAL = 0.85

var spit_cooldown_remaining := 1.0
var burrow_cooldown_remaining := 2.5
var trail_interval_remaining := 0.0
var burrow_time_remaining := 0.0
var serpent_burrowed := false
var saved_collision_layer := 1
var saved_collision_mask := 1


func _ready() -> void:
	max_health = 9.0
	attack_damage = EMERGE_DAMAGE
	super._ready()
	sprite.modulate = Color("#d9fbff")
	saved_collision_layer = collision_layer
	saved_collision_mask = collision_mask


func _physics_process(delta: float) -> void:
	spit_cooldown_remaining = maxf(spit_cooldown_remaining - delta, 0.0)
	burrow_cooldown_remaining = maxf(burrow_cooldown_remaining - delta, 0.0)
	trail_interval_remaining = maxf(trail_interval_remaining - delta, 0.0)
	if target == null or not is_instance_valid(target):
		velocity = Vector2.ZERO
		return

	if serpent_burrowed:
		burrow_time_remaining -= delta
		if burrow_time_remaining <= 0.0:
			_emerge_and_strike()
		return

	var to_target := target.global_position - global_position
	facing = _cardinal_direction(to_target)
	if to_target.length() <= BURROW_RANGE and burrow_cooldown_remaining <= 0.0:
		_start_burrow()
		return

	velocity = to_target.normalized() * SERPENT_SPEED
	if trail_interval_remaining <= 0.0 and velocity.length_squared() > 0.0:
		_leave_frost_trail()
		trail_interval_remaining = TRAIL_INTERVAL
	if to_target.length() <= SPIT_RANGE and spit_cooldown_remaining <= 0.0:
		_spit_shards(to_target.normalized())
		spit_cooldown_remaining = SPIT_COOLDOWN

	_update_sprite(delta)
	move_and_slide()


func _start_burrow() -> void:
	serpent_burrowed = true
	burrow_time_remaining = BURROW_DURATION
	burrow_cooldown_remaining = BURROW_COOLDOWN
	velocity = Vector2.ZERO
	sprite.hide()
	health_bar.hide()
	collision_layer = 0
	collision_mask = 0


func _emerge_and_strike() -> void:
	var to_target := target.global_position - global_position
	var direction := to_target.normalized()
	if direction.is_zero_approx():
		direction = Vector2.DOWN
	global_position = target.global_position - direction * 92.0
	serpent_burrowed = false
	collision_layer = saved_collision_layer
	collision_mask = saved_collision_mask
	sprite.show()
	health_bar.show()
	facing = _cardinal_direction(-direction)
	target.take_damage(EMERGE_DAMAGE)
	target.apply_chill(1.0, 0.62)
	_spit_shards(direction)


func _spit_shards(direction: Vector2) -> void:
	for spread in [-0.18, 0.0, 0.18]:
		var shard := FROST_SHARD_SCENE.instantiate() as FrostShard
		if shard == null:
			push_error("The FrostShard scene root must use the FrostShard script.")
			return
		shard.damage = 6
		shard.chill_duration = 1.4
		shard.direction = direction.rotated(spread)
		get_tree().current_scene.add_child(shard)
		shard.global_position = global_position + shard.direction * 28.0


func _leave_frost_trail() -> void:
	var trail := FROST_TRAIL_SCENE.instantiate() as FrostTrail
	if trail == null:
		push_error("The FrostTrail scene root must use the FrostTrail script.")
		return
	get_tree().current_scene.add_child(trail)
	trail.global_position = global_position
	trail.rotation = velocity.angle()