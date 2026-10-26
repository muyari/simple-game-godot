extends CharacterBody2D
class_name Wolf

signal died


const CHASE_SPEED = 110.0
const ATTACK_RANGE = 78.0
const ATTACK_DAMAGE = 20
const WINDUP_TIME = 0.35
const ATTACK_COOLDOWN = 0.9
const SWIPE_VISIBLE_TIME = 0.18
const ATTACK_ANIMATION_DURATION = WINDUP_TIME + SWIPE_VISIBLE_TIME
const FRAME_WIDTH = 150
const FRAME_HEIGHT = 100
const WALK_FRAME_DURATION = 0.15
const IDLE_FRAME_DURATION = 0.42
const MOVEMENT_FRAME_START = 2
const ATTACK_FRAME_START = 8
const MAX_HEALTH = 3.0
## Monsters wait where they are until the player comes this close (or hits them)...
const AGGRO_RANGE := 520.0
## ...and give up the hunt once the player gets this far away.
const LEASH_RANGE := 1100.0
const AURA_GROUP := "monster_auras"
const AURA_REFRESH_INTERVAL := 0.25
const MODIFIER_LABEL_COLOR := Color("#8fb8ff")
const MULTI_MODIFIER_LABEL_COLOR := Color("#ffd75e")

enum State { CHASING, WINDING_UP, COOLDOWN }

@export var target_path: NodePath = NodePath("../Player")

@onready var swipe: Line2D = $Swipe
@onready var sprite: Sprite2D = $Sprite2D
@onready var health_bar: ProgressBar = $HealthBar

var target: Player
@export var max_health: float = MAX_HEALTH
@export var attack_damage: int = ATTACK_DAMAGE
@export_range(1, 10000, 1) var experience_reward := 15
## Shown on the HUD's target bar.
@export var monster_name := "Monster"

## The monster the player damaged most recently. Touch screens have no mouse to hover with, so their
## target bar follows this instead.
static var last_hit: Wolf

var health: float
var state := State.CHASING
var state_timer := 0.0
var swipe_timer := 0.0
var stun_time_remaining := 0.0
var curse_time_remaining := 0.0
var curse_damage_multiplier := 1.0
var facing := Vector2.RIGHT
var animation_time := 0.0
var attack_animation_time_remaining := 0.0
var sprite_base_position := Vector2.ZERO
## Ids from MonsterModifiers.DEFINITIONS. Set before the monster enters the tree.
var modifier_ids: Array[String] = []
var modifier_stats := {}
var aura_bonuses := {}
var aura_refresh_remaining := 0.0
## Endgame difficulty: multiplies max health and every hit this monster deals. Set before the monster
## enters the tree.
var health_scale := 1.0
var damage_scale := 1.0
## Bosses hunt the player from anywhere. Set before the monster enters the tree.
var always_alert := false
## While not alert the monster stands idle and its physics (chasing, attacking) is off.
var is_alert := false
## Bosses shrug off blows: no flinch, no interrupted attacks and barely any knockback.
var stagger_immune := false
## Fades from 1 to 0 after each hit; drives the white hit flash.
var hit_flash := 0.0
var hit_knockback := Vector2.ZERO
## Set by the player while the mouse is over this monster.
var hovered := false
var stagger_recovery := 0.0


func _ready() -> void:
	add_to_group("enemies")
	sprite_base_position = sprite.position
	max_health *= health_scale
	_apply_modifiers()
	health = max_health
	health_bar.max_value = max_health
	health_bar.value = health
	# Top-down movement; the default (grounded) mode treats bodies below as floors to ride on.
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	target = get_node_or_null(target_path) as Player
	if target == null:
		push_error("Wolf could not find its player target at %s." % target_path)
	else:
		# The player walks through monsters, so a crowd can never pin them in place.
		add_collision_exception_with(target)
	is_alert = always_alert
	set_physics_process(is_alert)


func _process(delta: float) -> void:
	_update_hit_reaction(delta)
	if stun_time_remaining > 0.0:
		stun_time_remaining = maxf(stun_time_remaining - delta, 0.0)
		if stun_time_remaining == 0.0 and health > 0.0 and is_alert:
			set_physics_process(true)
	_update_alertness(delta)
	if curse_time_remaining > 0.0:
		curse_time_remaining = maxf(curse_time_remaining - delta, 0.0)
		if curse_time_remaining == 0.0:
			curse_damage_multiplier = 1.0
	var regen := get_stat(MonsterModifiers.STAT_REGEN)
	if regen > 0.0 and health > 0.0 and health < max_health:
		health = minf(health + max_health * regen * delta, max_health)
		health_bar.value = health
	aura_refresh_remaining -= delta
	if aura_refresh_remaining <= 0.0:
		aura_refresh_remaining = AURA_REFRESH_INTERVAL
		_refresh_aura_bonuses()


