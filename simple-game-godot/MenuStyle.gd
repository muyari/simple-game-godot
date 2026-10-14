extends RefCounted
class_name MenuStyle

# Shared look for the front-end menus (title, roster, character creation,
# level select) and the in-game pause menu.

const GOLD = Color("e8c77e")
const GOLD_DIM = Color("9e7d4a")
const TEXT = Color("ebe3cd")
const MUTED = Color("b7bdae")
const SAGE = Color("a9c08a")
const DANGER = Color("d9725a")
const PANEL_BG = Color(0.055, 0.07, 0.063, 0.84)
const BUTTON_BG = Color(0.11, 0.13, 0.115, 0.92)
const BUTTON_HOVER_BG = Color(0.18, 0.17, 0.12, 0.96)

const PORTRAIT_SHEETS = {
	"Warrior": preload("res://textures/warrior_sprite_atlas.png"),
	"Witch": preload("res://textures/witch_sprite_atlas.png"),
	"Ranger": preload("res://textures/ranger_sprite_atlas.png"),
}

static var _theme: Theme


static func get_theme() -> Theme:
	if _theme == null:
		_theme = _build_theme()
	return _theme


# Head-and-shoulders crop of a class's front-facing idle frame.
static func class_portrait(character_class: String) -> AtlasTexture:
	var portrait := AtlasTexture.new()
	portrait.atlas = PORTRAIT_SHEETS.get(character_class, PORTRAIT_SHEETS["Warrior"])
	portrait.region = Rect2(22, 6, 56, 56)
	return portrait


