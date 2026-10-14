extends Wolf

const HOMING_PULSE_SCENE = preload("res://homing_pulse.tscn")
const DETECT_RANGE = 520.0
const PULSE_COOLDOWN = 2.35
const PULSE_DAMAGE = 13

var pulse_cooldown_remaining := 1.0
var hover_time := 0.0
var hover_origin_y := 0.0
var hover_origin_set := false


func _ready() -> void:
	max_health = 11.0
	attack_damage = PULSE_DAMAGE
	super._ready()
	sprite.modulate = Color("#72d8e7")


func _physics_process(delta: float) -> void:
	if not hover_origin_set:
		hover_origin_y = global_position.y
		hover_origin_set = true
	pulse_cooldown_remaining = maxf(pulse_cooldown_remaining - get_action_delta(delta), 0.0)
	hover_time += delta
	if target == null or not is_instance_valid(target):
		velocity = Vector2.ZERO
		return

	var to_target := target.global_position - global_position
	facing = _cardinal_direction(to_target)
	if to_target.length() > DETECT_RANGE:
		velocity = to_target.normalized() * 86.0 * get_speed_multiplier()
	else:
		velocity = Vector2(-to_target.y, to_target.x).normalized() * 42.0 * get_speed_multiplier()
		if to_target.length() < 180.0:
			velocity = -to_target.normalized() * 78.0 * get_speed_multiplier()
		if pulse_cooldown_remaining <= 0.0:
			_fire_homing_pulse()
			pulse_cooldown_remaining = PULSE_COOLDOWN

	global_position.y = hover_origin_y + sin(hover_time * 3.5) * 3.0
	_update_sprite(delta)
	queue_redraw()
	move_and_slide()


func _fire_homing_pulse() -> void:
	var pulse := HOMING_PULSE_SCENE.instantiate() as HomingPulse
	if pulse == null:
		push_error("The homing pulse scene root must use the HomingPulse script.")
		return

	pulse.target = target
	pulse.damage = get_outgoing_damage(PULSE_DAMAGE)
	pulse.source_monster = self
	pulse.global_position = global_position
	pulse.initial_direction = (target.global_position + target.velocity * 0.45 - global_position).normalized()
	get_tree().current_scene.add_child(pulse)


func _draw() -> void:
	var pulse := sin(hover_time * 5.0) * 2.0
	draw_circle(Vector2.ZERO, 24.0 + pulse, Color(0.35, 0.9, 1.0, 0.12))
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(0.0, -18.0),
			Vector2(18.0, 0.0),
			Vector2(0.0, 18.0),
			Vector2(-18.0, 0.0)
		]),
		Color("#315979")
	)
	draw_circle(Vector2.ZERO, 8.0 + pulse * 0.3, Color("#8ff9ec"))
