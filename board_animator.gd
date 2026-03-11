class_name BoardAnimator
extends RefCounted

const ANIM_POP_SCALE := 1.25
const ANIM_POP_DURATION := 0.25
const ANIM_GROUP_SCALE := 1.12
const ANIM_GROUP_STAGGER := 0.03
const ANIM_GROUP_DURATION := 0.3
const ANIM_SHAKE_OFFSET := 6.0
const ANIM_SHAKE_STEP := 0.04
const ANIM_OVERLAY_FADE := 0.3
const ANIM_OVERLAY_SCALE_START := 0.7
const ANIM_OVERLAY_SCALE_DURATION := 0.4

var _host: Node

func setup(host: Node) -> void:
	_host = host

func check_group_completions(row: int, col: int, player_board: Array, solution_board: Array, buttons: Array[Array], flash: Color) -> float:
	var row_complete := true
	for c in range(SudokuSolver.SIZE):
		if player_board[row][c] != solution_board[row][c]:
			row_complete = false
			break

	var col_complete := true
	for r in range(SudokuSolver.SIZE):
		if player_board[r][col] != solution_board[r][col]:
			col_complete = false
			break

	var box_r := (row / SudokuSolver.BOX_SIZE) * SudokuSolver.BOX_SIZE
	var box_c := (col / SudokuSolver.BOX_SIZE) * SudokuSolver.BOX_SIZE
	var box_complete := true
	for r in range(box_r, box_r + SudokuSolver.BOX_SIZE):
		for c in range(box_c, box_c + SudokuSolver.BOX_SIZE):
			if player_board[r][c] != solution_board[r][c]:
				box_complete = false
				break
		if not box_complete:
			break

	var cells_to_animate := {}
	if row_complete:
		for c in range(SudokuSolver.SIZE):
			cells_to_animate[Vector2i(row, c)] = true
	if col_complete:
		for r in range(SudokuSolver.SIZE):
			cells_to_animate[Vector2i(r, col)] = true
	if box_complete:
		for r in range(box_r, box_r + SudokuSolver.BOX_SIZE):
			for c in range(box_c, box_c + SudokuSolver.BOX_SIZE):
				cells_to_animate[Vector2i(r, c)] = true

	if cells_to_animate.is_empty():
		return 0.0

	var origin := Vector2(buttons[row][col].global_position)
	var sorted_cells := cells_to_animate.keys()
	sorted_cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var da : float = buttons[a.x][a.y].global_position.distance_to(origin)
		var db : float = buttons[b.x][b.y].global_position.distance_to(origin)
		return da < db
	)

	var last_delay := 0.0
	for i in range(sorted_cells.size()):
		var cell : Vector2i = sorted_cells[i]
		var btn : Button = buttons[cell.x][cell.y]
		last_delay = i * ANIM_GROUP_STAGGER
		_animate_group_cell(btn, last_delay, flash)

	return last_delay + ANIM_GROUP_DURATION

func _animate_group_cell(btn: Button, delay: float, flash: Color) -> void:
	var tween := _host.create_tween()
	tween.tween_interval(delay)
	tween.tween_callback(func():
		btn.pivot_offset = btn.size / 2.0
		btn.z_index = 5
		btn.scale = Vector2(ANIM_GROUP_SCALE, ANIM_GROUP_SCALE)
		btn.modulate = flash
	)
	tween.tween_property(btn, "scale", Vector2.ONE, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	var mod_tween := _host.create_tween()
	mod_tween.tween_interval(delay)
	mod_tween.tween_property(btn, "modulate", Color.WHITE, 0.25).set_ease(Tween.EASE_OUT).set_delay(0.0)
	mod_tween.tween_callback(func(): btn.z_index = 0)

func animate_pop(btn: Button, flash: Color) -> void:
	btn.pivot_offset = btn.size / 2.0
	btn.z_index = 10
	btn.scale = Vector2(ANIM_POP_SCALE, ANIM_POP_SCALE)
	btn.modulate = flash
	var tween := _host.create_tween().set_parallel(true)
	tween.tween_property(btn, "scale", Vector2.ONE, ANIM_POP_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(btn, "modulate", Color.WHITE, 0.2).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(func(): btn.z_index = 0)

func animate_shake(btn: Button) -> void:
	var original_pos := btn.position
	var tween := _host.create_tween()
	tween.tween_property(btn, "position:x", original_pos.x + ANIM_SHAKE_OFFSET, ANIM_SHAKE_STEP)
	tween.tween_property(btn, "position:x", original_pos.x - ANIM_SHAKE_OFFSET, ANIM_SHAKE_STEP)
	tween.tween_property(btn, "position:x", original_pos.x + 4, ANIM_SHAKE_STEP)
	tween.tween_property(btn, "position:x", original_pos.x - 4, ANIM_SHAKE_STEP)
	tween.tween_property(btn, "position:x", original_pos.x, ANIM_SHAKE_STEP)

func show_win_overlay(win_overlay: ColorRect, win_content: VBoxContainer) -> void:
	win_overlay.visible = true
	win_overlay.modulate = Color(1, 1, 1, 0)
	win_content.pivot_offset = win_content.size / 2.0
	win_content.scale = Vector2(ANIM_OVERLAY_SCALE_START, ANIM_OVERLAY_SCALE_START)

	var tween := _host.create_tween().set_parallel(true)
	tween.tween_property(win_overlay, "modulate:a", 1.0, ANIM_OVERLAY_FADE).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(win_content, "scale", Vector2.ONE, ANIM_OVERLAY_SCALE_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
