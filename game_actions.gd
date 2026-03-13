class_name GameActions
extends RefCounted

var g

var notes: Array = []
var notes_mode := false
var hints_used := 0
var bonus_hints := 0
var undo_stack: Array[Dictionary] = []
var mistakes := 0

func setup(host) -> void:
	g = host

func reset() -> void:
	mistakes = 0
	g.mistakes_label.text = "Mistakes: 0/%d" % g.LIFE_LIMIT
	notes_mode = false
	var style = g.theme_mgr.create_numpad_style()
	g.theme_mgr.apply_button_styles(g.notes_toggle_btn, style)
	hints_used = 0
	bonus_hints = 0
	update_hint_button()
	undo_stack.clear()
	g.undo_btn.disabled = true
	init_notes()

func init_notes() -> void:
	notes = []
	for r in range(SudokuSolver.SIZE):
		notes.append([])
		for c in range(SudokuSolver.SIZE):
			notes[r].append(0)

func apply_theme() -> void:
	if notes_mode:
		var style = g.theme_mgr.create_numpad_style()
		style.bg_color = g.theme_mgr.color_notes_active
		g.theme_mgr.apply_button_styles(g.notes_toggle_btn, style)


# --- Notes ---

func has_note(r: int, c: int, n: int) -> bool:
	return (notes[r][c] & (1 << n)) != 0

func set_note(r: int, c: int, n: int) -> void:
	notes[r][c] |= (1 << n)

func clear_note(r: int, c: int, n: int) -> void:
	notes[r][c] &= ~(1 << n)

func toggle_note(r: int, c: int, n: int) -> void:
	notes[r][c] ^= (1 << n)

func clear_all_notes(r: int, c: int) -> void:
	notes[r][c] = 0

func get_note_list(r: int, c: int) -> Array[int]:
	var result: Array[int] = []
	for n in range(1, 10):
		if has_note(r, c, n):
			result.append(n)
	return result

func update_note_display(r: int, c: int) -> void:
	var data = g.note_labels[r][c]
	var grid : GridContainer = data["grid"]
	var labels : Array = data["labels"]

	var has_notes = notes[r][c] != 0 and g.player_board[r][c] == 0
	grid.visible = has_notes
	g.buttons[r][c].text = "" if has_notes else (str(g.player_board[r][c]) if g.player_board[r][c] != 0 else "")

	for n in range(1, 10):
		labels[n - 1].text = str(n) if has_note(r, c, n) and has_notes else ""

func update_number_pad() -> void:
	if g.custom.is_creating_puzzle:
		for i in range(1, 10):
			g.number_buttons[i].disabled = false
		return
	for n in range(1, 10):
		var count := 0
		for r in range(SudokuSolver.SIZE):
			for c in range(SudokuSolver.SIZE):
				if g.player_board[r][c] == n and g.solution_board[r][c] == n:
					count += 1
		g.number_buttons[n].disabled = (count >= SudokuSolver.SIZE)


# --- Actions ---

func on_notes_toggled() -> void:
	notes_mode = !notes_mode
	var style = g.theme_mgr.create_numpad_style()
	if notes_mode:
		style.bg_color = g.theme_mgr.color_notes_active
	g.theme_mgr.apply_button_styles(g.notes_toggle_btn, style)
	g.save_mgr.request_save()

func on_auto_notes_pressed() -> void:
	var constraints = g.solver.build_constraints(g.player_board)
	var row_used : Array = constraints[0]
	var col_used : Array = constraints[1]
	var box_used : Array = constraints[2]

	for r in range(SudokuSolver.SIZE):
		for c in range(SudokuSolver.SIZE):
			if g.player_board[r][c] != 0:
				continue
			var bi = (r / SudokuSolver.BOX_SIZE) * SudokuSolver.BOX_SIZE + c / SudokuSolver.BOX_SIZE
			var mask := 0
			for n in range(1, 10):
				if not row_used[r].has(n) and not col_used[c].has(n) and not box_used[bi].has(n):
					mask |= (1 << n)
			notes[r][c] = mask
			update_note_display(r, c)
	g.save_mgr.request_save()

func on_clear_notes_pressed() -> void:
	for r in range(SudokuSolver.SIZE):
		for c in range(SudokuSolver.SIZE):
			if notes[r][c] != 0:
				notes[r][c] = 0
				update_note_display(r, c)
	g.save_mgr.request_save()

func on_hint_pressed() -> void:
	if g.selected_button == null:
		return

	var r = g.selected_button.get_meta("row")
	var c = g.selected_button.get_meta("col")

	if g.player_board[r][c] == g.solution_board[r][c]:
		return

	var total_hints = g.HINT_LIMIT + bonus_hints
	if hints_used >= total_hints:
		AdManager.show_rewarded_ad(_grant_bonus_hint)
		return

	_use_hint()

func _grant_bonus_hint() -> void:
	bonus_hints += 1
	update_hint_button()
	_use_hint()

