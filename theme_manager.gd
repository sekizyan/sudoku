class_name ThemeManager
extends RefCounted

signal theme_changed

const CORNER_RADIUS_CELL := 5
const CORNER_RADIUS_BTN := 6
const CORNER_RADIUS_OVERLAY := 12

var dark_mode := true
var _cell_style_cache: Dictionary = {}

var color_selected : Color
var color_conflict : Color
var color_same_number : Color
var color_highlight : Color
var color_cell_default : Color
var color_text_initial : Color
var color_text_player : Color
var color_text_hint : Color
var color_text_wrong : Color
var color_note_text : Color
var color_notes_active : Color
var color_bg : Color
var color_border : Color
var color_top_bar_text : Color
var color_numpad_bg : Color
var color_numpad_pressed : Color
var color_numpad_text : Color
var color_btn_border : Color
var color_overlay : Color
var color_overlay_solid : Color
var color_overlay_btn_bg : Color
var color_overlay_btn_text : Color
var color_overlay_btn_pressed : Color
var color_overlay_label : Color
var color_tutorial_focus : Color
var color_tutorial_related : Color
var color_tutorial_eliminated : Color

func set_dark_mode(value: bool) -> void:
	dark_mode = value
	update_colors()
	_cell_style_cache.clear()

func update_colors() -> void:
	if dark_mode:
		color_bg = Color(0.11, 0.12, 0.16)
		color_selected = Color(0.22, 0.38, 0.56)
		color_conflict = Color(0.45, 0.18, 0.2)
		color_same_number = Color(0.28, 0.3, 0.2)
		color_highlight = Color(0.14, 0.16, 0.21)
		color_cell_default = Color(0.16, 0.17, 0.22)
		color_text_initial = Color(0.88, 0.9, 0.92)
		color_text_player = Color(0.45, 0.72, 0.95)
		color_text_hint = Color(0.45, 0.78, 0.55)
		color_text_wrong = Color(0.92, 0.38, 0.38)
		color_note_text = Color(0.48, 0.5, 0.55)
		color_notes_active = Color(0.22, 0.34, 0.5)
		color_border = Color(0.3, 0.32, 0.38)
		color_top_bar_text = Color(0.85, 0.87, 0.9)
		color_numpad_bg = Color(0.18, 0.19, 0.24)
		color_numpad_pressed = Color(0.25, 0.27, 0.33)
		color_numpad_text = Color(0.88, 0.9, 0.92)
		color_btn_border = Color(0.28, 0.3, 0.36)
		color_overlay = Color(0.05, 0.06, 0.08, 0.75)
		color_overlay_solid = Color(0.11, 0.12, 0.16, 1.0)
		color_overlay_btn_bg = Color(0.92, 0.93, 0.96)
		color_overlay_btn_text = Color(0.1, 0.1, 0.14)
		color_overlay_btn_pressed = Color(0.78, 0.8, 0.84)
		color_overlay_label = Color(0.88, 0.9, 0.92)
		color_tutorial_focus = Color(0.2, 0.45, 0.35)
		color_tutorial_related = Color(0.2, 0.25, 0.35)
		color_tutorial_eliminated = Color(0.4, 0.2, 0.2)
	else:
		color_bg = Color(0.94, 0.95, 0.97)
		color_selected = Color(0.8, 0.9, 0.98)
		color_conflict = Color(0.96, 0.85, 0.85)
		color_same_number = Color(0.9, 0.92, 0.82)
		color_highlight = Color(0.91, 0.93, 0.97)
		color_cell_default = Color(0.99, 0.99, 1.0)
		color_text_initial = Color(0.18, 0.2, 0.25)
		color_text_player = Color(0.24, 0.48, 0.82)
		color_text_hint = Color(0.3, 0.6, 0.42)
		color_text_wrong = Color(0.82, 0.28, 0.28)
		color_note_text = Color(0.52, 0.55, 0.6)
		color_notes_active = Color(0.78, 0.87, 0.98)
		color_border = Color(0.72, 0.74, 0.78)
		color_top_bar_text = Color(0.22, 0.24, 0.28)
		color_numpad_bg = Color(0.99, 0.99, 1.0)
		color_numpad_pressed = Color(0.9, 0.91, 0.94)
		color_numpad_text = Color(0.18, 0.2, 0.25)
		color_btn_border = Color(0.78, 0.8, 0.84)
		color_overlay = Color(0.94, 0.95, 0.97, 0.88)
		color_overlay_solid = Color(0.94, 0.95, 0.97, 1.0)
		color_overlay_btn_bg = Color(0.2, 0.22, 0.28)
		color_overlay_btn_text = Color(0.95, 0.96, 0.98)
		color_overlay_btn_pressed = Color(0.32, 0.34, 0.4)
		color_overlay_label = Color(0.18, 0.2, 0.25)
		color_tutorial_focus = Color(0.72, 0.92, 0.78)
		color_tutorial_related = Color(0.85, 0.9, 0.97)
		color_tutorial_eliminated = Color(0.95, 0.85, 0.85)

func apply_button_styles(btn: Button, normal: StyleBox, pressed: StyleBox = null) -> void:
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", normal)
	btn.add_theme_stylebox_override("disabled", normal)
	btn.add_theme_stylebox_override("pressed", pressed if pressed else normal)

