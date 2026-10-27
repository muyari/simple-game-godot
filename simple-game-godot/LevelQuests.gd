extends Node
class_name LevelQuests
## The quest sites and encounters of one campaign level: ForestQuests for the Forest Outskirts, DesertQuests
## for the Sunscorch Sands, IceQuests for the Ice Caves, UnderworldQuests for the Underworld. A level is
## endless and rebuilt region by region, so each site belongs to a fixed region (relative to the start) and is
## built when the LevelController generates that region. This base holds what the levels share: building
## sites, quest monsters, trips into and out of an underground area built far from the map (the Gloomhollow,
## the Sunken Vault, the Heartfrost Deep, the Cinder Throne), and telling the HUD's QuestTracker where the
## nearest objective is.

## Quest monsters fight outside the level's tally: they are not saved with the level, never called in as
## stragglers, and come back while their quest still needs them.
const QUEST_MONSTER_META := "quest_monster"
## Where in their regions scattered quest objects sit, so they aren't all dead centre.
const SCATTER_OFFSETS: Array[Vector2] = [Vector2(-140, 70), Vector2(160, -40), Vector2(-60, -110), Vector2(120, 100)]

var level_controller: Node
var level: Node2D
var player: Player
## Set while the player is down in the level's underground area.
var in_cave := false
var cave_return_position := Vector2.ZERO
var fade: ColorRect
var travelling := false


## Called by the LevelController before its first scenery is generated.
func setup(controller: Node, level_root: Node2D, level_player: Player) -> void:
	level_controller = controller
	level = level_root
	player = level_player


func _ready() -> void:
	add_to_group(QuestTracker.GUIDES_GROUP)
	GameState.quest_changed.connect(_on_quest_changed)
	var layer := CanvasLayer.new()
	layer.layer = 90
	add_child(layer)
	fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(fade)


## Builds whatever quest site belongs to this region. Runs before the region's scenery is placed, so it
## grows round the site.
func populate_region(_region: Vector2i, _region_center: Vector2) -> void:
	pass


func _on_quest_changed(_quest_id: String) -> void:
	pass


## What a monster counts as in kill events: its scene's name, e.g. "wolf", "scorpion", "desert_boss".
static func monster_kind(monster: Wolf) -> String:
	return monster.scene_file_path.get_file().get_basename()


# --- Building sites --------------------------------------------------------------------------------------

## A quest object standing at base, solid if collision_radius > 0. footprint (half size) is claimed from
## the region's scenery when set.
func _add_object(kind: QuestObject.Kind, base: Vector2, object_id: String, quest_id: String, footprint := Vector2.ZERO, collision_radius := 0.0) -> QuestObject:
	if footprint != Vector2.ZERO:
		_claim(base, footprint)
	var quest_object := QuestObject.new()
	quest_object.kind = kind
	quest_object.object_id = object_id
	quest_object.quest_id = quest_id
	if collision_radius <= 0.0:
		quest_object.position = base
		level.add_child.call_deferred(quest_object)
		return quest_object
	var body := _solid_body(base, collision_radius)
	body.add_child(quest_object)
	level.add_child.call_deferred(body)
	return quest_object


func _hub_prop(kind: HubProp.Kind, base: Vector2, settings: Dictionary, collision_radius: float) -> void:
	var prop := HubProp.new()
	prop.kind = kind
	for key in settings:
		if key == "scale":
			prop.scale = Vector2.ONE * float(settings[key])
		else:
			prop.set(key, settings[key])
	if collision_radius <= 0.0:
		prop.position = base
		level.add_child.call_deferred(prop)
		return
	var body := _solid_body(base, collision_radius)
	body.add_child(prop)
	level.add_child.call_deferred(body)


func _folk(base: Vector2, settings: Dictionary) -> HubFolk:
	var person := HubFolk.new()
	for key in settings:
		person.set(key, settings[key])
	person.position = base
	level.add_child.call_deferred(person)
	return person


func _sprite(texture: Texture2D, base: Vector2, uniform_scale: float, collision_radius: float, flip := false) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE * uniform_scale
	sprite.offset = Vector2(0, -texture.get_height() * 0.5)
	sprite.flip_h = flip
	if collision_radius <= 0.0:
		sprite.position = base
		level.add_child.call_deferred(sprite)
		return
	var body := _solid_body(base, collision_radius)
	body.add_child(sprite)
	level.add_child.call_deferred(body)


func _solid_body(base: Vector2, radius: float) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_mask = 0
	body.position = base
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	shape.position = Vector2(0, -radius * 0.4)
	body.add_child(shape)
	return body


## Keeps the region's random scenery off a site.
func _claim(base: Vector2, half_size: Vector2) -> void:
	level_controller.call("_claim_prop_spot", base, half_size, false)


func _entry_point() -> Vector2:
	return level_controller.get("region_origin") - player.get_node("Camera2D").offset


func _region_center(region: Vector2i) -> Vector2:
	return Vector2(level_controller.get("region_origin")) + Vector2(region) * Vector2(level_controller.get("region_size"))


# --- Quest monsters --------------------------------------------------------------------------------------