func _physics_process(delta: float) -> void:
	var action_delta := get_action_delta(delta)
	attack_animation_time_remaining = maxf(
		attack_animation_time_remaining - action_delta,
		0.0
	)
	if swipe_timer > 0.0:
		swipe_timer -= delta
		if swipe_timer <= 0.0:
			swipe.hide()

	if target == null or not is_instance_valid(target):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var to_target := target.global_position - global_position
	match state:
		State.CHASING:
			if to_target.length() <= ATTACK_RANGE:
				state = State.WINDING_UP
				state_timer = WINDUP_TIME
				attack_animation_time_remaining = ATTACK_ANIMATION_DURATION
				velocity = Vector2.ZERO
			else:
				facing = _cardinal_direction(to_target)
				velocity = to_target.normalized() * CHASE_SPEED * get_speed_multiplier()
		State.WINDING_UP:
			velocity = Vector2.ZERO
			facing = _cardinal_direction(to_target)
			state_timer -= action_delta
			if state_timer <= 0.0:
				if to_target.length() <= ATTACK_RANGE:
					deal_damage(attack_damage)
					swipe.rotation = facing.angle()
					swipe.show()
					swipe_timer = SWIPE_VISIBLE_TIME
				state = State.COOLDOWN
				state_timer = ATTACK_COOLDOWN
		State.COOLDOWN:
			velocity = Vector2.ZERO
			state_timer -= action_delta
			if state_timer <= 0.0:
				state = State.CHASING

	_update_sprite(delta)
	move_and_slide()


func _cardinal_direction(direction: Vector2) -> Vector2:
	if absf(direction.x) > absf(direction.y):
		return Vector2.RIGHT if direction.x > 0.0 else Vector2.LEFT
	return Vector2.DOWN if direction.y > 0.0 else Vector2.UP


func _update_sprite(delta: float) -> void:
	var row := 0
	if facing == Vector2.LEFT:
		row = 1
	elif facing == Vector2.RIGHT:
		row = 2
	elif facing == Vector2.UP:
		row = 3

	var is_moving := velocity.length_squared() > 0.0 \
			and attack_animation_time_remaining == 0.0
	animation_time += delta
	var frame := int(animation_time / IDLE_FRAME_DURATION) % 2
	if attack_animation_time_remaining > 0.0:
		var progress := 1.0 - (
			attack_animation_time_remaining / ATTACK_ANIMATION_DURATION
		)
		var attack_frame_count := 2 if row == 1 or row == 2 else 4
		frame = ATTACK_FRAME_START + mini(
			int(progress * attack_frame_count),
			attack_frame_count - 1
		)
	elif is_moving:
		var movement_frame_count := 2 if row == 1 or row == 2 else 6
		var movement_frame := int(animation_time / WALK_FRAME_DURATION)
		movement_frame %= movement_frame_count
		frame = MOVEMENT_FRAME_START + movement_frame
	sprite.position = sprite_base_position
	if is_moving:
		sprite.position.y += sin(animation_time * TAU / (WALK_FRAME_DURATION * 2.0)) * 1.2
	sprite.region_rect = Rect2(
		frame * FRAME_WIDTH,
		row * FRAME_HEIGHT,
		FRAME_WIDTH,
		FRAME_HEIGHT
	)


## Starts the hunt: notices the player approaching, or being hit from range.
func alert() -> void:
	if is_alert or health <= 0.0:
		return
	is_alert = true
	if stun_time_remaining == 0.0:
		set_physics_process(true)


func _update_alertness(delta: float) -> void:
	if always_alert or health <= 0.0 or target == null or not is_instance_valid(target):
		return
	var distance := global_position.distance_to(target.global_position)
	if not is_alert and distance <= AGGRO_RANGE:
		alert()
	elif is_alert and distance > LEASH_RANGE:
		is_alert = false
		state = State.CHASING
		velocity = Vector2.ZERO
		set_physics_process(false)
	if not is_alert:
		_update_sprite(delta)


func take_damage(amount: float) -> void:
	if health <= 0:
		return
	alert()

	if randf() < minf(get_stat(MonsterModifiers.STAT_DODGE), MonsterModifiers.MAX_DODGE_CHANCE):
		HitFeedback.number(get_parent(), _body_point(), 0.0)
		return

	var reduction := minf(
		get_stat(MonsterModifiers.STAT_DAMAGE_REDUCTION)
				+ get_aura_bonus(MonsterModifiers.STAT_AURA_DAMAGE_REDUCTION),
		MonsterModifiers.MAX_DAMAGE_REDUCTION
	)
	var damage_taken := minf(amount * curse_damage_multiplier * (1.0 - reduction), health)
	health -= damage_taken
	health_bar.value = health
	last_hit = self
	_react_to_hit(damage_taken)
	_reflect_damage(damage_taken)
	if health == 0:
		died.emit()
		queue_free()


