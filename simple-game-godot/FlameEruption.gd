extends Node2D
class_name FlameEruption
## A glowing scorch spreads on the ground as a warning, then a pillar of fire roars up through it,
## burning the player if they are still standing inside.

const WARNING_TIME := 0.9
const BURN_TIME := 0.7
const RADIUS := 50.0
const DAMAGE := 20
const WARNING_FILL := Color(0.9, 0.2, 0.05, 0.28)
const WARNING_EDGE := Color(1.0, 0.45, 0.12, 0.9)
const FLAME_COLORS: Array[Color] = [Color("#d9381e"), Color("#ff7a26"), Color("#ffc65c"), Color("#fff1a8")]

var source_monster: Wolf
var damage := DAMAGE
var time := 0.0
var erupted := false
var glow: FireGlow


static func spawn(parent: Node, world_position: Vector2, source: Wolf, eruption_damage := DAMAGE) -> FlameEruption:
	var eruption := FlameEruption.new()
	eruption.source_monster = source
	eruption.damage = eruption_damage
	eruption.position = world_position
	parent.add_child(eruption)
	return eruption


func _ready() -> void:
	glow = FireGlow.attach(self, Vector2.ZERO, RADIUS * 3.0, Color("#ff5a1a"), 0.0)


func _process(delta: float) -> void:
	time += delta
	if not erupted and time >= WARNING_TIME:
		erupted = true
		_burn()
	glow.strength = clampf(time / WARNING_TIME, 0.0, 1.0) * 0.35 if not erupted else 0.85
	if time >= WARNING_TIME + BURN_TIME:
		queue_free()
		return
	queue_redraw()


func _burn() -> void:
	FireShockwave.spawn(get_parent(), global_position, RADIUS * 1.4)
	var player := get_tree().current_scene.get_node_or_null("Player") as Player
	if player == null or player.health <= 0:
		return
	var offset := player.global_position - global_position
	# The scorch is an ellipse flattened for the top-down view.
	if Vector2(offset.x, offset.y / 0.55).length() > RADIUS:
		return
	var dealt := player.take_damage(damage)
	if is_instance_valid(source_monster):
		source_monster.register_hit(dealt)


func _draw() -> void:
	if not erupted:
		var progress := time / WARNING_TIME
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.55))
		draw_circle(Vector2.ZERO, RADIUS * progress, WARNING_FILL)
		draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 36, Color(WARNING_EDGE, 0.35 + 0.55 * progress), 2.5)
		return
	var burn := (time - WARNING_TIME) / BURN_TIME
	var height := 120.0 * sin(minf(burn * 1.6, 1.0) * PI * 0.5) * (1.0 - burn * 0.6)
	var fade := 1.0 - maxf(burn - 0.6, 0.0) / 0.4
	# Tongues of flame, outer colours first so the hot core sits on top.
	for layer in FLAME_COLORS.size():
		var width := RADIUS * (1.0 - layer * 0.22)
		var tongue_height := height * (1.0 - layer * 0.18)
		var points := PackedVector2Array()
		points.append(Vector2(-width, 0.0))
		for step in 7:
			var x := lerpf(-width, width, (step + 0.5) / 7.0)
			var flick := sin(time * 26.0 + step * 1.9 + layer) * 0.18 + 0.82
			var peak := tongue_height * flick * (1.0 - absf(x / width) * 0.65)
			points.append(Vector2(x, -peak))
		points.append(Vector2(width, 0.0))
		draw_colored_polygon(points, Color(FLAME_COLORS[layer], 0.9 * fade))
