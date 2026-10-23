extends Node2D
class_name Hellfire
## A bolt of hellfire thrown by underworld monsters: a flickering fireball trailing embers. Burns the
## player on contact, then bursts.

const SPEED := 270.0
const HIT_RADIUS := 17.0
const MAX_RANGE := 560.0
const TRAIL_LENGTH := 7
const CORE := Color("#fff1a8")
const FLAME := Color("#ff9a2e")
const OUTER := Color("#d9381e")

var damage := 12
var direction := Vector2.RIGHT
## Bigger bolts for the Archdemon.
var size := 1.0
## Monster that threw this, told about hits so on-hit modifiers like Vampiric work.
var source_monster: Wolf
var distance_travelled := 0.0
var time := 0.0
var trail: Array[Vector2] = []


static func launch(parent: Node, from: Vector2, toward: Vector2, bolt_damage: int, source: Wolf, bolt_size := 1.0) -> Hellfire:
	var bolt := Hellfire.new()
	bolt.direction = toward.normalized() if not toward.is_zero_approx() else Vector2.RIGHT
	bolt.damage = bolt_damage
	bolt.source_monster = source
	bolt.size = bolt_size
	bolt.z_index = 2
	parent.add_child(bolt)
	bolt.global_position = from
	FireGlow.attach(bolt, Vector2.ZERO, 60.0 * bolt_size, Color("#ff6a1f"), 0.5)
	return bolt


func _process(delta: float) -> void:
	time += delta
	var step := SPEED * delta
	var player := _find_hit_player(step)
	if player != null:
		var dealt := player.take_damage(damage)
		if is_instance_valid(source_monster):
			source_monster.register_hit(dealt)
		FireShockwave.spawn(get_parent(), global_position + Vector2(0.0, 10.0), 36.0 * size)
		queue_free()
		return
	trail.push_front(global_position)
	if trail.size() > TRAIL_LENGTH:
		trail.pop_back()
	global_position += direction * step
	distance_travelled += step
	if distance_travelled >= MAX_RANGE:
		FireShockwave.spawn(get_parent(), global_position + Vector2(0.0, 10.0), 24.0 * size)
		queue_free()
		return
	queue_redraw()


func _find_hit_player(step: float) -> Player:
	var player := get_tree().current_scene.get_node_or_null("Player") as Player
	if player == null or player.health <= 0:
		return null
	# Aim at the body, a little above the feet.
	var to_player := player.global_position + Vector2(0.0, -14.0) - global_position
	var projection := to_player.dot(direction)
	var radius := HIT_RADIUS * size
	if projection < -radius or projection > step + radius:
		return null
	var closest := direction * clampf(projection, 0.0, step)
	return player if (to_player - closest).length_squared() <= radius * radius else null


func _draw() -> void:
	for index in trail.size():
		var fade := 1.0 - float(index + 1) / (TRAIL_LENGTH + 1)
		var point := to_local(trail[index])
		draw_circle(point, (7.0 * fade + 1.5) * size, Color(OUTER, 0.5 * fade))
	var flicker := sin(time * 32.0) * 1.2
	draw_circle(Vector2.ZERO, (11.0 + flicker) * size, Color(OUTER, 0.85))
	draw_circle(direction * 2.0 * size, (7.5 + flicker * 0.5) * size, FLAME)
	draw_circle(direction * 3.5 * size, 4.0 * size, CORE)
