extends RefCounted
class_name SmoothArt
## Renders a scene's sprites through smooth_art.gdshader, so pixel art reads clean and anti-aliased at
## every screen size (matching the shader-drawn HUD) instead of jagged under nearest-pixel sampling.

const SHADER = preload("res://smooth_art.gdshader")

static var _material: ShaderMaterial


static func material() -> ShaderMaterial:
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = SHADER
	return _material


## Smooths `item` and every textured canvas item under it, skipping HUD layers and anything that already
## has its own material.
static func apply(root: Node) -> void:
	if root is CanvasLayer:
		return
	if root is Sprite2D or root is Polygon2D or root is AnimatedSprite2D or root is TextureRect:
		_smooth(root as CanvasItem)
	for child in root.get_children():
		apply(child)


## Keeps smoothing art added after the scene loads (pickups, effects, spawned props).
static func watch(tree: SceneTree, scene_root: Node) -> void:
	var on_added := func(node: Node) -> void:
		if is_instance_valid(scene_root) and scene_root.is_ancestor_of(node) and not _in_layer(node, scene_root):
			if node is Sprite2D or node is Polygon2D or node is AnimatedSprite2D:
				_smooth(node as CanvasItem)
	tree.node_added.connect(on_added)
	# Stop watching when the scene goes, or the lambda outlives the root it captured.
	scene_root.tree_exiting.connect(func() -> void:
		if tree.node_added.is_connected(on_added):
			tree.node_added.disconnect(on_added)
	, CONNECT_ONE_SHOT)


static func _smooth(item: CanvasItem) -> void:
	if item.material != null:
		return
	item.material = material()
	item.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS


static func _in_layer(node: Node, scene_root: Node) -> bool:
	var parent := node.get_parent()
	while parent != null and parent != scene_root:
		if parent is CanvasLayer:
			return true
		parent = parent.get_parent()
	return false
