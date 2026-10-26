extends UnderworldCreature
class_name Archdemon
## Lord of the Underworld. Hovers after the player on leathery wings: rakes anyone close with a burst of
## flame, hurls fans of hellfire at range and calls pillars of fire up under them. At 70% and 35% health it
## summons imps to its side, and below half health it enrages: it attacks faster, its fans widen and more
## pillars erupt.

const IMP_SCENE = preload("res://imp.tscn")
## Summoned imps carry this meta, so the level neither saves them nor counts them towards progress.
const SUMMONED_META := "summoned"
const SPEED_FACTOR := 0.5
const HOVER_RANGE := 190.0
const ATTACK_INTERVAL := 1.2
const ENRAGED_ATTACK_INTERVAL := 0.75
const ENRAGE_HEALTH_FRACTION := 0.5
const ENRAGED_SPEED_BONUS := 0.3
const ENRAGED_TINT := Color(1.25, 0.82, 0.72)
const HOVER_HEIGHT := 5.0
const HOVER_SPEED := 2.6
## Where hellfire leaves its hands, relative to the feet.
const HAND_OFFSET := Vector2(0.0, -86.0)

const CLAW_RANGE := 150.0
const CLAW_WINDUP := 0.55
const CLAW_RECOVERY := 0.45
const CLAW_DAMAGE := 32
const CLAW_RADIUS := 150.0
const CLAW_KNOCKBACK := 440.0

const VOLLEY_RANGE := 600.0
const VOLLEY_WINDUP := 0.6
const VOLLEY_RECOVERY := 0.45
const VOLLEY_BOLTS := 5
const ENRAGED_VOLLEY_BOLTS := 7
const VOLLEY_ARC := 0.95
const VOLLEY_DAMAGE := 12

const ERUPTION_WINDUP := 0.55
const ERUPTION_RECOVERY := 0.4
const ERUPTION_COUNT := 3
const ENRAGED_ERUPTION_COUNT := 5
const ERUPTION_SCATTER := 110.0
const ERUPTION_COOLDOWN := 6.0
const ERUPTION_DAMAGE := 22

const SUMMON_WINDUP := 0.8
const SUMMON_RECOVERY := 0.4
const SUMMON_THRESHOLDS: Array[float] = [0.7, 0.35]
const SUMMON_COUNT := 2

enum Attack { NONE, CLAW, VOLLEY, ERUPTION, SUMMON }

var attack := Attack.NONE
var attack_time := 0.0
var attack_cooldown := 1.6
var eruption_cooldown := 2.5
var attack_done := false
var enraged := false
var summons_done := 0
var hover_time := 0.0


func _ready() -> void:
	stagger_immune = true
	max_health = 240.0
	attack_damage = CLAW_DAMAGE
	experience_reward = 320
	super._ready()
	FireGlow.attach(self, Vector2(0.0, -10.0), 190.0, Color("#ff3d12"), 0.45)


func get_speed_multiplier() -> float:
	return super.get_speed_multiplier() + (ENRAGED_SPEED_BONUS if enraged else 0.0)


func take_damage(amount: float) -> void:
	super.take_damage(amount)
	if not enraged and health > 0.0 and health <= max_health * ENRAGE_HEALTH_FRACTION:
		enraged = true
		sprite.modulate = ENRAGED_TINT
		FireShockwave.spawn(get_parent(), global_position + get_feet_position(), 260.0)


func _physics_process(delta: float) -> void:
	var action_delta := get_action_delta(delta)
	attack_cooldown = maxf(attack_cooldown - action_delta, 0.0)
	eruption_cooldown = maxf(eruption_cooldown - action_delta, 0.0)
	if target == null or not is_instance_valid(target):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var to_target := target.global_position - global_position
	var distance := to_target.length()
	if attack == Attack.NONE:
		facing = _cardinal_direction(to_target)
		if attack_cooldown == 0.0:
			_choose_attack(distance)
		if attack == Attack.NONE:
			velocity = to_target.normalized() * CHASE_SPEED * SPEED_FACTOR * get_speed_multiplier() \
					if distance > HOVER_RANGE else Vector2.ZERO
	else:
		velocity = Vector2.ZERO
		attack_time += action_delta
		match attack:
			Attack.CLAW:
				_update_claw(to_target)
			Attack.VOLLEY:
				_update_volley(to_target)
			Attack.ERUPTION:
				_update_eruption()
			Attack.SUMMON:
				_update_summon()

	_update_sprite(delta)
	move_and_slide()


func _choose_attack(distance: float) -> void:
	if summons_done < SUMMON_THRESHOLDS.size() and health <= max_health * SUMMON_THRESHOLDS[summons_done]:
		_start(Attack.SUMMON)
	elif distance <= CLAW_RANGE:
		_start(Attack.CLAW)
	elif eruption_cooldown == 0.0:
		_start(Attack.ERUPTION)
	elif distance <= VOLLEY_RANGE:
		_start(Attack.VOLLEY)


