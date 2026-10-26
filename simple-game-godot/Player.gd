extends CharacterBody2D
class_name Player

signal health_changed(current_health: int, maximum_health: int)
signal mana_changed(current_mana: int, maximum_mana: int)
signal potion_counts_changed(health_count: int, mana_count: int, health_refill: float, mana_refill: float)
signal inventory_changed(items: Array[ItemData])
signal equipment_changed(equipment: Dictionary)
signal town_portal_cast_started
signal town_portal_cast_progress(remaining: float, duration: float)
signal town_portal_cast_cancelled
signal town_portal_opened
signal died


const SPEED = 300.0
const MAX_INVENTORY_SIZE = 25
const ACCELERATION = 1200.0
const DECELERATION = 1600.0
const MAX_HEALTH = 100
const WARRIOR_FRAME_SIZE = 100
const WARRIOR_WALK_FRAME_DURATION = 0.16
const RANGER_FRAME_SIZE = 100
const RANGER_WALK_FRAME_DURATION = 0.14
const RANGER_ATTACK_DURATION = 0.42
const WITCH_FRAME_SIZE = 100
const WITCH_WALK_FRAME_DURATION = 0.16
const WITCH_ATTACK_DURATION = 0.48
const ATTACK_DURATION = 0.3
const ATTACK_ARC = 1.35
const SWORD_REACH = 64.0
const SWORD_HIT_DOT_THRESHOLD = 0.2
const SWORD_HIT_TIME = 0.1
const MOUSE_DRAG_THRESHOLD = 8.0
const MAX_MANA = 100
const FIREBALL_MANA_COST = 25
const ICEBALL_MANA_COST = 0
const ICEBALL_COOLDOWN = 2.0
const MAX_POTIONS = 3
const POTION_REFILL_TIME = 10.0
const POTION_EFFECT_TIME = 3.0
const TOWN_PORTAL_CAST_DURATION = 3.0
const FIREBALL_SCENE = preload("res://fireball.tscn")
const WITCH_FAMILIAR_SCENE = preload("res://witch_familiar.tscn")
const WARRIOR_SHEET = preload("res://textures/warrior_sprite_atlas.png")
const WITCH_SHEET = preload("res://textures/witch_sprite_atlas.png")
const RANGER_SHEET = preload("res://textures/ranger_sprite_atlas.png")
const RANGER_ARROW_SCRIPT = preload("res://RangerArrow.gd")
const PORTAL_SCENE = preload("res://portal.tscn")
const TOWN_SCENE_PATH = "res://town.tscn"
const TOWN_ARRIVAL_POSITION = Vector2(576, 350)
const TOWN_RETURN_SCENE_META = "town_return_scene"
const TOWN_RETURN_POSITION_META = "town_return_position"

@export_enum("None", "Fireball", "Iceball", "Town Portal") var e_skill := "None"

var health := MAX_HEALTH
var mana := MAX_MANA
var health_potions := MAX_POTIONS
var mana_potions := MAX_POTIONS
var inventory: Array[ItemData] = []
var equipment: Dictionary = {}
var health_refill_timers: Array[float] = []
var mana_refill_timers: Array[float] = []
## Health and mana a drunk potion still has to pour in: what was missing when it was drunk, so a
## potion never fills past the maximum or tops up damage taken while it works.
var health_potion_remaining := 0.0
var mana_potion_remaining := 0.0
var health_heal_accumulator := 0.0
var mana_heal_accumulator := 0.0
var potion_ui_timer := 0.0
var facing := Vector2.DOWN
## Direction attacks and skills fire in. Matches facing unless free_aim is on
## (touch controls) or an aim stick is held.
var aim_direction := Vector2.DOWN
var aim_held := false
var free_aim := false
var sprite_base_scale := Vector2.ONE
var witch_attack_time_remaining := 0.0
var chill_time_remaining := 0.0
var chill_speed_factor := 1.0
var knockback_velocity := Vector2.ZERO
var arcane_shield_time_remaining := 0.0
var arcane_shield_damage_reduction := 0.0
var frost_nova_visual_time_remaining := 0.0
var witch_skill_cooldowns: Dictionary = {}
var warrior_skill_cooldowns: Dictionary = {}
var ranger_skill_cooldowns: Dictionary = {}
var war_cry_time_remaining := 0.0
var iron_resolve_time_remaining := 0.0
var iron_resolve_heal_accumulator := 0.0
var warrior_aoe_visual_time_remaining := 0.0
var warrior_aoe_visual_radius := 0.0
var warrior_skill_animation_id := ""
var warrior_skill_animation_time_remaining := 0.0
var warrior_skill_animation_tween: Tween
var ranger_attack_animation_time_remaining := 0.0
var ranger_attack_cooldown_remaining := 0.0
var ranger_walk_distance := 0.0
var ranger_smoke_visual_time_remaining := 0.0
var ranger_smoke_visual_radius := 0.0
var witch_familiar: WitchFamiliar
var selected_character := "Warrior"
var click_destination := Vector2.ZERO
var click_move_active := false
var mouse_move_held := false
var mouse_dragged := false
var mouse_press_position := Vector2.ZERO
var animation_time := 0.0
var iceball_cooldown_remaining := 0.0
var attack_time_remaining := 0.0
var attack_hit_applied := false
var town_portal: Portal
var town_portal_cast_time_remaining := 0.0
var is_casting_town_portal := false

@onready var sprite: Sprite2D = $Sprite2D
@onready var sword: Node2D = $Sword
@onready var wand: Node2D = $Wand
@onready var portal_cast_effect: Node2D = $PortalCastEffect


func _ready() -> void:
	# Top-down movement; the default (grounded) mode treats bodies below as floors to ride on.
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	selected_character = str(get_tree().get_meta("selected_character", "Warrior"))
	match selected_character:
		"Witch":
			sprite.texture = WITCH_SHEET
		"Ranger":
			sprite.texture = RANGER_SHEET
		_:
			sprite.texture = WARRIOR_SHEET
	sprite_base_scale = Vector2(0.64, 0.64)
	sprite.scale = sprite_base_scale
	sword.hide()
	wand.hide()
	inventory = GameState.get_inventory()
	equipment = GameState.get_equipment()
	if get_tree().has_meta("portal_spawn_position"):
		var spawn_position: Variant = get_tree().get_meta("portal_spawn_position")
		get_tree().remove_meta("portal_spawn_position")
		if spawn_position is Vector2:
			global_position = spawn_position
		else:
			push_error("Portal spawn position must be a Vector2.")
	var current_scene := get_tree().current_scene
	if current_scene != null:
		var level_id: int = GameState.get_level_id(current_scene.scene_file_path)
		if level_id > 0:
			var level_state: Dictionary = GameState.get_level_state(level_id)
			if not level_state.is_empty():
				var saved_position: Variant = level_state.get("player_position", null)
				if typeof(saved_position) == TYPE_ARRAY and saved_position.size() == 2 \
						and typeof(saved_position[0]) in [TYPE_INT, TYPE_FLOAT] \
						and typeof(saved_position[1]) in [TYPE_INT, TYPE_FLOAT]:
					global_position = Vector2(
						float(saved_position[0]),
						float(saved_position[1])
					)
				else:
					push_error("Saved player position for level %d is invalid." % level_id)
	health = get_max_health()
	mana = get_max_mana()
	if get_tree().has_meta("portal_player_vitals"):
		var saved_vitals: Variant = get_tree().get_meta("portal_player_vitals")
		get_tree().remove_meta("portal_player_vitals")
		if typeof(saved_vitals) == TYPE_DICTIONARY:
			health = clampi(int(saved_vitals.get("health", health)), 0, get_max_health())
			mana = clampi(int(saved_vitals.get("mana", mana)), 0, get_max_mana())
		else:
			push_error("Portal player vitals must be a Dictionary.")


