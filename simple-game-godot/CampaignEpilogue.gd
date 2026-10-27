extends CanvasLayer
class_name CampaignEpilogue
## The end of the campaign's story, added to every hub's HUD (TownUI). When a quest with an "epilogue"
## (Quests.LAST_WATCHFIRE) is completed, the screen fades to night and its pages tell, one at a time, what
## became of every land the player saved. It plays once per character: a quest counter remembers it was seen,
## and if the game closed before it could play, it plays on the next hub visit.
##
## Also hands over a completed quest's "item_reward" (the Brand of Ashgate), remembered the same way, and
## tries again on every hub visit while the player's pack is too full to take it.

const FADE_TIME := 1.4
const PAGE_FADE := 0.5
const SEEN_SUFFIX := "/epilogue_seen"
const GRANTED_SUFFIX := "/item_granted"

var player: Player
var backdrop: ColorRect
var page_box: VBoxContainer
var title_label: Label
var text_label: Label
var hint_label: Label
var pages: Array = []
var page_index := -1
## Set while a fade is running, so a click can't skip a page before it's shown.
var turning := false


func _ready() -> void:
	layer = 95
	visible = false
	_build()
	GameState.quest_changed.connect(_on_quest_changed)
	_on_quest_changed.call_deferred("")


func is_playing() -> bool:
	return visible


func _on_quest_changed(_quest_id: String) -> void:
	_grant_item_rewards()
	if is_playing():
		return
	for quest_id in Quests.DEFINITIONS:
		var quest: Dictionary = Quests.DEFINITIONS[quest_id]
		if quest.has("epilogue") and Quests.is_completed(quest_id) and GameState.get_quest_counter(quest_id + SEEN_SUFFIX) == 0:
			# Remembered first, so the counter's own quest_changed doesn't start it twice.
			GameState.set_quest_counter(quest_id + SEEN_SUFFIX, 1)
			play(quest["epilogue"])
			return


func _grant_item_rewards() -> void:
	if not is_instance_valid(player):
		return
	for quest_id in Quests.DEFINITIONS:
		if not Quests.DEFINITIONS[quest_id].has("item_reward") or not Quests.is_completed(quest_id) \
				or GameState.get_quest_counter(quest_id + GRANTED_SUFFIX) > 0:
			continue
		var item := Quests.create_item_reward(quest_id)
		if player.try_add_item(item):
			GameState.set_quest_counter(quest_id + GRANTED_SUFFIX, 1)
			_notify(quest_id, "You received the %s." % item.display_name)
		else:
			_notify(quest_id, "Your pack is full. Make room, then return to any hub to receive the %s." % item.display_name)


func _notify(quest_id: String, text: String) -> void:
	var toast := get_tree().get_first_node_in_group(QuestToast.GROUP) as QuestToast
	if toast != null:
		toast.show_notice(quest_id, text, false)


## Fades to night and shows the first of pages ({title, text}); the player can't move until it ends.
func play(epilogue_pages: Array) -> void:
	pages = epilogue_pages
	page_index = -1
	visible = true
	turning = true
	backdrop.color.a = 0.0
	page_box.modulate.a = 0.0
	if is_instance_valid(player):
		player.set_physics_process(false)
		player.set_process_unhandled_input(false)
	Audio.play_sfx("level_complete")
	var tween := create_tween()
	tween.tween_interval(1.2)
	tween.tween_property(backdrop, "color:a", 0.94, FADE_TIME)
	tween.tween_callback(_show_next_page)


func _show_next_page() -> void:
	page_index += 1
	if page_index >= pages.size():
		_finish()
		return
	turning = true
	var tween := create_tween()
	if page_box.modulate.a > 0.0:
		tween.tween_property(page_box, "modulate:a", 0.0, PAGE_FADE)
	tween.tween_callback(func() -> void:
		var page: Dictionary = pages[page_index]
		title_label.text = page["title"]
		text_label.text = page["text"]
		hint_label.text = ("Continue" if page_index < pages.size() - 1 else "Return to Ashgate") + MenuStyle.key_hint("Enter") + "      Skip" + MenuStyle.key_hint("Esc")
	)
	tween.tween_property(page_box, "modulate:a", 1.0, PAGE_FADE)
	tween.tween_callback(func() -> void: turning = false)


func _finish() -> void:
	turning = true
	var tween := create_tween()
	tween.tween_property(page_box, "modulate:a", 0.0, PAGE_FADE)
	tween.tween_property(backdrop, "color:a", 0.0, FADE_TIME)
	tween.tween_callback(func() -> void:
		visible = false
		turning = false
		if is_instance_valid(player) and player.health > 0:
			player.set_physics_process(true)
			player.set_process_unhandled_input(true)
	)


func _input(event: InputEvent) -> void:
	if not is_playing():
		return
	var advance: bool = event.is_action_pressed("ui_accept") \
			or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
			or (event is InputEventScreenTouch and event.pressed)
	var skip := event.is_action_pressed("ui_cancel")
	if not advance and not skip:
		return
	get_viewport().set_input_as_handled()
	if turning:
		return
	if skip:
		page_index = pages.size()
		_finish()
	else:
		_show_next_page()


func _build() -> void:
	var root := Control.new()
	root.theme = MenuStyle.get_theme()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	backdrop = ColorRect.new()
	backdrop.color = Color(0.02, 0.015, 0.03, 0.0)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	page_box = VBoxContainer.new()
	page_box.custom_minimum_size = Vector2(680, 0)
	page_box.add_theme_constant_override("separation", 22)
	page_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(page_box)
	title_label = _label(38, MenuStyle.GOLD)
	page_box.add_child(title_label)
	var rule := ColorRect.new()
	rule.color = Color(MenuStyle.GOLD_DIM, 0.7)
	rule.custom_minimum_size = Vector2(240, 2)
	rule.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	page_box.add_child(rule)
	text_label = _label(20, MenuStyle.TEXT)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.custom_minimum_size = Vector2(680, 0)
	page_box.add_child(text_label)
	hint_label = _label(15, MenuStyle.MUTED)
	page_box.add_child(hint_label)


func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
