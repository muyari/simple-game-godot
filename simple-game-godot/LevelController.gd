extends Node

signal progress_changed(defeated: int, total: int)
signal level_completed

const WOLF_SCENE = preload("res://wolf.tscn")
const SCORPION_SCENE = preload("res://scorpion.tscn")
const SNAKE_SCENE = preload("res://snake.tscn")
const FROSTBOUND_WRAITH_SCENE = preload("res://frostbound_wraith.tscn")
const CRYSTALBACK_YETI_SCENE = preload("res://crystalback_yeti.tscn")
const SHIVERFANG_ICE_SERPENT_SCENE = preload("res://shiverfang_ice_serpent.tscn")
const SENTINEL_HEXWALKER_SCENE = preload("res://sentinel_hexwalker.tscn")
const NEUROCORE_DRONE_SCENE = preload("res://neurocore_drone.tscn")
const TITANFORGE_EXO_UNIT_SCENE = preload("res://titanforge_exo_unit.tscn")
const PHASE_SHIFT_INFILTRATOR_SCENE = preload("res://phase_shift_infiltrator.tscn")
const DESERT_BOSS_SCENE = preload("res://desert_boss.tscn")
const ITEM_PICKUP_SCENE = preload("res://item_pickup.tscn")
const GOLD_PICKUP_SCENE = preload("res://gold_pickup.tscn")
const TREE_TEXTURE = preload("res://textures/forest_tree.svg")
const POND_TEXTURE = preload("res://textures/forest_pond.svg")
const BOULDERS_TEXTURE = preload("res://textures/forest_boulders.svg")
const CAVE_TEXTURE = preload("res://textures/forest_cave.svg")
const DESERT_CACTUS_TEXTURE = preload("res://textures/desert_cactus.svg")
const DESERT_OASIS_TEXTURE = preload("res://textures/desert_oasis.svg")
const DESERT_DUNES_TEXTURE = preload("res://textures/desert_dunes.svg")
const DESERT_RUINS_TEXTURE = preload("res://textures/desert_ruins.svg")
const ICE_GROUND_TEXTURE = preload("res://textures/ice_caves_ground.svg")
const FROZEN_TREE_TEXTURE = preload("res://textures/frozen_ice_tree.svg")
const AI_GROUND_TEXTURE = preload("res://textures/futuristic_ai_ground.svg")
const AI_RELAY_PYLON_TEXTURE = preload("res://textures/ai_relay_pylon.svg")
const AI_SERVER_STACK_TEXTURE = preload("res://textures/ai_server_stack.svg")
const AI_COMMAND_CORE_TEXTURE = preload("res://textures/ai_command_core.svg")
const MAX_FOREST_ENEMIES = 10
const MAX_DESERT_ENEMIES = 15
const MAX_ICE_ENEMIES = 12
const MAX_AI_ENEMIES = 15
const SPAWN_EDGE_MARGIN = 128.0
const SCENERY_PRELOAD_RADIUS = 1
const ITEM_DROP_CHANCE = 0.1
const SCENERY_CLEARANCE = 24.0

@export var player_path: NodePath = NodePath("../Player")
@export_enum("Forest", "Desert", "Ice Caves", "Futuristic AI Zone") var biome := 0
@export_range(1, 25, 1) var area_level := 1

var player: Player
var player_camera: Camera2D
var level_id := 0
var region_size := Vector2.ZERO
var region_origin := Vector2.ZERO
var current_region := Vector2i.ZERO
var last_player_position := Vector2.ZERO
var enemies_spawned := 0
var enemies_defeated := 0
var boss_spawned := false
var level_is_complete := false
var spawned_enemy_regions: Dictionary = {}
var generated_scenery_regions: Dictionary = {}
var scenery_placements_by_region: Dictionary = {}
var active_scenery_region := Vector2i.ZERO
var item_pool: Array[ItemData] = []
var loot_random := RandomNumberGenerator.new()


