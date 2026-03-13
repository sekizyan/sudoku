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
const FONT_SIZE_TOP_BAR := 28
const BOARD_BORDER_WIDTH := 2
const BOX_GAP := 3
const CELL_GAP := 1
const UNDO_LIMIT := 100

var theme_mgr := ThemeManager.new()
var save_mgr: SaveManager
var stats_mgr := StatsManager.new()
var animator := BoardAnimator.new()
var actions := GameActions.new()
var custom := CustomPuzzle.new()
var overlay_mgr := OverlayManager.new()

var solver := SudokuSolver.new()
var solution_board: Array = []
var player_board: Array = []
var initial_board: Array = []

var selected_button : Button = null
var buttons: Array[Array] = []
var number_buttons : Dictionary = {}
var notes_toggle_btn : Button
var hint_btn : Button
var undo_btn : Button
var auto_notes_btn : Button
var erase_btn : Button
var clear_notes_action_btn : Button
var create_clear_btn : Button
var create_play_btn : Button
var note_labels: Array[Array] = []
var timer_running := false
var timer_started := false
var elapsed_time := 0.0
var current_difficulty := ""
var bg_rect : ColorRect
var board_wrapper : PanelContainer
var box_grids: Array[GridContainer] = []
var font_regular : Font
var font_semibold : Font
var remaining_cells: int = 0
var _last_board_width := 0.0
var is_daily_game := false

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

	stats_mgr.setup(DIFFICULTIES.keys() + ["Custom"])
	stats_mgr.load_stats()

	theme_mgr.set_dark_mode(stats_mgr.get_dark_mode())

	animator.setup(self)
	actions.setup(self)
	custom.setup(self)
	overlay_mgr.setup(self)

	bg_rect = ColorRect.new()
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_rect.color = theme_mgr.color_bg
	add_child(bg_rect)
	move_child(bg_rect, 0)

	create_board_ui()
	create_number_pad()
	overlay_mgr.create_all()

	UIFactory.apply_pause_button_style(pause_button)
	pause_button.pressed.connect(overlay_mgr.on_pause_pressed)
	UIFactory.apply_pause_button_style(settings_button)
	settings_button.add_theme_font_size_override("font_size", 34)
	settings_button.custom_minimum_size = Vector2(62, 62)
	settings_button.pressed.connect(overlay_mgr.on_settings_pressed)
	move_child(settings_button, -1)

	_setup_top_bar_labels()
	board_wrapper.resized.connect(_on_board_resized)
	number_pad.resized.connect(_on_number_pad_resized)
	action_buttons.resized.connect(_on_action_buttons_resized)

	save_mgr = SaveManager.new()
	add_child(save_mgr)
	save_mgr.set_data_provider(_build_save_data)

	overlay_mgr.update_toggle_visual()
	_apply_theme()

	game_container.visible = false
	overlay_mgr.difficulty_overlay.visible = true
	overlay_mgr.update_continue_button()
	overlay_mgr.update_daily_button()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if game_container.visible and not overlay_mgr.win_overlay.visible and not overlay_mgr.lose_overlay.visible:
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

	actions.apply_theme()
	overlay_mgr.apply_theme()


# --- Helpers ---

func _reset_game_state() -> void:
	elapsed_time = 0.0
	timer_running = false
	timer_started = false
	timer_label.text = "Time: 00:00"
	selected_button = null
	for r in range(SudokuSolver.SIZE):
		for c in range(SudokuSolver.SIZE):
			theme_mgr.apply_button_styles(buttons[r][c], theme_mgr.get_cell_style(r, c, &"default"), theme_mgr.get_cell_style(r, c, &"default_pressed"))
	actions.reset()

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
	var seed_val : int = int(d.year) * 10000 + int(d.month) * 100 + int(d.day)
	var daily_difficulties := ["Easy", "Medium", "Hard"]
	var idx := int(d.day) % daily_difficulties.size()
	var diff_name : String = daily_difficulties[idx]
	return {"seed": seed_val, "difficulty": diff_name, "remove_count": DIFFICULTIES[diff_name]}

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
		"notes": actions.notes,
		"elapsed_time": elapsed_time,
		"mistakes": actions.mistakes,
		"hints_used": actions.hints_used,
		"notes_mode": actions.notes_mode,
		"difficulty_text": difficulty_label.text,
		"current_difficulty": current_difficulty,
		"origins": origins,
		"timer_started": timer_started,
		"is_daily": is_daily_game,
		"daily_date": _get_today_date_str() if is_daily_game else "",
		"is_custom_game": custom.is_custom_game,
		"is_creating": custom.is_creating_puzzle,
	}

