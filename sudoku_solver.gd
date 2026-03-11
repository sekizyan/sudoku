class_name SudokuSolver
extends RefCounted

const SIZE := 9
const BOX_SIZE := 3

func generate_puzzle(cells_to_remove: int) -> Array:
	var solution := _create_empty_board()
	_fill_board(solution)

	var puzzle := solution.duplicate(true)
	var cells := []
	for r in range(SIZE):
		for c in range(SIZE):
			cells.append(Vector2i(r, c))
	cells.shuffle()

	var removed := 0
	for cell in cells:
		if removed >= cells_to_remove:
			break
		var backup = puzzle[cell.x][cell.y]
		puzzle[cell.x][cell.y] = 0
		var test = puzzle.duplicate(true)
		if _count_solutions(test) != 1:
			puzzle[cell.x][cell.y] = backup
		else:
			removed += 1

	return [solution, puzzle]

func _create_empty_board() -> Array:
	var board := []
	for r in range(SIZE):
		board.append([])
		for c in range(SIZE):
			board[r].append(0)
	return board

func build_constraints(b: Array) -> Array:
	var row_used := []
	var col_used := []
	var box_used := []
	for i in range(SIZE):
		row_used.append({})
		col_used.append({})
		box_used.append({})
	for r in range(SIZE):
		for c in range(SIZE):
			if b[r][c] != 0:
				var n = b[r][c]
				row_used[r][n] = true
				col_used[c][n] = true
				box_used[(r / BOX_SIZE) * BOX_SIZE + c / BOX_SIZE][n] = true
	return [row_used, col_used, box_used]

func _fill_board(b: Array) -> bool:
	var c = build_constraints(b)
	return _fill_recursive(b, c[0], c[1], c[2])

func _find_best_cell(b: Array, row_used: Array, col_used: Array, box_used: Array) -> Vector3i:
	var best_r := -1
	var best_c := -1
	var best_count := 10
	for r in range(SIZE):
		for c in range(SIZE):
			if b[r][c] == 0:
				var bi := (r / BOX_SIZE) * BOX_SIZE + c / BOX_SIZE
				var cnt := 0
				for n in range(1, 10):
					if not row_used[r].has(n) and not col_used[c].has(n) and not box_used[bi].has(n):
						cnt += 1
				if cnt < best_count:
					best_count = cnt
					best_r = r
					best_c = c
					if cnt <= 1:
						break
		if best_count <= 1:
			break
	return Vector3i(best_r, best_c, best_count)

func _fill_recursive(b: Array, row_used: Array, col_used: Array, box_used: Array) -> bool:
	var cell := _find_best_cell(b, row_used, col_used, box_used)
	if cell.x == -1:
		return true
	if cell.z == 0:
		return false
	var best_r := cell.x
	var best_c := cell.y
	var bi = (best_r / BOX_SIZE) * BOX_SIZE + best_c / BOX_SIZE
	var nums = range(1, 10)
	nums.shuffle()
	for n in nums:
		if not row_used[best_r].has(n) and not col_used[best_c].has(n) and not box_used[bi].has(n):
			b[best_r][best_c] = n
			row_used[best_r][n] = true
			col_used[best_c][n] = true
			box_used[bi][n] = true
			if _fill_recursive(b, row_used, col_used, box_used):
				return true
			b[best_r][best_c] = 0
			row_used[best_r].erase(n)
			col_used[best_c].erase(n)
			box_used[bi].erase(n)
	return false

func _count_solutions(b: Array, limit: int = 2) -> int:
	var c = build_constraints(b)
	return _count_recursive(b, c[0], c[1], c[2], limit)

func _count_recursive(b: Array, row_used: Array, col_used: Array, box_used: Array, limit: int) -> int:
	var cell := _find_best_cell(b, row_used, col_used, box_used)
	if cell.x == -1:
		return 1
	if cell.z == 0:
		return 0
	var best_r := cell.x
	var best_c := cell.y
	var bi = (best_r / BOX_SIZE) * BOX_SIZE + best_c / BOX_SIZE
	var count = 0
	for n in range(1, 10):
		if not row_used[best_r].has(n) and not col_used[best_c].has(n) and not box_used[bi].has(n):
			b[best_r][best_c] = n
			row_used[best_r][n] = true
			col_used[best_c][n] = true
			box_used[bi][n] = true
			count += _count_recursive(b, row_used, col_used, box_used, limit - count)
			b[best_r][best_c] = 0
			row_used[best_r].erase(n)
			col_used[best_c].erase(n)
			box_used[bi].erase(n)
			if count >= limit:
				return count
	return count
