class_name TutorialData
extends RefCounted

const SOLUTION := [
	[5,3,4,6,7,8,9,1,2],
	[6,7,2,1,9,5,3,4,8],
	[1,9,8,3,4,2,5,6,7],
	[8,5,9,7,6,1,4,2,3],
	[4,2,6,8,5,3,7,9,1],
	[7,1,3,9,2,4,8,5,6],
	[9,6,1,5,3,7,2,8,4],
	[2,8,7,4,1,9,6,3,5],
	[3,4,5,2,8,6,1,7,9],
]

const SOLUTION_B := [
	[3,1,6,5,7,8,4,9,2],
	[5,2,9,1,3,4,7,6,8],
	[4,8,7,6,2,9,5,3,1],
	[2,6,3,4,1,5,9,8,7],
	[9,7,4,8,6,3,1,2,5],
	[8,5,1,7,9,2,6,4,3],
	[1,3,8,9,4,7,2,5,6],
	[6,9,2,3,5,1,8,7,4],
	[7,4,5,2,8,6,3,1,9],
]

static func _compute_candidates(player: Array, _solution: Array) -> Dictionary:
	var result := {}
	for r in range(9):
		for c in range(9):
			if player[r][c] != 0:
				continue
			var used := 0
			for i in range(9):
				used |= (1 << player[r][i])
				used |= (1 << player[i][c])
			var br := (r / 3) * 3
			var bc := (c / 3) * 3
			for bi in range(3):
				for bj in range(3):
					used |= (1 << player[br + bi][bc + bj])
			var mask := 0
			for n in range(1, 10):
				if (used & (1 << n)) == 0:
					mask |= (1 << n)
			result[Vector2i(r, c)] = mask
	return result

static func get_lesson_count() -> int:
	return 11

static func get_lesson_info() -> Array:
	return [
		{"title": "Last Remaining Cell", "subtitle": "Find the missing number"},
		{"title": "Naked Single", "subtitle": "Eliminate all but one candidate"},
		{"title": "Hidden Single", "subtitle": "Find the only possible spot"},
		{"title": "Naked Pair", "subtitle": "Two cells, two candidates"},
		{"title": "Hidden Pair", "subtitle": "Two numbers, two cells"},
		{"title": "Pointing Pair", "subtitle": "Box points along a line"},
		{"title": "Box/Line Reduction", "subtitle": "Line confined to a box"},
		{"title": "Naked Triple", "subtitle": "Three cells, three candidates"},
		{"title": "Hidden Triple", "subtitle": "Three numbers, three cells"},
		{"title": "X-Wing", "subtitle": "Rectangle elimination pattern"},
		{"title": "Swordfish", "subtitle": "Three-row elimination pattern"},
	]

static func get_lesson(index: int) -> Dictionary:
	match index:
		0: return _last_remaining_cell()
		1: return _naked_single()
		2: return _hidden_single()
		3: return _naked_pair()
		4: return _hidden_pair()
		5: return _pointing_pair()
		6: return _box_line_reduction()
		7: return _naked_triple()
		8: return _hidden_triple()
		9: return _xwing()
		10: return _swordfish()
	return {}


static func _last_remaining_cell() -> Dictionary:
	var player := SOLUTION.duplicate(true)
	player[0][6] = 0

	return {
		"title": "Last Remaining Cell",
		"solution": SOLUTION.duplicate(true),
		"player": player,
		"steps": [
			{
				"text": "When a row, column, or box has 8 cells filled, the empty cell must contain the missing number.\n\nThis is the simplest technique.",
				"highlights": {},
				"action": "next",
			},
			{
				"text": "This row has 8 of 9 cells filled.\n\n1, 2, 3, 4, 5, 6, 7, and 8 are all present.",
				"highlights": {
					Vector2i(0,0): "related", Vector2i(0,1): "related",
					Vector2i(0,2): "related", Vector2i(0,3): "related",
					Vector2i(0,4): "related", Vector2i(0,5): "related",
					Vector2i(0,7): "related", Vector2i(0,8): "related",
				},
				"action": "next",
			},
			{
				"text": "The only missing number is 9.\n\nTap the empty cell.",
				"highlights": {
					Vector2i(0,0): "related", Vector2i(0,1): "related",
					Vector2i(0,2): "related", Vector2i(0,3): "related",
					Vector2i(0,4): "related", Vector2i(0,5): "related",
					Vector2i(0,7): "related", Vector2i(0,8): "related",
					Vector2i(0,6): "focus",
				},
				"action": "tap_cell",
				"target": Vector2i(0, 6),
			},
			{
				"text": "Now enter 9 to complete the row!",
				"highlights": {Vector2i(0,6): "focus"},
				"action": "place_number",
				"target": Vector2i(0, 6),
				"number": 9,
			},
			{
				"text": "Well done! This works for columns and boxes too.\n\nAlways scan for units with just one empty cell.",
				"highlights": {},
				"action": "next",
			},
		],
	}