func _ready() -> void:
	var ground := get_node_or_null("../Background/Sprite2D") as Sprite2D
	if ground != null:
		if biome == 2:
			ground.texture = ICE_GROUND_TEXTURE
		elif biome == 3:
			ground.texture = AI_GROUND_TEXTURE

	player = get_node_or_null(player_path) as Player
	if player == null:
		push_error("LevelController could not find its player at %s." % player_path)
		set_physics_process(false)
		return

	player_camera = player.get_node_or_null("Camera2D") as Camera2D
	if player_camera == null:
		push_error("LevelController could not find the player's Camera2D.")
		set_physics_process(false)
		return

	region_size = get_viewport().get_visible_rect().size / player_camera.zoom
	if region_size.x <= 0.0 or region_size.y <= 0.0:
		push_error("LevelController requires a viewport with a non-zero size.")
		set_physics_process(false)
		return

	level_id = _get_level_id()
	var level_state := GameState.get_level_state(level_id)
	if level_state.is_empty():
		region_origin = player.global_position + player_camera.offset / player_camera.zoom
		current_region = _get_region_for_position(_get_camera_center())
	elif not _restore_level_state(level_state):
		level_state.clear()
		enemies_spawned = 0
		enemies_defeated = 0
		boss_spawned = false
		spawned_enemy_regions.clear()
	last_player_position = player.global_position
	_create_item_pool()
	loot_random.randomize()
	_generate_nearby_scenery(current_region)
	if not level_state.is_empty():
		call_deferred("_restore_active_enemies", level_state.get("enemies", []))
		call_deferred("_restore_level_drops", level_state.get("drops", []))
	player.died.connect(_on_player_died)
	call_deferred("_emit_initial_progress")


func _emit_initial_progress() -> void:
	progress_changed.emit(enemies_defeated, _get_max_enemies())


func _notification(what: int) -> void:
	if what in [NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_PAUSED]:
		save_current_level_state()


func _restore_level_state(level_state: Dictionary) -> bool:
	var saved_spawned: Variant = level_state.get("enemies_spawned", 0)
	var saved_defeated: Variant = level_state.get("enemies_defeated", 0)
	if typeof(saved_spawned) not in [TYPE_INT, TYPE_FLOAT] \
			or typeof(saved_defeated) not in [TYPE_INT, TYPE_FLOAT]:
		push_error("Saved level enemy counts are invalid.")
		GameState.clear_level_state(level_id)
		region_origin = player.global_position + player_camera.offset / player_camera.zoom
		current_region = _get_region_for_position(_get_camera_center())
		return false

	enemies_spawned = clampi(int(saved_spawned), 0, _get_max_enemies())
	enemies_defeated = clampi(int(saved_defeated), 0, enemies_spawned)
	boss_spawned = bool(level_state.get("boss_spawned", false))
	var saved_origin: Variant = _vector_from_record(
		level_state.get("region_origin", []),
		"region origin"
	)
	if saved_origin == null:
		GameState.clear_level_state(level_id)
		region_origin = player.global_position + player_camera.offset / player_camera.zoom
		current_region = _get_region_for_position(_get_camera_center())
		return false
	region_origin = Vector2(saved_origin)

	var saved_region: Variant = level_state.get("current_region", [])
	if typeof(saved_region) == TYPE_ARRAY and saved_region.size() == 2:
		current_region = Vector2i(int(saved_region[0]), int(saved_region[1]))
	else:
		current_region = _get_region_for_position(_get_camera_center())

	var saved_regions: Variant = level_state.get("spawned_enemy_regions", [])
	if typeof(saved_regions) != TYPE_ARRAY:
		push_error("Saved cleared-area list is invalid.")
		GameState.clear_level_state(level_id)
		return false
	for saved_region_entry in saved_regions:
		if typeof(saved_region_entry) != TYPE_ARRAY or saved_region_entry.size() != 2:
			push_error("Ignoring an invalid saved cleared area.")
			continue
		spawned_enemy_regions[_region_key(
			Vector2i(int(saved_region_entry[0]), int(saved_region_entry[1]))
		)] = true
	return true


