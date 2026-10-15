extends Control
class_name TouchStick

## Floating on-screen joystick. The base appears where a finger first touches
## inside this control and the knob follows that finger, so each stick owns one
## touch index and two sticks can be used at the same time.

signal tapped

const BASE_RADIUS := 100.0
const KNOB_RADIUS := 42.0
## Fraction of the radius that already counts as a full push.
const FULL_PUSH := 0.85
## Releases within this time and distance count as a tap instead of a drag.
const TAP_MAX_TIME := 0.25
const TAP_MAX_DISTANCE := 18.0

const RING_COLOR := Color(0.91, 0.78, 0.49)
const FILL_COLOR := Color(0.055, 0.07, 0.063)

## Stick deflection, length 0 to 1.
var output := Vector2.ZERO

var _touch_index := -1
var _base_position := Vector2.ZERO
var _knob_offset := Vector2.ZERO
var _press_time := 0.0
var _max_travel := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)
	visibility_changed.connect(_on_visibility_changed)


func is_active() -> bool:
	return _touch_index != -1


func reset() -> void:
	_touch_index = -1
	_knob_offset = Vector2.ZERO
	output = Vector2.ZERO
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	# Mouse events emulated from touch are swallowed here (MOUSE_FILTER_STOP) so
	# they never reach the player's click-to-move.
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			_touch_index = event.index
			_base_position = event.position
			_knob_offset = Vector2.ZERO
			_press_time = Time.get_ticks_msec() / 1000.0
			_max_travel = 0.0
			_update_output()
			accept_event()
		elif not event.pressed and event.index == _touch_index:
			var held_time := Time.get_ticks_msec() / 1000.0 - _press_time
			var was_tap := held_time <= TAP_MAX_TIME and _max_travel <= TAP_MAX_DISTANCE
			reset()
			accept_event()
			if was_tap:
				tapped.emit()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_knob_offset = (event.position - _base_position).limit_length(BASE_RADIUS)
		_max_travel = maxf(_max_travel, _knob_offset.length())
		_update_output()
		accept_event()


func _update_output() -> void:
	output = (_knob_offset / (BASE_RADIUS * FULL_PUSH)).limit_length(1.0)
	queue_redraw()


func _draw() -> void:
	# Invisible until touched; the whole half of the screen is the stick.
	if not is_active():
		return
	draw_circle(_base_position, BASE_RADIUS, Color(FILL_COLOR, 0.3))
	draw_arc(_base_position, BASE_RADIUS, 0.0, TAU, 64, Color(RING_COLOR, 0.5), 3.0, true)
	draw_circle(_base_position + _knob_offset, KNOB_RADIUS, Color(RING_COLOR, 0.3))
	draw_arc(_base_position + _knob_offset, KNOB_RADIUS, 0.0, TAU, 48, Color(RING_COLOR, 0.72), 2.0, true)


func _on_visibility_changed() -> void:
	if not is_visible_in_tree():
		reset()
