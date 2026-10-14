extends Wolf

const SLAM_RANGE = 148.0
const SLAM_WINDUP = 0.82
const SLAM_DAMAGE = 30
const SLAM_KNOCKBACK = 610.0
const SHIELD_DURATION = 1.65
const SHIELD_RECHARGE = 5.4

enum ExoMode { ADVANCING, WINDING_UP, RECOVERING }

var exo_mode := ExoMode.ADVANCING
var exo_timer := 0.0
var shield_timer := SHIELD_RECHARGE * 0.5
var shield_time_remaining := 0.0
var shield_active := false


func _ready() -> void:
	max_health = 42.0
	attack_damage = SLAM_DAMAGE
	super._ready()
	sprite.modulate = Color("#a1c9c9")


func _physics_process(delta: float) -> void:
	if shield_active:
		shield_time_remaining = maxf(shield_time_remaining - delta, 0.0)
		if shield_time_remaining == 0.0:
			shield_active = false
	else:
		shield_timer -= delta
		if shield_timer <= 0.0:
			shield_active = true
			shield_time_remaining = SHIELD_DURATION
			shield_timer = SHIELD_RECHARGE

	if target == null or not is_instance_valid(target):
		velocity = Vector2.ZERO
		return

	var to_target := target.global_position - global_position
	facing = _cardinal_direction(to_target)
	match exo_mode:
		ExoMode.ADVANCING:
			if to_target.length() <= SLAM_RANGE:
				exo_mode = ExoMode.WINDING_UP
				exo_timer = SLAM_WINDUP
				velocity = Vector2.ZERO
			else:
				velocity = to_target.normalized() * 48.0 * get_speed_multiplier()
		ExoMode.WINDING_UP:
			velocity = Vector2.ZERO
			exo_timer -= get_action_delta(delta)
			if exo_timer <= 0.0:
				if to_target.length() <= SLAM_RANGE + 18.0:
					_explode_slam(to_target)
				exo_mode = ExoMode.RECOVERING
				exo_timer = 1.6
		ExoMode.RECOVERING:
			velocity = Vector2.ZERO
			exo_timer -= get_action_delta(delta)
			if exo_timer <= 0.0:
				exo_mode = ExoMode.ADVANCING

	sprite.modulate = Color("#57dfee") if shield_active else Color("#a1c9c9")
	_update_sprite(delta)
	move_and_slide()


func _explode_slam(to_target: Vector2) -> void:
	if to_target.length() <= SLAM_RANGE:
		deal_damage(SLAM_DAMAGE)
		target.apply_knockback(to_target.normalized(), SLAM_KNOCKBACK)
	swipe.rotation = 0.0
	swipe.show()
	swipe_timer = 0.35


func take_damage(amount: float) -> void:
	super.take_damage(amount * (0.28 if shield_active else 1.0))


func _draw() -> void:
	if shield_active:
		draw_arc(Vector2.ZERO, 42.0, 0.0, TAU, 48, Color(0.3, 0.92, 1.0, 0.82), 4.0)