func apply_stun(duration: float) -> void:
	if health <= 0.0:
		return
	stun_time_remaining = maxf(stun_time_remaining, duration)
	velocity = Vector2.ZERO
	set_physics_process(false)


func apply_curse(duration: float, damage_multiplier: float) -> void:
	if health <= 0.0:
		return
	curse_time_remaining = maxf(curse_time_remaining, duration)
	curse_damage_multiplier = maxf(curse_damage_multiplier, damage_multiplier)


func take_percentage_damage(fraction: float) -> void:
	take_damage(max_health * clampf(fraction, 0.0, 1.0))


## Damages the player with this monster's modifiers applied. Returns the damage the player actually took.
func deal_damage(base_amount: int) -> int:
	if target == null or not is_instance_valid(target):
		return 0
	var damage_dealt := target.take_damage(get_outgoing_damage(base_amount))
	register_hit(damage_dealt)
	return damage_dealt


## Scales a base damage value by damage modifiers. Projectiles use this when they're fired.
func get_outgoing_damage(base_amount: int) -> int:
	var multiplier := 1.0 + get_stat(MonsterModifiers.STAT_DAMAGE) \
			+ get_aura_bonus(MonsterModifiers.STAT_AURA_DAMAGE)
	return roundi(base_amount * multiplier * damage_scale)


## Called whenever this monster, or a projectile it fired, damages the player.
func register_hit(damage_dealt: int) -> void:
	var lifesteal := get_stat(MonsterModifiers.STAT_LIFESTEAL)
	if damage_dealt <= 0 or lifesteal <= 0.0 or health <= 0.0:
		return
	health = minf(health + max_health * lifesteal, max_health)
	health_bar.value = health


## Multiplier for movement speed. Use get_action_delta() for attack timers.
func get_speed_multiplier() -> float:
	return 1.0 + get_stat(MonsterModifiers.STAT_SPEED) \
			+ get_aura_bonus(MonsterModifiers.STAT_AURA_SPEED)


## Frame delta scaled by attack speed, for wind-ups and cooldowns.
func get_action_delta(delta: float) -> float:
	return delta * get_speed_multiplier()


func get_stat(stat: String) -> float:
	return float(modifier_stats.get(stat, 0.0))


func get_aura_bonus(stat: String) -> float:
	return float(aura_bonuses.get(stat, 0.0))


func get_gold_multiplier() -> float:
	return 1.0 + get_stat(MonsterModifiers.STAT_GOLD)


func get_extra_item_drops() -> int:
	return roundi(get_stat(MonsterModifiers.STAT_EXTRA_ITEMS))


func _apply_modifiers() -> void:
	modifier_stats = MonsterModifiers.combine_stats(modifier_ids)
	if modifier_ids.is_empty():
		return

	max_health *= 1.0 + get_stat(MonsterModifiers.STAT_MAX_HEALTH)
	experience_reward = roundi(
		experience_reward
		* (1.0 + MonsterModifiers.EXPERIENCE_BONUS_PER_MODIFIER * modifier_ids.size())
	)
	if get_stat(MonsterModifiers.STAT_AURA_RADIUS) > 0.0:
		add_to_group(AURA_GROUP)
	_add_modifier_label()


func _add_modifier_label() -> void:
	var names: PackedStringArray = []
	for modifier_id in modifier_ids:
		names.append(MonsterModifiers.get_display_name(modifier_id))
	var label := Label.new()
	label.name = "ModifierLabel"
	label.text = "\n".join(names)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_constant_override("outline_size", 3)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.85))
	label.add_theme_color_override(
		"font_color",
		MULTI_MODIFIER_LABEL_COLOR if modifier_ids.size() > 1 else MODIFIER_LABEL_COLOR
	)
	# Parented to the health bar so it hides with it while a monster burrows or phases.
	health_bar.add_child(label)
	label.reset_size()
	label.position = Vector2(health_bar.size.x * 0.5 - label.size.x * 0.5, -label.size.y - 1.0)


func _refresh_aura_bonuses() -> void:
	aura_bonuses.clear()
	for node in get_tree().get_nodes_in_group(AURA_GROUP):
		var source := node as Wolf
		if source == null or source == self or source.health <= 0.0:
			continue
		var radius := source.get_stat(MonsterModifiers.STAT_AURA_RADIUS)
		if global_position.distance_squared_to(source.global_position) > radius * radius:
			continue
		for stat in MonsterModifiers.AURA_STATS:
			aura_bonuses[stat] = maxf(get_aura_bonus(stat), source.get_stat(stat))


