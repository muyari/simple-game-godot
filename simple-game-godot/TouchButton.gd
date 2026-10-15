extends Button
class_name TouchButton

## Button that also reacts to a second finger. Plain buttons only see the mouse
## events Godot emulates from the first touch, so they ignore a tap made while
## another finger is holding a joystick.

signal activated


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		activated.emit()
		accept_event()
	elif event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION:
		# Already handled as a touch above.
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed:
		activated.emit()