static func _build_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 17

	var title_font := SystemFont.new()
	title_font.font_names = PackedStringArray(
		["Georgia", "Palatino Linotype", "Book Antiqua", "Cambria", "serif"]
	)
	title_font.font_weight = 600
	var eyebrow_font := FontVariation.new()
	eyebrow_font.base_font = ThemeDB.fallback_font
	eyebrow_font.spacing_glyph = 3

	# Panels
	var panel := _box(PANEL_BG, GOLD_DIM, 2, 6)
	panel.set_content_margin_all(34.0)
	panel.content_margin_top = 30.0
	panel.shadow_color = Color(0, 0, 0, 0.45)
	panel.shadow_size = 22
	theme.set_type_variation("MenuPanel", "PanelContainer")
	theme.set_stylebox("panel", "MenuPanel", panel)

	# Labels
	theme.set_color("font_color", "Label", TEXT)
	theme.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.35))
	theme.set_constant("shadow_offset_y", "Label", 1)

	theme.set_type_variation("HeroTitleLabel", "Label")
	theme.set_font("font", "HeroTitleLabel", title_font)
	theme.set_font_size("font_size", "HeroTitleLabel", 56)
	theme.set_color("font_color", "HeroTitleLabel", GOLD)
	theme.set_color("font_shadow_color", "HeroTitleLabel", Color(0.2, 0.08, 0.02, 0.8))
	theme.set_constant("shadow_offset_x", "HeroTitleLabel", 0)
	theme.set_constant("shadow_offset_y", "HeroTitleLabel", 3)

	theme.set_type_variation("TitleLabel", "Label")
	theme.set_font("font", "TitleLabel", title_font)
	theme.set_font_size("font_size", "TitleLabel", 34)
	theme.set_color("font_color", "TitleLabel", GOLD)
	theme.set_color("font_shadow_color", "TitleLabel", Color(0.2, 0.08, 0.02, 0.75))
	theme.set_constant("shadow_offset_y", "TitleLabel", 2)

	theme.set_type_variation("EyebrowLabel", "Label")
	theme.set_font("font", "EyebrowLabel", eyebrow_font)
	theme.set_font_size("font_size", "EyebrowLabel", 13)
	theme.set_color("font_color", "EyebrowLabel", SAGE)

	theme.set_type_variation("SubtitleLabel", "Label")
	theme.set_font_size("font_size", "SubtitleLabel", 16)
	theme.set_color("font_color", "SubtitleLabel", MUTED)

	theme.set_type_variation("StatusLabel", "Label")
	theme.set_font_size("font_size", "StatusLabel", 15)
	theme.set_color("font_color", "StatusLabel", SAGE)

	theme.set_type_variation("HintLabel", "Label")
	theme.set_font_size("font_size", "HintLabel", 13)
	theme.set_color("font_color", "HintLabel", Color(MUTED, 0.7))

	# Buttons
	var normal := _box(BUTTON_BG, Color(GOLD_DIM, 0.45), 1, 4)
	var hover := _box(BUTTON_HOVER_BG, GOLD, 1, 4)
	hover.border_width_left = 4
	var pressed := _box(Color(0.08, 0.09, 0.08, 0.96), GOLD, 1, 4)
	pressed.border_width_left = 4
	var disabled := _box(Color(0.08, 0.09, 0.085, 0.6), Color(GOLD_DIM, 0.18), 1, 4)
	var focus := _box(Color(0, 0, 0, 0), Color(GOLD, 0.7), 2, 4)
	focus.draw_center = false
	for box in [normal, hover, pressed, disabled]:
		box.content_margin_left = 20.0
		box.content_margin_right = 20.0
		box.content_margin_top = 8.0
		box.content_margin_bottom = 8.0
	hover.content_margin_left = 23.0
	pressed.content_margin_left = 23.0
	theme.set_stylebox("normal", "Button", normal)
	theme.set_stylebox("hover", "Button", hover)
	theme.set_stylebox("pressed", "Button", pressed)
	theme.set_stylebox("hover_pressed", "Button", pressed)
	theme.set_stylebox("disabled", "Button", disabled)
	theme.set_stylebox("focus", "Button", focus)
	theme.set_font_size("font_size", "Button", 18)
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_hover_color", "Button", Color("f6e4b4"))
	theme.set_color("font_focus_color", "Button", TEXT)
	theme.set_color("font_pressed_color", "Button", GOLD)
	theme.set_color("font_hover_pressed_color", "Button", GOLD)
	theme.set_color("font_disabled_color", "Button", Color(MUTED, 0.38))
	theme.set_constant("h_separation", "Button", 14)
	theme.set_constant("icon_max_width", "Button", 44)

	# Selectable cards (roster entries, class choices): pressed = selected.
	theme.set_type_variation("ChoiceButton", "Button")
	var selected := _box(Color(0.2, 0.17, 0.1, 0.96), GOLD, 2, 4)
	selected.border_width_left = 5
	selected.content_margin_left = 16.0
	selected.content_margin_right = 20.0
	selected.content_margin_top = 6.0
	selected.content_margin_bottom = 6.0
	var choice_normal: StyleBoxFlat = normal.duplicate()
	choice_normal.content_margin_left = 16.0
	choice_normal.content_margin_top = 6.0
	choice_normal.content_margin_bottom = 6.0
	var choice_hover: StyleBoxFlat = hover.duplicate()
	choice_hover.content_margin_left = 16.0
	choice_hover.content_margin_top = 6.0
	choice_hover.content_margin_bottom = 6.0
	theme.set_stylebox("normal", "ChoiceButton", choice_normal)
	theme.set_stylebox("hover", "ChoiceButton", choice_hover)
	theme.set_stylebox("pressed", "ChoiceButton", selected)
	theme.set_stylebox("hover_pressed", "ChoiceButton", selected)
	theme.set_font_size("font_size", "ChoiceButton", 17)

	theme.set_type_variation("DangerButton", "Button")
	var danger_hover: StyleBoxFlat = hover.duplicate()
	danger_hover.border_color = DANGER
	danger_hover.bg_color = Color(0.2, 0.1, 0.08, 0.96)
	theme.set_stylebox("hover", "DangerButton", danger_hover)
	theme.set_color("font_hover_color", "DangerButton", Color("f2b29f"))

	# Text input
	var line_normal := _box(Color(0.03, 0.04, 0.035, 0.9), Color(GOLD_DIM, 0.55), 1, 4)
	line_normal.content_margin_left = 16.0
	line_normal.content_margin_right = 16.0
	var line_focus: StyleBoxFlat = line_normal.duplicate()
	line_focus.border_color = GOLD
	theme.set_stylebox("normal", "LineEdit", line_normal)
	theme.set_stylebox("focus", "LineEdit", line_focus)
	theme.set_font_size("font_size", "LineEdit", 18)
	theme.set_color("font_color", "LineEdit", TEXT)
	theme.set_color("font_placeholder_color", "LineEdit", Color(MUTED, 0.5))
	theme.set_color("caret_color", "LineEdit", GOLD)
	theme.set_color("selection_color", "LineEdit", Color(GOLD_DIM, 0.5))

	# Ornamental divider
	var divider := StyleBoxLine.new()
	divider.color = Color(GOLD_DIM, 0.65)
	divider.thickness = 1
	theme.set_stylebox("separator", "HSeparator", divider)
	theme.set_constant("separation", "HSeparator", 6)

	# Scrollbars
	var scroll_track := StyleBoxFlat.new()
	scroll_track.bg_color = Color(0, 0, 0, 0.25)
	scroll_track.set_corner_radius_all(3)
	scroll_track.content_margin_left = 3.0
	scroll_track.content_margin_right = 3.0
	var grabber := StyleBoxFlat.new()
	grabber.bg_color = Color(GOLD_DIM, 0.75)
	grabber.set_corner_radius_all(3)
	var grabber_hover: StyleBoxFlat = grabber.duplicate()
	grabber_hover.bg_color = GOLD
	theme.set_stylebox("scroll", "VScrollBar", scroll_track)
	theme.set_stylebox("grabber", "VScrollBar", grabber)
	theme.set_stylebox("grabber_highlight", "VScrollBar", grabber_hover)
	theme.set_stylebox("grabber_pressed", "VScrollBar", grabber_hover)

	# Dialogs (delete confirmation)
	var dialog_panel := _box(PANEL_BG, Color(0, 0, 0, 0), 0, 0)
	dialog_panel.set_content_margin_all(18.0)
	theme.set_stylebox("panel", "AcceptDialog", dialog_panel)
	var window_border := _box(Color(0.09, 0.1, 0.085, 1), GOLD_DIM, 2, 6)
	window_border.expand_margin_top = 32.0
	window_border.expand_margin_left = 2.0
	window_border.expand_margin_right = 2.0
	window_border.expand_margin_bottom = 2.0
	window_border.shadow_color = Color(0, 0, 0, 0.5)
	window_border.shadow_size = 16
	theme.set_stylebox("embedded_border", "Window", window_border)
	theme.set_stylebox("embedded_unfocused_border", "Window", window_border)
	theme.set_color("title_color", "Window", GOLD)
	theme.set_font("title_font", "Window", title_font)
	theme.set_font_size("title_font_size", "Window", 18)

	return theme


static func _box(bg: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	box.anti_aliasing = true
	return box