static func _naked_single() -> Dictionary:
	var player := SOLUTION.duplicate(true)
	player[0][0] = 0  # target cell — answer is 5
	player[0][2] = 0  # open row slot (was 4)
	player[0][5] = 0  # open row slot (was 8)
	player[3][0] = 0  # open col slot (was 8)

	# Row 0 present: 1,2,3,6,7,9 → candidates from row: 4,5,8
	# Col 0 present: 1,2,3,4,6,7,9 → narrows to: 5,8
	# Box 0 present: 1,2,3,6,7,8,9 → narrows to: 5

	return {
		"title": "Naked Single",
		"solution": SOLUTION.duplicate(true),
		"player": player,
		"steps": [
			{
				"text": "When only one number is possible for a cell — after checking its row, column, and box — it must go there.",
				"highlights": {Vector2i(0,0): "focus"},
				"action": "next",
			},
			{
				"text": "Check the row: it has 1, 2, 3, 6, 7, and 9.\n\nOnly 4, 5, or 8 could go in this cell.",
				"highlights": {
					Vector2i(0,0): "focus",
					Vector2i(0,1): "related", Vector2i(0,3): "related",
					Vector2i(0,4): "related", Vector2i(0,6): "related",
					Vector2i(0,7): "related", Vector2i(0,8): "related",
				},
				"action": "next",
			},
			{
				"text": "Check the column: it has 1, 2, 3, 4, 6, 7, and 9.\n\nThat rules out 4. Now only 5 or 8.",
				"highlights": {
					Vector2i(0,0): "focus",
					Vector2i(1,0): "related", Vector2i(2,0): "related",
					Vector2i(4,0): "related", Vector2i(5,0): "related",
					Vector2i(6,0): "related", Vector2i(7,0): "related",
					Vector2i(8,0): "related",
				},
				"action": "next",
			},
			{
				"text": "Check the box: it already has 8.\n\nThat rules out 8. The only possibility is 5!\n\nTap the cell.",
				"highlights": {
					Vector2i(0,0): "focus",
					Vector2i(0,1): "related",
					Vector2i(1,0): "related", Vector2i(1,1): "related",
					Vector2i(1,2): "related",
					Vector2i(2,0): "related", Vector2i(2,1): "related",
					Vector2i(2,2): "related",
				},
				"action": "tap_cell",
				"target": Vector2i(0, 0),
			},
			{
				"text": "Enter 5.",
				"highlights": {Vector2i(0,0): "focus"},
				"action": "place_number",
				"target": Vector2i(0, 0),
				"number": 5,
			},
			{
				"text": "Excellent! Use notes to track candidates.\n\nA Naked Single is a cell with just one pencil mark.",
				"highlights": {},
				"action": "next",
			},
		],
	}


static func _hidden_single() -> Dictionary:
	var player := SOLUTION.duplicate(true)
	# Box 8 (rows 6-8, cols 6-8) — target: (6,7)=8
	player[6][6] = 0  # was 2
	player[6][7] = 0  # was 8 — target
	player[7][6] = 0  # was 6
	player[7][7] = 0  # was 3
	player[8][6] = 0  # was 1
	# Give (6,7) multiple candidates so it's not also a naked single
	player[6][3] = 0  # was 5 — opens row 6
	player[6][4] = 0  # was 3 — opens row 6
	player[3][7] = 0  # was 2 — opens col 7

	# (6,7) candidates: row{2,3,5,8} ∩ col{2,3,8} ∩ box{1,2,3,6,8} = {2,3,8}
	# 8 is hidden single in box 8:
	#   (6,6),(7,6),(8,6) blocked by 8 at (5,6) via col 6
	#   (7,7) blocked by 8 at (7,1) via row 7

	return {
		"title": "Hidden Single",
		"solution": SOLUTION.duplicate(true),
		"player": player,
		"steps": [
			{
				"text": "Sometimes a cell has multiple candidates, but one number can only fit in one cell within its box.\n\nThat number must go there.",
				"highlights": {},
				"action": "next",
			},
			{
				"text": "This box needs 1, 2, 3, 6, and 8.\n\nLet's figure out where 8 goes.",
				"highlights": {
					Vector2i(6,6): "focus", Vector2i(6,7): "focus",
					Vector2i(7,6): "focus", Vector2i(7,7): "focus",
					Vector2i(8,6): "focus",
				},
				"action": "next",
			},
			{
				"text": "Can 8 go here? No — this column already has 8.",
				"highlights": {
					Vector2i(6,6): "eliminated", Vector2i(7,6): "eliminated",
					Vector2i(8,6): "eliminated",
					Vector2i(5,6): "related",
				},
				"action": "next",
			},
			{
				"text": "Can 8 go here? No — this row already has 8.",
				"highlights": {
					Vector2i(6,6): "eliminated", Vector2i(7,6): "eliminated",
					Vector2i(8,6): "eliminated",
					Vector2i(7,7): "eliminated",
					Vector2i(7,1): "related",
				},
				"action": "next",
			},
			{
				"text": "8 can only go in one cell in this box!\n\nTap it.",
				"highlights": {
					Vector2i(6,7): "focus",
					Vector2i(6,6): "eliminated", Vector2i(7,6): "eliminated",
					Vector2i(8,6): "eliminated", Vector2i(7,7): "eliminated",
				},
				"action": "tap_cell",
				"target": Vector2i(6, 7),
			},
			{
				"text": "Enter 8.",
				"highlights": {Vector2i(6,7): "focus"},
				"action": "place_number",
				"target": Vector2i(6, 7),
				"number": 8,
			},
			{
				"text": "Great work! For each box, ask: where can this number go?\n\nIf only one spot — that's a Hidden Single.",
				"highlights": {},
				"action": "next",
			},
		],
	}


