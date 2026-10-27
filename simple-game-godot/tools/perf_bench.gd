extends Node
## Measures how smoothly each level and hub runs, so performance changes can be compared before and after.
## Nothing here ships in the game. Run its scene windowed (headless skips rendering, so GPU cost wouldn't
## show):
##   Godot --path <project> res://tools/perf_bench.tscn [-- scene scene ...]
## Scenes are names like "main" or "desert_camp"; with none it measures every level and hub.
##
## Each scene is sampled where the player arrives, then levels are explored region by region (the player
## is teleported across the whole map and kept alive) and sampled again back at the start and at the map's
## far corner. Exploring is what made levels slow down over time, so the "explored" rows matter most.
## Plays as whichever character the save loads (Developer Mode's dev characters when it's on). Levels save
## as they're played, so the save files are copied first and put back when it finishes.

const DEFAULT_SCENES: Array[String] = [
	"main", "desert", "ice_caves", "underworld", "endgame_map",
	"town", "desert_camp", "ice_settlement", "besieged_outpost",
]
const SETTLE_FRAMES := 90
const SAMPLE_FRAMES := 300
const FRAMES_PER_REGION := 4
const SAVE_FILES: Array[String] = ["user://character_save.json", "user://character_roster.json"]
const CHARACTER_DIR := "user://characters/"

var player: Player


func _ready() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	_run.call_deferred()


func _run() -> void:
	var scenes := DEFAULT_SCENES
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		scenes.assign(args)
	var saves := _read_saves()
	print("scene | phase | avg ms | p95 ms | max ms | nodes | objects | processing | draw calls | canvas items")
	for scene_name in scenes:
		await _measure_scene("res://%s.tscn" % scene_name)
	# Out of the levels first, so nothing saves over the restored files on the way out.
	get_tree().unload_current_scene()
	await get_tree().process_frame
	_write_saves(saves)
	get_tree().quit()


func _read_saves() -> Dictionary:
	var paths := SAVE_FILES.duplicate()
	for file_name in DirAccess.get_files_at(CHARACTER_DIR):
		paths.append(CHARACTER_DIR + file_name)
	var saves := {}
	for path in paths:
		if FileAccess.file_exists(path):
			saves[path] = FileAccess.get_file_as_bytes(path)
	return saves


func _write_saves(saves: Dictionary) -> void:
	for path: String in saves:
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file == null:
			push_error("Could not restore %s." % path)
			continue
		file.store_buffer(saves[path])


func _measure_scene(scene_path: String) -> void:
	var tree := get_tree()
	# Out of the way of change_scene_to_packed(), which frees the current scene: this node runs alongside.
	if tree.current_scene == self:
		tree.current_scene = null
	var packed := load(scene_path) as PackedScene
	if packed == null or tree.change_scene_to_packed(packed) != OK:
		push_error("Could not open %s." % scene_path)
		return
	await tree.scene_changed
	var scene := tree.current_scene
	await _wait_frames(SETTLE_FRAMES)
	player = scene.get_node_or_null("Player") as Player
	var scene_name := scene_path.get_file().get_basename()
	await _sample(scene_name, "arrival")
	var level := scene.get_node_or_null("LevelController")
	if level == null or player == null:
		_print_busiest()
		return
	var start := player.global_position
	var corner := await _explore(level)
	_teleport(start)
	await _wait_frames(SETTLE_FRAMES)
	await _sample(scene_name, "explored, start")
	_teleport(corner)
	await _wait_frames(SETTLE_FRAMES)
	await _sample(scene_name, "explored, far corner")
	_print_busiest()


## Walks the camera over every region of the map in rows, generating its scenery and spawning its monsters
## the way a full run would. Returns the last spot visited.
func _explore(level: Node) -> Vector2:
	var half: Vector2i = level.MAP_HALF_REGIONS
	var region_origin: Vector2 = level.region_origin
	var region_size: Vector2 = level.region_size
	var spot := player.global_position
	for y in range(-half.y, half.y + 1):
		var xs := range(-half.x, half.x + 1)
		if (y + half.y) % 2 == 1:
			xs.reverse()
		for x in xs:
			spot = region_origin + Vector2(x, y) * region_size
			_teleport(spot)
			await _wait_frames(FRAMES_PER_REGION)
	return spot


func _teleport(world_position: Vector2) -> void:
	if is_instance_valid(player):
		player.global_position = world_position
		player.health = player.get_max_health()


func _wait_frames(count: int) -> void:
	for index in count:
		if is_instance_valid(player):
			player.health = player.get_max_health()
		await get_tree().process_frame


func _sample(scene_name: String, phase: String) -> void:
	var frame_ms: Array[float] = []
	var draw_calls := 0.0
	var frame_start_usec := Time.get_ticks_usec()
	for index in SAMPLE_FRAMES:
		if is_instance_valid(player):
			player.health = player.get_max_health()
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		frame_ms.append((now - frame_start_usec) / 1000.0)
		frame_start_usec = now
		draw_calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var total := 0.0
	for value in frame_ms:
		total += value
	var sorted := frame_ms.duplicate()
	sorted.sort()
	var counts := _count_nodes(get_tree().root)
	print("%s | %s | %.2f | %.2f | %.2f | %d | %d | %d | %d | %d" % [
		scene_name, phase,
		total / SAMPLE_FRAMES, sorted[int(SAMPLE_FRAMES * 0.95)], sorted[-1],
		Performance.get_monitor(Performance.OBJECT_NODE_COUNT), Performance.get_monitor(Performance.OBJECT_COUNT),
		counts["processing"], roundi(draw_calls / SAMPLE_FRAMES), counts["canvas_items"],
	])


func _count_nodes(node: Node, counts := {"processing": 0, "canvas_items": 0, "by_script": {}}) -> Dictionary:
	if node.can_process() and (node.is_processing() or node.is_physics_processing()):
		counts["processing"] += 1
		var script := node.get_script() as Script
		var key: String = script.resource_path.get_file() if script != null else node.get_class()
		counts["by_script"][key] = int(counts["by_script"].get(key, 0)) + 1
	if node is CanvasItem:
		counts["canvas_items"] += 1
	for child in node.get_children():
		_count_nodes(child, counts)
	return counts


func _print_busiest() -> void:
	var by_script: Dictionary = _count_nodes(get_tree().root)["by_script"]
	var keys := by_script.keys()
	keys.sort_custom(func(a: String, b: String) -> bool: return by_script[a] > by_script[b])
	var parts: PackedStringArray = []
	for key in keys.slice(0, 12):
		parts.append("%s x%d" % [key, by_script[key]])
	print("  processing nodes: ", ", ".join(parts))