func get_cell_style(row: int, col: int, state: StringName) -> StyleBoxFlat:
	var in_box_r := row % SudokuSolver.BOX_SIZE
	var in_box_c := col % SudokuSolver.BOX_SIZE
	var key := Vector3i(in_box_r, in_box_c, state.hash())
	if _cell_style_cache.has(key):
		return _cell_style_cache[key]
	var style := _build_cell_style(in_box_r, in_box_c, state)
	_cell_style_cache[key] = style
	return style

func _build_cell_style(in_box_r: int, in_box_c: int, state: StringName) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()

	match state:
		&"selected":
			style.bg_color = color_selected
		&"conflict":
			style.bg_color = color_conflict
		&"same_number":
			style.bg_color = color_same_number
		&"highlight":
			style.bg_color = color_highlight
		&"default":
			style.bg_color = color_cell_default
		&"selected_pressed":
			style.bg_color = _pressed_color(color_selected)
		&"conflict_pressed":
			style.bg_color = _pressed_color(color_conflict)
		&"same_number_pressed":
			style.bg_color = _pressed_color(color_same_number)
		&"highlight_pressed":
			style.bg_color = _pressed_color(color_highlight)
		&"default_pressed":
			style.bg_color = _pressed_color(color_cell_default)

	var last_in_box := SudokuSolver.BOX_SIZE - 1
	style.corner_radius_top_left = CORNER_RADIUS_CELL if in_box_r == 0 and in_box_c == 0 else 0
	style.corner_radius_top_right = CORNER_RADIUS_CELL if in_box_r == 0 and in_box_c == last_in_box else 0
	style.corner_radius_bottom_left = CORNER_RADIUS_CELL if in_box_r == last_in_box and in_box_c == 0 else 0
	style.corner_radius_bottom_right = CORNER_RADIUS_CELL if in_box_r == last_in_box and in_box_c == last_in_box else 0

	return style

func _pressed_color(base: Color) -> Color:
	if dark_mode:
		return base.lightened(0.15)
	return base.darkened(0.1)

func flash_color() -> Color:
	if dark_mode:
		return Color(1.4, 1.4, 1.4)
	return Color(0.82, 0.88, 1.0)

func create_numpad_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color_numpad_bg
	style.border_color = color_btn_border
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = CORNER_RADIUS_BTN
	style.corner_radius_top_right = CORNER_RADIUS_BTN
	style.corner_radius_bottom_left = CORNER_RADIUS_BTN
	style.corner_radius_bottom_right = CORNER_RADIUS_BTN
	return style

func apply_numpad_theme(btn: Button) -> void:
	btn.add_theme_color_override("font_color", color_numpad_text)
	btn.add_theme_color_override("font_pressed_color", color_numpad_text)
	btn.add_theme_color_override("font_focus_color", color_numpad_text)
	btn.add_theme_color_override("font_hover_color", color_numpad_text)
	var style = create_numpad_style()
	var pressed = style.duplicate()
	pressed.bg_color = color_numpad_pressed
	apply_button_styles(btn, style, pressed)

func apply_toolbar_button_theme(btn: Button) -> void:
	btn.add_theme_color_override("font_color", color_top_bar_text)
	btn.add_theme_color_override("font_pressed_color", color_top_bar_text)
	btn.add_theme_color_override("font_hover_color", color_top_bar_text)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = color_top_bar_text
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = CORNER_RADIUS_BTN
	style.corner_radius_top_right = CORNER_RADIUS_BTN
	style.corner_radius_bottom_left = CORNER_RADIUS_BTN
	style.corner_radius_bottom_right = CORNER_RADIUS_BTN
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	var pressed = style.duplicate()
	pressed.bg_color = Color(color_top_bar_text, 0.15)
	apply_button_styles(btn, style, pressed)

func theme_overlay_children(node: Node) -> void:
	for child in node.get_children():
		if child is Label:
			child.add_theme_color_override("font_color", color_overlay_label)
		elif child is Button:
			if child.get_meta("is_close_btn", false):
				child.add_theme_color_override("font_color", color_overlay_label)
				child.add_theme_color_override("font_pressed_color", Color(color_overlay_label, 0.5))
				child.add_theme_color_override("font_hover_color", color_overlay_label)
			else:
				child.add_theme_color_override("font_color", color_overlay_btn_text)
				child.add_theme_color_override("font_pressed_color", color_overlay_btn_text)
				child.add_theme_color_override("font_hover_color", color_overlay_btn_text)
				var btn_style = StyleBoxFlat.new()
				btn_style.bg_color = color_overlay_btn_bg
				btn_style.corner_radius_top_left = CORNER_RADIUS_OVERLAY
				btn_style.corner_radius_top_right = CORNER_RADIUS_OVERLAY
				btn_style.corner_radius_bottom_left = CORNER_RADIUS_OVERLAY
				btn_style.corner_radius_bottom_right = CORNER_RADIUS_OVERLAY
				var pressed_style = btn_style.duplicate()
				pressed_style.bg_color = color_overlay_btn_pressed
				apply_button_styles(child, btn_style, pressed_style)
		if child.get_child_count() > 0:
			theme_overlay_children(child)