static func _naked_pair() -> Dictionary:
	var player := SOLUTION.duplicate(true)
	# Row 0 pair cells + supporting removals
	player[0][0] = 0  # 5 — pair cell A
	player[0][1] = 0  # 3 — pair cell B
	player[0][6] = 0  # 9 — affected cell
	player[5][0] = 0  # 7
	player[8][0] = 0  # 3
	player[3][1] = 0  # 5
	player[7][1] = 0  # 8
	player[2][6] = 0  # 5
	player[4][6] = 0  # 7

	# Candidates: (0,0)={3,5} (0,1)={3,5} (0,6)={5,9}

	return {
		"title": "Naked Pair",
		"solution": SOLUTION.duplicate(true),
		"player": player,
		"steps": [
			{
				"text": "When two cells in a row, column, or box share the exact same two candidates, those numbers must go in those cells.\n\nRemove them from all other cells in the unit.",
				"highlights": {},
				"action": "next",
			},
			{
				"text": "Look at row 1. Three cells are empty.\n\nHere are their candidates.",
				"highlights": {},
				"set_notes": {
					Vector2i(0,0): 40, Vector2i(0,1): 40,
					Vector2i(0,6): 544,
				},
				"action": "next",
			},
			{
				"text": "These two cells both have exactly {3, 5} — a Naked Pair!\n\nOne gets 3, the other gets 5. We don't know which yet.",
				"highlights": {
					Vector2i(0,0): "focus", Vector2i(0,1): "focus",
				},
				"action": "next",
			},
			{
				"text": "This cell has {5, 9}. Since 5 must go in one of the pair cells, we can remove 5 here.",
				"highlights": {
					Vector2i(0,0): "focus", Vector2i(0,1): "focus",
					Vector2i(0,6): "eliminated",
				},
				"action": "next",
			},
			{
				"text": "After removing 5, only 9 remains!\n\nTap the cell.",
				"highlights": {Vector2i(0,6): "focus"},
				"set_notes": {Vector2i(0,6): 512},
				"action": "tap_cell",
				"target": Vector2i(0, 6),
			},
			{
				"text": "Enter 9.",
				"highlights": {Vector2i(0,6): "focus"},
				"action": "place_number",
				"target": Vector2i(0, 6),
				"number": 9,
			},
			{
				"text": "Naked Pairs let you eliminate candidates even when you can't place a number directly.\n\nLook for two cells with the same two candidates.",
				"highlights": {},
				"action": "next",
			},
		],
	}