func _physics_process(delta: float) -> void:
	_update_potion_refills(delta)
	_update_potion_effects(delta)
	iceball_cooldown_remaining = maxf(iceball_cooldown_remaining - delta, 0.0)
	ranger_attack_cooldown_remaining = maxf(ranger_attack_cooldown_remaining - delta, 0.0)
	ranger_attack_animation_time_remaining = maxf(
		ranger_attack_animation_time_remaining - delta,
		0.0
	)
	ranger_smoke_visual_time_remaining = maxf(ranger_smoke_visual_time_remaining - delta, 0.0)
	witch_attack_time_remaining = maxf(witch_attack_time_remaining - delta, 0.0)
	chill_time_remaining = maxf(chill_time_remaining - delta, 0.0)
	var shield_was_active := arcane_shield_time_remaining > 0.0
	arcane_shield_time_remaining = maxf(arcane_shield_time_remaining - delta, 0.0)
	frost_nova_visual_time_remaining = maxf(frost_nova_visual_time_remaining - delta, 0.0)
	var war_cry_was_active := war_cry_time_remaining > 0.0
	war_cry_time_remaining = maxf(war_cry_time_remaining - delta, 0.0)
	var iron_resolve_was_active := iron_resolve_time_remaining > 0.0
	iron_resolve_time_remaining = maxf(iron_resolve_time_remaining - delta, 0.0)
	if iron_resolve_time_remaining > 0.0:
		iron_resolve_heal_accumulator += (2.0 + float(GameState.get_warrior_skill_rank("iron_resolve"))) * delta
		var restored_health := int(iron_resolve_heal_accumulator)
		if restored_health > 0:
			iron_resolve_heal_accumulator -= restored_health
			health = mini(health + restored_health, get_max_health())
			health_changed.emit(health, get_max_health())
	elif iron_resolve_was_active:
		iron_resolve_heal_accumulator = 0.0
	if war_cry_was_active or iron_resolve_was_active \
			or frost_nova_visual_time_remaining > 0.0 \
			or shield_was_active or arcane_shield_time_remaining > 0.0 \
			or warrior_aoe_visual_time_remaining > 0.0 \
			or warrior_skill_animation_time_remaining > 0.0 \
			or ranger_smoke_visual_time_remaining > 0.0:
		queue_redraw()
	warrior_aoe_visual_time_remaining = maxf(warrior_aoe_visual_time_remaining - delta, 0.0)
	warrior_skill_animation_time_remaining = maxf(
		warrior_skill_animation_time_remaining - delta,
		0.0
	)
	if warrior_skill_animation_time_remaining == 0.0:
		warrior_skill_animation_id = ""
	_update_witch_skill_cooldowns(delta)
	_update_warrior_skill_cooldowns(delta)
	_update_ranger_skill_cooldowns(delta)
	if chill_time_remaining == 0.0:
		chill_speed_factor = 1.0
	if mouse_move_held and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_finish_mouse_move(get_viewport().get_mouse_position())

	var keyboard_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction := keyboard_direction
	if keyboard_direction != Vector2.ZERO:
		click_move_active = false
		mouse_move_held = false
		mouse_dragged = false
	elif click_move_active:
		var to_destination := click_destination - global_position
		if to_destination.length() <= 6.0:
			click_move_active = false
			velocity = Vector2.ZERO
		else:
			direction = to_destination.normalized()

	if is_casting_town_portal:
		velocity = Vector2.ZERO
		animation_time = 0.0
		town_portal_cast_time_remaining = maxf(
			town_portal_cast_time_remaining - delta,
			0.0
		)
		portal_cast_effect.progress = 1.0 - town_portal_cast_time_remaining / TOWN_PORTAL_CAST_DURATION
		town_portal_cast_progress.emit(
			town_portal_cast_time_remaining,
			TOWN_PORTAL_CAST_DURATION
		)
		_update_sprite(false)
		move_and_slide()
		if town_portal_cast_time_remaining == 0.0:
			is_casting_town_portal = false
			portal_cast_effect.stop()
			_spawn_town_portal()
		return

	if direction != Vector2.ZERO:
		var movement_velocity := direction * SPEED * _get_movement_speed_multiplier() \
			* chill_speed_factor
		if knockback_velocity.length_squared() > 0.0:
			movement_velocity += knockback_velocity
			knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 900.0 * delta)
		velocity = velocity.move_toward(movement_velocity, ACCELERATION * delta)
		if not aim_held:
			facing = _cardinal_direction(direction)
			aim_direction = direction.normalized() if free_aim else facing
		animation_time += delta
	else:
		var movement_velocity := knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 900.0 * delta)
		velocity = velocity.move_toward(movement_velocity, DECELERATION * delta)
		animation_time = 0.0

	if Input.is_action_just_pressed("ui_accept") or aim_held:
		_use_primary_attack()

	_update_sword(delta)
	_update_wand()
	if selected_character == "Ranger":
		var previous_position := global_position
		move_and_slide()
		var distance_moved := global_position.distance_to(previous_position)
		if distance_moved > 0.1:
			ranger_walk_distance += distance_moved
		else:
			ranger_walk_distance = 0.0
		_update_sprite(distance_moved > 0.1)
	else:
		_update_sprite(direction != Vector2.ZERO)
		move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if health <= 0:
		return
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and not event.pressed:
		if mouse_move_held:
			_finish_mouse_move(event.position)
		return
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed:
		mouse_press_position = event.position
		mouse_move_held = true
		mouse_dragged = false
		click_destination = get_global_mouse_position()
		click_move_active = true
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion \
			and mouse_move_held \
			and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if event.position.distance_to(mouse_press_position) >= MOUSE_DRAG_THRESHOLD:
			mouse_dragged = true
		click_destination = get_global_mouse_position()
		click_move_active = true
		return
	if not event is InputEventKey or not event.pressed or event.echo:
		return

	if event.keycode == KEY_1:
		_use_health_potion()
	elif event.keycode == KEY_2:
		_use_mana_potion()
	elif event.keycode == KEY_Q:
		activate_skill_slot("Q")
	elif event.keycode == KEY_W:
		activate_skill_slot("W")
	elif event.keycode == KEY_E:
		if not _try_interact():
			activate_skill_slot("E")
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_R:
		activate_skill_slot("R")
	elif event.keycode == KEY_T:
		_open_town_portal()


## Held aim from a touch stick: turns the player and keeps the primary attack
## firing in that direction until release_aim().
func set_aim(direction: Vector2) -> void:
	if direction.is_zero_approx():
		return
	aim_held = true
	aim_direction = direction.normalized()
	facing = _cardinal_direction(aim_direction)


func release_aim() -> void:
	aim_held = false


func tap_attack() -> void:
	if health <= 0 or is_casting_town_portal:
		return
	_use_primary_attack()


func activate_skill_slot(slot: String) -> void:
	if health <= 0 or is_casting_town_portal:
		return
	if selected_character == "Witch":
		if slot == "E":
			if not _cast_assigned_witch_skill(slot):
				_cast_e_skill()
		else:
			_cast_assigned_witch_skill(slot)
	elif selected_character == "Ranger":
		_cast_assigned_ranger_skill(slot)
	elif slot == "Q":
		if not _cast_assigned_warrior_skill(slot):
			_cast_fireball()
	elif slot == "E":
		if not _cast_assigned_warrior_skill(slot):
			_cast_e_skill()
	else:
		_cast_assigned_warrior_skill(slot)


func _try_interact() -> bool:
	var nearest_interactable := get_interact_target()
	if nearest_interactable == null:
		return false
	nearest_interactable.call("interact", self)
	return true


## Nearest interactable the player is in range of, or null.
func get_interact_target() -> Node2D:
	var nearest_interactable: Node2D
	var nearest_distance_squared := INF
	for candidate in get_tree().get_nodes_in_group("interactables"):
		if not candidate is Node2D \
				or not candidate.has_method("can_interact") \
				or not candidate.has_method("interact") \
				or not bool(candidate.call("can_interact", self)):
			continue

		var interactable := candidate as Node2D
		var distance_squared := global_position.distance_squared_to(interactable.global_position)
		if distance_squared < nearest_distance_squared:
			nearest_interactable = interactable
			nearest_distance_squared = distance_squared
	return nearest_interactable


func try_interact() -> bool:
	if health <= 0 or is_casting_town_portal:
		return false
	return _try_interact()


func cast_town_portal() -> void:
	if health <= 0:
		return
	_open_town_portal()


func _use_primary_attack() -> void:
	if selected_character == "Witch":
		if iceball_cooldown_remaining <= 0.0:
			_cast_iceball()
			iceball_cooldown_remaining = ICEBALL_COOLDOWN
	elif selected_character == "Ranger":
		if ranger_attack_cooldown_remaining <= 0.0:
			_spawn_ranger_arrow(
				aim_direction,
				_get_ranger_hit_damage(1.5 + float(get_weapon_damage_bonus()) * 0.5)
			)
			ranger_attack_cooldown_remaining = 0.42
			ranger_attack_animation_time_remaining = RANGER_ATTACK_DURATION
	elif attack_time_remaining <= 0.0:
		attack_time_remaining = ATTACK_DURATION
		attack_hit_applied = false


