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
const FRAME_SIZE = 64
const WALK_FRAME_DURATION = 0.12
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
const WARRIOR_SHEET = preload("res://textures/warrior_sheet.svg")
const WITCH_SHEET = preload("res://textures/witch_sheet.svg")
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
var health_potion_time := 0.0
var mana_potion_time := 0.0
var health_heal_accumulator := 0.0
var mana_heal_accumulator := 0.0
var potion_ui_timer := 0.0
var facing := Vector2.DOWN
var chill_time_remaining := 0.0
var chill_speed_factor := 1.0
var knockback_velocity := Vector2.ZERO
var arcane_shield_time_remaining := 0.0
var arcane_shield_damage_reduction := 0.0
var frost_nova_visual_time_remaining := 0.0
var witch_skill_cooldowns: Dictionary = {}
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
	selected_character = str(get_tree().get_meta("selected_character", "Warrior"))
	sprite.texture = WITCH_SHEET if selected_character == "Witch" else WARRIOR_SHEET
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
	if get_tree().has_meta("portal_player_vitals"):
		var saved_vitals: Variant = get_tree().get_meta("portal_player_vitals")
		get_tree().remove_meta("portal_player_vitals")
		if typeof(saved_vitals) == TYPE_DICTIONARY:
			health = clampi(int(saved_vitals.get("health", health)), 0, MAX_HEALTH)
			mana = clampi(int(saved_vitals.get("mana", mana)), 0, MAX_MANA)
		else:
			push_error("Portal player vitals must be a Dictionary.")


func _physics_process(delta: float) -> void:
	_update_potion_refills(delta)
	_update_potion_effects(delta)
	iceball_cooldown_remaining = maxf(iceball_cooldown_remaining - delta, 0.0)
	chill_time_remaining = maxf(chill_time_remaining - delta, 0.0)
	arcane_shield_time_remaining = maxf(arcane_shield_time_remaining - delta, 0.0)
	frost_nova_visual_time_remaining = maxf(frost_nova_visual_time_remaining - delta, 0.0)
	if arcane_shield_time_remaining > 0.0 or frost_nova_visual_time_remaining > 0.0:
		queue_redraw()
	_update_witch_skill_cooldowns(delta)
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
		var movement_velocity := direction * SPEED * chill_speed_factor
		if knockback_velocity.length_squared() > 0.0:
			movement_velocity += knockback_velocity
			knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 900.0 * delta)
		velocity = velocity.move_toward(movement_velocity, ACCELERATION * delta)
		facing = _cardinal_direction(direction)
		animation_time += delta
	else:
		var movement_velocity := knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 900.0 * delta)
		velocity = velocity.move_toward(movement_velocity, DECELERATION * delta)
		animation_time = 0.0

	if Input.is_action_just_pressed("ui_accept"):
		_use_primary_attack()

	_update_sprite(direction != Vector2.ZERO)
	_update_sword(delta)
	_update_wand()
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
		if selected_character == "Witch":
			_cast_assigned_witch_skill("Q")
		else:
			_cast_fireball()
	elif event.keycode == KEY_W and selected_character == "Witch":
		_cast_assigned_witch_skill("W")
	elif event.keycode == KEY_E:
		if not _try_interact():
			if selected_character == "Witch":
				if not _cast_assigned_witch_skill("E"):
					_cast_e_skill()
			else:
				_cast_e_skill()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_R and selected_character == "Witch":
		_cast_assigned_witch_skill("R")
	elif event.keycode == KEY_T:
		_open_town_portal()


func _try_interact() -> bool:
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

	if nearest_interactable == null:
		return false
	nearest_interactable.call("interact", self)
	return true


func _use_primary_attack() -> void:
	if selected_character == "Witch":
		if iceball_cooldown_remaining <= 0.0:
			_cast_iceball()
			iceball_cooldown_remaining = ICEBALL_COOLDOWN
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
	match skill_id:
		"firebolt":
			return "Firebolt\nDamage: %.1f per hit" % [1.2 + float(rank) * 0.8 + damage_bonus]
		"frost_nova":
			return "Frost Nova\nDamage: %.2f per enemy\nAlso stuns nearby enemies" % [1.5 + float(rank) * 0.75 + damage_bonus]
		"summon_wisp":
			return "Summon Wisp\nDamage: %.1f per bolt\nWisp duration: %.0f sec" % [
				1.0 + float(rank),
				9.0 + float(rank - 1) * 3.0
			]
		"soul_siphon":
			return "Soul Siphon\nDamage: %.1f\nRestores health and mana" % [2.0 + float(rank) * 1.5 + damage_bonus]
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
	mana_changed.emit(mana, MAX_MANA)
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
		"curse":
			_cast_witch_curse(rank)
		_:
			witch_skill_cooldowns.erase(skill_id)
			mana += mana_cost
			mana_changed.emit(mana, MAX_MANA)
			return false
	return true