static func _hidden_pair() -> Dictionary:
	var player := SOLUTION.duplicate(true)
	# Empty all of box 4 + supporting cells
	for c in range(3, 6):
		player[3][c] = 0
		player[4][c] = 0
		player[5][c] = 0
	player[3][0] = 0; player[3][1] = 0; player[3][2] = 0; player[3][8] = 0
	player[4][0] = 0; player[4][2] = 0; player[4][8] = 0
	player[5][0] = 0; player[5][6] = 0
	player[0][3] = 0; player[8][3] = 0
	player[2][4] = 0; player[8][4] = 0
	player[1][5] = 0; player[8][5] = 0

	# Box 4 candidates:
	# (3,3)={6,7,8,9}=960  (3,4)={5,6,8}=352  (3,5)={1,3,5,6}=106
	# (4,3)={6,8}=320      (4,4)={4,5,6,8}=368 (4,5)={1,3,4,5,6}=122
	# (5,3)={2,7,8,9}=900  (5,4)={2,4,8}=276   (5,5)={4}=16
	# Hidden pair {7,9} at (3,3) and (5,3)

	var box4_notes := {
		Vector2i(3,3): 960, Vector2i(3,4): 352, Vector2i(3,5): 106,
		Vector2i(4,3): 320, Vector2i(4,4): 368, Vector2i(4,5): 122,
		Vector2i(5,3): 900, Vector2i(5,4): 276, Vector2i(5,5): 16,
	}

	return {
		"title": "Hidden Pair",
		"solution": SOLUTION.duplicate(true),
		"player": player,
		"steps": [
			{
				"text": "When two numbers only appear as candidates in the same two cells of a unit, those cells must hold those numbers.\n\nRemove all other candidates from them.",
				"highlights": {},
				"action": "next",
			},
			{
				"text": "Here are the candidates for every empty cell in this box.",
				"highlights": {},
				"set_notes": box4_notes,
				"action": "next",
			},
			{
				"text": "Numbers 7 and 9 only appear in these two cells.\n\nThey must contain 7 and 9!",
				"highlights": {
					Vector2i(3,3): "focus", Vector2i(5,3): "focus",
					Vector2i(3,4): "related", Vector2i(3,5): "related",
					Vector2i(4,3): "related", Vector2i(4,4): "related",
					Vector2i(4,5): "related", Vector2i(5,4): "related",
					Vector2i(5,5): "related",
				},
				"action": "next",
			},
			{
				"text": "These cells also have other candidates (6, 8 and 2, 8).\n\nSince 7 and 9 must go here, remove everything else.",
				"highlights": {
					Vector2i(3,3): "focus", Vector2i(5,3): "focus",
				},
				"action": "next",
			},
			{
				"text": "After removing extras, look at the box again. Number 2 can now only go in one cell!",
				"highlights": {
					Vector2i(3,3): "related", Vector2i(5,3): "related",
					Vector2i(5,4): "focus",
				},
				"set_notes": {
					Vector2i(3,3): 640, Vector2i(5,3): 640,
				},
				"action": "next",
			},
			{
				"text": "Tap the cell where 2 must go.",
				"highlights": {Vector2i(5,4): "focus"},
				"action": "tap_cell",
				"target": Vector2i(5, 4),
			},
			{
				"text": "Enter 2.",
				"highlights": {Vector2i(5,4): "focus"},
				"action": "place_number",
				"target": Vector2i(5, 4),
				"number": 2,
			},
		],
	}


static func _pointing_pair() -> Dictionary:
	var player := SOLUTION.duplicate(true)
	# 5 in box 0 only in row 0 → eliminate from row 0 outside box 0
	player[0][0] = 0  # 5
	player[0][1] = 0  # 3
	player[0][6] = 0  # 9
	player[0][7] = 0  # 1
	player[8][0] = 0  # 3
	player[3][1] = 0  # 5
	player[2][6] = 0  # 5
	player[4][6] = 0  # 7
	player[3][7] = 0  # 2
	player[5][7] = 0  # 5

	# (0,0)={3,5}=40  (0,1)={3,5}=40
	# (0,6)={5,9}=544  (0,7)={1,5}=34
	# 5 in box 0 at (0,0) and (0,1) only — both in row 0

	return {
		"title": "Pointing Pair",
		"solution": SOLUTION.duplicate(true),
		"player": player,
		"steps": [
			{
				"text": "When a candidate in a box can only go in one row, it must be in that row.\n\nRemove it from the rest of that row outside the box.",
				"highlights": {},
				"action": "next",
			},
			{
				"text": "In this box, look at where 5 can go.\n\n5 only appears in these two cells — both in row 1.",
				"highlights": {
					Vector2i(0,0): "focus", Vector2i(0,1): "focus",
				},
				"set_notes": {
					Vector2i(0,0): 40, Vector2i(0,1): 40,
					Vector2i(0,6): 544, Vector2i(0,7): 34,
				},
				"action": "next",
			},
			{
				"text": "Since 5 must be in this row inside the box, it can't be anywhere else in row 1.",
				"highlights": {
					Vector2i(0,0): "focus", Vector2i(0,1): "focus",
					Vector2i(0,6): "eliminated", Vector2i(0,7): "eliminated",
				},
				"action": "next",
			},
			{
				"text": "Remove 5 from these cells outside the box.",
				"highlights": {
					Vector2i(0,6): "eliminated", Vector2i(0,7): "eliminated",
				},
				"set_notes": {
					Vector2i(0,6): 512, Vector2i(0,7): 2,
				},
				"action": "next",
			},
			{
				"text": "Now this cell has only one candidate: 9!\n\nTap it.",
				"highlights": {Vector2i(0,6): "focus"},
				"action": "tap_cell",
				"target": Vector2i(0, 6),
			},
			{
				"text": "Enter 9.",
				"highlights": {Vector2i(0,6): "focus"},
				"action": "place_number",
				"target": Vector2i(0, 6),
				"number": 9,
			},
			{
				"text": "A Pointing Pair narrows candidates by using box constraints to eliminate along a row or column.",
				"highlights": {},
				"action": "next",
			},
		],
	}