func _cast_e_skill() -> void:
	match e_skill:
		"Fireball":
			_cast_fireball()
		"Iceball":
			if iceball_cooldown_remaining <= 0.0:
				_cast_iceball()
				iceball_cooldown_remaining = ICEBALL_COOLDOWN
		"Town Portal":
			_open_town_portal()


func _update_witch_skill_cooldowns(delta: float) -> void:
	for skill_id in witch_skill_cooldowns.keys():
		var remaining := maxf(float(witch_skill_cooldowns[skill_id]) - delta, 0.0)
		if remaining == 0.0:
			witch_skill_cooldowns.erase(skill_id)
		else:
			witch_skill_cooldowns[skill_id] = remaining


func _update_warrior_skill_cooldowns(delta: float) -> void:
	for skill_id in warrior_skill_cooldowns.keys():
		var remaining := maxf(float(warrior_skill_cooldowns[skill_id]) - delta, 0.0)
		if remaining == 0.0:
			warrior_skill_cooldowns.erase(skill_id)
		else:
			warrior_skill_cooldowns[skill_id] = remaining


func _update_ranger_skill_cooldowns(delta: float) -> void:
	for skill_id in ranger_skill_cooldowns.keys():
		var remaining := maxf(float(ranger_skill_cooldowns[skill_id]) - delta, 0.0)
		if remaining == 0.0:
			ranger_skill_cooldowns.erase(skill_id)
		else:
			ranger_skill_cooldowns[skill_id] = remaining


func get_warrior_skill_cooldown_ratio(skill_id: String) -> float:
	var remaining := float(warrior_skill_cooldowns.get(skill_id, 0.0))
	if remaining <= 0.0:
		return 0.0
	var definition := GameState.get_warrior_skill_definition(skill_id)
	if definition.is_empty():
		return 0.0
	var rank := GameState.get_warrior_skill_rank(skill_id)
	var cooldown := maxf(float(definition["cooldown"]) - float(rank - 1) * 0.3, 0.5)
	return clampf(remaining / cooldown, 0.0, 1.0)


func get_warrior_skill_tooltip(skill_id: String) -> String:
	var definition := GameState.get_warrior_skill_definition(skill_id)
	var rank := GameState.get_warrior_skill_rank(skill_id)
	if definition.is_empty() or rank <= 0:
		return ""
	return "%s\n%s\n%d mana  |  %.1f sec cooldown" % [
		definition["name"],
		definition["description"],
		definition["mana_cost"],
		maxf(float(definition["cooldown"]) - float(rank - 1) * 0.3, 0.5)
	]


func get_ranger_skill_cooldown_ratio(skill_id: String) -> float:
	var remaining := float(ranger_skill_cooldowns.get(skill_id, 0.0))
	if remaining <= 0.0:
		return 0.0
	var definition := GameState.get_ranger_skill_definition(skill_id)
	if definition.is_empty():
		return 0.0
	var rank := GameState.get_ranger_skill_rank(skill_id)
	var cooldown := maxf(float(definition["cooldown"]) - float(rank - 1) * 0.35, 0.5)
	return clampf(remaining / cooldown, 0.0, 1.0)


func get_ranger_skill_tooltip(skill_id: String) -> String:
	var definition := GameState.get_ranger_skill_definition(skill_id)
	var rank := GameState.get_ranger_skill_rank(skill_id)
	if definition.is_empty() or rank <= 0:
		return ""
	return "%s\n%s\n%d mana  |  %.1f sec cooldown" % [
		definition["name"],
		definition["description"],
		_get_ranger_mana_cost(int(definition["mana_cost"])),
		maxf(float(definition["cooldown"]) - float(rank - 1) * 0.35, 0.5)
	]


func _cast_assigned_ranger_skill(slot: String) -> bool:
	if selected_character != "Ranger":
		return false
	var skill_id := GameState.get_ranger_equipped_skill(slot)
	var rank := GameState.get_ranger_skill_rank(skill_id)
	if skill_id.is_empty() or rank <= 0:
		return false
	if ranger_skill_cooldowns.has(skill_id):
		return true

	var definition := GameState.get_ranger_skill_definition(skill_id)
	if definition.is_empty():
		return false
	var mana_cost := _get_ranger_mana_cost(int(definition["mana_cost"]))
	if mana < mana_cost:
		return true

	mana -= mana_cost
	mana_changed.emit(mana, get_max_mana())
	ranger_skill_cooldowns[skill_id] = maxf(
		float(definition["cooldown"]) - float(rank - 1) * 0.35,
		0.5
	)
	match skill_id:
		"power_shot":
			_spawn_ranger_arrow(
				aim_direction,
				_get_ranger_hit_damage(
					4.0 + float(rank) * 1.8 + float(get_weapon_damage_bonus())
				),
				rank - 1
			)
		"multi_shot":
			var spread := 0.22
			var damage := _get_ranger_hit_damage(
				1.5 + float(rank) * 1.0 + float(get_weapon_damage_bonus()) * 0.5
			)
			_spawn_ranger_arrow(aim_direction.rotated(-spread), damage)
			_spawn_ranger_arrow(aim_direction, damage)
			_spawn_ranger_arrow(aim_direction.rotated(spread), damage)
		"explosive_arrow":
			var trap_multiplier := 1.0 + float(
				GameState.get_ranger_passive_stat_totals().get("trap_efficiency", 0.0)
			)
			_spawn_ranger_arrow(
				aim_direction,
				_get_ranger_hit_damage(
					2.5 + float(rank) * 1.2 + float(get_weapon_damage_bonus())
				),
				0,
				(74.0 + float(rank - 1) * 18.0) * trap_multiplier,
				_get_ranger_hit_damage(
					1.5 + float(rank) * 1.1 + float(get_weapon_damage_bonus()) * 0.5
				)
			)
		"smoke_bomb":
			_cast_ranger_smoke_bomb(rank)
		_:
			ranger_skill_cooldowns.erase(skill_id)
			mana += mana_cost
			mana_changed.emit(mana, get_max_mana())
			return false
	ranger_attack_animation_time_remaining = RANGER_ATTACK_DURATION
	return true


func _spawn_ranger_arrow(
	direction: Vector2,
	arrow_damage: float,
	pierce_count: int = 0,
	explosion_radius: float = 0.0,
	explosion_damage: float = 0.0
) -> void:
	var arrow: RangerArrow = RANGER_ARROW_SCRIPT.new()
	arrow.direction = direction.normalized()
	var passive_stats := GameState.get_ranger_passive_stat_totals()
	arrow.speed = RangerArrow.BASE_SPEED * (
		1.0 + float(passive_stats.get("projectile_speed", 0.0))
	)
	arrow.hit_radius = RangerArrow.BASE_HIT_RADIUS * (
		1.0 + float(passive_stats.get("accuracy", 0.0))
	)
	arrow.max_range = RangerArrow.BASE_MAX_RANGE * (
		1.0 + float(passive_stats.get("accuracy", 0.0))
	)
	arrow.damage = arrow_damage
	arrow.pierce_count = pierce_count
	arrow.explosion_radius = explosion_radius
	arrow.explosion_damage = explosion_damage
	get_tree().current_scene.add_child(arrow)
	arrow.global_position = global_position + direction.normalized() * 24.0


func _cast_ranger_smoke_bomb(rank: int) -> void:
	var trap_multiplier := 1.0 + float(
		GameState.get_ranger_passive_stat_totals().get("trap_efficiency", 0.0)
	)
	var radius := (92.0 + float(rank - 1) * 18.0) * trap_multiplier
	var stagger_duration := (0.55 + float(rank - 1) * 0.2) * trap_multiplier
	ranger_smoke_visual_radius = radius
	ranger_smoke_visual_time_remaining = 0.9
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy is Node2D or not enemy.has_method("apply_stun"):
			continue
		var enemy_node := enemy as Node2D
		if global_position.distance_to(enemy_node.global_position) <= radius:
			enemy.call("apply_stun", stagger_duration)
	queue_redraw()


func _get_ranger_mana_cost(base_cost: int) -> int:
	var reduction := float(
		GameState.get_ranger_passive_stat_totals().get("mana_cost_reduction", 0.0)
	)
	return maxi(roundi(float(base_cost) * (1.0 - clampf(reduction, 0.0, 0.6))), 0)


func _get_ranger_hit_damage(base_damage: float) -> float:
	var stats := GameState.get_ranger_passive_stat_totals()
	var crit_chance := clampf(0.05 + float(stats.get("critical_chance", 0.0)), 0.0, 0.75)
	if randf() < crit_chance:
		return base_damage * (1.5 + float(stats.get("critical_damage", 0.0)))
	return base_damage