func save_current_level_state() -> bool:
	if level_id == 0:
		push_error("Cannot save level state for an unsupported scene.")
		return false
	if level_is_complete:
		return true

	var enemy_records: Array[Dictionary] = []
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		var enemy := enemy_node as Wolf
		if enemy == null or enemy.health <= 0.0 or enemy.scene_file_path.is_empty():
			continue
		enemy_records.append({
			"scene_path": enemy.scene_file_path,
			"position": [enemy.global_position.x, enemy.global_position.y],
			"health": enemy.health
		})

	var drop_records: Array[Dictionary] = []
	for drop_node in get_tree().get_nodes_in_group("level_drops"):
		var item_pickup := drop_node as ItemPickup
		if item_pickup != null:
			if item_pickup.item == null:
				push_error("Cannot save an item pickup without item data.")
				continue
			drop_records.append({
				"type": "item",
				"position": [item_pickup.global_position.x, item_pickup.global_position.y],
				"item": _item_to_record(item_pickup.item)
			})
			continue

		var gold_pickup := drop_node as GoldPickup
		if gold_pickup != null:
			drop_records.append({
				"type": "gold",
				"position": [gold_pickup.global_position.x, gold_pickup.global_position.y],
				"amount": gold_pickup.amount
			})

	var cleared_regions: Array[Array] = []
	for region_key in spawned_enemy_regions:
		var coordinates := str(region_key).split(",")
		if coordinates.size() == 2:
			cleared_regions.append([coordinates[0].to_int(), coordinates[1].to_int()])

	var level_state := {
		"enemies_spawned": enemies_spawned,
		"enemies_defeated": enemies_defeated,
		"boss_spawned": boss_spawned,
		"player_position": [player.global_position.x, player.global_position.y],
		"region_origin": [region_origin.x, region_origin.y],
		"current_region": [current_region.x, current_region.y],
		"spawned_enemy_regions": cleared_regions,
		"enemies": enemy_records,
		"drops": drop_records
	}
	if not GameState.set_level_state(level_id, level_state):
		push_error("Could not persist progress for level %d." % level_id)
		return false
	return true


func _save_level_state() -> void:
	if not save_current_level_state():
		push_error("Could not save the current level state.")


func _restore_active_enemies(raw_enemies: Variant) -> void:
	if typeof(raw_enemies) != TYPE_ARRAY:
		push_error("Saved active enemy list is invalid.")
		return

	for raw_enemy in raw_enemies:
		if typeof(raw_enemy) != TYPE_DICTIONARY:
			push_error("Ignoring an invalid saved enemy.")
			continue
		var enemy_record: Dictionary = raw_enemy
		var scene_path: Variant = enemy_record.get("scene_path", null)
		var saved_health: Variant = enemy_record.get("health", null)
		if typeof(scene_path) != TYPE_STRING \
				or typeof(saved_health) not in [TYPE_INT, TYPE_FLOAT]:
			push_error("Ignoring saved enemy with invalid fields.")
			continue
		var enemy_scene := _get_enemy_scene(str(scene_path))
		if enemy_scene == null:
			push_error("Ignoring saved enemy with unsupported scene '%s'." % scene_path)
			continue
		var enemy := enemy_scene.instantiate() as Wolf
		if enemy == null:
			push_error("Saved enemy scene '%s' does not use the Wolf script." % scene_path)
			continue
		var enemy_position: Variant = _vector_from_record(
			enemy_record.get("position", []),
			"enemy position"
		)
		if enemy_position == null:
			enemy.free()
			continue

		enemy.target_path = NodePath("../Player")
		if str(scene_path) == "res://desert_boss.tscn":
			enemy.died.connect(_on_desert_boss_died.bind(enemy))
		else:
			enemy.died.connect(_on_enemy_died.bind(enemy))
		get_parent().add_child(enemy)
		enemy.global_position = enemy_position
		enemy.health = clampf(float(saved_health), 0.0, enemy.max_health)
		var health_bar := enemy.get_node_or_null("HealthBar") as ProgressBar
		if health_bar != null:
			health_bar.value = enemy.health


