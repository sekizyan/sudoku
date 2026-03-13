extends Control

const BUTTON_SIZE := 64
const FONT_SIZE := 32
const NOTE_FONT_SIZE := 14
const DIFFICULTIES := {
	"Easy": 30,
	"Medium": 40,
	"Hard": 50,
	"Expert": 58,
}
const LIFE_LIMIT := 3
const HINT_LIMIT := 3

const CORNER_RADIUS_BOARD := 8
const CORNER_RADIUS_TOGGLE := 21

const FONT_SIZE_TOP_BAR := 28
const FONT_SIZE_OVERLAY_TITLE := 72
const FONT_SIZE_OVERLAY_BTN := 36
const FONT_SIZE_SETTINGS_LABEL := 36
const FONT_SIZE_STATS_TITLE := 28
const FONT_SIZE_STATS_DETAIL := 22

const TOGGLE_TRACK_W := 81
const TOGGLE_TRACK_H := 41
const TOGGLE_KNOB_SIZE := 31
const TOGGLE_KNOB_MARGIN := 5

const BOARD_BORDER_WIDTH := 2
const BOX_GAP := 3
const CELL_GAP := 1

const UNDO_LIMIT := 100

var theme_mgr := ThemeManager.new()
var save_mgr: SaveManager
var stats_mgr := StatsManager.new()
var animator := BoardAnimator.new()

var solver := SudokuSolver.new()
var solution_board: Array = []
var player_board: Array = []
var initial_board: Array = []

var selected_button : Button = null
var buttons: Array[Array] = []
var number_buttons : Dictionary = {}
var win_overlay : ColorRect
var win_content : VBoxContainer
var win_time_label : Label
var win_mistakes_label : Label
var win_best_label : Label
var lose_overlay : ColorRect
var pause_overlay : ColorRect
var settings_overlay : ColorRect
var stats_overlay : ColorRect
var stats_container : VBoxContainer
var difficulty_overlay : ColorRect
var continue_btn : Button
var notes_mode := false
var notes_toggle_btn : Button
var hint_btn : Button
var hints_used := 0
var bonus_hints := 0
var undo_btn : Button
var auto_notes_btn : Button
var undo_stack: Array[Dictionary] = []
var notes: Array = []
var note_labels: Array[Array] = []
var timer_running := false
var timer_started := false
var elapsed_time := 0.0
var mistakes := 0
var current_difficulty := ""
var theme_toggle_track : Panel
var theme_toggle_knob : Panel
var bg_rect : ColorRect
var board_wrapper : PanelContainer
var box_grids: Array[GridContainer] = []
var font_regular : Font
var font_semibold : Font
var remaining_cells: int = 0
var _last_board_width := 0.0
var is_daily_game := false
var daily_btn : Button
var daily_streak_label : Label
var win_streak_label : Label
var win_best_streak_label : Label

@onready var game_container = $MarginContainer
@onready var difficulty_label = $MarginContainer/VBoxContainer/TopBar/DifficultyLabel
@onready var timer_label = $MarginContainer/VBoxContainer/TopBar/TimerLabel
@onready var mistakes_label = $MarginContainer/VBoxContainer/TopBar/MistakesLabel
@onready var pause_button = $MarginContainer/VBoxContainer/TopBar/PauseButton
@onready var settings_button = $SettingsButton
@onready var board = $MarginContainer/VBoxContainer/Board
@onready var number_pad = $MarginContainer/VBoxContainer/NumberPad
@onready var action_buttons = $MarginContainer/VBoxContainer/ActionButtons


func _ready() -> void:
	_setup_fonts()

	stats_mgr.setup(DIFFICULTIES.keys())
	stats_mgr.load_stats()

	theme_mgr.set_dark_mode(stats_mgr.get_dark_mode())

	animator.setup(self)

	bg_rect = ColorRect.new()
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_rect.color = theme_mgr.color_bg
	add_child(bg_rect)
	move_child(bg_rect, 0)

	create_board_ui()
	create_number_pad()
	create_win_overlay()
	create_lose_overlay()
	create_pause_overlay()
	create_difficulty_overlay()
	create_settings_overlay()
	create_stats_overlay()

	UIFactory.apply_pause_button_style(pause_button)
	pause_button.pressed.connect(_on_pause_pressed)
	UIFactory.apply_pause_button_style(settings_button)
	settings_button.add_theme_font_size_override("font_size", 34)
	settings_button.custom_minimum_size = Vector2(62, 62)
	settings_button.pressed.connect(_on_settings_pressed)
	move_child(settings_button, -1)

	_setup_top_bar_labels()
	board_wrapper.resized.connect(_on_board_resized)
	number_pad.resized.connect(_on_number_pad_resized)
	action_buttons.resized.connect(_on_action_buttons_resized)

	save_mgr = SaveManager.new()
	add_child(save_mgr)
	save_mgr.set_data_provider(_build_save_data)

	_update_toggle_visual()
	_apply_theme()

	game_container.visible = false
	difficulty_overlay.visible = true
	_update_continue_button()
	_update_daily_button()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if game_container.visible and not win_overlay.visible and not lose_overlay.visible:
			save_mgr.save_immediate()


# --- Theme ---

func _setup_fonts() -> void:
	font_semibold = load("res://fonts/Inter/static/Inter_24pt-SemiBold.ttf")
	font_regular = load("res://fonts/Inter/static/Inter_24pt-Regular.ttf")
	var game_theme := Theme.new()
	game_theme.set_default_font(font_semibold)
	theme = game_theme

