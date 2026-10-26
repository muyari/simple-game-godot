extends IceCreature
## The Cryohydra, guardian of the Ice Caves. Bites up close, breathes a sweep of frost at anyone level
## with it and spits volleys of ice shards further out. Below half health it enrages: it attacks more
## often, its volleys widen and ice erupts from the ground under the player.

const FROST_SHARD_SCENE = preload("res://FrostShard.tscn")
const ERUPTION_TEXTURE = preload("res://textures/ice_crystals_c.png")
const SPEED_FACTOR = 0.55
## Pause between attacks.
const ATTACK_INTERVAL = 1.1
const ENRAGED_ATTACK_INTERVAL = 0.7
const ENRAGE_HEALTH_FRACTION = 0.5
const ENRAGED_SPEED_BONUS = 0.25
const ENRAGED_TINT := Color(0.82, 0.92, 1.15)
## Where the heads breathe and spit from, relative to the feet with the art facing right.
const MOUTH_OFFSET := Vector2(96.0, -84.0)

const BITE_RANGE = 125.0
const BITE_WINDUP = 0.45
const BITE_RECOVERY = 0.35
const BITE_DAMAGE = 30

## The breath sweeps sideways from the mouth: this far ahead, and widening the further it reaches.
const BREATH_RANGE = 270.0
const BREATH_HALF_HEIGHT = 34.0
const BREATH_SPREAD = 0.28
const BREATH_WINDUP = 0.8
const BREATH_DURATION = 1.25
const BREATH_TICK = 0.2
const BREATH_TICK_DAMAGE = 7
const BREATH_COOLDOWN = 4.0

const VOLLEY_RANGE = 560.0
const VOLLEY_WINDUP = 0.6
const VOLLEY_RECOVERY = 0.4
const VOLLEY_SHARDS = 5
const ENRAGED_VOLLEY_SHARDS = 7
const VOLLEY_ARC = 0.9
const VOLLEY_DAMAGE = 9

const ERUPTION_WINDUP = 0.7
const ERUPTION_COUNT = 3
const ERUPTION_SCATTER = 90.0
const ERUPTION_COOLDOWN = 6.5

enum Attack { NONE, BITE, BREATH, VOLLEY, ERUPTION }

var attack := Attack.NONE
var attack_time := 0.0
var attack_cooldown := 1.5
var breath_cooldown := 2.0
var eruption_cooldown := 1.0
var breath_tick := 0.0
var attack_done := false
var enraged := false
var breath_spray: CPUParticles2D


func _ready() -> void:
	stagger_immune = true
	max_health = 120.0
	attack_damage = BITE_DAMAGE
	experience_reward = 200
	super._ready()
	breath_spray = _build_breath_spray()


func get_speed_multiplier() -> float:
	return super.get_speed_multiplier() + (ENRAGED_SPEED_BONUS if enraged else 0.0)


func take_damage(amount: float) -> void:
	super.take_damage(amount)
	if not enraged and health > 0.0 and health <= max_health * ENRAGE_HEALTH_FRACTION:
		enraged = true
		sprite.modulate = ENRAGED_TINT
		IceShockwave.spawn(get_parent(), global_position + get_feet_position(), 220.0)


func _physics_process(delta: float) -> void:
	var action_delta := get_action_delta(delta)
	breath_cooldown = maxf(breath_cooldown - action_delta, 0.0)
	eruption_cooldown = maxf(eruption_cooldown - action_delta, 0.0)
	if target == null or not is_instance_valid(target):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var to_target := target.global_position - global_position
	if attack == Attack.NONE:
		attack_cooldown = maxf(attack_cooldown - action_delta, 0.0)
		facing = _cardinal_direction(to_target)
		if to_target.x != 0.0:
			facing_left = to_target.x < 0.0
		var next_attack := _choose_attack(to_target) if attack_cooldown == 0.0 else Attack.NONE
		if next_attack != Attack.NONE:
			_start_attack(next_attack)
		elif to_target.length() > BITE_RANGE * 0.8:
			velocity = to_target.normalized() * CHASE_SPEED * SPEED_FACTOR * get_speed_multiplier()
		else:
			velocity = Vector2.ZERO
	else:
		velocity = Vector2.ZERO
		attack_time += action_delta
		match attack:
			Attack.BITE:
				_update_bite(to_target)
			Attack.BREATH:
				_update_breath(action_delta)
			Attack.VOLLEY:
				_update_volley()
			Attack.ERUPTION:
				_update_eruption()

	_update_sprite(delta)
	# Holds its side while attacking so the breath goes where the art points.
	facing = Vector2.LEFT if facing_left else Vector2.RIGHT
	move_and_slide()


func _choose_attack(to_target: Vector2) -> Attack:
	var distance := to_target.length()
	if enraged and eruption_cooldown == 0.0 and distance <= VOLLEY_RANGE:
		return Attack.ERUPTION
	if distance <= BITE_RANGE:
		return Attack.BITE
	if breath_cooldown == 0.0 and absf(to_target.x) <= BREATH_RANGE * 0.85 \
			and absf(to_target.y) <= BREATH_HALF_HEIGHT + absf(to_target.x) * BREATH_SPREAD:
		return Attack.BREATH
	if distance <= VOLLEY_RANGE:
		return Attack.VOLLEY
	return Attack.NONE


func _start_attack(next_attack: Attack) -> void:
	attack = next_attack
	attack_time = 0.0
	attack_done = false
	velocity = Vector2.ZERO
	if next_attack == Attack.BREATH:
		breath_cooldown = BREATH_COOLDOWN
		breath_tick = 0.0
	elif next_attack == Attack.ERUPTION:
		eruption_cooldown = ERUPTION_COOLDOWN