func _restore_level_drops(raw_drops: Variant) -> void:
	if typeof(raw_drops) != TYPE_ARRAY:
		push_error("Saved level drop list is invalid.")
		return

	for raw_drop in raw_drops:
		if typeof(raw_drop) != TYPE_DICTIONARY:
			push_error("Ignoring an invalid saved level drop.")
			continue
		var drop_record: Dictionary = raw_drop
		var drop_type: Variant = drop_record.get("type", null)
		var drop_position: Variant = _vector_from_record(
			drop_record.get("position", []),
			"drop position"
		)
		if drop_position == null:
			continue

		match drop_type:
			"gold":
				var amount: Variant = drop_record.get("amount", null)
				if typeof(amount) not in [TYPE_INT, TYPE_FLOAT] \
						or int(amount) < 1 or int(amount) > 3:
					push_error("Ignoring saved gold pickup with invalid amount.")
					continue
				_spawn_gold_pickup(drop_position, int(amount))
			"item":
				var item_record: Variant = drop_record.get("item", null)
				if typeof(item_record) != TYPE_DICTIONARY:
					push_error("Ignoring saved item pickup with invalid item data.")
					continue
				var item := _item_from_record(item_record)
				if item == null:
					continue
				_spawn_item_pickup(item, drop_position)
			_:
				push_error("Ignoring saved pickup with unsupported type '%s'." % drop_type)


func _item_to_record(item: ItemData) -> Dictionary:
	return {
		"display_name": item.display_name,
		"equipment_slot": item.equipment_slot,
		"icon_color": item.icon_color.to_html(true),
		"damage_bonus": item.damage_bonus,
		"damage_reduction": item.damage_reduction,
		"price": item.price
	}


func _item_from_record(raw_item: Dictionary) -> ItemData:
	var display_name: Variant = raw_item.get("display_name", null)
	var equipment_slot: Variant = raw_item.get("equipment_slot", null)
	var icon_color: Variant = raw_item.get("icon_color", null)
	var damage_bonus: Variant = raw_item.get("damage_bonus", null)
	var damage_reduction: Variant = raw_item.get("damage_reduction", null)
	var price: Variant = raw_item.get("price", null)
	if typeof(display_name) != TYPE_STRING \
			or typeof(equipment_slot) != TYPE_STRING \
			or typeof(icon_color) != TYPE_STRING \
			or typeof(damage_bonus) not in [TYPE_INT, TYPE_FLOAT] \
			or typeof(damage_reduction) not in [TYPE_INT, TYPE_FLOAT] \
			or typeof(price) not in [TYPE_INT, TYPE_FLOAT]:
		push_error("Ignoring saved item pickup with invalid item fields.")
		return null

	var item := ItemData.new()
	item.display_name = display_name
	item.equipment_slot = equipment_slot
	item.icon_color = Color.from_string(icon_color, Color.WHITE)
	item.damage_bonus = int(damage_bonus)
	item.damage_reduction = int(damage_reduction)
	item.price = int(price)
	return item


func _get_enemy_scene(scene_path: String) -> PackedScene:
	match scene_path:
		"res://wolf.tscn":
			return WOLF_SCENE
		"res://scorpion.tscn":
			return SCORPION_SCENE
		"res://snake.tscn":
			return SNAKE_SCENE
		"res://frostbound_wraith.tscn":
			return FROSTBOUND_WRAITH_SCENE
		"res://crystalback_yeti.tscn":
			return CRYSTALBACK_YETI_SCENE
		"res://shiverfang_ice_serpent.tscn":
			return SHIVERFANG_ICE_SERPENT_SCENE
		"res://sentinel_hexwalker.tscn":
			return SENTINEL_HEXWALKER_SCENE
		"res://neurocore_drone.tscn":
			return NEUROCORE_DRONE_SCENE
		"res://titanforge_exo_unit.tscn":
			return TITANFORGE_EXO_UNIT_SCENE
		"res://phase_shift_infiltrator.tscn":
			return PHASE_SHIFT_INFILTRATOR_SCENE
		"res://desert_boss.tscn":
			return DESERT_BOSS_SCENE
	return null


func _vector_from_record(value: Variant, field_name: String) -> Variant:
	if typeof(value) != TYPE_ARRAY or value.size() != 2 \
			or typeof(value[0]) not in [TYPE_INT, TYPE_FLOAT] \
			or typeof(value[1]) not in [TYPE_INT, TYPE_FLOAT]:
		push_error("Saved %s is invalid." % field_name)
		return null
	return Vector2(float(value[0]), float(value[1]))


func _region_key(region: Vector2i) -> String:
	return "%d,%d" % [region.x, region.y]


func _get_level_id() -> int:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return 0
	return GameState.get_level_id(current_scene.scene_file_path)