func _apply_theme() -> void:
	bg_rect.color = theme_mgr.color_bg

	var wrapper_style : StyleBoxFlat = board_wrapper.get_theme_stylebox("panel")
	wrapper_style.bg_color = theme_mgr.color_border

	for label in [difficulty_label, timer_label, mistakes_label]:
		label.add_theme_color_override("font_color", theme_mgr.color_top_bar_text)

	theme_mgr.apply_toolbar_button_theme(pause_button)
	theme_mgr.apply_toolbar_button_theme(settings_button)

	for r in range(SudokuSolver.SIZE):
		for c in range(SudokuSolver.SIZE):
			var btn = buttons[r][c]
			var origin = btn.get_meta("origin", "")
			_apply_cell_color(btn, origin)
			for lbl in note_labels[r][c]["labels"]:
				lbl.add_theme_color_override("font_color", theme_mgr.color_note_text)

	if selected_button != null:
		refresh_board_styles()
	else:
		for r in range(SudokuSolver.SIZE):
			for c in range(SudokuSolver.SIZE):
				theme_mgr.apply_button_styles(buttons[r][c], theme_mgr.get_cell_style(r, c, &"default"), theme_mgr.get_cell_style(r, c, &"default_pressed"))

	for i in range(1, 10):
		theme_mgr.apply_numpad_theme(number_buttons[i])
	for child in action_buttons.get_children():
		theme_mgr.apply_numpad_theme(child)

	if notes_mode:
		var style := theme_mgr.create_numpad_style()
		style.bg_color = theme_mgr.color_notes_active
		theme_mgr.apply_button_styles(notes_toggle_btn, style)

	win_overlay.color = theme_mgr.color_overlay
	lose_overlay.color = theme_mgr.color_overlay
	pause_overlay.color = theme_mgr.color_overlay
	settings_overlay.color = theme_mgr.color_overlay_solid
	stats_overlay.color = theme_mgr.color_overlay_solid
	difficulty_overlay.color = theme_mgr.color_overlay_solid

	for overlay in [win_overlay, lose_overlay, pause_overlay, settings_overlay, stats_overlay, difficulty_overlay]:
		theme_mgr.theme_overlay_children(overlay)

	_update_daily_button()


# --- Helpers ---

func _has_note(r: int, c: int, n: int) -> bool:
	return (notes[r][c] & (1 << n)) != 0

func _set_note(r: int, c: int, n: int) -> void:
	notes[r][c] |= (1 << n)

func _clear_note(r: int, c: int, n: int) -> void:
	notes[r][c] &= ~(1 << n)

func _toggle_note(r: int, c: int, n: int) -> void:
	notes[r][c] ^= (1 << n)

func _clear_all_notes(r: int, c: int) -> void:
	notes[r][c] = 0

func _get_note_list(r: int, c: int) -> Array[int]:
	var result: Array[int] = []
	for n in range(1, 10):
		if _has_note(r, c, n):
			result.append(n)
	return result

func _reset_game_state() -> void:
	elapsed_time = 0.0
	timer_running = false
	timer_started = false
	timer_label.text = "Time: 00:00"
	mistakes = 0
	mistakes_label.text = "Mistakes: 0/%d" % LIFE_LIMIT
	selected_button = null
	for r in range(SudokuSolver.SIZE):
		for c in range(SudokuSolver.SIZE):
			theme_mgr.apply_button_styles(buttons[r][c], theme_mgr.get_cell_style(r, c, &"default"), theme_mgr.get_cell_style(r, c, &"default_pressed"))
	notes_mode = false
	var style := theme_mgr.create_numpad_style()
	theme_mgr.apply_button_styles(notes_toggle_btn, style)
	hints_used = 0
	bonus_hints = 0
	_update_hint_button()
	undo_stack.clear()
	undo_btn.disabled = true
	notes = []
	for r in range(SudokuSolver.SIZE):
		notes.append([])
		for c in range(SudokuSolver.SIZE):
			notes[r].append(0)

func _get_today_date_str() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [d.year, d.month, d.day]

func _get_yesterday_date_str() -> String:
	var d := Time.get_date_dict_from_system()
	var year := int(d.year)
	var month := int(d.month)
	var day := int(d.day) - 1
	if day < 1:
		month -= 1
		if month < 1:
			month = 12
			year -= 1
		day = _days_in_month(year, month)
	return "%04d-%02d-%02d" % [year, month, day]

func _days_in_month(year: int, month: int) -> int:
	match month:
		1, 3, 5, 7, 8, 10, 12: return 31
		4, 6, 9, 11: return 30
		2: return 29 if (year % 4 == 0 and (year % 100 != 0 or year % 400 == 0)) else 28
	return 30

func _get_daily_info() -> Dictionary:
	var d := Time.get_date_dict_from_system()
	var seed_val := d.year * 10000 + d.month * 100 + d.day
	var keys := DIFFICULTIES.keys()
	var idx := int(d.day) % keys.size()
	var diff_name : String = keys[idx]
	return {"seed": seed_val, "difficulty": diff_name, "remove_count": DIFFICULTIES[diff_name]}

func _go_to_difficulty(overlay: ColorRect) -> void:
	overlay.visible = false
	game_container.visible = false
	difficulty_overlay.visible = true
	save_mgr.clear()
	_update_continue_button()
	_update_daily_button()

func _apply_cell_color(btn: Button, origin: String) -> void:
	var color : Color
	match origin:
		"initial":
			color = theme_mgr.color_text_initial
		"player":
			color = theme_mgr.color_text_player
		"hint":
			color = theme_mgr.color_text_hint
		"wrong":
			color = theme_mgr.color_text_wrong
		_:
			color = theme_mgr.color_text_initial
	btn.add_theme_color_override("font_color", color)
	btn.add_theme_color_override("font_pressed_color", color)
	btn.add_theme_color_override("font_hover_color", color)
	btn.add_theme_color_override("font_disabled_color", color)
	btn.add_theme_color_override("font_focus_color", color)
	btn.modulate = Color.WHITE
	btn.set_meta("origin", origin)

func _setup_top_bar_labels() -> void:
	for label in [difficulty_label, timer_label, mistakes_label]:
		label.add_theme_font_size_override("font_size", FONT_SIZE_TOP_BAR)

func _on_board_resized() -> void:
	if is_equal_approx(board_wrapper.size.x, _last_board_width):
		return
	_last_board_width = board_wrapper.size.x
	board_wrapper.custom_minimum_size = Vector2(board_wrapper.size.x, board_wrapper.size.x)
	var total_gap := BOARD_BORDER_WIDTH * 2 + BOX_GAP * 2 + CELL_GAP * 6
	var cell_size := (board_wrapper.size.x - total_gap) / float(SudokuSolver.SIZE)
	var font_size : int = max(1, int(cell_size / 2.5))
	var note_size : int = max(1, int(cell_size / 5.0))
	for r in range(SudokuSolver.SIZE):
		for c in range(SudokuSolver.SIZE):
			buttons[r][c].add_theme_font_size_override("font_size", font_size)
			for lbl in note_labels[r][c]["labels"]:
				lbl.add_theme_font_size_override("font_size", note_size)

func _on_number_pad_resized() -> void:
	var btn_width : float = number_pad.size.x / number_pad.columns
	for i in range(1, 10):
		number_buttons[i].custom_minimum_size.y = btn_width