func _use_hint() -> void:
	if g.selected_button == null:
		return

	var r = g.selected_button.get_meta("row")
	var c = g.selected_button.get_meta("col")

	if g.player_board[r][c] == g.solution_board[r][c]:
		return

	if not g.timer_started:
		g.timer_started = true
		g.timer_running = true

	var correct = g.solution_board[r][c]
	clear_all_notes(r, c)
	update_note_display(r, c)

	g.player_board[r][c] = correct
	g.selected_button.text = str(correct)
	g.selected_button.set_meta("is_locked", true)
	g._apply_cell_color(g.selected_button, "hint")
	g.animator.animate_pop(g.selected_button, g.theme_mgr.flash_color())

	g.remaining_cells -= 1

	hints_used += 1
	update_hint_button()

	clear_notes_for_peers(r, c, correct)
	update_number_pad()
	g.refresh_board_styles()
	var anim_duration = g.animator.check_group_completions(r, c, g.player_board, g.solution_board, g.buttons, g.theme_mgr.flash_color())
	check_win(anim_duration)
	if not g.overlay_mgr.win_overlay.visible:
		g.save_mgr.request_save()

func update_hint_button() -> void:
	var total_hints = g.HINT_LIMIT + bonus_hints
	var remaining = total_hints - hints_used
	if remaining > 0:
		g.hint_btn.text = "Hint (%d)" % remaining
		g.hint_btn.disabled = false
	else:
		g.hint_btn.text = "Ad Hint"
		g.hint_btn.disabled = false

func on_undo_pressed() -> void:
	if undo_stack.is_empty():
		return

	var entry = undo_stack.pop_back()
	var r : int = entry["row"]
	var c : int = entry["col"]
	var btn = g.buttons[r][c]

	match entry["type"]:
		"place":
			for peer in entry["cleared_peers"]:
				set_note(peer["row"], peer["col"], peer["number"])
				update_note_display(peer["row"], peer["col"])

			if not entry.get("was_mistake", false):
				g.remaining_cells += 1

			g.player_board[r][c] = entry["prev_value"]
			notes[r][c] = entry["prev_notes"]
			btn.set_meta("is_locked", false)

			if entry["prev_value"] == 0:
				btn.text = ""
			else:
				btn.text = str(entry["prev_value"])

			g._apply_cell_color(btn, entry.get("prev_origin", ""))
			update_note_display(r, c)

		"erase":
			g.player_board[r][c] = entry["prev_value"]
			notes[r][c] = entry["prev_notes"]

			if entry["prev_value"] != 0:
				btn.text = str(entry["prev_value"])
			else:
				btn.text = ""

			g._apply_cell_color(btn, entry.get("prev_origin", ""))
			update_note_display(r, c)

		"note":
			if entry["was_added"]:
				clear_note(r, c, entry["number"])
			else:
				set_note(r, c, entry["number"])
			update_note_display(r, c)

	g.undo_btn.disabled = undo_stack.is_empty()
	update_number_pad()
	g.refresh_board_styles()
	g.save_mgr.request_save()

func on_delete_pressed() -> void:
	if g.selected_button == null:
		return
	if g.custom.is_creating_puzzle:
		var r = g.selected_button.get_meta("row")
		var c = g.selected_button.get_meta("col")
		if g.player_board[r][c] != 0:
			g.player_board[r][c] = 0
			g.selected_button.text = ""
			g._apply_cell_color(g.selected_button, "")
			g.refresh_board_styles()
			g.save_mgr.request_save()
		return
	if g.selected_button.get_meta("is_locked", false):
		return

	var r = g.selected_button.get_meta("row")
	var c = g.selected_button.get_meta("col")

	var prev_value = g.player_board[r][c]
	var prev_notes = notes[r][c]
	var prev_origin = g.selected_button.get_meta("origin", "")

	if prev_value == 0 and prev_notes == 0:
		return

	if notes[r][c] != 0:
		notes[r][c] = 0
		update_note_display(r, c)

	if g.player_board[r][c] != 0:
		g.player_board[r][c] = 0
		g.selected_button.text = ""
		g._apply_cell_color(g.selected_button, "")
		update_number_pad()
		g.refresh_board_styles()

	undo_stack.append({
		"type": "erase",
		"row": r,
		"col": c,
		"prev_value": prev_value,
		"prev_notes": prev_notes,
		"prev_origin": prev_origin,
	})
	if undo_stack.size() > g.UNDO_LIMIT:
		undo_stack.pop_front()
	g.undo_btn.disabled = false
	g.save_mgr.request_save()