func _cast_assigned_warrior_skill(slot: String) -> bool:
	if selected_character != "Warrior":
		return false
	var skill_id := GameState.get_warrior_equipped_skill(slot)
	var rank := GameState.get_warrior_skill_rank(skill_id)
	if skill_id.is_empty() or rank <= 0:
		return false
	if warrior_skill_cooldowns.has(skill_id):
		return true

	var definition := GameState.get_warrior_skill_definition(skill_id)
	if definition.is_empty():
		return false
	var mana_cost := int(definition["mana_cost"])
	if mana < mana_cost:
		return true

	mana -= mana_cost
	mana_changed.emit(mana, get_max_mana())
	var cooldown := maxf(float(definition["cooldown"]) - float(rank - 1) * 0.3, 0.5)
	warrior_skill_cooldowns[skill_id] = cooldown
	match skill_id:
		"heavy_strike":
			_warrior_heavy_strike(rank)
		"shield_bash":
			_warrior_shield_bash(rank)
		"cleave":
			_warrior_cleave(rank)
		"leap_slam":
			_warrior_leap_slam(rank)
		"war_cry":
			war_cry_time_remaining = 8.0 + float(rank - 1) * 2.0
			queue_redraw()
		"iron_resolve":
			iron_resolve_time_remaining = 8.0 + float(rank - 1) * 2.0
			queue_redraw()
		_:
			warrior_skill_cooldowns.erase(skill_id)
			mana += mana_cost
			mana_changed.emit(mana, get_max_mana())
			return false
	_start_warrior_skill_animation(skill_id)
	return true


func _warrior_heavy_strike(rank: int) -> void:
	_damage_enemies_in_front(
		2.0 + float(rank) * 0.65 + float(get_weapon_damage_bonus()),
		78.0,
		0.35
	)


func _warrior_shield_bash(rank: int) -> void:
	var target := _get_facing_enemy(94.0, 0.15)
	if target == null:
		return
	target.call("take_damage", 1.6 + float(rank) * 0.55 + float(get_weapon_damage_bonus()))
	if target.has_method("apply_stun"):
		target.call("apply_stun", 0.55 + float(rank - 1) * 0.2)


func _warrior_cleave(rank: int) -> void:
	var radius := 94.0 + float(rank - 1) * 14.0
	var damage := 0.75 + float(rank) * 0.45 + float(get_weapon_damage_bonus())
	_damage_enemies_in_radius(radius, damage, true)
	_show_warrior_aoe(radius)