static func _box_line_reduction() -> Dictionary:
	var player := SOLUTION.duplicate(true)
	# 5 in row 0 only in box 0 → eliminate from box 0 outside row 0
	player[0][0] = 0  # 5
	player[0][1] = 0  # 3
	player[0][2] = 0  # 4
	player[0][6] = 0  # 9
	player[1][0] = 0  # 6
	player[1][5] = 0  # 5
	player[1][6] = 0  # 3
	player[2][0] = 0  # 1
	player[2][1] = 0  # 9
	player[3][1] = 0  # 5
	player[6][0] = 0  # 9

	# (0,0)={5,9}=544  (0,1)={3,5,9}=552  (0,2)={4}=16
	# (1,0)={5,6}=96
	# 5 in row 0 only at (0,0) and (0,1) — both in box 0

	return {
		"title": "Box/Line Reduction",
		"solution": SOLUTION.duplicate(true),
		"player": player,
		"steps": [
			{
				"text": "The reverse of Pointing Pair: when a candidate in a row appears only inside one box, it must be in that box.\n\nRemove it from other cells in the box.",
				"highlights": {},
				"action": "next",
			},
			{
				"text": "In row 1, candidate 5 only appears inside this box.",
				"highlights": {
					Vector2i(0,0): "focus", Vector2i(0,1): "focus",
				},
				"set_notes": {
					Vector2i(0,0): 544, Vector2i(0,1): 552,
					Vector2i(1,0): 96,
				},
				"action": "next",
			},
			{
				"text": "Since 5 must go in row 1 within this box, we can remove 5 from other box cells.",
				"highlights": {
					Vector2i(0,0): "focus", Vector2i(0,1): "focus",
					Vector2i(1,0): "eliminated",
				},
				"action": "next",
			},
			{
				"text": "This cell also had 5 as a candidate. Remove it.",
				"highlights": {Vector2i(1,0): "eliminated"},
				"set_notes": {Vector2i(1,0): 64},
				"action": "next",
			},
			{
				"text": "Now only 6 remains!\n\nTap the cell.",
				"highlights": {Vector2i(1,0): "focus"},
				"action": "tap_cell",
				"target": Vector2i(1, 0),
			},
			{
				"text": "Enter 6.",
				"highlights": {Vector2i(1,0): "focus"},
				"action": "place_number",
				"target": Vector2i(1, 0),
				"number": 6,
			},
			{
				"text": "Box/Line Reduction uses row constraints to eliminate within a box — the reverse of Pointing Pair.",
				"highlights": {},
				"action": "next",
			},
		],
	}