func _start(next: Attack) -> void:
	attack = next
	attack_time = 0.0
	attack_done = false
	velocity = Vector2.ZERO


func _finish() -> void:
	attack = Attack.NONE
	attack_cooldown = ENRAGED_ATTACK_INTERVAL if enraged else ATTACK_INTERVAL
	sprite.scale = Vector2.ONE * _base_sprite_scale()


func _base_sprite_scale() -> float:
	return 2.0


## Rears up (swelling) and then rakes the ground in front of it with fire.
func _update_claw(to_target: Vector2) -> void:
	var windup := clampf(attack_time / CLAW_WINDUP, 0.0, 1.0)
	sprite.scale = Vector2.ONE * _base_sprite_scale() * (1.0 + 0.12 * windup if not attack_done else 1.0)
	if not attack_done and attack_time >= CLAW_WINDUP:
		attack_done = true
		var feet := global_position + get_feet_position()
		FireShockwave.spawn(get_parent(), feet, CLAW_RADIUS)
		if to_target.length() <= CLAW_RADIUS:
			deal_damage(CLAW_DAMAGE)
			var push := to_target.normalized() if not to_target.is_zero_approx() else facing
			target.apply_knockback(push, CLAW_KNOCKBACK)
	if attack_time >= CLAW_WINDUP + CLAW_RECOVERY:
		_finish()


func _update_volley(to_target: Vector2) -> void:
	if not attack_done and attack_time >= VOLLEY_WINDUP:
		attack_done = true
		var origin := global_position + get_feet_position() + HAND_OFFSET
		var aim := target.global_position + Vector2(0.0, -14.0) - origin
		var bolts := ENRAGED_VOLLEY_BOLTS if enraged else VOLLEY_BOLTS
		var arc := VOLLEY_ARC * (1.25 if enraged else 1.0)
		for index in bolts:
			var angle := lerpf(-arc * 0.5, arc * 0.5, float(index) / (bolts - 1))
			Hellfire.launch(get_parent(), origin, aim.rotated(angle), get_outgoing_damage(VOLLEY_DAMAGE), self, 1.4)
	if attack_time >= VOLLEY_WINDUP + VOLLEY_RECOVERY:
		_finish()


func _update_eruption() -> void:
	if not attack_done and attack_time >= ERUPTION_WINDUP:
		attack_done = true
		eruption_cooldown = ERUPTION_COOLDOWN
		var count := ENRAGED_ERUPTION_COUNT if enraged else ERUPTION_COUNT
		# One right under the player, the rest scattered around them.
		for index in count:
			var spot := target.global_position
			if index > 0:
				var angle := TAU * index / (count - 1) + randf() * 0.5
				spot += Vector2(cos(angle), sin(angle) * 0.6) * ERUPTION_SCATTER * randf_range(0.7, 1.1)
			FlameEruption.spawn(get_parent(), spot, self, get_outgoing_damage(ERUPTION_DAMAGE))
	if attack_time >= ERUPTION_WINDUP + ERUPTION_RECOVERY:
		_finish()


func _update_summon() -> void:
	if not attack_done and attack_time >= SUMMON_WINDUP:
		attack_done = true
		summons_done += 1
		for index in SUMMON_COUNT:
			var side := -1.0 if index % 2 == 0 else 1.0
			_summon_imp(global_position + Vector2(side * 110.0, 30.0))
	if attack_time >= SUMMON_WINDUP + SUMMON_RECOVERY:
		_finish()


func _summon_imp(world_position: Vector2) -> void:
	var imp := IMP_SCENE.instantiate() as Wolf
	if imp == null:
		push_error("The imp scene root must use the Wolf base script.")
		return
	imp.target_path = target_path
	imp.always_alert = true
	imp.set_meta(SUMMONED_META, true)
	get_parent().add_child(imp)
	imp.global_position = world_position
	FireShockwave.spawn(get_parent(), world_position, 60.0)


func _update_sprite(delta: float) -> void:
	super._update_sprite(delta)
	hover_time += delta
	sprite.position.y += sin(hover_time * HOVER_SPEED) * HOVER_HEIGHT


## Shows its back while flying up the screen; otherwise faces the camera.
func _pick_frame(is_moving: bool) -> Vector2i:
	if action_animation == "" and is_moving and velocity.y < 0.0 and absf(velocity.y) > absf(velocity.x) \
			and animations.has("back"):
		var back: Vector2i = animations["back"]
		return Vector2i(int(animation_time / walk_frame_duration) % back.y, back.x)
	return super._pick_frame(is_moving)
