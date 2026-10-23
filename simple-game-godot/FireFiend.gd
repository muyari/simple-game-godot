extends UnderworldCreature
class_name FireFiend
## A horned caster that keeps its distance, backing away from anyone who gets close, and hurls bolts of
## hellfire. Every third cast it throws a fan of three.

const SPEED_FACTOR := 0.7
const PREFERRED_MIN := 210.0
const PREFERRED_MAX := 330.0
const CAST_RANGE := 460.0
const CAST_WINDUP := 0.6
const CAST_RECOVERY := 0.4
const CAST_COOLDOWN := 2.2
const BOLT_DAMAGE := 13
const FAN_SPREAD := 0.28
## Where the bolt leaves the trident, relative to the feet with the art facing right.
const HAND_OFFSET := Vector2(22.0, -40.0)
const TINT := Color(1.0, 0.82, 0.72)

var casting := false
var cast_time := 0.0
var cast_cooldown := 1.2
var casts := 0
var thrown := false


func _ready() -> void:
	max_health = 18.0
	attack_damage = BOLT_DAMAGE
	experience_reward = 28
	super._ready()
	sprite.modulate = TINT
	FireGlow.attach(self, Vector2(0.0, -20.0), 70.0, Color("#ff7a26"), 0.35)


func _physics_process(delta: float) -> void:
	var action_delta := get_action_delta(delta)
	cast_cooldown = maxf(cast_cooldown - action_delta, 0.0)
	if target == null or not is_instance_valid(target):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var to_target := target.global_position - global_position
	var distance := to_target.length()
	if to_target.x != 0.0:
		facing = Vector2(signf(to_target.x), 0.0)
	if casting:
		cast_time += action_delta
		velocity = Vector2.ZERO
		show_action("cast", 0 if cast_time < CAST_WINDUP else 1)
		if not thrown and cast_time >= CAST_WINDUP:
			thrown = true
			_throw(to_target)
		if cast_time >= CAST_WINDUP + CAST_RECOVERY:
			casting = false
			clear_action()
	elif cast_cooldown == 0.0 and distance <= CAST_RANGE:
		casting = true
		thrown = false
		cast_time = 0.0
		velocity = Vector2.ZERO
	elif distance < PREFERRED_MIN:
		velocity = -to_target.normalized() * CHASE_SPEED * SPEED_FACTOR * get_speed_multiplier()
	elif distance > PREFERRED_MAX:
		velocity = to_target.normalized() * CHASE_SPEED * SPEED_FACTOR * get_speed_multiplier()
	else:
		# Circles its prey at a safe distance.
		velocity = to_target.normalized().orthogonal() * CHASE_SPEED * SPEED_FACTOR * 0.5 * get_speed_multiplier()

	_update_sprite(delta)
	move_and_slide()


func _throw(to_target: Vector2) -> void:
	casts += 1
	cast_cooldown = CAST_COOLDOWN
	var hand := HAND_OFFSET * Vector2(-1.0 if facing_left else 1.0, 1.0)
	var origin := global_position + get_feet_position() + hand
	var aim := target.global_position + Vector2(0.0, -14.0) - origin
	var angles := [0.0] if casts % 3 != 0 else [-FAN_SPREAD, 0.0, FAN_SPREAD]
	for angle in angles:
		Hellfire.launch(get_parent(), origin, aim.rotated(angle), get_outgoing_damage(BOLT_DAMAGE), self)
