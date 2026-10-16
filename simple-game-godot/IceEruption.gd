extends Node2D
class_name IceEruption
## A frost circle spreads on the ground as a warning, then ice crystals burst up through it, hurting and
## chilling the player if they are still standing inside.

const WARNING_TIME := 0.9
const SPIKE_TIME := 0.7
const RADIUS := 48.0
const DAMAGE := 18
const WARNING_COLOR := Color(0.22, 0.5, 0.9, 0.3)
const WARNING_EDGE := Color(0.16, 0.42, 0.85, 0.9)
const SPIKE_SCALE := 1.1

var source_monster: Wolf
var spike: Sprite2D
var time := 0.0
var erupted := false


static func spawn(parent: Node, world_position: Vector2, source: Wolf, spike_texture: Texture2D) -> IceEruption:
	var eruption := IceEruption.new()
	eruption.source_monster = source
	eruption.position = world_position
	# The warning lies flat on the ground; the spike itself stands with everything else.
	eruption.z_index = -3
	var spike_sprite := Sprite2D.new()
	spike_sprite.texture = spike_texture
	spike_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spike_sprite.offset = Vector2(0.0, -spike_texture.get_height() * 0.5)
	spike_sprite.position = Vector2(0.0, RADIUS * 0.25)
	spike_sprite.visible = false
	spike_sprite.z_index = 3
	eruption.spike = spike_sprite
	eruption.add_child(spike_sprite)
	parent.add_child(eruption)
	return eruption


func _process(delta: float) -> void:
	time += delta
	if not erupted and time >= WARNING_TIME:
		erupted = true
		_erupt()
	if erupted:
		var progress := (time - WARNING_TIME) / SPIKE_TIME
		# Shoots up fast, then sinks and fades.
		spike.scale = Vector2(SPIKE_SCALE, SPIKE_SCALE * minf(progress * 5.0, 1.0))
		spike.modulate.a = 1.0 - smoothstep(0.6, 1.0, progress)
		if progress >= 1.0:
			queue_free()
	queue_redraw()


func _erupt() -> void:
	spike.show()
	IceShockwave.spawn(get_parent(), global_position, RADIUS * 1.4)
	var player := get_tree().current_scene.get_node_or_null("Player") as Player
	if player == null or player.health <= 0:
		return
	var offset := player.global_position - global_position
	if Vector2(offset.x, offset.y * 2.0).length() > RADIUS * 1.6:
		return
	var damage := DAMAGE
	if is_instance_valid(source_monster):
		damage = source_monster.get_outgoing_damage(DAMAGE)
	var dealt := player.take_damage(damage)
	player.apply_chill(1.4, 0.5)
	if is_instance_valid(source_monster):
		source_monster.register_hit(dealt)


func _draw() -> void:
	if erupted:
		return
	var progress := time / WARNING_TIME
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5))
	draw_circle(Vector2.ZERO, RADIUS * 1.6 * progress, WARNING_COLOR)
	draw_arc(Vector2.ZERO, RADIUS * 1.6, 0.0, TAU, 36, Color(WARNING_EDGE, 0.3 + 0.5 * progress), 2.0)
