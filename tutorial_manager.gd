class_name TutorialManager
extends RefCounted

var g
var is_active := false
var current_lesson: Dictionary
var current_step_idx := 0

var tutorial_overlay: ColorRect
var instruction_panel: PanelContainer
var instruction_label: Label
var step_label: Label
var next_btn: Button
var exit_btn: Button


func setup(host) -> void:
	g = host


func create_all() -> void:
	_create_tutorial_overlay()
	_create_instruction_panel()


func _create_tutorial_overlay() -> void:
	tutorial_overlay = ColorRect.new()
	tutorial_overlay.color = Color(0, 0, 0, 1.0)
	tutorial_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	tutorial_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	tutorial_overlay.visible = false
	g.add_child(tutorial_overlay)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 60)
	margin.add_theme_constant_override("margin_bottom", 20)
	tutorial_overlay.add_child(margin)

	var outer_vbox := VBoxContainer.new()
	outer_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer_vbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	outer_vbox.add_theme_constant_override("separation", 8)
	margin.add_child(outer_vbox)

	var title := UIFactory.create_overlay_label("Learn", 52)
	outer_vbox.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer_vbox.add_child(scroll)

	var scroll_vbox := VBoxContainer.new()
	scroll_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_vbox.add_theme_constant_override("separation", 12)
	scroll.add_child(scroll_vbox)

	var categories := [
		{"name": "Beginner", "range": [0, 3]},
		{"name": "Intermediate", "range": [3, 7]},
		{"name": "Advanced", "range": [7, 11]},
	]

	var lessons = TutorialData.get_lesson_info()
	for cat in categories:
		var from: int = cat.range[0]
		var to: int = cat.range[1]
		if from >= lessons.size():
			break

		var header := Label.new()
		header.text = cat.name
		header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		header.add_theme_font_size_override("font_size", 26)
		header.add_theme_color_override("font_color", Color(0.9, 0.75, 0.2))
		scroll_vbox.add_child(header)

		var end := mini(to, lessons.size())
		for i in range(from, end):
			var info = lessons[i]

			var entry := VBoxContainer.new()
			entry.alignment = BoxContainer.ALIGNMENT_CENTER
			entry.add_theme_constant_override("separation", 2)

			var btn = UIFactory.create_overlay_button(info.title, start_lesson.bind(i))
			btn.custom_minimum_size = Vector2(340, 64)
			btn.add_theme_font_size_override("font_size", 28)
			entry.add_child(btn)

			var sub := Label.new()
			sub.text = info.subtitle
			sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			sub.add_theme_font_size_override("font_size", 20)
			entry.add_child(sub)

			scroll_vbox.add_child(entry)

	tutorial_overlay.add_child(UIFactory.create_close_button(_on_overlay_close))