func _cast_witch_firebolt(rank: int) -> void:
	var projectile: Fireball = FIREBALL_SCENE.instantiate()
	projectile.direction = facing
	projectile.direct_damage = 1.2 + float(rank) * 0.8 + get_weapon_damage_bonus()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = global_position + facing * 20.0


func _cast_witch_frost_nova(rank: int) -> void:
	frost_nova_visual_time_remaining = 0.55
	var radius := 118.0 + float(rank - 1) * 22.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy is Node2D or not enemy.has_method("take_damage"):
			continue
		var enemy_node := enemy as Node2D
		if global_position.distance_to(enemy_node.global_position) <= radius:
			enemy.call("take_damage", 1.5 + float(rank) * 0.75 + get_weapon_damage_bonus())
			if enemy.has_method("apply_stun"):
				enemy.call("apply_stun", 0.55 + float(rank - 1) * 0.25)


func _cast_witch_summon_wisp(rank: int) -> void:
	if is_instance_valid(witch_familiar):
		witch_familiar.duration_remaining = maxf(
			witch_familiar.duration_remaining,
			9.0 + float(rank - 1) * 3.0
		)
		witch_familiar.damage = 1.0 + float(rank)
		return

	witch_familiar = WITCH_FAMILIAR_SCENE.instantiate() as WitchFamiliar
	if witch_familiar == null:
		push_error("The Witch familiar scene root must use the WitchFamiliar script.")
		return
	witch_familiar.owner_player = self
	witch_familiar.duration = 9.0 + float(rank - 1) * 3.0
	witch_familiar.damage = 1.0 + float(rank)
	get_tree().current_scene.add_child(witch_familiar)
	witch_familiar.global_position = global_position + Vector2(32.0, -28.0)


func _cast_witch_soul_siphon(rank: int) -> void:
	var target_enemy := _find_nearest_enemy(360.0)
	if target_enemy == null:
		return
	target_enemy.call("take_damage", 2.0 + float(rank) * 1.5 + get_weapon_damage_bonus())
	health = mini(health + 3 + rank * 2, MAX_HEALTH)
	mana = mini(mana + 5 + rank * 3, MAX_MANA)
	health_changed.emit(health, MAX_HEALTH)
	mana_changed.emit(mana, MAX_MANA)


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
		mana_changed.emit(mana, MAX_MANA)
	var fireball: Fireball = FIREBALL_SCENE.instantiate()
	fireball.direction = facing
	fireball.is_ice = is_ice
	if is_ice:
		fireball.ice_damage = _get_primary_attack_damage()
	get_tree().current_scene.add_child(fireball)
	fireball.global_position = global_position + facing * 20.0


func _update_wand() -> void:
	if selected_character != "Witch":
		return

	wand.visible = Input.is_action_pressed("ui_accept")
	wand.position = facing * 8.0 + Vector2(6.0, 0.0)
	wand.rotation = facing.angle()


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


func get_weapon_damage_bonus() -> int:
	var bonus := 0
	for slot in ["Weapon", "Ring 1", "Ring 2", "Amulet"]:
		if equipment.has(slot):
			bonus += (equipment[slot] as ItemData).damage_bonus
	return bonus


func get_damage_reduction() -> int:
	var reduction := 0
	for slot in ["Helm", "Chest", "Legs", "Gloves", "Boots"]:
		if equipment.has(slot):
			reduction += (equipment[slot] as ItemData).damage_reduction
	return reduction


func _use_health_potion() -> void:
	if health_potions <= 0 or health >= MAX_HEALTH or health_potion_time > 0.0:
		return

	health_potions -= 1
	health_refill_timers.append(POTION_REFILL_TIME)
	health_potion_time = POTION_EFFECT_TIME
	_emit_potion_counts()


func _use_mana_potion() -> void:
	if mana_potions <= 0 or mana >= MAX_MANA or mana_potion_time > 0.0:
		return

	mana_potions -= 1
	mana_refill_timers.append(POTION_REFILL_TIME)
	mana_potion_time = POTION_EFFECT_TIME
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


