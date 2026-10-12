extends CharacterBody2D
class_name Player

signal health_changed(current_health: int, maximum_health: int)
signal mana_changed(current_mana: int, maximum_mana: int)
signal potion_counts_changed(health_count: int, mana_count: int, health_refill: float, mana_refill: float)
signal inventory_changed(items: Array[ItemData])
signal equipment_changed(equipment: Dictionary)
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
const MAX_MANA = 100
const FIREBALL_MANA_COST = 25
const MAX_POTIONS = 3
const POTION_REFILL_TIME = 10.0
const POTION_EFFECT_TIME = 3.0
const FIREBALL_SCENE = preload("res://fireball.tscn")
const PORTAL_SCENE = preload("res://portal.tscn")
const TOWN_SCENE_PATH = "res://town.tscn"
const TOWN_ARRIVAL_POSITION = Vector2(576, 350)
const TOWN_RETURN_SCENE_META = "town_return_scene"
const TOWN_RETURN_POSITION_META = "town_return_position"

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
var animation_time := 0.0
var attack_time_remaining := 0.0
var attack_hit_applied := false
var town_portal_open := false

@onready var sprite: Sprite2D = $Sprite2D
@onready var sword: Node2D = $Sword


func _ready() -> void:
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

	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction != Vector2.ZERO:
		velocity = velocity.move_toward(direction * SPEED, ACCELERATION * delta)
		facing = _cardinal_direction(direction)
		animation_time += delta
	else:
		velocity = velocity.move_toward(Vector2.ZERO, DECELERATION * delta)
		animation_time = 0.0

	if Input.is_action_just_pressed("ui_accept") and attack_time_remaining <= 0.0:
		attack_time_remaining = ATTACK_DURATION
		attack_hit_applied = false

	_update_sprite(direction != Vector2.ZERO)
	_update_sword(delta)
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if health <= 0 or not event is InputEventKey or not event.pressed or event.echo:
		return

	if event.keycode == KEY_1:
		_use_health_potion()
	elif event.keycode == KEY_2:
		_use_mana_potion()
	elif event.keycode == KEY_Q:
		_cast_fireball()
	elif event.keycode == KEY_T:
		_open_town_portal()


func _open_town_portal() -> void:
	if town_portal_open:
		return
	var current_scene_path := get_tree().current_scene.scene_file_path
	if current_scene_path not in ["res://main.tscn", "res://desert.tscn"]:
		return

	var portal := PORTAL_SCENE.instantiate() as Portal
	if portal == null:
		push_error("The portal scene root must use the Portal script.")
		return

	portal.destination_scene = TOWN_SCENE_PATH
	portal.destination_position = TOWN_ARRIVAL_POSITION
	get_tree().set_meta(TOWN_RETURN_SCENE_META, current_scene_path)
	get_tree().set_meta(TOWN_RETURN_POSITION_META, global_position)
	get_tree().current_scene.add_child(portal)
	portal.global_position = global_position + facing * 64.0
	town_portal_open = true
	town_portal_opened.emit()


func _cast_fireball() -> void:
	if mana < FIREBALL_MANA_COST:
		return

	mana -= FIREBALL_MANA_COST
	mana_changed.emit(mana, MAX_MANA)
	var fireball: Fireball = FIREBALL_SCENE.instantiate()
	fireball.direction = facing
	get_tree().current_scene.add_child(fireball)
	fireball.global_position = global_position + facing * 20.0


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
			enemy.call("take_damage", 1.0 + get_weapon_damage_bonus())


func take_damage(amount: int) -> void:
	if health <= 0:
		return

	var reduced_damage := maxi(amount - get_damage_reduction(), 0)
	health = maxi(health - reduced_damage, 0)
	health_changed.emit(health, MAX_HEALTH)
	if health == 0:
		velocity = Vector2.ZERO
		set_physics_process(false)
		died.emit()