func _on_action_buttons_resized() -> void:
	var btn_width : float = action_buttons.size.x / action_buttons.columns
	var btn_height : float = btn_width / 2.0
	for child in action_buttons.get_children():
		child.custom_minimum_size.y = btn_height

func _create_action_button(text: String, callback: Callable, disabled := false) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", FONT_SIZE)
	theme_mgr.apply_numpad_theme(btn)
	btn.disabled = disabled
	btn.pressed.connect(callback)
	action_buttons.add_child(btn)
	return btn


# --- Save / Load ---

func _build_save_data() -> Dictionary:
	var origins := []
	for r in range(SudokuSolver.SIZE):
		origins.append([])
		for c in range(SudokuSolver.SIZE):
			origins[r].append(buttons[r][c].get_meta("origin", ""))

	return {
		"solution_board": solution_board,
		"player_board": player_board,
		"initial_board": initial_board,
		"notes": notes,
		"elapsed_time": elapsed_time,
		"mistakes": mistakes,
		"hints_used": hints_used,
		"notes_mode": notes_mode,
		"difficulty_text": difficulty_label.text,
		"current_difficulty": current_difficulty,
		"origins": origins,
		"timer_started": timer_started,
		"is_daily": is_daily_game,
		"daily_date": _get_today_date_str() if is_daily_game else "",
	}

func _load_game() -> bool:
	var data = save_mgr.load_data()
	if data == null:
		return false

	is_daily_game = data.get("is_daily", false)
	if is_daily_game and data.get("daily_date", "") != _get_today_date_str():
		save_mgr.clear()
		is_daily_game = false
		return false

	solution_board = SaveManager.to_int_board(data["solution_board"])
	player_board = SaveManager.to_int_board(data["player_board"])
	initial_board = SaveManager.to_int_board(data["initial_board"])
	notes = SaveManager.to_int_board(data["notes"])
	elapsed_time = float(data["elapsed_time"])
	mistakes = int(data["mistakes"])
	hints_used = int(data["hints_used"])
	notes_mode = data.get("notes_mode", false)
	timer_started = data.get("timer_started", false)
	current_difficulty = data.get("current_difficulty", "")

	difficulty_label.text = data["difficulty_text"]
	mistakes_label.text = "Mistakes: %d/%d" % [mistakes, LIFE_LIMIT]
	timer_label.text = format_time(elapsed_time)
	bonus_hints = 0
	_update_hint_button()
	undo_stack.clear()
	undo_btn.disabled = true

	if notes_mode:
		var style := theme_mgr.create_numpad_style()
		style.bg_color = theme_mgr.color_notes_active
		theme_mgr.apply_button_styles(notes_toggle_btn, style)

	var origins = data.get("origins", [])
	for r in range(SudokuSolver.SIZE):
		for c in range(SudokuSolver.SIZE):
			var value = player_board[r][c]
			var btn = buttons[r][c]
			var origin := ""
			if r < origins.size() and c < origins[r].size():
				origin = origins[r][c]

			if value == 0:
				btn.text = ""
				btn.set_meta("is_locked", false)
			else:
				btn.text = str(value)
				btn.set_meta("is_locked", origin in ["initial", "player", "hint"])

			_apply_cell_color(btn, origin)
			update_note_display(r, c)

	update_number_pad()

	remaining_cells = 0
	for r in range(SudokuSolver.SIZE):
		for c in range(SudokuSolver.SIZE):
			if player_board[r][c] != solution_board[r][c]:
				remaining_cells += 1

	if timer_started:
		timer_running = true

	return true


# --- Board UI ---

func create_board_ui() -> void:
	board_wrapper = PanelContainer.new()
	board_wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var wrapper_style := StyleBoxFlat.new()
	wrapper_style.bg_color = theme_mgr.color_border
	wrapper_style.corner_radius_top_left = CORNER_RADIUS_BOARD
	wrapper_style.corner_radius_top_right = CORNER_RADIUS_BOARD
	wrapper_style.corner_radius_bottom_left = CORNER_RADIUS_BOARD
	wrapper_style.corner_radius_bottom_right = CORNER_RADIUS_BOARD
	wrapper_style.content_margin_left = BOARD_BORDER_WIDTH
	wrapper_style.content_margin_right = BOARD_BORDER_WIDTH
	wrapper_style.content_margin_top = BOARD_BORDER_WIDTH
	wrapper_style.content_margin_bottom = BOARD_BORDER_WIDTH
	board_wrapper.add_theme_stylebox_override("panel", wrapper_style)

	var parent := board.get_parent()
	var idx := board.get_index()
	parent.remove_child(board)
	parent.add_child(board_wrapper)
	parent.move_child(board_wrapper, idx)
	board_wrapper.add_child(board)

	board.columns = SudokuSolver.BOX_SIZE
	board.add_theme_constant_override("h_separation", BOX_GAP)
	board.add_theme_constant_override("v_separation", BOX_GAP)
	board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL

	for box_idx in range(SudokuSolver.SIZE):
		var box_grid := GridContainer.new()
		box_grid.columns = SudokuSolver.BOX_SIZE
		box_grid.add_theme_constant_override("h_separation", CELL_GAP)
		box_grid.add_theme_constant_override("v_separation", CELL_GAP)
		box_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
		board.add_child(box_grid)
		box_grids.append(box_grid)

	for r in range(SudokuSolver.SIZE):
		buttons.append([])
		note_labels.append([])
		for c in range(SudokuSolver.SIZE):
			var btn := Button.new()
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
			btn.clip_contents = true
			btn.focus_mode = Control.FOCUS_NONE
			btn.add_theme_font_size_override("font_size", FONT_SIZE)

			btn.set_meta("row", r)
			btn.set_meta("col", c)

			btn.pressed.connect(_on_cell_pressed.bind(btn))

			theme_mgr.apply_button_styles(btn, theme_mgr.get_cell_style(r, c, &"default"), theme_mgr.get_cell_style(r, c, &"default_pressed"))

			var note_grid := GridContainer.new()
			note_grid.columns = 3
			note_grid.anchor_left = 0
			note_grid.anchor_top = 0
			note_grid.anchor_right = 1
			note_grid.anchor_bottom = 1
			note_grid.offset_left = 2
			note_grid.offset_top = 1
			note_grid.offset_right = -2
			note_grid.offset_bottom = -1
			note_grid.add_theme_constant_override("h_separation", 0)
			note_grid.add_theme_constant_override("v_separation", 0)
			note_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
			note_grid.visible = false

			var cell_labels := []
			for n in range(1, 10):
				var lbl := Label.new()
				lbl.text = ""
				lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
				lbl.add_theme_font_size_override("font_size", NOTE_FONT_SIZE)
				lbl.add_theme_font_override("font", font_regular)
				lbl.add_theme_color_override("font_color", theme_mgr.color_note_text)
				lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
				note_grid.add_child(lbl)
				cell_labels.append(lbl)

			btn.add_child(note_grid)

			var box_r := r / SudokuSolver.BOX_SIZE
			var box_c := c / SudokuSolver.BOX_SIZE
			var box_idx := box_r * SudokuSolver.BOX_SIZE + box_c
			box_grids[box_idx].add_child(btn)

			buttons[r].append(btn)
			note_labels[r].append({"grid": note_grid, "labels": cell_labels})

