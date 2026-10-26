extends IceCreature

const FROST_SHARD_SCENE = preload("res://FrostShard.tscn")
const CHARGE_START_RANGE = 360.0
const CHARGE_WINDUP = 0.72
const CHARGE_SPEED = 420.0
const CHARGE_DURATION = 0.95
const CHARGE_COOLDOWN = 3.0
const CHARGE_DAMAGE = 28
const KNOCKBACK_STRENGTH = 540.0
const SHARD_COUNT = 7
## The fist-out impact pose is held this long after a charge ends.
const IMPACT_POSE_TIME = 0.35
const CHARGE_TINT := Color(0.86, 0.95, 1.12)

enum YetiMode { HUNTING, WINDING_UP, CHARGING, RECOVERING }

var yeti_mode := YetiMode.HUNTING
var yeti_timer := 0.0
var charge_direction := Vector2.RIGHT


func _ready() -> void:
	max_health = 28.0
	attack_damage = CHARGE_DAMAGE
	experience_reward = 25
	super._ready()


func _physics_process(delta: float) -> void:
	var action_delta := get_action_delta(delta)
	if target == null or not is_instance_valid(target):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var to_target := target.global_position - global_position
	match yeti_mode:
		YetiMode.HUNTING:
			if to_target.length() <= CHARGE_START_RANGE:
				yeti_mode = YetiMode.WINDING_UP
				yeti_timer = CHARGE_WINDUP
				charge_direction = to_target.normalized()
				facing = _cardinal_direction(to_target)
				velocity = Vector2.ZERO
			else:
				velocity = to_target.normalized() * CHASE_SPEED * 0.52 * get_speed_multiplier()
				facing = _cardinal_direction(to_target)
		YetiMode.WINDING_UP:
			velocity = Vector2.ZERO
			yeti_timer -= action_delta
			# Rears back and roars, claws out.
			show_action_progress("attack", (1.0 - yeti_timer / CHARGE_WINDUP) * 0.5)
			if yeti_timer <= 0.0:
				yeti_mode = YetiMode.CHARGING
				yeti_timer = CHARGE_DURATION
				# Face the way it charges, even when that is mostly up or down.
				if charge_direction.x != 0.0:
					facing = Vector2(signf(charge_direction.x), 0.0)
				sprite.modulate = CHARGE_TINT
		YetiMode.CHARGING:
			velocity = charge_direction * CHARGE_SPEED * get_speed_multiplier()
			yeti_timer -= action_delta
			show_action("attack", 3)
		YetiMode.RECOVERING:
			velocity = Vector2.ZERO
			yeti_timer -= action_delta
			if yeti_timer > CHARGE_COOLDOWN - IMPACT_POSE_TIME:
				show_action("attack", 2)
			else:
				clear_action()
			if yeti_timer <= 0.0:
				yeti_mode = YetiMode.HUNTING

	_update_sprite(delta)
	move_and_slide()
	if yeti_mode == YetiMode.CHARGING:
		var hit_player := target.global_position.distance_to(global_position) <= 42.0
		if hit_player:
			deal_damage(CHARGE_DAMAGE)
			target.apply_knockback(charge_direction, KNOCKBACK_STRENGTH)
		if hit_player or get_slide_collision_count() > 0 or yeti_timer <= 0.0:
			_roar_shard_burst()
			yeti_mode = YetiMode.RECOVERING
			yeti_timer = CHARGE_COOLDOWN
			sprite.modulate = Color.WHITE


func _roar_shard_burst() -> void:
	for shard_index in range(SHARD_COUNT):
		var direction := Vector2.RIGHT.rotated(TAU * float(shard_index) / SHARD_COUNT)
		var shard := FROST_SHARD_SCENE.instantiate() as FrostShard
		if shard == null:
			push_error("The FrostShard scene root must use the FrostShard script.")
			return
		shard.damage = get_outgoing_damage(7)
		shard.source_monster = self
		shard.chill_duration = 1.0
		shard.direction = direction
		get_tree().current_scene.add_child(shard)
		shard.global_position = global_position + direction * 30.0


## A heavy blow during the wind-up stops the charge before it starts.
func _interrupt_attack() -> void:
	if yeti_mode == YetiMode.WINDING_UP:
		yeti_mode = YetiMode.RECOVERING
		yeti_timer = CHARGE_COOLDOWN * 0.5
		clear_action()