func _create_instruction_panel() -> void:
	instruction_panel = PanelContainer.new()
	instruction_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	instruction_panel.visible = false

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = g.theme_mgr.color_numpad_bg
	panel_style.border_color = g.theme_mgr.color_btn_border
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(12)
	panel_style.content_margin_left = 20
	panel_style.content_margin_right = 20
	panel_style.content_margin_top = 16
	panel_style.content_margin_bottom = 16
	instruction_panel.add_theme_stylebox_override("panel", panel_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	instruction_panel.add_child(vbox)

	instruction_label = Label.new()
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instruction_label.add_theme_font_size_override("font_size", 22)
	instruction_label.add_theme_color_override("font_color", g.theme_mgr.color_numpad_text)
	vbox.add_child(instruction_label)

	var bottom_row := HBoxContainer.new()
	bottom_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_row.add_theme_constant_override("separation", 12)

	step_label = Label.new()
	step_label.add_theme_font_size_override("font_size", 18)
	step_label.add_theme_color_override("font_color", g.theme_mgr.color_note_text)
	bottom_row.add_child(step_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_row.add_child(spacer)

	exit_btn = Button.new()
	exit_btn.text = "Exit"
	exit_btn.custom_minimum_size = Vector2(70, 44)
	exit_btn.focus_mode = Control.FOCUS_NONE
	exit_btn.add_theme_font_size_override("font_size", 20)
	exit_btn.pressed.connect(end_tutorial)
	g.theme_mgr.apply_numpad_theme(exit_btn)
	bottom_row.add_child(exit_btn)

	next_btn = Button.new()
	next_btn.text = "Next"
	next_btn.custom_minimum_size = Vector2(100, 44)
	next_btn.focus_mode = Control.FOCUS_NONE
	next_btn.add_theme_font_size_override("font_size", 22)
	next_btn.pressed.connect(_on_next_pressed)
	g.theme_mgr.apply_numpad_theme(next_btn)
	bottom_row.add_child(next_btn)

	vbox.add_child(bottom_row)

	var parent = g.board_wrapper.get_parent()
	parent.add_child(instruction_panel)
	parent.move_child(instruction_panel, g.board_wrapper.get_index() + 1)


func apply_theme() -> void:
	if tutorial_overlay:
		tutorial_overlay.color = g.theme_mgr.color_overlay_solid
		g.theme_mgr.theme_overlay_children(tutorial_overlay)

	if instruction_panel:
		var panel_style: StyleBoxFlat = instruction_panel.get_theme_stylebox("panel")
		panel_style.bg_color = g.theme_mgr.color_numpad_bg
		panel_style.border_color = g.theme_mgr.color_btn_border
		instruction_label.add_theme_color_override("font_color", g.theme_mgr.color_numpad_text)
		step_label.add_theme_color_override("font_color", g.theme_mgr.color_note_text)
		g.theme_mgr.apply_numpad_theme(next_btn)
		g.theme_mgr.apply_numpad_theme(exit_btn)

	if is_active:
		_apply_highlights()


# --- Lesson Flow ---

func start_lesson(index: int) -> void:
	current_lesson = TutorialData.get_lesson(index)
	current_step_idx = 0
	is_active = true

	tutorial_overlay.visible = false
	g.game_container.visible = true

	g.solution_board = current_lesson.solution.duplicate(true)
	g.player_board = current_lesson.player.duplicate(true)
	g.initial_board = current_lesson.player.duplicate(true)

	g._reset_game_state()
	g.update_ui()

	var init_notes: Dictionary = current_lesson.get("initial_notes", {})
	for cell in init_notes:
		g.actions.notes[cell.x][cell.y] = init_notes[cell]
		g.actions.update_note_display(cell.x, cell.y)

	g.difficulty_label.text = current_lesson.title
	g.timer_label.visible = false
	g.mistakes_label.visible = false
	g.pause_button.visible = false
	g.settings_button.visible = false
	g.board_pad_spacer.visible = false
	g.pad_action_spacer.visible = false
	g.action_buttons.visible = false
	g.number_pad.visible = false

	instruction_panel.visible = true
	_show_step()


func _show_step() -> void:
	var steps: Array = current_lesson.steps
	var step: Dictionary = steps[current_step_idx]

	instruction_label.text = step.text
	step_label.text = "Step %d/%d" % [current_step_idx + 1, steps.size()]

	var note_updates: Dictionary = step.get("set_notes", {})
	for cell in note_updates:
		g.actions.notes[cell.x][cell.y] = note_updates[cell]
		g.actions.update_note_display(cell.x, cell.y)

	var action: String = step.get("action", "next")
	var is_last := current_step_idx == steps.size() - 1

	match action:
		"next":
			next_btn.visible = true
			next_btn.text = "Complete" if is_last else "Next"
			g.number_pad.visible = false
		"tap_cell":
			next_btn.visible = false
			g.number_pad.visible = false
		"place_number":
			next_btn.visible = false
			g.number_pad.visible = true
			var target_num: int = step.get("number", 0)
			for i in range(1, 10):
				g.number_buttons[i].disabled = (i != target_num)

	_apply_highlights()


func _apply_highlights() -> void:
	var steps: Array = current_lesson.steps
	var step: Dictionary = steps[current_step_idx]
	var highlights: Dictionary = step.get("highlights", {})

	for r in range(SudokuSolver.SIZE):
		for c in range(SudokuSolver.SIZE):
			g.theme_mgr.apply_button_styles(
				g.buttons[r][c],
				g.theme_mgr.get_cell_style(r, c, &"default"),
				g.theme_mgr.get_cell_style(r, c, &"default_pressed")
			)

	for cell in highlights:
		var btn: Button = g.buttons[cell.x][cell.y]
		var type: String = highlights[cell]
		var color: Color
		match type:
			"focus":
				color = g.theme_mgr.color_tutorial_focus
			"related":
				color = g.theme_mgr.color_tutorial_related
			"eliminated":
				color = g.theme_mgr.color_tutorial_eliminated
			_:
				continue
		var style: StyleBoxFlat = g.theme_mgr.get_cell_style(cell.x, cell.y, &"default").duplicate()
		style.bg_color = color
		var pressed_style := style.duplicate()
		pressed_style.bg_color = g.theme_mgr._pressed_color(color)
		g.theme_mgr.apply_button_styles(btn, style, pressed_style)


func _on_next_pressed() -> void:
	_advance()


func _advance() -> void:
	current_step_idx += 1
	var steps: Array = current_lesson.steps
	if current_step_idx >= steps.size():
		end_tutorial()
	else:
		_show_step()


# --- User Interaction ---

func on_cell_pressed(btn: Button) -> void:
	var steps: Array = current_lesson.steps
	var step: Dictionary = steps[current_step_idx]
	if step.get("action") != "tap_cell":
		return

	var target: Vector2i = step.get("target", Vector2i(-1, -1))
	var r: int = btn.get_meta("row")
	var c: int = btn.get_meta("col")

	if Vector2i(r, c) == target:
		g.selected_button = btn
		_advance()


func on_number_pressed(number: int) -> void:
	var steps: Array = current_lesson.steps
	var step: Dictionary = steps[current_step_idx]
	if step.get("action") != "place_number":
		return

	var target_num: int = step.get("number", 0)
	if number != target_num:
		return

	var target: Vector2i = step.get("target", Vector2i(-1, -1))
	var r := target.x
	var c := target.y

	g.player_board[r][c] = number
	var btn: Button = g.buttons[r][c]
	btn.text = str(number)
	btn.set_meta("is_locked", true)
	g._apply_cell_color(btn, "player")
	g.animator.animate_pop(btn, g.theme_mgr.flash_color())

	_advance()


# --- Exit ---

func end_tutorial() -> void:
	is_active = false
	g.selected_button = null

	g.game_container.visible = false
	g.timer_label.visible = true
	g.mistakes_label.visible = true
	g.pause_button.visible = true
	g.board_pad_spacer.visible = true
	g.pad_action_spacer.visible = true
	g.action_buttons.visible = true
	g.number_pad.visible = true
	instruction_panel.visible = false

	for i in range(1, 10):
		g.number_buttons[i].disabled = false

	tutorial_overlay.visible = true


func _on_overlay_close() -> void:
	tutorial_overlay.visible = false
	g.settings_button.visible = true
	g.overlay_mgr.difficulty_overlay.visible = true