func _update_potion_effects(delta: float) -> void:
	if health_potion_time > 0.0:
		health_heal_accumulator += float(MAX_HEALTH) / POTION_EFFECT_TIME * delta
		var health_to_restore := int(health_heal_accumulator)
		health_heal_accumulator -= health_to_restore
		health = mini(health + health_to_restore, MAX_HEALTH)
		health_potion_time = maxf(health_potion_time - delta, 0.0)
		if health_potion_time == 0.0:
			health = MAX_HEALTH
			health_heal_accumulator = 0.0
		health_changed.emit(health, MAX_HEALTH)

	if mana_potion_time > 0.0:
		mana_heal_accumulator += float(MAX_MANA) / POTION_EFFECT_TIME * delta
		var mana_to_restore := int(mana_heal_accumulator)
		mana_heal_accumulator -= mana_to_restore
		mana = mini(mana + mana_to_restore, MAX_MANA)
		mana_potion_time = maxf(mana_potion_time - delta, 0.0)
		if mana_potion_time == 0.0:
			mana = MAX_MANA
			mana_heal_accumulator = 0.0
		mana_changed.emit(mana, MAX_MANA)


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

	var frame := 0
	if is_moving:
		frame = 1 + (int(animation_time / WALK_FRAME_DURATION) % 3)
	sprite.region_rect = Rect2(frame * FRAME_SIZE, row * FRAME_SIZE, FRAME_SIZE, FRAME_SIZE)


func _update_sword(delta: float) -> void:
	sword.position = facing * 8.0
	if attack_time_remaining > 0.0:
		attack_time_remaining = maxf(attack_time_remaining - delta, 0.0)
		var progress := 1.0 - attack_time_remaining / ATTACK_DURATION
		sword.rotation = facing.angle() + lerpf(-ATTACK_ARC, ATTACK_ARC, progress)
		sword.show()
		if not attack_hit_applied and progress >= SWORD_HIT_TIME:
			_damage_wolves_in_swing()
			attack_hit_applied = true
	else:
		sword.rotation = facing.angle()
		sword.hide()


func _damage_wolves_in_swing() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy is Node2D:
			continue

		var enemy_node := enemy as Node2D
		var to_enemy := enemy_node.global_position - global_position
		if to_enemy.length() <= SWORD_REACH and to_enemy.normalized().dot(facing) >= SWORD_HIT_DOT_THRESHOLD:
			enemy.call("take_damage", _get_primary_attack_damage())


func _get_primary_attack_damage() -> float:
	return 1.0 + get_weapon_damage_bonus()


func _draw() -> void:
	if frost_nova_visual_time_remaining > 0.0:
		var progress := 1.0 - frost_nova_visual_time_remaining / 0.55
		var nova_radius := lerpf(36.0, 168.0, progress)
		draw_arc(Vector2.ZERO, nova_radius, 0.0, TAU, 64, Color(0.63, 0.92, 1.0, 1.0 - progress), 4.0)
	if arcane_shield_time_remaining > 0.0:
		var shield_alpha := 0.45 + sin(Time.get_ticks_msec() * 0.012) * 0.12
		draw_arc(Vector2.ZERO, 39.0, 0.0, TAU, 48, Color(0.46, 0.87, 1.0, shield_alpha), 3.0)


func apply_chill(duration: float, speed_factor := 0.55) -> void:
	chill_time_remaining = maxf(chill_time_remaining, duration)
	chill_speed_factor = minf(chill_speed_factor, clampf(speed_factor, 0.1, 1.0))


func apply_knockback(direction: Vector2, strength: float) -> void:
	if direction.is_zero_approx():
		return
	click_move_active = false
	mouse_move_held = false
	knockback_velocity += direction.normalized() * strength


func take_damage(amount: int) -> void:
	if health <= 0:
		return

	var reduced_damage := maxi(amount - get_damage_reduction(), 0)
	if arcane_shield_time_remaining > 0.0:
		reduced_damage = roundi(float(reduced_damage) * (1.0 - arcane_shield_damage_reduction))
	if reduced_damage > 0:
		_cancel_town_portal_cast()
	health = maxi(health - reduced_damage, 0)
	health_changed.emit(health, MAX_HEALTH)
	if health == 0:
		velocity = Vector2.ZERO
		set_physics_process(false)
		died.emit()
