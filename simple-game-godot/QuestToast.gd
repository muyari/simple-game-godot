extends VBoxContainer
class_name QuestToast
## Short notices near the top of the screen when a quest moves on out in the world: "Trees picked 2/5",
## or the quest's title and new status line. Each fades out after a few seconds.

const GROUP := "quest_toast"
const SHOW_TIME := 4.0
const FADE_TIME := 0.6
const MAX_NOTICES := 3
const TITLE_COLOR := Color("#ffd34d")
const TEXT_COLOR := Color("#f3ead8")


## Shows the updates from Quests.record_event on the HUD's toast, if there is one.
static func show_updates(tree: SceneTree, updates: Array[Dictionary]) -> void:
	var toast := tree.get_first_node_in_group(GROUP) as QuestToast
	if toast == null:
		return
	for update in updates:
		toast.show_notice(update["quest_id"], update["text"], bool(update.get("advanced", false)))


func _ready() -> void:
	add_to_group(GROUP)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	offset_left = -260.0
	offset_right = 260.0
	offset_top = 12.0
	add_theme_constant_override("separation", 6)
	alignment = BoxContainer.ALIGNMENT_BEGIN


func show_notice(quest_id: String, text: String, advanced: bool) -> void:
	while get_child_count() >= MAX_NOTICES:
		var oldest := get_child(0)
		remove_child(oldest)
		oldest.queue_free()
	var notice := VBoxContainer.new()
	notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notice.add_theme_constant_override("separation", 0)
	var title := _label(("Quest Updated: %s" if advanced else "%s") % Quests.get_definition(quest_id).get("title", ""), 16, TITLE_COLOR)
	notice.add_child(title)
	notice.add_child(_label(text, 15, TEXT_COLOR))
	add_child(notice)
	var tween := notice.create_tween()
	tween.tween_interval(SHOW_TIME)
	tween.tween_property(notice, "modulate:a", 0.0, FADE_TIME)
	tween.tween_callback(notice.queue_free)


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	MenuStyle.outline_hud_label(label)
	return label
