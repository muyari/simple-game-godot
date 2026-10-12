extends Wolf

const FROST_SHARD_SCENE = preload("res://FrostShard.tscn")
const CHARGE_START_RANGE = 360.0
const CHARGE_WINDUP = 0.72
const CHARGE_SPEED = 420.0
const CHARGE_DURATION = 0.95
const CHARGE_COOLDOWN = 3.0
const CHARGE_DAMAGE = 28
const KNOCKBACK_STRENGTH = 540.0
const SHARD_COUNT = 7

enum YetiMode { HUNTING, WINDING_UP, CHARGING, RECOVERING }

var yeti_mode := YetiMode.HUNTING
var yeti_timer := 0.0
var charge_direction := Vector2.RIGHT


func _ready() -> void:
	max_health = 28.0
	attack_damage = CHARGE_DAMAGE
	super._ready()
	sprite.modulate = Color("#d7f1f5")


func _physics_process(delta: float) -> void:
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
				sprite.modulate = Color("#f4e4bd")
			else:
				velocity = to_target.normalized() * CHASE_SPEED * 0.52
				facing = _cardinal_direction(to_target)
				_update_sprite(delta)
				move_and_slide()
				return
		YetiMode.WINDING_UP:
			velocity = Vector2.ZERO
			yeti_timer -= delta
			if yeti_timer <= 0.0:
				yeti_mode = YetiMode.CHARGING
				yeti_timer = CHARGE_DURATION
				sprite.modulate = Color("#bcecff")
		YetiMode.CHARGING:
			velocity = charge_direction * CHARGE_SPEED
			yeti_timer -= delta
		YetiMode.RECOVERING:
			velocity = Vector2.ZERO
			yeti_timer -= delta
			if yeti_timer <= 0.0:
				yeti_mode = YetiMode.HUNTING
				sprite.modulate = Color("#d7f1f5")

	_update_sprite(delta)
	move_and_slide()
	if yeti_mode == YetiMode.CHARGING:
		var hit_player := target.global_position.distance_to(global_position) <= 42.0
		if hit_player:
			target.take_damage(CHARGE_DAMAGE)
			target.apply_knockback(charge_direction, KNOCKBACK_STRENGTH)
		if hit_player or get_slide_collision_count() > 0 or yeti_timer <= 0.0:
			_roar_shard_burst()
			yeti_mode = YetiMode.RECOVERING
			yeti_timer = CHARGE_COOLDOWN


func _roar_shard_burst() -> void:
	for shard_index in range(SHARD_COUNT):
		var direction := Vector2.RIGHT.rotated(TAU * float(shard_index) / SHARD_COUNT)
		var shard := FROST_SHARD_SCENE.instantiate() as FrostShard
		if shard == null:
			push_error("The FrostShard scene root must use the FrostShard script.")
			return
		shard.damage = 7
		shard.chill_duration = 1.0
		shard.direction = direction
		get_tree().current_scene.add_child(shard)
		shard.global_position = global_position + direction * 30.0