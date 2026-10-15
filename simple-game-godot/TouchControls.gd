extends Control
class_name TouchControls

## Touch HUD for phones and tablets, laid out in touch_controls.tscn: the left
## half of the screen moves the player and the right half aims and attacks.
## The HudLayout markers in that scene position the HUD's own globes, potions
## and skill slots. Added behind the rest of the HUD so skill slots, menus and
## other UI still take touches first.

const SCENE_PATH := "res://touch_controls.tscn"
const MOVE_ACTIONS := {
	"move_left": Vector2.LEFT,
	"move_right": Vector2.RIGHT,
	"move_up": Vector2.UP,
	"move_down": Vector2.DOWN,
}
## Aim deflection needed before the right stick starts aiming and attacking.
const AIM_THRESHOLD := 0.25

var player: Player

var _pressed_actions: Dictionary = {}

@onready var move_stick: TouchStick = $MoveStick
@onready var aim_stick: TouchStick = $AimStick
@onready var interact_button: TouchButton = $InteractButton
@onready var hud_layout: Control = $HudLayout


## Phones and tablets only, so PC players (touchscreen laptops included) keep
## the keyboard and mouse HUD. Enabling Input Devices > Pointing > Emulate
## Touch From Mouse in Project Settings turns them on for testing on a PC.
static func is_supported() -> bool:
	return OS.has_feature("mobile") or Input.is_emulating_touch_from_mouse()


static func create(for_player: Player) -> TouchControls:
	var controls := (load(SCENE_PATH) as PackedScene).instantiate() as TouchControls
	controls.player = for_player
	return controls


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	player.free_aim = true
	aim_stick.tapped.connect(_on_aim_stick_tapped)
	interact_button.theme = MenuStyle.get_theme()
	interact_button.activated.connect(_on_interact_pressed)
	interact_button.hide()
	_apply_hud_layout()
	_let_touches_through_globes()
	_make_potions_tappable()


## Moves each HUD node to the marker with the same name, then drops the markers.
func _apply_hud_layout() -> void:
	for marker in hud_layout.get_children():
		var target := get_parent().get_node_or_null(NodePath(marker.name)) as Control
		if target == null:
			continue
		# A left/top anchor past the current right/bottom one is dropped, so open
		# the far sides fully first; every step below then stays valid.
		target.set_anchor(SIDE_RIGHT, 1.0, true, false)
		target.set_anchor(SIDE_BOTTOM, 1.0, true, false)
		for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			target.set_anchor(side, marker.get_anchor(side), true, false)
		for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			target.set_offset(side, marker.get_offset(side))
		if target is SkillSlot:
			(target as SkillSlot).touch_style = true
	hud_layout.queue_free()


## The health and mana globes are display only; let a thumb that lands on one
## start the joystick underneath.
func _let_touches_through_globes() -> void:
	for node_name in ["HealthOrb", "ManaOrb"]:
		var globe := get_parent().get_node_or_null(node_name) as Control
		if globe != null:
			globe.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _make_potions_tappable() -> void:
	var hud := get_parent()
	var potions := {
		"HealthPotion": player.use_health_potion,
		"ManaPotion": player.use_mana_potion,
	}
	for node_name in potions:
		var flask := hud.get_node_or_null(node_name) as Control
		if flask == null:
			continue
		flask.mouse_filter = Control.MOUSE_FILTER_STOP
		flask.gui_input.connect(_on_potion_input.bind(flask, potions[node_name]))


func _on_potion_input(event: InputEvent, flask: Control, use_potion: Callable) -> void:
	if event is InputEventScreenTouch and event.pressed:
		if player.is_physics_processing():
			use_potion.call()
		flask.accept_event()


func _process(_delta: float) -> void:
	var player_active := is_instance_valid(player) and player.is_physics_processing() \
			and not get_tree().paused
	move_stick.visible = player_active
	aim_stick.visible = player_active

	_apply_movement(move_stick.output if player_active else Vector2.ZERO)
	if not is_instance_valid(player):
		return
	if player_active and aim_stick.output.length() > AIM_THRESHOLD:
		player.set_aim(aim_stick.output)
	elif player.aim_held:
		player.release_aim()
	_update_interact_button(player.get_interact_target() if player_active else null)


func _update_interact_button(target: Node2D) -> void:
	interact_button.visible = target != null
	if target != null:
		interact_button.text = _get_interact_label(target)


## The interactable's own world prompt ("E  Talk") without the key hint.
func _get_interact_label(target: Node2D) -> String:
	for property in ["prompt", "interaction_prompt"]:
		var prompt_label := target.get(property) as Label
		if prompt_label != null and not prompt_label.text.is_empty():
			return prompt_label.text.trim_prefix("E  ").strip_edges()
	return "Interact"


func _on_interact_pressed() -> void:
	if is_instance_valid(player) and player.is_physics_processing():
		player.try_interact()


func _exit_tree() -> void:
	_apply_movement(Vector2.ZERO)


func _apply_movement(direction: Vector2) -> void:
	for action in MOVE_ACTIONS:
		var strength := maxf(direction.dot(MOVE_ACTIONS[action]), 0.0)
		if strength > 0.0:
			Input.action_press(action, strength)
			_pressed_actions[action] = true
		elif _pressed_actions.has(action):
			# Only release what the stick pressed, so a keyboard keeps working.
			Input.action_release(action)
			_pressed_actions.erase(action)


func _on_aim_stick_tapped() -> void:
	if is_instance_valid(player) and player.is_physics_processing():
		player.tap_attack()