func _finish_attack() -> void:
	attack = Attack.NONE
	attack_cooldown = ENRAGED_ATTACK_INTERVAL if enraged else ATTACK_INTERVAL
	breath_spray.emitting = false
	clear_action()


func _update_bite(to_target: Vector2) -> void:
	show_action("bite", 0 if attack_time < BITE_WINDUP else 1)
	if not attack_done and attack_time >= BITE_WINDUP:
		attack_done = true
		if to_target.length() <= BITE_RANGE * 1.15:
			deal_damage(BITE_DAMAGE)
			target.apply_chill(0.8, 0.6)
	if attack_time >= BITE_WINDUP + BITE_RECOVERY:
		_finish_attack()


func _update_breath(action_delta: float) -> void:
	if attack_time < BREATH_WINDUP:
		show_action_progress("breath", attack_time / BREATH_WINDUP * 0.75)
		return
	show_action("breath", 3)
	if not breath_spray.emitting:
		_aim_breath_spray()
		breath_spray.emitting = true
	breath_tick -= action_delta
	if breath_tick <= 0.0:
		breath_tick = BREATH_TICK
		if _is_in_breath(target.global_position):
			deal_damage(BREATH_TICK_DAMAGE)
			target.apply_chill(1.0, 0.5)
	if attack_time >= BREATH_WINDUP + BREATH_DURATION:
		_finish_attack()


## True when a point is inside the sideways cone of frost in front of the heads.
func _is_in_breath(world_point: Vector2) -> bool:
	var mouth := global_position + _mouth_offset()
	var ahead := (world_point.x - mouth.x) * (-1.0 if facing_left else 1.0)
	if ahead < -40.0 or ahead > BREATH_RANGE:
		return false
	# The feet are lower than the mouth; measure the cone along the ground.
	var ground_y := global_position.y
	return absf(world_point.y - ground_y) <= BREATH_HALF_HEIGHT + maxf(ahead, 0.0) * BREATH_SPREAD


func _update_volley() -> void:
	var release := VOLLEY_WINDUP
	show_action_progress("spit", minf(attack_time / release, 1.0) * 0.99)
	if not attack_done and attack_time >= release:
		attack_done = true
		_fire_volley()
	if attack_time >= release + VOLLEY_RECOVERY:
		_finish_attack()


func _fire_volley() -> void:
	var origin := global_position + _mouth_offset()
	var aim := (target.global_position - origin).normalized()
	if aim.is_zero_approx():
		aim = Vector2.LEFT if facing_left else Vector2.RIGHT
	var count := ENRAGED_VOLLEY_SHARDS if enraged else VOLLEY_SHARDS
	for index in count:
		var shard := FROST_SHARD_SCENE.instantiate() as FrostShard
		if shard == null:
			push_error("The FrostShard scene root must use the FrostShard script.")
			return
		var spread := (float(index) / (count - 1) - 0.5) * VOLLEY_ARC
		shard.direction = aim.rotated(spread)
		shard.damage = get_outgoing_damage(VOLLEY_DAMAGE)
		shard.chill_duration = 1.2
		shard.source_monster = self
		get_tree().current_scene.add_child(shard)
		shard.global_position = origin


func _update_eruption() -> void:
	# All three heads rear back and roar.
	show_action("spit", 0 if attack_time < ERUPTION_WINDUP * 0.5 else 1)
	if not attack_done and attack_time >= ERUPTION_WINDUP:
		attack_done = true
		for index in ERUPTION_COUNT:
			var spot := target.global_position
			if index > 0:
				spot += Vector2.RIGHT.rotated(randf() * TAU) * randf_range(ERUPTION_SCATTER * 0.5, ERUPTION_SCATTER)
			IceEruption.spawn(get_parent(), spot, self, ERUPTION_TEXTURE)
	if attack_time >= ERUPTION_WINDUP + 0.3:
		_finish_attack()


func _mouth_offset() -> Vector2:
	var offset := get_feet_position() + MOUTH_OFFSET
	if facing_left:
		offset.x = -offset.x
	return offset


func _aim_breath_spray() -> void:
	breath_spray.position = _mouth_offset()
	breath_spray.direction = Vector2.LEFT if facing_left else Vector2.RIGHT


## Frost billowing from the heads, reaching as far as the breath does damage.
func _build_breath_spray() -> CPUParticles2D:
	var spray := CPUParticles2D.new()
	spray.emitting = false
	spray.amount = 70
	spray.lifetime = 0.75
	spray.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spray.direction = Vector2.RIGHT
	spray.spread = 14.0
	spray.gravity = Vector2(0.0, 60.0)
	spray.initial_velocity_min = BREATH_RANGE / 0.75 * 0.85
	spray.initial_velocity_max = BREATH_RANGE / 0.75 * 1.1
	spray.damping_min = 20.0
	spray.damping_max = 60.0
	spray.scale_amount_min = 3.0
	spray.scale_amount_max = 7.0
	var colors := Gradient.new()
	colors.offsets = PackedFloat32Array([0.0, 0.4, 1.0])
	colors.colors = PackedColorArray([Color(0.92, 0.98, 1.0, 0.95), Color(0.45, 0.78, 1.0, 0.8), Color(0.35, 0.65, 0.95, 0.0)])
	spray.color_ramp = colors
	add_child(spray)
	return spray
