extends DesertCreature

const SPIT_RANGE = 340.0
const SPIT_WINDUP = 0.65
const SPIT_COOLDOWN = 1.4
const VENOM_SCENE = preload("res://venom_ball.tscn")
## Open-mouthed frame held briefly after the venom leaves.
const SPIT_FRAME = 7
const SPIT_HOLD_TIME = 0.3
const SLITHER_SKEW = 0.12

var spit_damage := 20


func _ready() -> void:
	experience_reward = 20
	super._ready()


func _physics_process(delta: float) -> void:
	var action_delta := get_action_delta(delta)
	if target == null or not is_instance_valid(target):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var to_target := target.global_position - global_position
	match state:
		State.CHASING:
			if to_target.length() <= SPIT_RANGE:
				state = State.WINDING_UP
				state_timer = SPIT_WINDUP
				velocity = Vector2.ZERO
			else:
				facing = _cardinal_direction(to_target)
				velocity = to_target.normalized() * CHASE_SPEED * get_speed_multiplier()
		State.WINDING_UP:
			velocity = Vector2.ZERO
			facing = _cardinal_direction(to_target)
			state_timer -= action_delta
			if state_timer <= 0.0:
				if to_target.length() <= SPIT_RANGE:
					_spit_venom(to_target.normalized())
				state = State.COOLDOWN
				state_timer = SPIT_COOLDOWN
		State.COOLDOWN:
			velocity = Vector2.ZERO
			state_timer -= action_delta
			if state_timer <= 0.0:
				state = State.CHASING

	_update_sprite(delta)
	move_and_slide()


func _spit_venom(direction: Vector2) -> void:
	if direction.is_zero_approx():
		direction = facing

	var venom := VENOM_SCENE.instantiate() as VenomBall
	if venom == null:
		push_error("The venom projectile scene root must use the VenomBall script.")
		return

	venom.direction = direction
	venom.damage = get_outgoing_damage(spit_damage)
	venom.source_monster = self
	get_tree().current_scene.add_child(venom)
	venom.global_position = global_position + direction * 26.0


func _pick_frame(is_moving: bool) -> int:
	# Coils sway side to side as the snake slithers.
	sprite.skew = sin(animation_time * TAU / (move_frame_duration * 4.0)) * SLITHER_SKEW if is_moving else 0.0
	if state == State.WINDING_UP:
		return _frame_at(attack_frames, 1.0 - state_timer / SPIT_WINDUP)
	if state == State.COOLDOWN and state_timer > SPIT_COOLDOWN - SPIT_HOLD_TIME:
		return SPIT_FRAME
	return super._pick_frame(is_moving)