func _warrior_leap_slam(rank: int) -> void:
	var nearest_enemy: Node2D
	var nearest_distance := 260.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not _is_live_warrior_target(enemy):
			continue
		var enemy_node := enemy as Node2D
		var distance := global_position.distance_to(enemy_node.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_enemy = enemy_node

	var leap_direction := aim_direction
	if nearest_enemy != null:
		leap_direction = (nearest_enemy.global_position - global_position).normalized()
	var leap_distance := mini(roundi(nearest_distance - 58.0), 150) if nearest_enemy != null else 110
	if leap_distance > 0:
		move_and_collide(leap_direction * float(leap_distance))
	var radius := 104.0 + float(rank - 1) * 14.0
	_damage_enemies_in_radius(
		radius,
		1.4 + float(rank) * 0.65 + float(get_weapon_damage_bonus()),
		false
	)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is Node2D and global_position.distance_to((enemy as Node2D).global_position) <= radius \
				and enemy.has_method("apply_stun"):
			enemy.call("apply_stun", 0.35 + float(rank - 1) * 0.15)
	_show_warrior_aoe(radius)


func _start_warrior_skill_animation(skill_id: String) -> void:
	warrior_skill_animation_id = skill_id
	warrior_skill_animation_time_remaining = 0.58
	queue_redraw()

	if skill_id in ["heavy_strike", "shield_bash", "cleave"]:
		attack_time_remaining = 0.38
		attack_hit_applied = true

	if is_instance_valid(warrior_skill_animation_tween):
		warrior_skill_animation_tween.kill()
	sprite.position = Vector2.ZERO
	sprite.scale = sprite_base_scale
	sprite.modulate = Color.WHITE

	var start_offset := -aim_direction * 4.0
	var strike_offset := aim_direction * 8.0
	var tint := Color.WHITE
	match skill_id:
		"heavy_strike":
			strike_offset += aim_direction * 3.0
			tint = Color("#ffe4a0")
		"shield_bash":
			strike_offset += aim_direction * 9.0
			tint = Color("#9de8ff")
		"cleave":
			tint = Color("#ffd08a")
		"leap_slam":
			start_offset += Vector2(0.0, -10.0)
			strike_offset += Vector2(0.0, -16.0)
			tint = Color("#ffe08a")
		"war_cry":
			tint = Color("#ffc95a")
		"iron_resolve":
			tint = Color("#c2edab")

	warrior_skill_animation_tween = create_tween()
	warrior_skill_animation_tween.tween_property(sprite, "position", start_offset, 0.08) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	warrior_skill_animation_tween.tween_property(sprite, "position", strike_offset, 0.12) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	warrior_skill_animation_tween.parallel().tween_property(
		sprite,
		"scale",
		sprite_base_scale * (
			Vector2(1.16, 0.9) if skill_id != "leap_slam" else Vector2(0.94, 1.16)
		),
		0.12
	)
	warrior_skill_animation_tween.parallel().tween_property(
		sprite,
		"modulate",
		tint,
		0.12
	)
	warrior_skill_animation_tween.tween_property(sprite, "position", Vector2.ZERO, 0.2) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	warrior_skill_animation_tween.parallel().tween_property(
		sprite,
		"scale",
		sprite_base_scale,
		0.2
	)
	warrior_skill_animation_tween.parallel().tween_property(sprite, "modulate", Color.WHITE, 0.2)


func _get_facing_enemy(max_distance: float, min_dot: float) -> Node2D:
	var nearest_enemy: Node2D
	var nearest_distance := max_distance
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not _is_live_warrior_target(enemy):
			continue
		var enemy_node := enemy as Node2D
		var to_enemy := enemy_node.global_position - global_position
		var distance := to_enemy.length()
		if distance <= nearest_distance and distance > 0.0 \
				and to_enemy.normalized().dot(aim_direction) >= min_dot:
			nearest_enemy = enemy_node
			nearest_distance = distance
	return nearest_enemy


func _damage_enemies_in_front(damage: float, max_distance: float, min_dot: float) -> void:
	var target := _get_facing_enemy(max_distance, min_dot)
	if target != null and target.has_method("take_damage"):
		target.call("take_damage", damage * _get_war_cry_attack_multiplier())


func _damage_enemies_in_radius(radius: float, damage: float, facing_only: bool) -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not _is_live_warrior_target(enemy) or not enemy.has_method("take_damage"):
			continue
		var enemy_node := enemy as Node2D
		var to_enemy := enemy_node.global_position - global_position
		if to_enemy.length() > radius:
			continue
		if facing_only and not to_enemy.is_zero_approx() \
				and to_enemy.normalized().dot(aim_direction) < -0.25:
			continue
		enemy.call("take_damage", damage * _get_war_cry_attack_multiplier())


func _is_live_warrior_target(enemy: Node) -> bool:
	var wolf := enemy as Wolf
	return wolf != null and wolf.health > 0.0


func _show_warrior_aoe(radius: float) -> void:
	warrior_aoe_visual_radius = radius
	warrior_aoe_visual_time_remaining = 0.35
	queue_redraw()


func _get_war_cry_attack_multiplier() -> float:
	if war_cry_time_remaining <= 0.0:
		return 1.0
	return 1.25 + float(GameState.get_warrior_skill_rank("war_cry") - 1) * 0.1


func get_witch_skill_cooldown_ratio(skill_id: String) -> float:
	var remaining := float(witch_skill_cooldowns.get(skill_id, 0.0))
	if remaining <= 0.0:
		return 0.0
	var definition := GameState.get_witch_skill_definition(skill_id)
	if definition.is_empty():
		return 0.0
	var rank := GameState.get_witch_skill_rank(skill_id)
	var cooldown := maxf(float(definition["cooldown"]) - float(rank - 1) * 0.12, 0.5)
	return clampf(remaining / cooldown, 0.0, 1.0)


func get_witch_skill_tooltip(skill_id: String) -> String:
	var rank := GameState.get_witch_skill_rank(skill_id)
	if rank <= 0:
		return ""

	var definition := GameState.get_witch_skill_definition(skill_id)
	if definition.is_empty():
		return ""
	var damage_bonus := get_weapon_damage_bonus()
	var spell_mult := get_spell_damage_multiplier()
	match skill_id:
		"firebolt":
			return "Firebolt\nDamage: %.1f per hit" % [(1.2 + float(rank) * 0.8 + damage_bonus) * spell_mult]
		"frost_nova":
			return "Frost Nova\nDamage: %.2f per enemy\nAlso stuns nearby enemies" % [(1.5 + float(rank) * 0.75 + damage_bonus) * spell_mult]
		"summon_wisp":
			return "Summon Wisp\nDamage: %.1f per bolt\nWisp duration: %.0f sec" % [
				(1.0 + float(rank)) * spell_mult,
				9.0 + float(rank - 1) * 3.0
			]
		"soul_siphon":
			return "Soul Siphon\nDamage: %.1f\nRestores health and mana" % [(2.0 + float(rank) * 1.5 + damage_bonus) * spell_mult]
		"arcane_shield":
			return "Arcane Shield\nNo direct damage\nReduces incoming damage by %d%% for %.1f sec" % [
				roundi((0.5 + float(rank - 1) * 0.1) * 100.0),
				4.0 + float(rank - 1) * 1.5
			]
		"curse":
			return "Curse\nNo direct damage\nTarget takes %d%% more damage for %.1f sec" % [
				roundi((0.3 + float(rank - 1) * 0.15) * 100.0),
				5.0 + float(rank - 1)
			]
	return str(definition.get("description", ""))


func _cast_assigned_witch_skill(slot: String) -> bool:
	var skill_id := GameState.get_witch_equipped_skill(slot)
	var rank := GameState.get_witch_skill_rank(skill_id)
	if skill_id.is_empty() or rank <= 0 or witch_skill_cooldowns.has(skill_id):
		return false

	var definition := GameState.get_witch_skill_definition(skill_id)
	if definition.is_empty():
		return false
	var mana_cost := int(definition["mana_cost"])
	if mana < mana_cost:
		return true

	mana -= mana_cost
	mana_changed.emit(mana, get_max_mana())
	var cooldown := maxf(float(definition["cooldown"]) - float(rank - 1) * 0.12, 0.5)
	witch_skill_cooldowns[skill_id] = cooldown
	match skill_id:
		"firebolt":
			_cast_witch_firebolt(rank)
		"frost_nova":
			_cast_witch_frost_nova(rank)
		"summon_wisp":
			_cast_witch_summon_wisp(rank)
		"soul_siphon":
			_cast_witch_soul_siphon(rank)
		"arcane_shield":
			arcane_shield_time_remaining = 4.0 + float(rank - 1) * 1.5
			arcane_shield_damage_reduction = 0.5 + float(rank - 1) * 0.1
			witch_attack_time_remaining = WITCH_ATTACK_DURATION
		"curse":
			_cast_witch_curse(rank)
		_:
			witch_skill_cooldowns.erase(skill_id)
			mana += mana_cost
			mana_changed.emit(mana, get_max_mana())
			return false
	return true


func _cast_witch_firebolt(rank: int) -> void:
	var projectile: Fireball = FIREBALL_SCENE.instantiate()
	projectile.direction = aim_direction
	projectile.direct_damage = (1.2 + float(rank) * 0.8 + get_weapon_damage_bonus()) * get_spell_damage_multiplier()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = global_position + aim_direction * 20.0


func _cast_witch_frost_nova(rank: int) -> void:
	frost_nova_visual_time_remaining = 0.55
	var radius := 118.0 + float(rank - 1) * 22.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy is Node2D or not enemy.has_method("take_damage"):
			continue
		var enemy_node := enemy as Node2D
		if global_position.distance_to(enemy_node.global_position) <= radius:
			enemy.call("take_damage", (1.5 + float(rank) * 0.75 + get_weapon_damage_bonus()) * get_spell_damage_multiplier())
			if enemy.has_method("apply_stun"):
				enemy.call("apply_stun", 0.55 + float(rank - 1) * 0.25)


func _cast_witch_summon_wisp(rank: int) -> void:
	if is_instance_valid(witch_familiar):
		witch_familiar.duration_remaining = maxf(
			witch_familiar.duration_remaining,
			9.0 + float(rank - 1) * 3.0
		)
		witch_familiar.damage = (1.0 + float(rank)) * get_spell_damage_multiplier()
		return

	witch_familiar = WITCH_FAMILIAR_SCENE.instantiate() as WitchFamiliar
	if witch_familiar == null:
		push_error("The Witch familiar scene root must use the WitchFamiliar script.")
		return
	witch_familiar.owner_player = self
	witch_familiar.duration = 9.0 + float(rank - 1) * 3.0
	witch_familiar.damage = (1.0 + float(rank)) * get_spell_damage_multiplier()
	get_tree().current_scene.add_child(witch_familiar)
	witch_familiar.global_position = global_position + Vector2(32.0, -28.0)


func _cast_witch_soul_siphon(rank: int) -> void:
	var target_enemy := _find_nearest_enemy(360.0)
	if target_enemy == null:
		return
	target_enemy.call("take_damage", (2.0 + float(rank) * 1.5 + get_weapon_damage_bonus()) * get_spell_damage_multiplier())
	health = mini(health + 3 + rank * 2, get_max_health())
	mana = mini(mana + 5 + rank * 3, get_max_mana())
	health_changed.emit(health, get_max_health())
	mana_changed.emit(mana, get_max_mana())


func _cast_witch_curse(rank: int) -> void:
	var target_enemy := _find_nearest_enemy(440.0)
	if target_enemy != null and target_enemy.has_method("apply_curse"):
		target_enemy.call("apply_curse", 5.0 + float(rank - 1), 1.3 + float(rank - 1) * 0.15)


func _find_nearest_enemy(max_distance: float) -> Node2D:
	var nearest_enemy: Node2D
	var nearest_distance := max_distance
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy is Node2D or not enemy.has_method("take_damage"):
			continue
		var enemy_node := enemy as Node2D
		var distance := global_position.distance_to(enemy_node.global_position)
		if distance < nearest_distance:
			nearest_enemy = enemy_node
			nearest_distance = distance
	return nearest_enemy


func _finish_mouse_move(release_position: Vector2) -> void:
	if release_position.distance_to(mouse_press_position) >= MOUSE_DRAG_THRESHOLD:
		mouse_dragged = true

	mouse_move_held = false
	if mouse_dragged:
		click_move_active = false
		velocity = Vector2.ZERO
	elif (click_destination - global_position).length() <= 6.0:
		click_move_active = false
		velocity = Vector2.ZERO
	else:
		click_move_active = true
	mouse_dragged = false


func _open_town_portal() -> void:
	var current_scene_path := get_tree().current_scene.scene_file_path
	if GameState.get_level_id(current_scene_path) == 0:
		return
	if is_casting_town_portal:
		return

	is_casting_town_portal = true
	town_portal_cast_time_remaining = TOWN_PORTAL_CAST_DURATION
	velocity = Vector2.ZERO
	attack_time_remaining = 0.0
	sword.hide()
	wand.hide()
	portal_cast_effect.play()
	town_portal_cast_started.emit()


func _spawn_town_portal() -> void:
	var current_scene_path := get_tree().current_scene.scene_file_path
	if GameState.get_level_id(current_scene_path) == 0:
		return

	var current_scene := get_tree().current_scene
	if is_instance_valid(town_portal):
		if town_portal.get_parent() == current_scene:
			current_scene.remove_child(town_portal)
		town_portal.queue_free()
		town_portal = null

	var portal := PORTAL_SCENE.instantiate() as Portal
	if portal == null:
		push_error("The portal scene root must use the Portal script.")
		return

	portal.destination_scene = TOWN_SCENE_PATH
	portal.destination_position = TOWN_ARRIVAL_POSITION
	get_tree().set_meta(TOWN_RETURN_SCENE_META, current_scene_path)
	get_tree().set_meta(TOWN_RETURN_POSITION_META, global_position)
	current_scene.add_child(portal)
	portal.global_position = global_position + facing * 64.0
	town_portal = portal
	town_portal_opened.emit()


func _cancel_town_portal_cast() -> void:
	if not is_casting_town_portal:
		return

	is_casting_town_portal = false
	town_portal_cast_time_remaining = 0.0
	portal_cast_effect.stop()
	town_portal_cast_cancelled.emit()


func _cast_fireball() -> void:
	_cast_projectile(false, FIREBALL_MANA_COST)


func _cast_iceball() -> void:
	_cast_projectile(true, ICEBALL_MANA_COST)


func _cast_projectile(is_ice: bool, mana_cost: int) -> void:
	if mana < mana_cost:
		return

	if mana_cost > 0:
		mana -= mana_cost
		mana_changed.emit(mana, get_max_mana())
	var fireball: Fireball = FIREBALL_SCENE.instantiate()
	fireball.direction = aim_direction
	fireball.is_ice = is_ice
	if is_ice:
		fireball.ice_damage = _get_primary_attack_damage()
	get_tree().current_scene.add_child(fireball)
	fireball.global_position = global_position + aim_direction * 20.0
	if selected_character == "Witch":
		witch_attack_time_remaining = WITCH_ATTACK_DURATION


func _update_wand() -> void:
	if selected_character != "Witch":
		return

	wand.hide()


func try_add_item(item: ItemData) -> bool:
	if item == null:
		push_error("Cannot add a null item to the inventory.")
		return false
	if inventory.size() >= MAX_INVENTORY_SIZE:
		return false

	inventory.append(item)
	GameState.save_character(inventory, equipment)
	inventory_changed.emit(inventory)
	return true


func gain_experience(amount: int) -> bool:
	return GameState.add_experience(amount)


func purchase_item(item: ItemData) -> bool:
	if not GameState.purchase_item(item, inventory, equipment, MAX_INVENTORY_SIZE):
		return false

	inventory.append(item)
	inventory_changed.emit(inventory)
	return true


func sell_inventory_item(inventory_index: int) -> bool:
	if inventory_index < 0 or inventory_index >= inventory.size():
		push_error("Inventory sale index is out of range.")
		return false

	if not GameState.sell_inventory_item(inventory, equipment, inventory_index):
		return false

	inventory.remove_at(inventory_index)
	inventory_changed.emit(inventory)
	return true


func equip_inventory_item(inventory_index: int) -> bool:
	if inventory_index < 0 or inventory_index >= inventory.size():
		push_error("Inventory item index is out of range.")
		return false

	var item := inventory[inventory_index]
	var slot := item.equipment_slot
	if slot == "Ring":
		if not equipment.has("Ring 1"):
			slot = "Ring 1"
		elif not equipment.has("Ring 2"):
			slot = "Ring 2"
		else:
			slot = "Ring 1"
	elif slot not in ["Weapon", "Helm", "Chest", "Legs", "Gloves", "Boots", "Amulet"]:
		push_error("Item '%s' has unsupported equipment slot '%s'." % [item.display_name, slot])
		return false

	if equipment.has(slot):
		inventory[inventory_index] = equipment[slot]
	else:
		inventory.remove_at(inventory_index)

	equipment[slot] = item
	GameState.save_character(inventory, equipment)
	inventory_changed.emit(inventory)
	equipment_changed.emit(equipment)
	return true


func equip_best_inventory_items() -> int:
	var updated_equipment := equipment.duplicate()
	var changed_slots := 0
	var equipment_slots: Array[String] = [
		"Weapon",
		"Helm",
		"Chest",
		"Legs",
		"Gloves",
		"Boots",
		"Amulet"
	]

	for slot in equipment_slots:
		var current_item := equipment.get(slot) as ItemData
		var best_item := current_item
		var found_better_inventory_item := false
		var best_score := _get_equipment_item_score(current_item) if current_item != null else -1
		for inventory_index in range(inventory.size()):
			var candidate := inventory[inventory_index]
			if candidate.equipment_slot != slot:
				continue
			var candidate_score := _get_equipment_item_score(candidate)
			if candidate_score > best_score:
				best_item = candidate
				found_better_inventory_item = true
				best_score = candidate_score
		if found_better_inventory_item:
			updated_equipment[slot] = best_item
			changed_slots += 1

	var ring_candidates: Array[Dictionary] = []
	for slot in ["Ring 1", "Ring 2"]:
		var equipped_ring := equipment.get(slot) as ItemData
		if equipped_ring != null:
			ring_candidates.append({
				"item": equipped_ring
			})
	for inventory_index in range(inventory.size()):
		if inventory[inventory_index].equipment_slot == "Ring":
			ring_candidates.append({
				"item": inventory[inventory_index]
			})

	var best_rings: Array[Dictionary] = []
	for ring_index in range(mini(2, ring_candidates.size())):
		var best_candidate_index := 0
		var best_score := _get_equipment_item_score(
			ring_candidates[best_candidate_index]["item"] as ItemData
		)
		for candidate_index in range(1, ring_candidates.size()):
			var candidate_score := _get_equipment_item_score(
				ring_candidates[candidate_index]["item"] as ItemData
			)
			if candidate_score > best_score:
				best_candidate_index = candidate_index
				best_score = candidate_score
		best_rings.append(ring_candidates[best_candidate_index])
		ring_candidates.remove_at(best_candidate_index)

	for ring_slot_index in range(2):
		var slot := "Ring %d" % (ring_slot_index + 1)
		var selected_ring := best_rings[ring_slot_index]["item"] as ItemData \
			if ring_slot_index < best_rings.size() else null
		var current_ring := equipment.get(slot) as ItemData
		if selected_ring == current_ring:
			continue
		changed_slots += 1
		if selected_ring == null:
			updated_equipment.erase(slot)
		else:
			updated_equipment[slot] = selected_ring

	if changed_slots == 0:
		return 0

	var equipped_item_ids: Dictionary = {}
	for item in updated_equipment.values():
		var equipped_item := item as ItemData
		if equipped_item != null:
			equipped_item_ids[equipped_item.get_instance_id()] = true

	var updated_inventory: Array[ItemData] = []
	var inventory_item_ids: Dictionary = {}
	for item in inventory:
		if not equipped_item_ids.has(item.get_instance_id()):
			updated_inventory.append(item)
			inventory_item_ids[item.get_instance_id()] = true
	for item in equipment.values():
		var unequipped_item := item as ItemData
		if unequipped_item != null \
				and not equipped_item_ids.has(unequipped_item.get_instance_id()) \
				and not inventory_item_ids.has(unequipped_item.get_instance_id()):
			updated_inventory.append(unequipped_item)

	if not GameState.save_character(updated_inventory, updated_equipment):
		return -1

	inventory = updated_inventory
	equipment = updated_equipment
	inventory_changed.emit(inventory)
	equipment_changed.emit(equipment)
	return changed_slots


func _get_equipment_item_score(item: ItemData) -> int:
	return item.damage_bonus + item.damage_reduction


func get_max_health() -> int:
	var total: int = MAX_HEALTH
	if selected_character == "Witch":
		var passive_stats := GameState.get_witch_passive_stat_totals()
		total += int(passive_stats.get("max_health", 0))
	elif selected_character == "Warrior":
		var passive_stats := GameState.get_warrior_passive_stat_totals()
		total += int(passive_stats.get("max_health", 0))
	elif selected_character == "Ranger":
		var passive_stats := GameState.get_ranger_passive_stat_totals()
		total += int(passive_stats.get("max_health", 0))
	return total


func get_max_mana() -> int:
	var total: int = MAX_MANA
	if selected_character == "Witch":
		var passive_stats := GameState.get_witch_passive_stat_totals()
		total += int(passive_stats.get("max_mana", 0))
	elif selected_character == "Warrior":
		var passive_stats := GameState.get_warrior_passive_stat_totals()
		total += int(passive_stats.get("max_mana", 0))
	elif selected_character == "Ranger":
		var passive_stats := GameState.get_ranger_passive_stat_totals()
		total += int(passive_stats.get("max_mana", 0))
	return total


func get_evasion() -> float:
	var passive_stats: Dictionary
	if selected_character == "Witch":
		passive_stats = GameState.get_witch_passive_stat_totals()
	elif selected_character == "Ranger":
		passive_stats = GameState.get_ranger_passive_stat_totals()
	else:
		return 0.0
	return clampf(float(passive_stats.get("evasion", 0.0)), 0.0, 0.75)


func get_spell_damage_multiplier() -> float:
	if selected_character != "Witch":
		return 1.0
	var passive_stats := GameState.get_witch_passive_stat_totals()
	return maxf(1.0 + float(passive_stats.get("spell_damage_percent", 0.0)), 0.1)


func get_passive_damage_reduction_percent() -> float:
	var passive_stats: Dictionary
	if selected_character == "Witch":
		passive_stats = GameState.get_witch_passive_stat_totals()
	elif selected_character == "Warrior":
		passive_stats = GameState.get_warrior_passive_stat_totals()
	else:
		return 0.0
	return clampf(float(passive_stats.get("damage_reduction_percent", 0.0)), 0.0, 0.8)


func _get_movement_speed_multiplier() -> float:
	if selected_character != "Ranger":
		return 1.0
	var passive_stats := GameState.get_ranger_passive_stat_totals()
	return 1.0 + float(passive_stats.get("movement_speed", 0.0))


func refresh_passives_and_vitals() -> void:
	var max_h := get_max_health()
	var max_m := get_max_mana()
	health = mini(health, max_h)
	mana = mini(mana, max_m)
	health_changed.emit(health, max_h)
	mana_changed.emit(mana, max_m)


func get_weapon_damage_bonus() -> int:
	var bonus := 0
	for slot in ["Weapon", "Ring 1", "Ring 2", "Amulet"]:
		if equipment.has(slot):
			bonus += (equipment[slot] as ItemData).damage_bonus
	if selected_character == "Warrior":
		bonus += int(GameState.get_warrior_passive_stat_totals().get("weapon_damage_bonus", 0))
	return bonus


func get_damage_reduction() -> int:
	var reduction := 0
	for slot in ["Helm", "Chest", "Legs", "Gloves", "Boots"]:
		if equipment.has(slot):
			reduction += (equipment[slot] as ItemData).damage_reduction
	if selected_character == "Warrior":
		reduction += int(GameState.get_warrior_passive_stat_totals().get("armor", 0))
	return reduction


func use_health_potion() -> void:
	if health > 0:
		_use_health_potion()


func use_mana_potion() -> void:
	if health > 0:
		_use_mana_potion()


func _use_health_potion() -> void:
	if health_potions <= 0 or health >= get_max_health() or health_potion_remaining > 0.0:
		return

	health_potions -= 1
	health_refill_timers.append(POTION_REFILL_TIME)
	health_potion_remaining = float(get_max_health() - health)
	_emit_potion_counts()


func _use_mana_potion() -> void:
	if mana_potions <= 0 or mana >= get_max_mana() or mana_potion_remaining > 0.0:
		return

	mana_potions -= 1
	mana_refill_timers.append(POTION_REFILL_TIME)
	mana_potion_remaining = float(get_max_mana() - mana)
	_emit_potion_counts()


func _update_potion_refills(delta: float) -> void:
	var refilled := false
	potion_ui_timer -= delta
	for index in range(health_refill_timers.size() - 1, -1, -1):
		health_refill_timers[index] -= delta
		if health_refill_timers[index] <= 0.0:
			health_refill_timers.remove_at(index)
			health_potions = mini(health_potions + 1, MAX_POTIONS)
			refilled = true

	for index in range(mana_refill_timers.size() - 1, -1, -1):
		mana_refill_timers[index] -= delta
		if mana_refill_timers[index] <= 0.0:
			mana_refill_timers.remove_at(index)
			mana_potions = mini(mana_potions + 1, MAX_POTIONS)
			refilled = true

	if refilled or potion_ui_timer <= 0.0:
		potion_ui_timer = 0.25
		_emit_potion_counts()


## Pours in what a potion has left, at a full globe per POTION_EFFECT_TIME, never past the current
## maximum. The potion is done once its amount is used up or the globe is full.
func _update_potion_effects(delta: float) -> void:
	if health_potion_remaining > 0.0:
		var step := minf(float(get_max_health()) / POTION_EFFECT_TIME * delta, health_potion_remaining)
		health_potion_remaining -= step
		health_heal_accumulator += step
		var health_to_restore := int(health_heal_accumulator)
		health_heal_accumulator -= health_to_restore
		if health_potion_remaining <= 0.0:
			health_to_restore += roundi(health_heal_accumulator)
		health = mini(health + health_to_restore, get_max_health())
		if health_potion_remaining <= 0.0 or health >= get_max_health():
			health_potion_remaining = 0.0
			health_heal_accumulator = 0.0
		health_changed.emit(health, get_max_health())

	if mana_potion_remaining > 0.0:
		var step := minf(float(get_max_mana()) / POTION_EFFECT_TIME * delta, mana_potion_remaining)
		mana_potion_remaining -= step
		mana_heal_accumulator += step
		var mana_to_restore := int(mana_heal_accumulator)
		mana_heal_accumulator -= mana_to_restore
		if mana_potion_remaining <= 0.0:
			mana_to_restore += roundi(mana_heal_accumulator)
		mana = mini(mana + mana_to_restore, get_max_mana())
		if mana_potion_remaining <= 0.0 or mana >= get_max_mana():
			mana_potion_remaining = 0.0
			mana_heal_accumulator = 0.0
		mana_changed.emit(mana, get_max_mana())


func _emit_potion_counts() -> void:
	potion_counts_changed.emit(
		health_potions,
		mana_potions,
		_get_next_refill(health_refill_timers),
		_get_next_refill(mana_refill_timers)
	)


func _get_next_refill(timers: Array[float]) -> float:
	if timers.is_empty():
		return 0.0

	var next_refill := timers[0]
	for timer in timers:
		next_refill = minf(next_refill, timer)
	return next_refill


func _cardinal_direction(direction: Vector2) -> Vector2:
	if absf(direction.x) > absf(direction.y):
		return Vector2.RIGHT if direction.x > 0.0 else Vector2.LEFT
	return Vector2.DOWN if direction.y > 0.0 else Vector2.UP


func _update_sprite(is_moving: bool) -> void:
	var row := 0
	if facing == Vector2.LEFT:
		row = 1
	elif facing == Vector2.RIGHT:
		row = 2
	elif facing == Vector2.UP:
		row = 3

	if selected_character == "Ranger":
		var ranger_frame := 0
		if ranger_attack_animation_time_remaining > 0.0:
			var attack_progress := 1.0 - (
				ranger_attack_animation_time_remaining / RANGER_ATTACK_DURATION
			)
			ranger_frame = 3 + mini(int(attack_progress * 3.0), 2)
		elif is_moving:
			var distance_per_frame := SPEED * RANGER_WALK_FRAME_DURATION
			ranger_frame = 1 + int(ranger_walk_distance / distance_per_frame) % 2
		sprite.region_rect = Rect2(
			ranger_frame * RANGER_FRAME_SIZE,
			row * RANGER_FRAME_SIZE,
			RANGER_FRAME_SIZE,
			RANGER_FRAME_SIZE
		)
		return

	if selected_character != "Witch":
		if facing == Vector2.LEFT:
			row = 2
		elif facing == Vector2.RIGHT:
			row = 1
		var warrior_frame := 1
		if attack_time_remaining > 0.0:
			var attack_duration := 0.38 if warrior_skill_animation_id in [
				"heavy_strike",
				"shield_bash",
				"cleave"
			] else ATTACK_DURATION
			var attack_progress := clampf(
				1.0 - attack_time_remaining / attack_duration,
				0.0,
				1.0
			)
			warrior_frame = 3 + mini(int(attack_progress * 6.0), 5)
		elif is_moving:
			warrior_frame = 1 + (
				int(animation_time / WARRIOR_WALK_FRAME_DURATION) % 2
			)
		sprite.region_rect = Rect2(
			warrior_frame * WARRIOR_FRAME_SIZE,
			row * WARRIOR_FRAME_SIZE,
			WARRIOR_FRAME_SIZE,
			WARRIOR_FRAME_SIZE
		)
		return

	var witch_frame := 0
	if witch_attack_time_remaining > 0.0:
		var attack_progress := 1.0 - witch_attack_time_remaining / WITCH_ATTACK_DURATION
		witch_frame = 3 + mini(int(attack_progress * 6.0), 5)
	elif is_moving:
		witch_frame = 1 + (
			int(animation_time / WITCH_WALK_FRAME_DURATION) % 2
		)
	sprite.region_rect = Rect2(
		witch_frame * WITCH_FRAME_SIZE,
		row * WITCH_FRAME_SIZE,
		WITCH_FRAME_SIZE,
		WITCH_FRAME_SIZE
	)


func _update_sword(delta: float) -> void:
	sword.position = aim_direction * 8.0
	if attack_time_remaining > 0.0:
		attack_time_remaining = maxf(attack_time_remaining - delta, 0.0)
		var special_swing := warrior_skill_animation_id in [
			"heavy_strike",
			"shield_bash",
			"cleave"
		]
		var swing_duration := 0.38 if special_swing else ATTACK_DURATION
		var swing_arc := ATTACK_ARC
		match warrior_skill_animation_id:
			"heavy_strike":
				swing_arc = 2.15
			"shield_bash":
				swing_arc = 0.62
			"cleave":
				swing_arc = 2.8
		var progress := 1.0 - attack_time_remaining / swing_duration
		sword.rotation = aim_direction.angle() + lerpf(-swing_arc, swing_arc, progress)
		match warrior_skill_animation_id:
			"heavy_strike":
				sword.modulate = Color("#ffe4a0")
			"shield_bash":
				sword.modulate = Color("#9de8ff")
			"cleave":
				sword.modulate = Color("#ffd08a")
			_:
				sword.modulate = Color.WHITE
		if selected_character == "Witch":
			sword.show()
		else:
			sword.hide()
		if not attack_hit_applied and progress >= SWORD_HIT_TIME:
			_damage_wolves_in_swing()
			attack_hit_applied = true
	else:
		sword.rotation = aim_direction.angle()
		sword.modulate = Color.WHITE
		sword.hide()


func _damage_wolves_in_swing() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy is Node2D:
			continue

		var enemy_node := enemy as Node2D
		var to_enemy := enemy_node.global_position - global_position
		if to_enemy.length() <= SWORD_REACH and to_enemy.normalized().dot(aim_direction) >= SWORD_HIT_DOT_THRESHOLD:
			enemy.call("take_damage", _get_primary_attack_damage())


func _get_primary_attack_damage() -> float:
	var base := 1.0 + float(get_weapon_damage_bonus())
	if selected_character == "Witch":
		base *= get_spell_damage_multiplier()
	elif selected_character == "Warrior":
		base *= _get_war_cry_attack_multiplier()
	return base


func _draw() -> void:
	if warrior_skill_animation_time_remaining > 0.0:
		_draw_warrior_skill_animation()
	if warrior_aoe_visual_time_remaining > 0.0:
		var progress := 1.0 - warrior_aoe_visual_time_remaining / 0.35
		var radius := lerpf(36.0, warrior_aoe_visual_radius, progress)
		draw_arc(
			Vector2.ZERO,
			radius,
			0.0,
			TAU,
			64,
			Color(0.95, 0.72, 0.28, 1.0 - progress),
			4.0
		)
	if frost_nova_visual_time_remaining > 0.0:
		var progress := 1.0 - frost_nova_visual_time_remaining / 0.55
		var nova_radius := lerpf(36.0, 168.0, progress)
		draw_arc(Vector2.ZERO, nova_radius, 0.0, TAU, 64, Color(0.63, 0.92, 1.0, 1.0 - progress), 4.0)
	if arcane_shield_time_remaining > 0.0:
		var shield_alpha := 0.45 + sin(Time.get_ticks_msec() * 0.012) * 0.12
		draw_arc(Vector2.ZERO, 39.0, 0.0, TAU, 48, Color(0.46, 0.87, 1.0, shield_alpha), 3.0)
	if war_cry_time_remaining > 0.0:
		draw_arc(Vector2.ZERO, 46.0, 0.0, TAU, 48, Color("#f3ba45"), 2.5)
	if iron_resolve_time_remaining > 0.0:
		draw_arc(Vector2.ZERO, 51.0, 0.0, TAU, 48, Color("#b6d9a0"), 2.5)
	if ranger_smoke_visual_time_remaining > 0.0:
		var smoke_progress := 1.0 - ranger_smoke_visual_time_remaining / 0.9
		var smoke_alpha := 0.5 * (1.0 - smoke_progress)
		for smoke_index in range(5):
			var angle := smoke_progress * TAU + float(smoke_index) * TAU / 5.0
			var smoke_center := Vector2.from_angle(angle) * ranger_smoke_visual_radius * 0.35
			draw_circle(
				smoke_center,
				ranger_smoke_visual_radius * 0.24,
				Color(0.68, 0.73, 0.72, smoke_alpha)
			)


func _draw_warrior_skill_animation() -> void:
	var progress := 1.0 - warrior_skill_animation_time_remaining / 0.58
	var alpha := 1.0 - progress
	var facing_angle := aim_direction.angle()
	match warrior_skill_animation_id:
		"heavy_strike":
			draw_arc(
				Vector2.ZERO,
				lerpf(24.0, 66.0, progress),
				facing_angle - 0.9,
				facing_angle + 0.9,
				32,
				Color(1.0, 0.82, 0.38, alpha),
				5.0
			)
		"shield_bash":
			var impact_center := aim_direction * 34.0
			draw_arc(
				impact_center,
				lerpf(5.0, 29.0, progress),
				0.0,
				TAU,
				32,
				Color(0.55, 0.88, 1.0, alpha),
				4.0
			)
			for ray_index in range(8):
				var ray_angle := TAU * float(ray_index) / 8.0
				draw_line(
					impact_center + Vector2.from_angle(ray_angle) * 9.0,
					impact_center + Vector2.from_angle(ray_angle) * 31.0,
					Color(0.7, 0.94, 1.0, alpha),
					2.5
				)
		"cleave":
			draw_arc(
				Vector2.ZERO,
				lerpf(42.0, 92.0, progress),
				facing_angle - 1.45,
				facing_angle + 1.45,
				48,
				Color(1.0, 0.62, 0.28, alpha),
				6.0
			)
		"leap_slam":
			draw_arc(
				Vector2.ZERO,
				lerpf(18.0, warrior_aoe_visual_radius, progress),
				0.0,
				TAU,
				48,
				Color(1.0, 0.78, 0.34, alpha),
				5.0
			)
		"war_cry":
			for wave_index in range(2):
				var wave_progress := clampf(progress * 1.6 - float(wave_index) * 0.35, 0.0, 1.0)
				draw_arc(
					Vector2.ZERO,
					lerpf(24.0, 88.0, wave_progress),
					0.0,
					TAU,
					48,
					Color(1.0, 0.73, 0.27, alpha * (1.0 - float(wave_index) * 0.2)),
					3.0
				)
		"iron_resolve":
			var guard_radius := lerpf(30.0, 56.0, progress)
			draw_arc(
				Vector2.ZERO,
				guard_radius,
				0.0,
				TAU,
				48,
				Color(0.7, 0.92, 0.62, alpha),
				4.0
			)
			for ray_index in range(4):
				var ray_angle := TAU * float(ray_index) / 4.0
				draw_line(
					Vector2.from_angle(ray_angle) * (guard_radius - 7.0),
					Vector2.from_angle(ray_angle) * (guard_radius + 9.0),
					Color(0.82, 1.0, 0.7, alpha),
					3.0
				)


func apply_chill(duration: float, speed_factor := 0.55) -> void:
	chill_time_remaining = maxf(chill_time_remaining, duration)
	chill_speed_factor = minf(chill_speed_factor, clampf(speed_factor, 0.1, 1.0))


func apply_knockback(direction: Vector2, strength: float) -> void:
	if direction.is_zero_approx():
		return
	click_move_active = false
	mouse_move_held = false
	knockback_velocity += direction.normalized() * strength


## Returns the damage actually taken after evasion and reductions.
func take_damage(amount: int) -> int:
	if health <= 0:
		return 0

	var evasion_chance := get_evasion()
	if evasion_chance > 0.0 and randf() < evasion_chance:
		return 0

	var flat_reduced := maxi(amount - get_damage_reduction(), 0)
	var reduced_damage := flat_reduced
	var passive_reduction_pct := get_passive_damage_reduction_percent()
	if passive_reduction_pct > 0.0:
		reduced_damage = roundi(float(reduced_damage) * (1.0 - passive_reduction_pct))
	if arcane_shield_time_remaining > 0.0:
		reduced_damage = roundi(float(reduced_damage) * (1.0 - arcane_shield_damage_reduction))
	var warrior_reduction := _get_warrior_damage_reduction()
	if warrior_reduction > 0.0:
		reduced_damage = roundi(float(reduced_damage) * (1.0 - warrior_reduction))
	if reduced_damage > 0:
		_cancel_town_portal_cast()
	var damage_taken := mini(reduced_damage, health)
	health -= damage_taken
	health_changed.emit(health, get_max_health())
	if health == 0:
		velocity = Vector2.ZERO
		set_physics_process(false)
		died.emit()
	return damage_taken


func _get_warrior_damage_reduction() -> float:
	var damage_reduction := 0.0
	if war_cry_time_remaining > 0.0:
		var war_cry_rank := GameState.get_warrior_skill_rank("war_cry")
		damage_reduction = 0.2 + float(war_cry_rank - 1) * 0.05
	if iron_resolve_time_remaining > 0.0:
		var resolve_rank := GameState.get_warrior_skill_rank("iron_resolve")
		damage_reduction = maxf(
			damage_reduction,
			0.35 + float(resolve_rank - 1) * 0.05
		)
	return clampf(damage_reduction, 0.0, 0.65)
