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
var region_size := Vector2.ZERO
var region_origin := Vector2.ZERO
var current_region := Vector2i.ZERO
var last_player_position := Vector2.ZERO
var enemies_spawned := 0
var enemies_defeated := 0
var boss_spawned := false
var level_is_complete := false
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

	region_origin = player.global_position + player_camera.offset / player_camera.zoom
	current_region = _get_region_for_position(_get_camera_center())
	last_player_position = player.global_position
	_create_item_pool()
	loot_random.randomize()
	_generate_nearby_scenery(current_region)
	player.died.connect(_on_player_died)
	progress_changed.emit(enemies_defeated, _get_max_enemies())


func _physics_process(_delta: float) -> void:
	if enemies_spawned >= _get_max_enemies():
		return

	var camera_center := _get_camera_center()
	var entered_region := _get_region_for_position(camera_center)
	if entered_region != current_region:
		var movement := player.global_position - last_player_position
		_generate_nearby_scenery(entered_region)
		if movement.length_squared() > 0.0:
			_spawn_enemy(movement.normalized())
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
	pickup.position = world_position
	get_parent().call_deferred("add_child", pickup)


func _spawn_gold_pickup(world_position: Vector2) -> void:
	var pickup := GOLD_PICKUP_SCENE.instantiate() as GoldPickup
	if pickup == null:
		push_error("The gold pickup scene root must use the GoldPickup script.")
		return

	pickup.amount = loot_random.randi_range(1, 3)
	pickup.position = world_position
	get_parent().call_deferred("add_child", pickup)


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


func _spawn_enemy(direction: Vector2) -> void:
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
		return

	enemy.target_path = NodePath("../Player")
	enemy.died.connect(_on_enemy_died.bind(enemy))
	get_parent().add_child(enemy)
	enemy.global_position = player.global_position + direction * _get_spawn_distance(direction)
	enemies_spawned += 1


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
	elif biome != 1 and enemies_spawned == max_enemies and enemies_defeated == max_enemies:
		level_is_complete = true
		level_completed.emit()


func _on_desert_boss_died(boss: Wolf) -> void:
	var experience_reward := _get_scaled_experience_reward(boss)
	if not player.gain_experience(experience_reward):
		push_error("Could not award %d XP for defeating the desert boss." % experience_reward)
	_drop_enemy_loot(boss, true)
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
