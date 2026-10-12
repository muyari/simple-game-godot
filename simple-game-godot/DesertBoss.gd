extends Wolf

const VENOM_SCENE = preload("res://venom_ball.tscn")
const VENOM_RANGE = 460.0
const MIN_SPIT_INTERVAL = 1.8
const MAX_SPIT_INTERVAL = 3.6
const SPIT_CHANCE = 0.6

var spit_timer := 0.0
var spit_random := RandomNumberGenerator.new()


func _ready() -> void:
	super._ready()
	max_health = Wolf.MAX_HEALTH * 1.25 * 5.0
	attack_damage = roundi(Wolf.ATTACK_DAMAGE * 1.5 * 1.25)
	health = max_health
	health_bar.max_value = max_health
	health_bar.value = health
	spit_random.randomize()
	spit_timer = spit_random.randf_range(MIN_SPIT_INTERVAL, MAX_SPIT_INTERVAL)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if target == null or not is_instance_valid(target) or health <= 0.0:
		return

	spit_timer -= delta
	if spit_timer > 0.0:
		return

	spit_timer = spit_random.randf_range(MIN_SPIT_INTERVAL, MAX_SPIT_INTERVAL)
	if global_position.distance_to(target.global_position) <= VENOM_RANGE \
			and spit_random.randf() < SPIT_CHANCE:
		_spit_venom()


func _spit_venom() -> void:
	var direction := (target.global_position - global_position).normalized()
	if direction.is_zero_approx():
		direction = facing

	var venom := VENOM_SCENE.instantiate() as VenomBall
	if venom == null:
		push_error("The venom projectile scene root must use the VenomBall script.")
		return

	venom.direction = direction
	venom.damage = attack_damage
	get_tree().current_scene.add_child(venom)
	venom.global_position = global_position + direction * 42.0