static func _naked_triple() -> Dictionary:
	var player := SOLUTION.duplicate(true)
	# Triple {1,5,6} in col 0 at rows 0,1,2
	# Remove from col 0
	for r in [0,1,2,3,5,6]:
		player[r][0] = 0
	# Remove from cols 3,6 for same rows
	for r in [0,1,2,3,5,6]:
		player[r][3] = 0
		player[r][6] = 0
	# Remove from col 8 for rows 0-2
	for r in [0,1,2]:
		player[r][8] = 0
	# Remove from col 1 for rows 3,5,6
	for r in [3,5,6]:
		player[r][1] = 0

	# Col 0 candidates:
	# (0,0)={5,6}=96  (1,0)={1,6}=66  (2,0)={1,5}=34
	# (3,0)={5,7,8}=416  (5,0)={1,7,8}=386  (6,0)={6,9}=576
	# Triple: (0,0),(1,0),(2,0) → {1,5,6}
	# Eliminate 5 from (3,0), 1 from (5,0), 6 from (6,0)
	# (6,0) becomes {9}

	return {
		"title": "Naked Triple",
		"solution": SOLUTION.duplicate(true),
		"player": player,
		"steps": [
			{
				"text": "When three cells in a unit contain only three numbers between them, those numbers must go in those cells.\n\nRemove them from all other cells in the unit.",
				"highlights": {},
				"action": "next",
			},
			{
				"text": "Look at this column. Six cells are empty.\n\nHere are their candidates.",
				"highlights": {},
				"set_notes": {
					Vector2i(0,0): 96, Vector2i(1,0): 66, Vector2i(2,0): 34,
					Vector2i(3,0): 416, Vector2i(5,0): 386, Vector2i(6,0): 576,
				},
				"action": "next",
			},
			{
				"text": "These three cells contain only {1, 5, 6} between them.\n\n{5,6}, {1,6}, and {1,5} — that's a Naked Triple!",
				"highlights": {
					Vector2i(0,0): "focus", Vector2i(1,0): "focus",
					Vector2i(2,0): "focus",
				},
				"action": "next",
			},
			{
				"text": "Three numbers, three cells — each number goes in exactly one of them.\n\nRemove 1, 5, and 6 from all other cells in this column.",
				"highlights": {
					Vector2i(0,0): "focus", Vector2i(1,0): "focus",
					Vector2i(2,0): "focus",
					Vector2i(3,0): "eliminated", Vector2i(5,0): "eliminated",
					Vector2i(6,0): "eliminated",
				},
				"action": "next",
			},
			{
				"text": "After eliminating, this cell has only 9 left!",
				"highlights": {Vector2i(6,0): "focus"},
				"set_notes": {
					Vector2i(3,0): 384, Vector2i(5,0): 384,
					Vector2i(6,0): 512,
				},
				"action": "next",
			},
			{
				"text": "Tap the cell.",
				"highlights": {Vector2i(6,0): "focus"},
				"action": "tap_cell",
				"target": Vector2i(6, 0),
			},
			{
				"text": "Enter 9.",
				"highlights": {Vector2i(6,0): "focus"},
				"action": "place_number",
				"target": Vector2i(6, 0),
				"number": 9,
			},
			{
				"text": "Naked Triples work like Naked Pairs but with three cells.\n\nEach cell doesn't need all three numbers — just a subset.",
				"highlights": {},
				"action": "next",
			},
		],
	}


static func _hidden_triple() -> Dictionary:
	var player := SOLUTION.duplicate(true)
	# Hidden triple {2,3,7} at (0,1),(1,1),(1,2) in box 0
	# Remove all of box 0
	for r in range(3):
		for c in range(3):
			player[r][c] = 0
	# Remove from cols 6,7 for rows 0-2
	for r in range(3):
		player[r][6] = 0
		player[r][7] = 0
	# Remove from rows 3,6 cols 0-2
	for c in range(3):
		player[3][c] = 0
		player[6][c] = 0

	# Box 0 candidates:
	# (0,0)={1,5,9}=546  (0,1)={3,5,9}=552  (0,2)={1,4,9}=530
	# (1,0)={6}=64       (1,1)={3,6,7}=200   (1,2)={2,4}=20
	# (2,0)={1,5,6,8,9}=866  (2,1)={5,6,9}=608  (2,2)={1,8,9}=770
	# Hidden triple {2,3,7}: 2 in (1,2), 3 in (0,1)+(1,1), 7 in (1,1)
	# All confined to cells (0,1),(1,1),(1,2)
	# Eliminate extras: (0,1) {5,9}→{3}, (1,1) {6}→{3,7}, (1,2) {4}→{2}

	var box0_notes := {
		Vector2i(0,0): 546, Vector2i(0,1): 552, Vector2i(0,2): 530,
		Vector2i(1,0): 64, Vector2i(1,1): 200, Vector2i(1,2): 20,
		Vector2i(2,0): 866, Vector2i(2,1): 608, Vector2i(2,2): 770,
	}

	return {
		"title": "Hidden Triple",
		"solution": SOLUTION.duplicate(true),
		"player": player,
		"steps": [
			{
				"text": "When three numbers only appear in three cells of a unit, those cells must hold those numbers.\n\nRemove all other candidates.",
				"highlights": {},
				"action": "next",
			},
			{
				"text": "Here are the candidates for this box.",
				"highlights": {},
				"set_notes": box0_notes,
				"action": "next",
			},
			{
				"text": "Numbers 2, 3, and 7 only appear in these three cells.\n\nThey must contain 2, 3, and 7!",
				"highlights": {
					Vector2i(0,1): "focus", Vector2i(1,1): "focus",
					Vector2i(1,2): "focus",
					Vector2i(0,0): "related", Vector2i(0,2): "related",
					Vector2i(2,0): "related", Vector2i(2,1): "related",
					Vector2i(2,2): "related",
				},
				"action": "next",
			},
			{
				"text": "These cells also have other candidates (5, 9, 6, 4).\n\nSince only 2, 3, 7 belong here, remove the rest.",
				"highlights": {
					Vector2i(0,1): "focus", Vector2i(1,1): "focus",
					Vector2i(1,2): "focus",
				},
				"action": "next",
			},
			{
				"text": "After removing extras, this cell has only one candidate: 3!",
				"highlights": {
					Vector2i(0,1): "focus",
					Vector2i(1,1): "related", Vector2i(1,2): "related",
				},
				"set_notes": {
					Vector2i(0,1): 8, Vector2i(1,1): 136,
					Vector2i(1,2): 4,
				},
				"action": "next",
			},
			{
				"text": "Tap the cell.",
				"highlights": {Vector2i(0,1): "focus"},
				"action": "tap_cell",
				"target": Vector2i(0, 1),
			},
			{
				"text": "Enter 3.",
				"highlights": {Vector2i(0,1): "focus"},
				"action": "place_number",
				"target": Vector2i(0, 1),
				"number": 3,
			},
			{
				"text": "Hidden Triples are hard to spot because the cells have extra candidates hiding the pattern.\n\nLook for three numbers confined to three cells.",
				"highlights": {},
				"action": "next",
			},
		],
	}