## Spawns a monster that belongs to a quest. stats: name, scale, health and damage (multipliers),
## experience, tint. on_died returns any further quest updates to show.
func spawn_quest_monster(scene: PackedScene, world_position: Vector2, stats: Dictionary, on_died: Callable) -> Wolf:
	var monster := scene.instantiate() as Wolf
	monster.target_path = NodePath("../Player")
	monster.set_meta(QUEST_MONSTER_META, true)
	monster.scale *= float(stats.get("scale", 1.0))
	monster.health_scale = float(stats.get("health", 1.0))
	monster.damage_scale = float(stats.get("damage", 1.0))
	monster.died.connect(_on_quest_monster_died.bind(monster, on_died))
	level.add_child(monster)
	monster.global_position = world_position
	# Some monsters set their own name and reward on entering the tree, so the quest's go on after.
	if stats.has("name"):
		monster.monster_name = stats["name"]
	if stats.has("experience"):
		monster.experience_reward = int(stats["experience"])
	if stats.has("tint"):
		monster.get_node("Sprite2D").modulate = stats["tint"]
	return monster


func _on_quest_monster_died(monster: Wolf, on_died: Callable) -> void:
	level_controller.call("reward_quest_monster", monster)
	var updates := Quests.record_event("kill", monster_kind(monster))
	if on_died.is_valid():
		updates.append_array(on_died.call())
	QuestToast.show_updates(get_tree(), updates)


# --- Going underground -----------------------------------------------------------------------------------

func leave_cave() -> void:
	if travelling or not in_cave:
		return
	_travel(_exit_cave)


## Moves the player back up from the underground area; each level's own version says which area.
func _exit_cave() -> void:
	pass


## Fades to black, runs move, then fades back in. The player can't act meanwhile.
func _travel(move: Callable) -> void:
	travelling = true
	player.set_physics_process(false)
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.3)
	tween.tween_callback(move)
	tween.tween_interval(0.15)
	tween.tween_property(fade, "color:a", 0.0, 0.4)
	tween.tween_callback(func() -> void:
		travelling = false
		if player.health > 0:
			player.set_physics_process(true)
	)


## Takes the player down into an underground area (whose monsters carry area_meta), leaving the surface
## holding still and its sky behind.
func _go_underground(arrival: Vector2, area_meta: String, tint: Color) -> void:
	cave_return_position = player.global_position
	in_cave = true
	_hold_surface(true, area_meta)
	_set_ambience_underground(true, tint)
	_place_player(arrival)


func _return_to_surface(area_meta: String) -> void:
	in_cave = false
	_hold_surface(false, area_meta)
	_set_ambience_underground(false, Color.WHITE)
	_place_player(cave_return_position)
	level_controller.set("last_player_position", player.global_position)


## The level's monsters hold still while the player is underground.
func _hold_surface(still: bool, area_meta: String) -> void:
	for node in get_tree().get_nodes_in_group("enemies"):
		if not node.has_meta(area_meta):
			node.process_mode = Node.PROCESS_MODE_DISABLED if still else Node.PROCESS_MODE_INHERIT


func _set_ambience_underground(underground: bool, tint: Color) -> void:
	for node in level.get_children():
		if node.has_method("set_underground"):
			node.call("set_underground", underground, tint)


func _place_player(world_position: Vector2) -> void:
	player.global_position = world_position
	player.velocity = Vector2.ZERO
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if camera != null:
		camera.reset_smoothing()


## Where the level should remember the player: outside the way down while they're underground, since the
## underground area is rebuilt only when entered.
func get_save_position() -> Vector2:
	return cave_return_position if in_cave else player.global_position


# --- Tracking --------------------------------------------------------------------------------------------

## The nearest place one of this level's active quests wants the player to go, as {position, label}, or {}.
func get_tracked_target() -> Dictionary:
	var best := {}
	var best_distance := INF
	for target in _get_targets():
		var distance := player.global_position.distance_squared_to(target["position"])
		if distance < best_distance:
			best_distance = distance
			best = target
	return best


func _get_targets() -> Array[Dictionary]:
	var targets: Array[Dictionary] = []
	if in_cave:
		return targets
	var level_id := int(level_controller.get("level_id"))
	for quest_id in Quests.DEFINITIONS:
		var quest: Dictionary = Quests.DEFINITIONS[quest_id]
		var quest_state := GameState.get_quest_state(quest_id)
		if int(quest["area"]) != level_id or not Quests.is_active(quest_state):
			continue
		var label: String = quest["title"]
		for talk in quest.get("talks", []):
			if talk["requires_state"] == quest_state and _npc_position(talk["npc"]) != Vector2.INF:
				targets.append({"position": _npc_position(talk["npc"]), "label": label})
		for event in quest.get("events", []):
			if event["requires_state"] != quest_state:
				continue
			for spot in _event_positions(quest_id, event["target"]):
				targets.append({"position": spot, "label": label})
	return targets


## Where an NPC of this level stands, or Vector2.INF if they aren't out here.
func _npc_position(_npc_id: String) -> Vector2:
	return Vector2.INF


## Where the places or objects an event target names are.
func _event_positions(_quest_id: String, _target: String) -> Array[Vector2]:
	return []


## Spots of the objects (one per region in regions, at SCATTER_OFFSETS) the quest hasn't used yet.
func _unused_spots(quest_id: String, prefix: String, regions: Array[Vector2i], offset_shift := 0) -> Array[Vector2]:
	var spots: Array[Vector2] = []
	for index in regions.size():
		if not Quests.is_object_used(quest_id, "%s_%d" % [prefix, index]):
			spots.append(_region_center(regions[index]) + SCATTER_OFFSETS[(index + offset_shift) % SCATTER_OFFSETS.size()])
	return spots