func _load_game() -> bool:
	var data = save_mgr.load_data()
	if data == null:
		return false

	is_daily_game = data.get("is_daily", false)
	custom.is_custom_game = data.get("is_custom_game", false)
	custom.is_creating_puzzle = data.get("is_creating", false)
	if is_daily_game and data.get("daily_date", "") != _get_today_date_str():
		save_mgr.clear()
		is_daily_game = false
		return false

	solution_board = SaveManager.to_int_board(data["solution_board"])
	player_board = SaveManager.to_int_board(data["player_board"])
	initial_board = SaveManager.to_int_board(data["initial_board"])
	actions.notes = SaveManager.to_int_board(data["notes"])
	elapsed_time = float(data["elapsed_time"])
	actions.mistakes = int(data["mistakes"])
	actions.hints_used = int(data["hints_used"])
	actions.notes_mode = data.get("notes_mode", false)
	timer_started = data.get("timer_started", false)
	current_difficulty = data.get("current_difficulty", "")

	difficulty_label.text = data["difficulty_text"]
	mistakes_label.text = "Mistakes: %d/%d" % [actions.mistakes, LIFE_LIMIT]
	timer_label.text = format_time(elapsed_time)
	actions.bonus_hints = 0
	actions.update_hint_button()
	actions.undo_stack.clear()
	undo_btn.disabled = true

	if actions.notes_mode:
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
			actions.update_note_display(r, c)

	actions.update_number_pad()

	remaining_cells = 0
	for r in range(SudokuSolver.SIZE):
		for c in range(SudokuSolver.SIZE):
			if player_board[r][c] != solution_board[r][c]:
				remaining_cells += 1

	if custom.is_creating_puzzle:
		for r in range(SudokuSolver.SIZE):
			for c in range(SudokuSolver.SIZE):
				buttons[r][c].set_meta("is_locked", false)
		custom.enter_create_mode()
	elif timer_started:
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
			var has_note_match = (sel_value != 0 and cell_value == 0 and actions.has_note(r, c, sel_value))
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
		btn.pressed.connect(actions.on_number_pressed.bind(i))
		number_buttons[i] = btn
		number_pad.add_child(btn)

	erase_btn = _create_action_button("Erase", actions.on_delete_pressed)
	notes_toggle_btn = _create_action_button("Notes", actions.on_notes_toggled)
	hint_btn = _create_action_button("Hint (%d)" % HINT_LIMIT, actions.on_hint_pressed)
	undo_btn = _create_action_button("Undo", actions.on_undo_pressed, true)
	auto_notes_btn = _create_action_button("Auto", actions.on_auto_notes_pressed)
	clear_notes_action_btn = _create_action_button("Clear Notes", actions.on_clear_notes_pressed)
	create_clear_btn = _create_action_button("Clear", custom.on_create_clear_pressed)
	create_clear_btn.visible = false
	create_play_btn = _create_action_button("Solve ▶", custom.on_create_play_pressed)
	create_play_btn.visible = false


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
				actions.update_note_display(r, c)
	actions.update_number_pad()

func format_time(seconds: float) -> String:
	var mins := int(seconds) / 60
	var secs := int(seconds) % 60
	return "Time: %02d:%02d" % [mins, secs]

func _process(delta: float) -> void:
	if timer_running:
		elapsed_time += delta
		timer_label.text = format_time(elapsed_time)
