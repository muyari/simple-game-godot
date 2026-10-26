extends VBoxContainer
class_name AudioSettings
## Music and sound effect volume sliders. Changes apply (and save) as the slider moves; a test sound
## plays when the effects slider is let go so the new level can be heard.

const SLIDER_HEIGHT := 34.0
const TOUCH_SLIDER_HEIGHT := 48.0


func _ready() -> void:
	add_theme_constant_override("separation", 6)
	_add_row("Music", Audio.music_volume, Audio.set_music_volume, Callable())
	_add_row("Sound Effects", Audio.sfx_volume, Audio.set_sfx_volume, Audio.play_sfx.bind("coin"))


func _add_row(label_text: String, value: float, on_changed: Callable, on_released: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	add_child(row)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 140.0
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	slider.value = roundf(value * 100.0)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.custom_minimum_size.y = TOUCH_SLIDER_HEIGHT if TouchControls.is_supported() else SLIDER_HEIGHT
	row.add_child(slider)

	var amount := Label.new()
	amount.custom_minimum_size.x = 44.0
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	amount.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	amount.theme_type_variation = &"HintLabel"
	amount.text = "%d%%" % roundi(slider.value)
	row.add_child(amount)

	slider.value_changed.connect(func(new_value: float) -> void:
		amount.text = "%d%%" % roundi(new_value)
		on_changed.call(new_value / 100.0)
	)
	if on_released.is_valid():
		slider.drag_ended.connect(func(_changed: bool) -> void: on_released.call())