static func _xwing() -> Dictionary:
	var player := SOLUTION_B.duplicate(true)
	# X-Wing: candidate 8, rows 2,5, cols 0,1
	var removes := [
		[0,0],[0,1],[0,3],[0,4],[0,6],[0,7],[0,8],
		[1,0],[1,1],[1,2],[1,3],
		[2,0],[2,1],[2,2],[2,3],[2,4],[2,5],[2,6],[2,7],
		[3,1],[3,2],[3,3],[3,6],
		[4,1],[4,3],[4,5],
		[5,0],[5,1],[5,2],[5,5],[5,6],[5,7],[5,8],
		[6,0],[6,4],[6,7],[6,8],
		[7,0],[7,2],[7,3],[7,4],[7,5],[7,6],[7,7],
		[8,0],[8,3],[8,4],[8,5],[8,6],[8,7],
	]
	for rc in removes:
		player[rc[0]][rc[1]] = 0

	# X-Wing pattern (8 in exactly 2 cells per row, same cols):
	# Row 2: (2,0)={3,4,5,7,8}  (2,1)={2,5,7,8}
	# Row 5: (5,0)={1,3,5,6,8}  (5,1)={1,5,6,8}
	# 8 in cols 0,1 → eliminate 8 from other col 0,1 cells
	# Only elimination: (4,1)={7,8} → {7}

	return {
		"title": "X-Wing",
		"solution": SOLUTION_B.duplicate(true),
		"player": player,
		"steps": [
			{
				"text": "When a candidate appears in exactly two spots in two different rows, and those spots share the same two columns, it forms an X-Wing.\n\nEliminate that candidate from the rest of those columns.",
				"highlights": {},
				"action": "next",
			},
			{
				"text": "In row 3, candidate 8 can only go in two places.",
				"highlights": {
					Vector2i(2,0): "focus", Vector2i(2,1): "focus",
				},
				"set_notes": {
					Vector2i(2,0): 440, Vector2i(2,1): 420,
					Vector2i(5,0): 362, Vector2i(5,1): 354,
					Vector2i(4,1): 384,
				},
				"action": "next",
			},
			{
				"text": "In row 6, candidate 8 also appears in exactly two places — and they line up in the same columns!",
				"highlights": {
					Vector2i(2,0): "focus", Vector2i(2,1): "focus",
					Vector2i(5,0): "focus", Vector2i(5,1): "focus",
				},
				"action": "next",
			},
			{
				"text": "These four cells form a rectangle.\n\n8 must appear once per row — so it covers both columns either way.",
				"highlights": {
					Vector2i(2,0): "focus", Vector2i(2,1): "focus",
					Vector2i(5,0): "focus", Vector2i(5,1): "focus",
				},
				"action": "next",
			},
			{
				"text": "Since 8 is accounted for in columns 1 and 2, remove it from other cells in those columns.",
				"highlights": {
					Vector2i(2,0): "focus", Vector2i(2,1): "focus",
					Vector2i(5,0): "focus", Vector2i(5,1): "focus",
					Vector2i(4,1): "eliminated",
				},
				"action": "next",
			},
			{
				"text": "After removing 8, this cell has only 7 left!",
				"highlights": {Vector2i(4,1): "focus"},
				"set_notes": {Vector2i(4,1): 128},
				"action": "next",
			},
			{
				"text": "Tap the cell.",
				"highlights": {Vector2i(4,1): "focus"},
				"action": "tap_cell",
				"target": Vector2i(4, 1),
			},
			{
				"text": "Enter 7.",
				"highlights": {Vector2i(4,1): "focus"},
				"action": "place_number",
				"target": Vector2i(4, 1),
				"number": 7,
			},
		],
	}