func _on_cell_pressed(btn: Button) -> void:
	selected_button = btn
	refresh_board_styles()

func refresh_board_styles() -> void:
	if selected_button == null:
		return

	var sel_r = selected_button.get_meta("row")
	var sel_c = selected_button.get_meta("col")
	var sel_value = player_board[sel_r][sel_c]

	var box_start_r = (sel_r / SudokuSolver.BOX_SIZE) * SudokuSolver.BOX_SIZE
	var box_start_c = (sel_c / SudokuSolver.BOX_SIZE) * SudokuSolver.BOX_SIZE

	var conflict_set := {}
	if sel_value != 0:
		for i in range(SudokuSolver.SIZE):
			if i != sel_c and player_board[sel_r][i] == sel_value:
				conflict_set[Vector2i(sel_r, i)] = true
			if i != sel_r and player_board[i][sel_c] == sel_value:
				conflict_set[Vector2i(i, sel_c)] = true
		for br in range(box_start_r, box_start_r + SudokuSolver.BOX_SIZE):
			for bc in range(box_start_c, box_start_c + SudokuSolver.BOX_SIZE):
				if (br != sel_r or bc != sel_c) and player_board[br][bc] == sel_value:
					conflict_set[Vector2i(br, bc)] = true

	for r in range(SudokuSolver.SIZE):
		for c in range(SudokuSolver.SIZE):
			var btn = buttons[r][c]
			var cell_value = player_board[r][c]

			var is_selected = (btn == selected_button)
			var in_highlight = (r == sel_r) or (c == sel_c) or (
				r >= box_start_r and r < box_start_r + SudokuSolver.BOX_SIZE and
				c >= box_start_c and c < box_start_c + SudokuSolver.BOX_SIZE)
			var has_note_match = (sel_value != 0 and cell_value == 0 and _has_note(r, c, sel_value))
			var same_number = (sel_value != 0 and (cell_value == sel_value or has_note_match) and not is_selected)
			var is_conflict := Vector2i(r, c) in conflict_set

			var state: StringName
			if is_selected:
				state = &"selected"
			elif is_conflict:
				state = &"conflict"
			elif same_number:
				state = &"same_number"
			elif in_highlight:
				state = &"highlight"
			else:
				state = &"default"
			var pressed_state := StringName(String(state) + "_pressed")
			theme_mgr.apply_button_styles(btn, theme_mgr.get_cell_style(r, c, state), theme_mgr.get_cell_style(r, c, pressed_state))


# --- Number Pad ---

func create_number_pad() -> void:
	number_pad.columns = 9
	action_buttons.columns = 3

	for i in range(1, 10):
		var btn := Button.new()
		btn.text = str(i)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_size_override("font_size", FONT_SIZE)
		theme_mgr.apply_numpad_theme(btn)
		btn.pressed.connect(_on_number_pressed.bind(i))
		number_buttons[i] = btn
		number_pad.add_child(btn)

	_create_action_button("Erase", _on_delete_pressed)
	notes_toggle_btn = _create_action_button("Notes", _on_notes_toggled)
	hint_btn = _create_action_button("Hint (%d)" % HINT_LIMIT, _on_hint_pressed)
	undo_btn = _create_action_button("Undo", _on_undo_pressed, true)
	auto_notes_btn = _create_action_button("Auto", _on_auto_notes_pressed)
	_create_action_button("Clear Notes", _on_clear_notes_pressed)

func update_number_pad() -> void:
	for n in range(1, 10):
		var count := 0
		for r in range(SudokuSolver.SIZE):
			for c in range(SudokuSolver.SIZE):
				if player_board[r][c] == n and solution_board[r][c] == n:
					count += 1
		number_buttons[n].disabled = (count >= SudokuSolver.SIZE)

func update_note_display(r: int, c: int) -> void:
	var data = note_labels[r][c]
	var grid : GridContainer = data["grid"]
	var labels : Array = data["labels"]

	var has_notes = notes[r][c] != 0 and player_board[r][c] == 0
	grid.visible = has_notes
	buttons[r][c].text = "" if has_notes else (str(player_board[r][c]) if player_board[r][c] != 0 else "")

	for n in range(1, 10):
		labels[n - 1].text = str(n) if _has_note(r, c, n) and has_notes else ""


# --- Game Actions ---

func _on_notes_toggled() -> void:
	notes_mode = !notes_mode
	var style := theme_mgr.create_numpad_style()
	if notes_mode:
		style.bg_color = theme_mgr.color_notes_active
	theme_mgr.apply_button_styles(notes_toggle_btn, style)
	save_mgr.request_save()

func _on_auto_notes_pressed() -> void:
	var constraints := solver.build_constraints(player_board)
	var row_used : Array = constraints[0]
	var col_used : Array = constraints[1]
	var box_used : Array = constraints[2]

	for r in range(SudokuSolver.SIZE):
		for c in range(SudokuSolver.SIZE):
			if player_board[r][c] != 0:
				continue
			var bi = (r / SudokuSolver.BOX_SIZE) * SudokuSolver.BOX_SIZE + c / SudokuSolver.BOX_SIZE
			var mask := 0
			for n in range(1, 10):
				if not row_used[r].has(n) and not col_used[c].has(n) and not box_used[bi].has(n):
					mask |= (1 << n)
			notes[r][c] = mask
			update_note_display(r, c)
	save_mgr.request_save()

func _on_clear_notes_pressed() -> void:
	for r in range(SudokuSolver.SIZE):
		for c in range(SudokuSolver.SIZE):
			if notes[r][c] != 0:
				notes[r][c] = 0
				update_note_display(r, c)
	save_mgr.request_save()