func _physics_process(_delta: float) -> void:
	if enemies_spawned >= _get_max_enemies():
		return

	var camera_center := _get_camera_center()
	var entered_region := _get_region_for_position(camera_center)
	if entered_region != current_region:
		var movement := player.global_position - last_player_position
		_generate_nearby_scenery(entered_region)
		var region_key := _region_key(entered_region)
		if movement.length_squared() > 0.0 and not spawned_enemy_regions.has(region_key):
			if _spawn_enemy(movement.normalized()):
				spawned_enemy_regions[region_key] = true
				_save_level_state()
		current_region = entered_region

	last_player_position = player.global_position


func _generate_nearby_scenery(center_region: Vector2i) -> void:
	for x_offset in range(-SCENERY_PRELOAD_RADIUS, SCENERY_PRELOAD_RADIUS + 1):
		for y_offset in range(-SCENERY_PRELOAD_RADIUS, SCENERY_PRELOAD_RADIUS + 1):
			_generate_scenery_for_region(center_region + Vector2i(x_offset, y_offset))


func _create_item_pool() -> void:
	item_pool = GameState.get_vendor_items()


func _spawn_item_pickup(item: ItemData, world_position: Vector2) -> void:
	var pickup := ITEM_PICKUP_SCENE.instantiate() as ItemPickup
	if pickup == null:
		push_error("The item pickup scene root must use the ItemPickup script.")
		return

	pickup.item = item
	pickup.collected.connect(_save_level_state)
	get_parent().add_child(pickup)
	pickup.global_position = world_position


func _spawn_gold_pickup(world_position: Vector2, amount := 0) -> void:
	var pickup := GOLD_PICKUP_SCENE.instantiate() as GoldPickup
	if pickup == null:
		push_error("The gold pickup scene root must use the GoldPickup script.")
		return

	pickup.amount = amount if amount > 0 else loot_random.randi_range(1, 3)
	pickup.collected.connect(_save_level_state)
	get_parent().add_child(pickup)
	pickup.global_position = world_position


func _generate_scenery_for_region(region: Vector2i) -> void:
	if generated_scenery_regions.has(region):
		return
	generated_scenery_regions[region] = true
	active_scenery_region = region

	var random := RandomNumberGenerator.new()
	random.seed = int(region.x) * 73856093 ^ int(region.y) * 19349663
	var region_center := region_origin + Vector2(region) * region_size
	var safe_area := region_size * 0.39

	if biome == 1:
		_generate_desert_scenery(random, region_center, safe_area)
		return
	if biome == 2:
		_generate_ice_scenery(random, region_center, safe_area)
		return
	if biome == 3:
		_generate_ai_scenery(random, region_center, safe_area)
		return

	for _tree_index in range(random.randi_range(3, 5)):
		_add_scenery_sprite(
			TREE_TEXTURE,
			region_center + _random_region_offset(random, safe_area),
			random.randf_range(0.7, 1.15),
			24.0,
			Vector2(0.0, 62.0)
		)

	for _boulder_index in range(random.randi_range(2, 3)):
		_add_random_scenery_sprite(
			random,
			BOULDERS_TEXTURE,
			region_center,
			safe_area,
			random.randf_range(0.7, 1.1),
			47.0,
			Vector2(0.0, 16.0)
		)

	if random.randf() < 0.45:
		_add_scenery_sprite(
			POND_TEXTURE,
			region_center + _random_region_offset(random, safe_area * 0.7),
			random.randf_range(0.75, 1.1)
		)

	_add_random_scenery_sprite(
		random,
		CAVE_TEXTURE,
		region_center,
		safe_area * 0.7,
		random.randf_range(0.8, 1.15),
		70.0,
		Vector2(0.0, 47.0)
	)


