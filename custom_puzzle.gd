class_name CustomPuzzle
extends RefCounted

var g

var is_creating_puzzle := false
var is_custom_game := false

func setup(host) -> void:
	g = host

func on_create_puzzle_pressed() -> void:
	g.overlay_mgr.difficulty_overlay.visible = false
	g.game_container.visible = true
	is_creating_puzzle = true
	is_custom_game = true
	g.is_daily_game = false
	g.current_difficulty = "Custom"
	g.difficulty_label.text = "Create Puzzle"

	g._reset_game_state()
	g.solution_board = g.solver._create_empty_board()
	g.player_board = g.solver._create_empty_board()
	g.initial_board = g.solver._create_empty_board()

	for r in range(SudokuSolver.SIZE):
		for c in range(SudokuSolver.SIZE):
			g.buttons[r][c].text = ""
			g.buttons[r][c].set_meta("is_locked", false)
			g._apply_cell_color(g.buttons[r][c], "")
			g.actions.update_note_display(r, c)

	g.actions.update_number_pad()
	enter_create_mode()
	g.save_mgr.request_save()

func on_create_play_pressed() -> void:
	var filled := 0
	for r in range(SudokuSolver.SIZE):
		for c in range(SudokuSolver.SIZE):
			if g.player_board[r][c] != 0:
				filled += 1
	if filled == 0:
		g.overlay_mgr.show_validation_error("Place some numbers first")
		return

	if _has_board_conflicts():
		g.overlay_mgr.show_validation_error("Conflicting numbers found")
		return

	var test = g.player_board.duplicate(true)
	var solutions = g.solver._count_solutions(test)
	if solutions == 0:
		g.overlay_mgr.show_validation_error("This puzzle has no solution")
		return
	if solutions > 1:
		g.overlay_mgr.show_validation_error("Multiple solutions found.\nAdd more numbers.")
		return

	var sol = g.player_board.duplicate(true)
	g.solver._fill_board(sol)
	g.solution_board = sol
	g.initial_board = g.player_board.duplicate(true)

	is_creating_puzzle = false
	enter_solve_mode()
	g._reset_game_state()
	g.player_board = g.initial_board.duplicate(true)
	g.difficulty_label.text = "Custom"
	g.stats_mgr.record_game_started("Custom")

	for r in range(SudokuSolver.SIZE):
		for c in range(SudokuSolver.SIZE):
			var btn = g.buttons[r][c]
			if g.initial_board[r][c] != 0:
				btn.text = str(g.initial_board[r][c])
				btn.set_meta("is_locked", true)
				g._apply_cell_color(btn, "initial")
			else:
				btn.text = ""
				btn.set_meta("is_locked", false)
				g._apply_cell_color(btn, "")
			g.actions.update_note_display(r, c)

	g.remaining_cells = 0
	for r in range(SudokuSolver.SIZE):
		for c in range(SudokuSolver.SIZE):
			if g.player_board[r][c] != g.solution_board[r][c]:
				g.remaining_cells += 1

	g.actions.update_number_pad()
	g.save_mgr.request_save()

func on_create_clear_pressed() -> void:
	for r in range(SudokuSolver.SIZE):
		for c in range(SudokuSolver.SIZE):
			g.player_board[r][c] = 0
			g.buttons[r][c].text = ""
			g._apply_cell_color(g.buttons[r][c], "")
	g.selected_button = null
	for r in range(SudokuSolver.SIZE):
		for c in range(SudokuSolver.SIZE):
			g.theme_mgr.apply_button_styles(g.buttons[r][c], g.theme_mgr.get_cell_style(r, c, &"default"), g.theme_mgr.get_cell_style(r, c, &"default_pressed"))
	g.save_mgr.request_save()

func enter_create_mode() -> void:
	g.timer_label.visible = false
	g.mistakes_label.visible = false
	g.pause_button.visible = false
	g.notes_toggle_btn.visible = false
	g.hint_btn.visible = false
	g.undo_btn.visible = false
	g.auto_notes_btn.visible = false
	g.clear_notes_action_btn.visible = false
	g.create_clear_btn.visible = true
	g.create_play_btn.visible = true

func enter_solve_mode() -> void:
	g.timer_label.visible = true
	g.mistakes_label.visible = true
	g.pause_button.visible = true
	g.notes_toggle_btn.visible = true
	g.hint_btn.visible = true
	g.undo_btn.visible = true
	g.auto_notes_btn.visible = true
	g.clear_notes_action_btn.visible = true
	g.create_clear_btn.visible = false
	g.create_play_btn.visible = false

func _has_board_conflicts() -> bool:
	for r in range(SudokuSolver.SIZE):
		var seen := {}
		for c in range(SudokuSolver.SIZE):
			var n = g.player_board[r][c]
			if n != 0:
				if seen.has(n):
					return true
				seen[n] = true
	for c in range(SudokuSolver.SIZE):
		var seen := {}
		for r in range(SudokuSolver.SIZE):
			var n = g.player_board[r][c]
			if n != 0:
				if seen.has(n):
					return true
				seen[n] = true
	for box in range(SudokuSolver.SIZE):
		var seen := {}
		var br = (box / SudokuSolver.BOX_SIZE) * SudokuSolver.BOX_SIZE
		var bc = (box % SudokuSolver.BOX_SIZE) * SudokuSolver.BOX_SIZE
		for r in range(br, br + SudokuSolver.BOX_SIZE):
			for c in range(bc, bc + SudokuSolver.BOX_SIZE):
				var n = g.player_board[r][c]
				if n != 0:
					if seen.has(n):
						return true
					seen[n] = true
	return false