func _on_hint_pressed() -> void:
	if selected_button == null:
		return

	var r = selected_button.get_meta("row")
	var c = selected_button.get_meta("col")

	if player_board[r][c] == solution_board[r][c]:
		return

	var total_hints := HINT_LIMIT + bonus_hints
	if hints_used >= total_hints:
		AdManager.show_rewarded_ad(_grant_bonus_hint)
		return

	_use_hint()

func _grant_bonus_hint() -> void:
	bonus_hints += 1
	_update_hint_button()
	_use_hint()

func _use_hint() -> void:
	if selected_button == null:
		return

	var r = selected_button.get_meta("row")
	var c = selected_button.get_meta("col")

	if player_board[r][c] == solution_board[r][c]:
		return

	if not timer_started:
		timer_started = true
		timer_running = true

	var correct = solution_board[r][c]
	_clear_all_notes(r, c)
	update_note_display(r, c)

	player_board[r][c] = correct
	selected_button.text = str(correct)
	selected_button.set_meta("is_locked", true)
	_apply_cell_color(selected_button, "hint")
	animator.animate_pop(selected_button, theme_mgr.flash_color())

	remaining_cells -= 1

	hints_used += 1
	_update_hint_button()

	clear_notes_for_peers(r, c, correct)
	update_number_pad()
	refresh_board_styles()
	var anim_duration := animator.check_group_completions(r, c, player_board, solution_board, buttons, theme_mgr.flash_color())
	check_win(anim_duration)
	if not win_overlay.visible:
		save_mgr.request_save()

func _update_hint_button() -> void:
	var total_hints := HINT_LIMIT + bonus_hints
	var remaining := total_hints - hints_used
	if remaining > 0:
		hint_btn.text = "Hint (%d)" % remaining
		hint_btn.disabled = false
	else:
		hint_btn.text = "Ad Hint"
		hint_btn.disabled = false

func _on_undo_pressed() -> void:
	if undo_stack.is_empty():
		return

	var entry = undo_stack.pop_back()
	var r : int = entry["row"]
	var c : int = entry["col"]
	var btn = buttons[r][c]

	match entry["type"]:
		"place":
			for peer in entry["cleared_peers"]:
				_set_note(peer["row"], peer["col"], peer["number"])
				update_note_display(peer["row"], peer["col"])

			if not entry.get("was_mistake", false):
				remaining_cells += 1

			player_board[r][c] = entry["prev_value"]
			notes[r][c] = entry["prev_notes"]
			btn.set_meta("is_locked", false)

			if entry["prev_value"] == 0:
				btn.text = ""
			else:
				btn.text = str(entry["prev_value"])

			_apply_cell_color(btn, entry.get("prev_origin", ""))
			update_note_display(r, c)

		"erase":
			player_board[r][c] = entry["prev_value"]
			notes[r][c] = entry["prev_notes"]

			if entry["prev_value"] != 0:
				btn.text = str(entry["prev_value"])
			else:
				btn.text = ""

			_apply_cell_color(btn, entry.get("prev_origin", ""))
			update_note_display(r, c)

		"note":
			if entry["was_added"]:
				_clear_note(r, c, entry["number"])
			else:
				_set_note(r, c, entry["number"])
			update_note_display(r, c)

	undo_btn.disabled = undo_stack.is_empty()
	update_number_pad()
	refresh_board_styles()
	save_mgr.request_save()

func _on_delete_pressed() -> void:
	if selected_button == null:
		return
	if selected_button.get_meta("is_locked", false):
		return

	var r = selected_button.get_meta("row")
	var c = selected_button.get_meta("col")

	var prev_value = player_board[r][c]
	var prev_notes = notes[r][c]
	var prev_origin = selected_button.get_meta("origin", "")

	if prev_value == 0 and prev_notes == 0:
		return

	if notes[r][c] != 0:
		notes[r][c] = 0
		update_note_display(r, c)

	if player_board[r][c] != 0:
		player_board[r][c] = 0
		selected_button.text = ""
		_apply_cell_color(selected_button, "")
		update_number_pad()
		refresh_board_styles()

	undo_stack.append({
		"type": "erase",
		"row": r,
		"col": c,
		"prev_value": prev_value,
		"prev_notes": prev_notes,
		"prev_origin": prev_origin,
	})
	if undo_stack.size() > UNDO_LIMIT:
		undo_stack.pop_front()
	undo_btn.disabled = false
	save_mgr.request_save()

func _on_number_pressed(number: int) -> void:
	if selected_button == null:
		return
	if selected_button.get_meta("is_locked", false):
		return

	var r = selected_button.get_meta("row")
	var c = selected_button.get_meta("col")

	if notes_mode:
		if player_board[r][c] != 0:
			return
		if not timer_started:
			timer_started = true
			timer_running = true
		var was_added : bool = not _has_note(r, c, number)
		_toggle_note(r, c, number)
		undo_stack.append({
			"type": "note",
			"row": r,
			"col": c,
			"number": number,
			"was_added": was_added,
		})
		if undo_stack.size() > UNDO_LIMIT:
			undo_stack.pop_front()
		undo_btn.disabled = false
		update_note_display(r, c)
		save_mgr.request_save()
		return

	if not timer_started:
		timer_started = true
		timer_running = true

	var prev_value = player_board[r][c]
	var prev_notes = notes[r][c]
	var prev_origin = selected_button.get_meta("origin", "")

	_clear_all_notes(r, c)
	update_note_display(r, c)

	player_board[r][c] = number
	selected_button.text = str(number)
	var was_mistake : bool = (solution_board[r][c] != number)
	if not was_mistake:
		remaining_cells -= 1
		selected_button.set_meta("is_locked", true)
		_apply_cell_color(selected_button, "player")
		animator.animate_pop(selected_button, theme_mgr.flash_color())
	else:
		_apply_cell_color(selected_button, "wrong")
		animator.animate_shake(selected_button)
		mistakes += 1
		mistakes_label.text = "Mistakes: %d/%d" % [mistakes, LIFE_LIMIT]
		if mistakes >= LIFE_LIMIT:
			timer_running = false
			lose_overlay.visible = true
			save_mgr.clear()
			return

	var cleared_peers = clear_notes_for_peers(r, c, number)

	undo_stack.append({
		"type": "place",
		"row": r,
		"col": c,
		"prev_value": prev_value,
		"prev_notes": prev_notes,
		"prev_origin": prev_origin,
		"cleared_peers": cleared_peers,
		"was_mistake": was_mistake,
	})
	if undo_stack.size() > UNDO_LIMIT:
		undo_stack.pop_front()
	undo_btn.disabled = false

	update_number_pad()
	refresh_board_styles()
	var anim_duration := 0.0
	if not was_mistake:
		anim_duration = animator.check_group_completions(r, c, player_board, solution_board, buttons, theme_mgr.flash_color())
	check_win(anim_duration)
	if not win_overlay.visible:
		save_mgr.request_save()

