extends Wolf

const SCAN_RANGE = 280.0
const BURST_RANGE = 165.0
const BURST_DAMAGE = 12
const BURST_COOLDOWN = 1.55

var laser_angle := 0.0
var burst_cooldown_remaining := 0.7


func _ready() -> void:
	max_health = 15.0
	attack_damage = BURST_DAMAGE
	super._ready()
	sprite.modulate = Color("#84e5dc")


func _physics_process(delta: float) -> void:
	laser_angle = wrapf(laser_angle + delta * 1.7, 0.0, TAU)
	burst_cooldown_remaining = maxf(burst_cooldown_remaining - get_action_delta(delta), 0.0)
	if target == null or not is_instance_valid(target):
		velocity = Vector2.ZERO
		return

	var to_target := target.global_position - global_position
	if to_target.length() > SCAN_RANGE:
		velocity = to_target.normalized() * 72.0 * get_speed_multiplier()
		facing = _cardinal_direction(to_target)
	else:
		velocity = Vector2.ZERO
		facing = _cardinal_direction(to_target)
		if to_target.length() <= BURST_RANGE \
				and target.velocity.length_squared() > 900.0 \
				and burst_cooldown_remaining <= 0.0:
			deal_damage(BURST_DAMAGE)
			burst_cooldown_remaining = BURST_COOLDOWN
			swipe.rotation = to_target.angle()
			swipe.show()
			swipe_timer = SWIPE_VISIBLE_TIME

	_update_sprite(delta)
	queue_redraw()
	move_and_slide()


func _draw() -> void:
	for beam_offset in [-0.55, 0.0, 0.55]:
		var beam_direction := Vector2.RIGHT.rotated(laser_angle + beam_offset)
		draw_line(
			Vector2.ZERO,
			beam_direction * SCAN_RANGE,
			Color(0.32, 0.95, 0.88, 0.16),
			2.0
		)