func _generate_desert_scenery(
	random: RandomNumberGenerator,
	region_center: Vector2,
	safe_area: Vector2
) -> void:
	for _rock_index in range(random.randi_range(1, 2)):
		_add_scenery_sprite(
			BOULDERS_TEXTURE,
			region_center + _random_region_offset(random, safe_area),
			random.randf_range(0.7, 1.05),
			44.0,
			Vector2(0.0, 14.0)
		)

	for _cactus_index in range(random.randi_range(3, 5)):
		_add_scenery_sprite(
			DESERT_CACTUS_TEXTURE,
			region_center + _random_region_offset(random, safe_area),
			random.randf_range(0.7, 1.15),
			18.0,
			Vector2(0.0, 55.0)
		)

	for _dune_index in range(random.randi_range(1, 2)):
		_add_scenery_sprite(
			DESERT_DUNES_TEXTURE,
			region_center + _random_region_offset(random, safe_area),
			random.randf_range(0.7, 1.1)
		)

	if random.randf() < 0.38:
		_add_scenery_sprite(
			DESERT_OASIS_TEXTURE,
			region_center + _random_region_offset(random, safe_area * 0.65),
			random.randf_range(0.75, 1.0)
		)

	if random.randf() < 0.2:
		_add_scenery_sprite(
			DESERT_RUINS_TEXTURE,
			region_center + _random_region_offset(random, safe_area * 0.7),
			random.randf_range(0.75, 1.1),
			72.0,
			Vector2(0.0, 15.0)
		)

	if random.randf() < 0.24:
		_add_scenery_sprite(
			CAVE_TEXTURE,
			region_center + _random_region_offset(random, safe_area * 0.65),
			random.randf_range(0.8, 1.05),
			66.0,
			Vector2(0.0, 44.0)
		)


func _generate_ice_scenery(
	random: RandomNumberGenerator,
	region_center: Vector2,
	safe_area: Vector2
) -> void:
	for _tree_index in range(random.randi_range(2, 3)):
		_add_scenery_sprite(
			FROZEN_TREE_TEXTURE,
			region_center + _random_region_offset(random, safe_area),
			random.randf_range(0.75, 1.2)
		)

	for _ice_rock_index in range(random.randi_range(2, 4)):
		_add_scenery_sprite(
			BOULDERS_TEXTURE,
			region_center + _random_region_offset(random, safe_area),
			random.randf_range(0.75, 1.25),
			42.0,
			Vector2(0.0, 16.0)
		)

func _generate_ai_scenery(
	random: RandomNumberGenerator,
	region_center: Vector2,
	safe_area: Vector2
) -> void:
	for _pylon_index in range(random.randi_range(2, 3)):
		_add_scenery_sprite(
			AI_RELAY_PYLON_TEXTURE,
			region_center + _random_region_offset(random, safe_area),
			random.randf_range(0.75, 1.15),
			24.0,
			Vector2(0.0, 28.0)
		)

	for _server_index in range(random.randi_range(1, 2)):
		_add_scenery_sprite(
			AI_SERVER_STACK_TEXTURE,
			region_center + _random_region_offset(random, safe_area),
			random.randf_range(0.7, 1.0),
			38.0,
			Vector2(0.0, 18.0)
		)

	if random.randf() < 0.6:
		_add_scenery_sprite(
			AI_COMMAND_CORE_TEXTURE,
			region_center + _random_region_offset(random, safe_area * 0.65),
			random.randf_range(0.75, 1.0),
			44.0,
			Vector2(0.0, 20.0)
		)


func _random_region_offset(random: RandomNumberGenerator, safe_area: Vector2) -> Vector2:
	return Vector2(
		random.randf_range(-safe_area.x, safe_area.x),
		random.randf_range(-safe_area.y, safe_area.y)
	)


func _add_scenery_sprite(
	texture: Texture2D,
	world_position: Vector2,
	uniform_scale: float,
	collision_radius := 0.0,
	collision_offset := Vector2.ZERO
) -> void:
	var sprite_size := Vector2(texture.get_width(), texture.get_height()) * uniform_scale
	var half_size := sprite_size * 0.5
	if collision_radius > 0.0:
		var collision_extent := Vector2(
			collision_radius * uniform_scale + absf(collision_offset.x * uniform_scale),
			collision_radius * uniform_scale + absf(collision_offset.y * uniform_scale)
		)
		half_size.x = maxf(half_size.x, collision_extent.x)
		half_size.y = maxf(half_size.y, collision_extent.y)
	if not _has_scenery_clearance(world_position, half_size):
		return

	var placements: Array = scenery_placements_by_region.get(active_scenery_region, [])
	placements.append({"position": world_position, "half_size": half_size})
	scenery_placements_by_region[active_scenery_region] = placements

	var scenery := Sprite2D.new()
	scenery.texture = texture
	scenery.scale = Vector2.ONE * uniform_scale
	if biome == 2:
		scenery.modulate = Color("#9bd9f5")
	elif biome == 3:
		scenery.modulate = Color("#67d9ce")
	scenery.z_index = -1
	if collision_radius <= 0.0:
		scenery.position = world_position
		get_parent().call_deferred("add_child", scenery)
		return

	var obstacle := StaticBody2D.new()
	obstacle.position = world_position
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = collision_radius * uniform_scale
	collision.shape = shape
	collision.position = collision_offset * uniform_scale
	obstacle.add_child(collision)
	obstacle.add_child(scenery)
	get_parent().call_deferred("add_child", obstacle)