func clear_notes_for_peers(row: int, col: int, number: int) -> Array:
	var cleared := []
	var visited := {}
	var box_r = (row / SudokuSolver.BOX_SIZE) * SudokuSolver.BOX_SIZE
	var box_c = (col / SudokuSolver.BOX_SIZE) * SudokuSolver.BOX_SIZE

	var peers := []
	for i in range(SudokuSolver.SIZE):
		peers.append(Vector2i(row, i))
		peers.append(Vector2i(i, col))
	for br in range(box_r, box_r + SudokuSolver.BOX_SIZE):
		for bc in range(box_c, box_c + SudokuSolver.BOX_SIZE):
			peers.append(Vector2i(br, bc))

	for peer in peers:
		if peer == Vector2i(row, col):
			continue
		if visited.has(peer):
			continue
		visited[peer] = true
		if _has_note(peer.x, peer.y, number):
			_clear_note(peer.x, peer.y, number)
			cleared.append({"row": peer.x, "col": peer.y, "number": number})
			update_note_display(peer.x, peer.y)

	return cleared

func check_win(delay := 0.0) -> void:
	if remaining_cells > 0:
		return
	timer_running = false

	var mins := int(elapsed_time) / 60
	var secs := int(elapsed_time) % 60
	win_time_label.text = "Time: %02d:%02d" % [mins, secs]
	win_mistakes_label.text = "Mistakes: %d/%d" % [mistakes, LIFE_LIMIT]

	var gold := Color(0.9, 0.75, 0.2) if theme_mgr.dark_mode else Color(0.7, 0.5, 0.0)

	var is_best := false
	if current_difficulty != "":
		stats_mgr.init_stats()
		var prev_best := float(stats_mgr.stats[current_difficulty].get("best_time", -1.0))
		is_best = prev_best < 0 or elapsed_time < prev_best
		stats_mgr.record_game_won(current_difficulty, elapsed_time)

	win_best_label.visible = is_best
	if is_best:
		win_best_label.text = "New Best Time!"
		win_best_label.add_theme_color_override("font_color", gold)

	if is_daily_game:
		var today := _get_today_date_str()
		var yesterday := _get_yesterday_date_str()
		stats_mgr.record_daily_won(today, yesterday, elapsed_time)
		var streak := stats_mgr.get_daily_streak(today, yesterday)
		win_streak_label.text = "Streak: %d %s" % [streak, "day" if streak == 1 else "days"]
		win_streak_label.add_theme_color_override("font_color", gold)
		win_streak_label.visible = true
		var best_s := stats_mgr.get_daily_best_streak()
		if streak >= best_s and streak > 1:
			win_best_streak_label.text = "New Best Streak!"
			win_best_streak_label.add_theme_color_override("font_color", gold)
			win_best_streak_label.visible = true
		else:
			win_best_streak_label.visible = false
	else:
		win_streak_label.visible = false
		win_best_streak_label.visible = false

	save_mgr.clear()
	if delay > 0.0:
		var tween := create_tween()
		tween.tween_interval(delay)
		tween.tween_callback(func(): animator.show_win_overlay(win_overlay, win_content))
	else:
		animator.show_win_overlay(win_overlay, win_content)


# --- Overlays ---

func create_win_overlay() -> void:
	var result = UIFactory.create_overlay(self)
	win_overlay = result[0]
	win_content = result[1]

	win_content.add_child(UIFactory.create_overlay_label("You Won!!"))

	var stats_box := VBoxContainer.new()
	stats_box.alignment = BoxContainer.ALIGNMENT_CENTER
	stats_box.add_theme_constant_override("separation", 8)

	win_time_label = UIFactory.create_overlay_label("", 32)
	stats_box.add_child(win_time_label)

	win_mistakes_label = UIFactory.create_overlay_label("", 32)
	stats_box.add_child(win_mistakes_label)

	win_best_label = UIFactory.create_overlay_label("", FONT_SIZE_STATS_TITLE)
	win_best_label.visible = false
	stats_box.add_child(win_best_label)

	win_streak_label = UIFactory.create_overlay_label("", FONT_SIZE_STATS_TITLE)
	win_streak_label.visible = false
	stats_box.add_child(win_streak_label)

	win_best_streak_label = UIFactory.create_overlay_label("", FONT_SIZE_STATS_DETAIL)
	win_best_streak_label.visible = false
	stats_box.add_child(win_best_streak_label)

	win_content.add_child(stats_box)
	win_content.add_child(UIFactory.create_overlay_button("New Game", _go_to_difficulty.bind(win_overlay)))

func create_lose_overlay() -> void:
	var result = UIFactory.create_overlay(self)
	lose_overlay = result[0]
	var vbox = result[1]

	vbox.add_child(UIFactory.create_overlay_label("You Lost"))
	var ad_life_btn := UIFactory.create_overlay_button("Watch Ad for Life", _on_another_life_pressed)
	ad_life_btn.name = "AdLifeButton"
	vbox.add_child(ad_life_btn)
	vbox.add_child(UIFactory.create_overlay_button("New Game", _go_to_difficulty.bind(lose_overlay)))

func create_pause_overlay() -> void:
	var result = UIFactory.create_overlay(self)
	pause_overlay = result[0]
	var vbox = result[1]

	vbox.add_child(UIFactory.create_overlay_label("Paused"))
	vbox.add_child(UIFactory.create_overlay_button("Resume", _on_resume_pressed))
	vbox.add_child(UIFactory.create_overlay_button("Restart", _on_restart_pressed))
	vbox.add_child(UIFactory.create_overlay_button("New Game", _go_to_difficulty.bind(pause_overlay)))