func on_number_pressed(number: int) -> void:
	if g.selected_button == null:
		return
	if g.custom.is_creating_puzzle:
		var r = g.selected_button.get_meta("row")
		var c = g.selected_button.get_meta("col")
		if g.player_board[r][c] == number:
			g.player_board[r][c] = 0
			g.selected_button.text = ""
			g._apply_cell_color(g.selected_button, "")
		else:
			g.player_board[r][c] = number
			g.selected_button.text = str(number)
			g._apply_cell_color(g.selected_button, "initial")
		g.refresh_board_styles()
		g.save_mgr.request_save()
		return
	if g.selected_button.get_meta("is_locked", false):
		return

	var r = g.selected_button.get_meta("row")
	var c = g.selected_button.get_meta("col")

	if notes_mode:
		if g.player_board[r][c] != 0:
			return
		if not g.timer_started:
			g.timer_started = true
			g.timer_running = true
		var was_added : bool = not has_note(r, c, number)
		toggle_note(r, c, number)
		undo_stack.append({
			"type": "note",
			"row": r,
			"col": c,
			"number": number,
			"was_added": was_added,
		})
		if undo_stack.size() > g.UNDO_LIMIT:
			undo_stack.pop_front()
		g.undo_btn.disabled = false
		update_note_display(r, c)
		g.save_mgr.request_save()
		return

	if not g.timer_started:
		g.timer_started = true
		g.timer_running = true

	var prev_value = g.player_board[r][c]
	var prev_notes = notes[r][c]
	var prev_origin = g.selected_button.get_meta("origin", "")

	clear_all_notes(r, c)
	update_note_display(r, c)

	g.player_board[r][c] = number
	g.selected_button.text = str(number)
	var was_mistake : bool = (g.solution_board[r][c] != number)
	if not was_mistake:
		g.remaining_cells -= 1
		g.selected_button.set_meta("is_locked", true)
		g._apply_cell_color(g.selected_button, "player")
		g.animator.animate_pop(g.selected_button, g.theme_mgr.flash_color())
	else:
		g._apply_cell_color(g.selected_button, "wrong")
		g.animator.animate_shake(g.selected_button)
		mistakes += 1
		g.mistakes_label.text = "Mistakes: %d/%d" % [mistakes, g.LIFE_LIMIT]
		if mistakes >= g.LIFE_LIMIT:
			g.timer_running = false
			g.overlay_mgr.lose_overlay.visible = true
			g.save_mgr.clear()
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
	if undo_stack.size() > g.UNDO_LIMIT:
		undo_stack.pop_front()
	g.undo_btn.disabled = false

	update_number_pad()
	g.refresh_board_styles()
	var anim_duration := 0.0
	if not was_mistake:
		anim_duration = g.animator.check_group_completions(r, c, g.player_board, g.solution_board, g.buttons, g.theme_mgr.flash_color())
	check_win(anim_duration)
	if not g.overlay_mgr.win_overlay.visible:
		g.save_mgr.request_save()

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
		if has_note(peer.x, peer.y, number):
			clear_note(peer.x, peer.y, number)
			cleared.append({"row": peer.x, "col": peer.y, "number": number})
			update_note_display(peer.x, peer.y)

	return cleared

func check_win(delay := 0.0) -> void:
	if g.remaining_cells > 0:
		return
	g.timer_running = false

	var mins := int(g.elapsed_time) / 60
	var secs := int(g.elapsed_time) % 60
	g.overlay_mgr.win_time_label.text = "Time: %02d:%02d" % [mins, secs]
	g.overlay_mgr.win_mistakes_label.text = "Mistakes: %d/%d" % [mistakes, g.LIFE_LIMIT]

	var gold := Color(0.9, 0.75, 0.2) if g.theme_mgr.dark_mode else Color(0.7, 0.5, 0.0)

	var is_best := false
	if g.current_difficulty != "":
		g.stats_mgr.init_stats()
		var prev_best := float(g.stats_mgr.stats[g.current_difficulty].get("best_time", -1.0))
		is_best = prev_best < 0 or g.elapsed_time < prev_best
		g.stats_mgr.record_game_won(g.current_difficulty, g.elapsed_time)

	g.overlay_mgr.win_best_label.visible = is_best
	if is_best:
		g.overlay_mgr.win_best_label.text = "New Best Time!"
		g.overlay_mgr.win_best_label.add_theme_color_override("font_color", gold)

	if g.is_daily_game:
		var today = g._get_today_date_str()
		var yesterday = g._get_yesterday_date_str()
		g.stats_mgr.record_daily_won(today, yesterday, g.elapsed_time)
		var streak = g.stats_mgr.get_daily_streak(today, yesterday)
		g.overlay_mgr.win_streak_label.text = "Streak: %d %s" % [streak, "day" if streak == 1 else "days"]
		g.overlay_mgr.win_streak_label.add_theme_color_override("font_color", gold)
		g.overlay_mgr.win_streak_label.visible = true
		var best_s = g.stats_mgr.get_daily_best_streak()
		if streak >= best_s and streak > 1:
			g.overlay_mgr.win_best_streak_label.text = "New Best Streak!"
			g.overlay_mgr.win_best_streak_label.add_theme_color_override("font_color", gold)
			g.overlay_mgr.win_best_streak_label.visible = true
		else:
			g.overlay_mgr.win_best_streak_label.visible = false
	else:
		g.overlay_mgr.win_streak_label.visible = false
		g.overlay_mgr.win_best_streak_label.visible = false

	g.save_mgr.clear()
	if delay > 0.0:
		var tween = g.create_tween()
		tween.tween_interval(delay)
		tween.tween_callback(func(): g.animator.show_win_overlay(g.overlay_mgr.win_overlay, g.overlay_mgr.win_content))
	else:
		g.animator.show_win_overlay(g.overlay_mgr.win_overlay, g.overlay_mgr.win_content)