func _add_random_scenery_sprite(
	random: RandomNumberGenerator,
	texture: Texture2D,
	region_center: Vector2,
	safe_area: Vector2,
	uniform_scale: float,
	collision_radius := 0.0,
	collision_offset := Vector2.ZERO
) -> bool:
	for _attempt in range(32):
		var existing_placement_count: int = scenery_placements_by_region.get(
			active_scenery_region,
			[]
		).size()
		_add_scenery_sprite(
			texture,
			region_center + _random_region_offset(random, safe_area),
			uniform_scale,
			collision_radius,
			collision_offset
		)
		var updated_placements: Array = scenery_placements_by_region.get(active_scenery_region, [])
		if updated_placements.size() > existing_placement_count:
			return true
	return false


func _has_scenery_clearance(world_position: Vector2, half_size: Vector2) -> bool:
	for x_offset in range(-1, 2):
		for y_offset in range(-1, 2):
			var nearby_region := active_scenery_region + Vector2i(x_offset, y_offset)
			var placements: Array = scenery_placements_by_region.get(nearby_region, [])
			for placement in placements:
				var other_position: Vector2 = placement["position"]
				var other_half_size: Vector2 = placement["half_size"]
				var separation := world_position - other_position
				if absf(separation.x) < half_size.x + other_half_size.x + SCENERY_CLEARANCE \
						and absf(separation.y) < half_size.y + other_half_size.y + SCENERY_CLEARANCE:
					return false
	return true


func _get_camera_center() -> Vector2:
	return player.global_position + player_camera.offset / player_camera.zoom


func _get_region_for_position(world_position: Vector2) -> Vector2i:
	return Vector2i(
		floori((world_position.x - region_origin.x + region_size.x * 0.5) / region_size.x),
		floori((world_position.y - region_origin.y + region_size.y * 0.5) / region_size.y)
	)


func _get_max_enemies() -> int:
	match biome:
		1:
			return MAX_DESERT_ENEMIES
		2:
			return MAX_ICE_ENEMIES
		3:
			return MAX_AI_ENEMIES
	return MAX_FOREST_ENEMIES


func _spawn_enemy(direction: Vector2) -> bool:
	var enemy_scene: PackedScene = WOLF_SCENE
	if biome == 1:
		enemy_scene = SCORPION_SCENE if loot_random.randf() < 0.75 else SNAKE_SCENE
	elif biome == 2:
		var ice_enemy_roll := loot_random.randf()
		if ice_enemy_roll < 0.34:
			enemy_scene = FROSTBOUND_WRAITH_SCENE
		elif ice_enemy_roll < 0.67:
			enemy_scene = CRYSTALBACK_YETI_SCENE
		else:
			enemy_scene = SHIVERFANG_ICE_SERPENT_SCENE
	elif biome == 3:
		var robot_roll := loot_random.randf()
		if robot_roll < 0.25:
			enemy_scene = SENTINEL_HEXWALKER_SCENE
		elif robot_roll < 0.5:
			enemy_scene = NEUROCORE_DRONE_SCENE
		elif robot_roll < 0.75:
			enemy_scene = TITANFORGE_EXO_UNIT_SCENE
		else:
			enemy_scene = PHASE_SHIFT_INFILTRATOR_SCENE
	var enemy := enemy_scene.instantiate() as Wolf
	if enemy == null:
		push_error("The enemy scene root must use the Wolf base script.")
		set_physics_process(false)
		return false

	enemy.target_path = NodePath("../Player")
	enemy.died.connect(_on_enemy_died.bind(enemy))
	get_parent().add_child(enemy)
	enemy.global_position = player.global_position + direction * _get_spawn_distance(direction)
	enemies_spawned += 1
	return true