func create_settings_overlay() -> void:
	var result = UIFactory.create_overlay(self, Color(0, 0, 0, 1.0))
	settings_overlay = result[0]
	var vbox = result[1]

	settings_overlay.add_child(UIFactory.create_close_button(_on_settings_close_pressed))

	vbox.add_child(UIFactory.create_overlay_label("Settings"))

	var theme_row := HBoxContainer.new()
	theme_row.alignment = BoxContainer.ALIGNMENT_CENTER
	theme_row.add_theme_constant_override("separation", 20)

	var theme_label := Label.new()
	theme_label.text = "Dark Mode"
	theme_label.add_theme_font_size_override("font_size", FONT_SIZE_SETTINGS_LABEL)
	theme_label.add_theme_color_override("font_color", Color.WHITE)
	theme_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	theme_row.add_child(theme_label)

	var toggle_container := Control.new()
	toggle_container.custom_minimum_size = Vector2(TOGGLE_TRACK_W, TOGGLE_TRACK_H)
	toggle_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var track_style := StyleBoxFlat.new()
	track_style.corner_radius_top_left = CORNER_RADIUS_TOGGLE
	track_style.corner_radius_top_right = CORNER_RADIUS_TOGGLE
	track_style.corner_radius_bottom_left = CORNER_RADIUS_TOGGLE
	track_style.corner_radius_bottom_right = CORNER_RADIUS_TOGGLE

	theme_toggle_track = Panel.new()
	theme_toggle_track.size = Vector2(TOGGLE_TRACK_W, TOGGLE_TRACK_H)
	theme_toggle_track.add_theme_stylebox_override("panel", track_style)
	toggle_container.add_child(theme_toggle_track)

	var knob_style := StyleBoxFlat.new()
	knob_style.bg_color = Color.WHITE
	knob_style.corner_radius_top_left = 15
	knob_style.corner_radius_top_right = 15
	knob_style.corner_radius_bottom_left = 15
	knob_style.corner_radius_bottom_right = 15

	theme_toggle_knob = Panel.new()
	theme_toggle_knob.size = Vector2(TOGGLE_KNOB_SIZE, TOGGLE_KNOB_SIZE)
	theme_toggle_knob.add_theme_stylebox_override("panel", knob_style)
	theme_toggle_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toggle_container.add_child(theme_toggle_knob)

	_update_toggle_visual()

	var toggle_btn := Button.new()
	toggle_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	toggle_btn.focus_mode = Control.FOCUS_NONE
	toggle_btn.flat = true
	toggle_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	toggle_btn.pressed.connect(_on_theme_toggle_pressed)
	toggle_container.add_child(toggle_btn)

	theme_row.add_child(toggle_container)
	vbox.add_child(theme_row)
	vbox.add_child(UIFactory.create_overlay_button("Statistics", _on_statistics_pressed))

func create_stats_overlay() -> void:
	var result = UIFactory.create_overlay(self, Color(0, 0, 0, 1.0), 20)
	stats_overlay = result[0]
	var vbox = result[1]

	stats_overlay.add_child(UIFactory.create_close_button(_on_stats_back_pressed))

	vbox.add_child(UIFactory.create_overlay_label("Statistics", 48))

	stats_container = VBoxContainer.new()
	stats_container.add_theme_constant_override("separation", 12)
	vbox.add_child(stats_container)

	vbox.add_child(UIFactory.create_overlay_button("Back", _on_stats_back_pressed))

func _update_stats_display() -> void:
	for child in stats_container.get_children():
		child.queue_free()

	stats_mgr.init_stats()

	var today := _get_today_date_str()
	var yesterday := _get_yesterday_date_str()
	var daily_section := VBoxContainer.new()
	daily_section.add_theme_constant_override("separation", 2)

	var daily_title := Label.new()
	daily_title.text = "Daily"
	daily_title.add_theme_font_size_override("font_size", FONT_SIZE_STATS_TITLE)
	var warm := Color(0.9, 0.75, 0.2) if theme_mgr.dark_mode else Color(0.6, 0.4, 0.0)
	daily_title.add_theme_color_override("font_color", warm)
	daily_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	daily_section.add_child(daily_title)

	var streak := stats_mgr.get_daily_streak(today, yesterday)
	var best_streak := stats_mgr.get_daily_best_streak()
	var daily_best_time := stats_mgr.get_daily_best_time()

	var daily_detail := Label.new()
	daily_detail.text = "Streak: %d   Record: %d   Best: %s" % [streak, best_streak, stats_mgr.format_best_time(daily_best_time)]
	daily_detail.add_theme_font_size_override("font_size", FONT_SIZE_STATS_DETAIL)
	daily_detail.add_theme_color_override("font_color", theme_mgr.color_overlay_label)
	daily_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	daily_section.add_child(daily_detail)

	stats_container.add_child(daily_section)

	for diff_name in DIFFICULTIES:
		var entry : Dictionary = stats_mgr.stats[diff_name]
		var started := int(entry.get("started", 0))
		var won := int(entry.get("won", 0))
		var best := float(entry.get("best_time", -1.0))

		var section := VBoxContainer.new()
		section.add_theme_constant_override("separation", 2)

		var title := Label.new()
		title.text = diff_name
		title.add_theme_font_size_override("font_size", FONT_SIZE_STATS_TITLE)
		title.add_theme_color_override("font_color", Color(0.9, 0.75, 0.2) if theme_mgr.dark_mode else Color(0.6, 0.4, 0.0))
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		section.add_child(title)

		var detail := Label.new()
		detail.text = "Played: %d   Won: %d   Best: %s" % [started, won, stats_mgr.format_best_time(best)]
		detail.add_theme_font_size_override("font_size", FONT_SIZE_STATS_DETAIL)
		detail.add_theme_color_override("font_color", theme_mgr.color_overlay_label)
		detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		section.add_child(detail)

		stats_container.add_child(section)

func create_difficulty_overlay() -> void:
	var result = UIFactory.create_overlay(self, Color(0, 0, 0, 1.0), 24)
	difficulty_overlay = result[0]
	var vbox = result[1]

	vbox.add_child(UIFactory.create_overlay_label("Select Difficulty", 52))

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 16)
	vbox.add_child(spacer)

	continue_btn = UIFactory.create_overlay_button("Continue", _on_continue_pressed)
	continue_btn.custom_minimum_size = Vector2(340, 72)
	continue_btn.add_theme_font_size_override("font_size", 32)
	continue_btn.visible = false
	vbox.add_child(continue_btn)

	var daily_section := VBoxContainer.new()
	daily_section.alignment = BoxContainer.ALIGNMENT_CENTER
	daily_section.add_theme_constant_override("separation", 8)

	daily_btn = UIFactory.create_overlay_button("Daily Puzzle", _on_daily_pressed)
	daily_btn.custom_minimum_size = Vector2(340, 72)
	daily_btn.add_theme_font_size_override("font_size", 32)
	daily_section.add_child(daily_btn)

	daily_streak_label = Label.new()
	daily_streak_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	daily_streak_label.add_theme_font_size_override("font_size", FONT_SIZE_STATS_DETAIL)
	daily_section.add_child(daily_streak_label)

	vbox.add_child(daily_section)

	for diff_name in DIFFICULTIES:
		var btn = UIFactory.create_overlay_button(diff_name, _on_difficulty_selected.bind(diff_name, DIFFICULTIES[diff_name]))
		btn.custom_minimum_size = Vector2(340, 72)
		btn.add_theme_font_size_override("font_size", 32)
		vbox.add_child(btn)