## Reflection is relative: losing 50% of the monster's HP with 15% reflect costs the player
## 7.5% of their max HP. Player and monster HP use very different scales, so raw values can't be used.
func _reflect_damage(damage_taken: float) -> void:
	var reflect := get_stat(MonsterModifiers.STAT_REFLECT)
	if reflect <= 0.0 or damage_taken <= 0.0 or target == null or not is_instance_valid(target):
		return
	var reflected := maxi(roundi(damage_taken / max_health * reflect * target.get_max_health()), 1)
	target.take_damage(reflected)


# --- Hit reactions -------------------------------------------------------------------------------------

## A hit for at least this share of max health is heavy: it staggers longer and interrupts an attack.
const HEAVY_HIT_FRACTION := 0.2
const FLINCH_TIME := 0.1
const STAGGER_TIME := 0.35
const KNOCKBACK := 170.0
const HEAVY_KNOCKBACK := 290.0
const KNOCKBACK_DECAY := 1300.0
const FLASH_TIME := 0.13
## After a stagger a monster keeps its footing this long, so rapid hits can't pin it in place.
const STAGGER_RECOVERY := 0.8


## Picks the living monster drawn under `point` (world space); overlapping sprites go to the one whose
## feet are nearest. `padding` grows each sprite's box in screen-ish pixels.
static func find_at(tree: SceneTree, point: Vector2, padding := 6.0) -> Wolf:
	var best: Wolf = null
	var best_distance := INF
	for node in tree.get_nodes_in_group("enemies"):
		var enemy := node as Wolf
		if enemy == null or enemy.health <= 0.0 or not enemy.is_inside_tree() or not enemy.sprite.is_visible_in_tree():
			continue
		var sprite_padding := padding / maxf(enemy.sprite.global_transform.get_scale().x, 0.01)
		if not enemy.sprite.get_rect().grow(sprite_padding).has_point(enemy.sprite.to_local(point)):
			continue
		var distance := enemy.global_position.distance_squared_to(point)
		if distance < best_distance:
			best = enemy
			best_distance = distance
	return best


## Roughly the middle of the monster's body, where hits land and numbers rise from.
func _body_point() -> Vector2:
	return sprite.global_position + Vector2(0.0, -12.0)


## Flash, a damage number and sparks, then a shove away from the player; anything but a boss flinches,
## and a heavy blow staggers it and breaks off whatever attack it was winding up.
func _react_to_hit(damage_taken: float) -> void:
	if damage_taken <= 0.0:
		return
	var heavy := damage_taken >= max_health * HEAVY_HIT_FRACTION
	var away := Vector2.RIGHT
	if target != null and is_instance_valid(target):
		away = (global_position - target.global_position).normalized()
	hit_flash = 1.0
	HitFeedback.number(get_parent(), _body_point() + Vector2(0.0, -14.0), damage_taken, heavy)
	HitFeedback.sparks(get_parent(), _body_point() - away * 8.0, away, heavy)
	if health <= 0.0:
		return
	# Small hits only nudge; a blow worth a fifth of its health or more sends it flying.
	var weight := clampf(damage_taken / (max_health * HEAVY_HIT_FRACTION), 0.2, 1.0)
	var push := HEAVY_KNOCKBACK if heavy else KNOCKBACK * weight
	hit_knockback += away * push * (0.12 if stagger_immune else 1.0)
	if stagger_immune or stagger_recovery > 0.0:
		return
	stagger_recovery = STAGGER_RECOVERY
	apply_stun(STAGGER_TIME if heavy else FLINCH_TIME)
	if heavy:
		_interrupt_attack()


## Breaks off an attack in progress. Monsters with their own attack states override this.
func _interrupt_attack() -> void:
	if state == State.WINDING_UP:
		state = State.COOLDOWN
		state_timer = ATTACK_COOLDOWN * 0.5
	attack_animation_time_remaining = 0.0
	swipe_timer = 0.0
	swipe.hide()


func _update_hit_reaction(delta: float) -> void:
	stagger_recovery = maxf(stagger_recovery - delta, 0.0)
	if hit_knockback.length_squared() > 1.0:
		move_and_collide(hit_knockback * delta)
		hit_knockback = hit_knockback.move_toward(Vector2.ZERO, KNOCKBACK_DECAY * delta)
	hit_flash = maxf(hit_flash - delta / FLASH_TIME, 0.0)
	# White flash on a hit, a faint glow while the mouse is over it.
	var glow := hit_flash * 2.2 + (0.22 if hovered else 0.0)
	sprite.self_modulate = Color(1.0 + glow, 1.0 + glow, 1.0 + glow)