func _spawn_desert_boss() -> void:
	var boss := DESERT_BOSS_SCENE.instantiate() as Wolf
	if boss == null:
		push_error("The desert boss scene root must use the Wolf base script.")
		set_physics_process(false)
		return

	boss.target_path = NodePath("../Player")
	boss.died.connect(_on_desert_boss_died.bind(boss))
	get_parent().add_child(boss)
	var spawn_direction := player.facing
	if spawn_direction.is_zero_approx():
		spawn_direction = Vector2.RIGHT
	boss.global_position = player.global_position + spawn_direction * _get_spawn_distance(spawn_direction)
	boss_spawned = true


func _get_spawn_distance(direction: Vector2) -> float:
	var half_view := region_size * 0.5
	var horizontal_distance := INF
	var vertical_distance := INF
	if not is_zero_approx(direction.x):
		horizontal_distance = half_view.x / absf(direction.x)
	if not is_zero_approx(direction.y):
		vertical_distance = half_view.y / absf(direction.y)
	return minf(horizontal_distance, vertical_distance) + SPAWN_EDGE_MARGIN


func _on_enemy_died(enemy: Wolf) -> void:
	enemies_defeated += 1
	progress_changed.emit(enemies_defeated, _get_max_enemies())
	var experience_reward := _get_scaled_experience_reward(enemy)
	if not player.gain_experience(experience_reward):
		push_error("Could not award %d XP for defeating %s." % [
			experience_reward,
			enemy.name
		])
	_drop_enemy_loot(enemy)

	var max_enemies := _get_max_enemies()
	if biome == 1 and enemies_defeated == max_enemies and not boss_spawned:
		_spawn_desert_boss()
		_save_level_state()
	elif biome != 1 and enemies_spawned == max_enemies and enemies_defeated == max_enemies:
		_complete_current_level()
	else:
		_save_level_state()


func _on_desert_boss_died(boss: Wolf) -> void:
	var experience_reward := _get_scaled_experience_reward(boss)
	if not player.gain_experience(experience_reward):
		push_error("Could not award %d XP for defeating the desert boss." % experience_reward)
	_drop_enemy_loot(boss, true)
	_complete_current_level()


func _complete_current_level() -> void:
	level_is_complete = true
	level_completed.emit()


func _get_scaled_experience_reward(enemy: Wolf) -> int:
	var area_multiplier := 1.0 + float(area_level - 1) * 0.5
	return maxi(roundi(enemy.experience_reward * area_multiplier), 1)


func _drop_enemy_loot(enemy: Wolf, is_desert_boss := false) -> void:
	_spawn_gold_pickup(enemy.global_position)
	if is_desert_boss:
		_spawn_item_pickup(_create_desert_gear(true), enemy.global_position)
	elif biome == 1 or biome == 3:
		if loot_random.randf() < ITEM_DROP_CHANCE:
			_spawn_item_pickup(_create_desert_gear(false), enemy.global_position)
	elif loot_random.randf() < ITEM_DROP_CHANCE:
		var dropped_item := item_pool[loot_random.randi_range(0, item_pool.size() - 1)]
		_spawn_item_pickup(dropped_item, enemy.global_position)


func _create_desert_gear(is_boss_drop: bool) -> ItemData:
	var gear_choice := loot_random.randi_range(0, 2)
	var bonus := 3 if is_boss_drop else 2
	var prefix := "Scorched" if is_boss_drop else "Dune"
	var item := ItemData.new()
	item.price = 25

	match gear_choice:
		0:
			item.display_name = "%s Scimitar" % prefix
			item.equipment_slot = "Weapon"
			item.icon_color = Color("#e7a74b")
			item.damage_bonus = bonus
		1:
			item.display_name = "%s Helm" % prefix
			item.equipment_slot = "Helm"
			item.icon_color = Color("#d4a76a")
			item.damage_reduction = bonus
		2:
			item.display_name = "%s Signet Ring" % prefix
			item.equipment_slot = "Ring"
			item.icon_color = Color("#d8bc59")
			item.damage_bonus = bonus

	return item


func _on_player_died() -> void:
	set_physics_process(false)
	_save_level_state()
