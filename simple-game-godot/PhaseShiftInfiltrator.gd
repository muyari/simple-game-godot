extends Wolf

const PHASE_RANGE = 122.0
const PHASE_DURATION = 0.72
const PHASE_COOLDOWN = 3.15
const AMBUSH_DAMAGE = 19

enum InfiltratorMode { STALKING, PHASING, RECOVERING }

var infiltrator_mode := InfiltratorMode.STALKING
var phase_timer := 0.0
var phase_cooldown_remaining := 1.3
var saved_collision_layer := 1
var saved_collision_mask := 1


func _ready() -> void:
	max_health = 13.0
	attack_damage = AMBUSH_DAMAGE
	super._ready()
	sprite.modulate = Color("#69d8cc")
	saved_collision_layer = collision_layer
	saved_collision_mask = collision_mask


func _physics_process(delta: float) -> void:
	phase_cooldown_remaining = maxf(phase_cooldown_remaining - delta, 0.0)
	if target == null or not is_instance_valid(target):
		velocity = Vector2.ZERO
		return

	var to_target := target.global_position - global_position
	facing = _cardinal_direction(to_target)
	match infiltrator_mode:
		InfiltratorMode.STALKING:
			if to_target.length() <= PHASE_RANGE and phase_cooldown_remaining <= 0.0:
				_start_phase()
			else:
				velocity = to_target.normalized() * (CHASE_SPEED * 1.22)
		InfiltratorMode.PHASING:
			velocity = Vector2.ZERO
			phase_timer -= delta
			if phase_timer <= 0.0:
				_ambush_from_phase()
		InfiltratorMode.RECOVERING:
			velocity = Vector2.ZERO
			phase_timer -= delta
			if phase_timer <= 0.0:
				infiltrator_mode = InfiltratorMode.STALKING

	_update_sprite(delta)
	move_and_slide()


func _start_phase() -> void:
	infiltrator_mode = InfiltratorMode.PHASING
	phase_timer = PHASE_DURATION
	phase_cooldown_remaining = PHASE_COOLDOWN
	sprite.hide()
	health_bar.hide()
	collision_layer = 0
	collision_mask = 0
	velocity = Vector2.ZERO


func _ambush_from_phase() -> void:
	var behind_player := -target.facing
	if behind_player.is_zero_approx():
		behind_player = Vector2.UP
	global_position = target.global_position + behind_player * 62.0
	facing = _cardinal_direction(-behind_player)
	collision_layer = saved_collision_layer
	collision_mask = saved_collision_mask
	sprite.show()
	health_bar.show()
	if target.global_position.distance_to(global_position) <= PHASE_RANGE:
		target.take_damage(AMBUSH_DAMAGE)
		swipe.rotation = facing.angle()
		swipe.show()
		swipe_timer = SWIPE_VISIBLE_TIME
	infiltrator_mode = InfiltratorMode.RECOVERING
	phase_timer = 0.6


func take_damage(amount: float) -> void:
	if infiltrator_mode != InfiltratorMode.PHASING:
		super.take_damage(amount)