static func _swordfish() -> Dictionary:
	var player := SOLUTION_B.duplicate(true)
	# Swordfish: candidate 4, rows 1,2,3, cols 0,3,5
	var removes := [
		[0,0],[0,1],[0,2],[0,4],[0,5],[0,7],
		[1,0],[1,1],[1,3],[1,4],[1,5],[1,6],[1,7],[1,8],
		[2,0],[2,3],[2,4],[2,7],[2,8],
		[3,3],[3,4],[3,5],[3,6],[3,7],[3,8],
		[4,0],[4,2],[4,5],[4,6],[4,8],
		[5,0],[5,3],[5,4],[5,5],[5,8],
		[7,0],[7,1],[7,2],[7,3],[7,5],[7,6],[7,8],
		[8,0],[8,3],[8,4],[8,5],[8,8],
	]
	for rc in removes:
		player[rc[0]][rc[1]] = 0

	# Swordfish pattern (4 in 2-3 cells per row, same 3 cols):
	# Row 1: (1,0)={3,4,5,6}  (1,3)={1,2,3,4,6,7}  (1,5)={1,2,3,4,6,8}
	# Row 2: (2,0)={3,4,6}    (2,3)={1,2,3,4,6}
	# Row 3: (3,3)={1,4,7}    (3,5)={1,4,5}
	# 4 in cols 0,3,5 → eliminate from other cells in those cols
	# (4,0)={4,9}→{9}  (4,5)={1,3,4,5}→{1,3,5}

	return {
		"title": "Swordfish",
		"solution": SOLUTION_B.duplicate(true),
		"player": player,
		"steps": [
			{
				"text": "A Swordfish extends the X-Wing to three rows and three columns.\n\nIf a candidate is restricted to three columns across three rows, eliminate it from other cells in those columns.",
				"highlights": {},
				"action": "next",
			},
			{
				"text": "In row 2, candidate 4 appears in columns 1, 4, and 6.",
				"highlights": {
					Vector2i(1,0): "focus", Vector2i(1,3): "focus",
					Vector2i(1,5): "focus",
				},
				"set_notes": {
					Vector2i(1,0): 120, Vector2i(1,3): 222, Vector2i(1,5): 350,
					Vector2i(2,0): 88, Vector2i(2,3): 94,
					Vector2i(3,3): 146, Vector2i(3,5): 50,
					Vector2i(4,0): 528, Vector2i(4,5): 58,
				},
				"action": "next",
			},
			{
				"text": "In row 3, candidate 4 appears in columns 1 and 4.",
				"highlights": {
					Vector2i(1,0): "related", Vector2i(1,3): "related",
					Vector2i(1,5): "related",
					Vector2i(2,0): "focus", Vector2i(2,3): "focus",
				},
				"action": "next",
			},
			{
				"text": "In row 4, candidate 4 appears in columns 4 and 6.\n\nAll positions fall in the same three columns!",
				"highlights": {
					Vector2i(1,0): "related", Vector2i(1,3): "related",
					Vector2i(1,5): "related",
					Vector2i(2,0): "related", Vector2i(2,3): "related",
					Vector2i(3,3): "focus", Vector2i(3,5): "focus",
				},
				"action": "next",
			},
			{
				"text": "4 must appear once per row and once per column in this pattern.\n\nRemove 4 from other cells in columns 1, 4, and 6.",
				"highlights": {
					Vector2i(1,0): "focus", Vector2i(1,3): "focus",
					Vector2i(1,5): "focus",
					Vector2i(2,0): "focus", Vector2i(2,3): "focus",
					Vector2i(3,3): "focus", Vector2i(3,5): "focus",
					Vector2i(4,0): "eliminated", Vector2i(4,5): "eliminated",
				},
				"action": "next",
			},
			{
				"text": "After removing 4, this cell has only 9 left!",
				"highlights": {Vector2i(4,0): "focus"},
				"set_notes": {
					Vector2i(4,0): 512, Vector2i(4,5): 42,
				},
				"action": "next",
			},
			{
				"text": "Tap the cell.",
				"highlights": {Vector2i(4,0): "focus"},
				"action": "tap_cell",
				"target": Vector2i(4, 0),
			},
			{
				"text": "Enter 9.",
				"highlights": {Vector2i(4,0): "focus"},
				"action": "place_number",
				"target": Vector2i(4, 0),
				"number": 9,
			},
		],
	}