func _on_continue_pressed() -> void:
	if _load_game():
		difficulty_overlay.visible = false
		game_container.visible = true

func _update_continue_button() -> void:
	if not save_mgr.has_save():
		continue_btn.visible = false
		return
	var data = save_mgr.load_data()
	if data != null and data.get("is_daily", false):
		if data.get("daily_date", "") != _get_today_date_str():
			save_mgr.clear()
			continue_btn.visible = false
			return
	continue_btn.visible = true

func _on_another_life_pressed() -> void:
	AdManager.show_rewarded_ad(_grant_extra_life)

func _grant_extra_life() -> void:
	lose_overlay.visible = false
	mistakes = LIFE_LIMIT - 1
	mistakes_label.text = "Mistakes: %d/%d" % [mistakes, LIFE_LIMIT]
	timer_running = true
	save_mgr.request_save()

func _on_theme_toggle_pressed() -> void:
	theme_mgr.set_dark_mode(!theme_mgr.dark_mode)
	_update_toggle_visual()
	_apply_theme()
	stats_mgr.set_dark_mode(theme_mgr.dark_mode)
	stats_mgr.save_stats()

func _update_toggle_visual() -> void:
	var track_style : StyleBoxFlat = theme_toggle_track.get_theme_stylebox("panel")
	if theme_mgr.dark_mode:
		track_style.bg_color = Color(0.3, 0.7, 0.4)
		theme_toggle_knob.position = Vector2(TOGGLE_TRACK_W - TOGGLE_KNOB_SIZE - TOGGLE_KNOB_MARGIN, TOGGLE_KNOB_MARGIN)
	else:
		track_style.bg_color = Color(0.5, 0.5, 0.5)
		theme_toggle_knob.position = Vector2(TOGGLE_KNOB_MARGIN, TOGGLE_KNOB_MARGIN)

func _on_settings_pressed() -> void:
	timer_running = false
	settings_button.visible = false
	settings_overlay.visible = true

func _on_settings_close_pressed() -> void:
	settings_overlay.visible = false
	settings_button.visible = true
	if timer_started:
		timer_running = true

func _on_statistics_pressed() -> void:
	settings_overlay.visible = false
	_update_stats_display()
	stats_overlay.visible = true

func _on_stats_back_pressed() -> void:
	stats_overlay.visible = false
	settings_overlay.visible = true

func _on_pause_pressed() -> void:
	timer_running = false
	pause_overlay.visible = true
	save_mgr.save_immediate()

func _on_resume_pressed() -> void:
	pause_overlay.visible = false
	timer_running = true

func _on_restart_pressed() -> void:
	pause_overlay.visible = false
	player_board = initial_board.duplicate(true)
	_reset_game_state()
	update_ui()
	refresh_board_styles()
	save_mgr.request_save()

func _on_difficulty_selected(diff_name: String, remove_count: int) -> void:
	difficulty_overlay.visible = false
	game_container.visible = true
	difficulty_label.text = "Level: " + diff_name
	current_difficulty = diff_name
	is_daily_game = false

	_reset_game_state()
	stats_mgr.record_game_started(diff_name)
	var result = solver.generate_puzzle(remove_count)
	solution_board = result[0]
	player_board = result[1]
	initial_board = player_board.duplicate(true)
	update_ui()
	refresh_board_styles()
	save_mgr.request_save()

func _on_daily_pressed() -> void:
	var info := _get_daily_info()
	difficulty_overlay.visible = false
	game_container.visible = true
	is_daily_game = true
	current_difficulty = ""
	difficulty_label.text = "Daily - " + info.difficulty

	_reset_game_state()
	var result = solver.generate_daily_puzzle(info.seed, info.remove_count)
	solution_board = result[0]
	player_board = result[1]
	initial_board = player_board.duplicate(true)
	update_ui()
	refresh_board_styles()
	save_mgr.request_save()

func _update_daily_button() -> void:
	var today := _get_today_date_str()
	var yesterday := _get_yesterday_date_str()
	var completed := stats_mgr.is_daily_completed(today)

	if completed:
		daily_btn.text = "Daily Complete ✓"
		daily_btn.disabled = true
	else:
		var info := _get_daily_info()
		daily_btn.text = "Daily Puzzle (%s)" % info.difficulty
		daily_btn.disabled = false

	var streak := stats_mgr.get_daily_streak(today, yesterday)
	var warm := Color(0.9, 0.75, 0.2) if theme_mgr.dark_mode else Color(0.6, 0.4, 0.0)
	daily_streak_label.add_theme_color_override("font_color", warm)
	if streak > 0:
		daily_streak_label.text = "%d day streak" % streak
	else:
		daily_streak_label.text = "Start your streak!"


# --- Update UI ---

func update_ui() -> void:
	remaining_cells = 0
	for r in range(SudokuSolver.SIZE):
		for c in range(SudokuSolver.SIZE):
			var value = player_board[r][c]
			var btn = buttons[r][c]

			if value == 0:
				btn.text = ""
				btn.set_meta("is_locked", false)
				_apply_cell_color(btn, "")
			else:
				btn.text = str(value)
				btn.set_meta("is_locked", true)
				_apply_cell_color(btn, "initial")

			if player_board[r][c] != solution_board[r][c]:
				remaining_cells += 1

			if note_labels.size() > 0:
				update_note_display(r, c)
	update_number_pad()

func format_time(seconds: float) -> String:
	var mins := int(seconds) / 60
	var secs := int(seconds) % 60
	return "Time: %02d:%02d" % [mins, secs]

func _process(delta: float) -> void:
	if timer_running:
		elapsed_time += delta
		timer_label.text = format_time(elapsed_time)
