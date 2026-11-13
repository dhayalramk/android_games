extends RefCounted
## Soft-but-clever AI — blocks wins, takes wins, likes power cells.

enum Power { NONE, BOMB, WARP, FREEZE }

static func pick_move(board: Array, powers: Array, ai_mark: int, player_mark: int) -> int:
	# board: 9 ints, 0 empty, 1 X, 2 O
	var win := _find_winning_move(board, ai_mark)
	if win >= 0:
		return win
	var block := _find_winning_move(board, player_mark)
	if block >= 0:
		return block
	# Prefer power cells that help
	var powered: Array[int] = []
	var empties: Array[int] = []
	for i in range(9):
		if board[i] != 0:
			continue
		empties.append(i)
		if powers[i] != Power.NONE:
			powered.append(i)
	if powered.size() > 0 and randf() < 0.7:
		return powered[randi() % powered.size()]
	# Center / corners
	if board[4] == 0:
		return 4
	var corners := [0, 2, 6, 8]
	corners.shuffle()
	for c in corners:
		if board[c] == 0:
			return c
	if empties.is_empty():
		return -1
	return empties[randi() % empties.size()]

static func _find_winning_move(board: Array, mark: int) -> int:
	var lines := [
		[0, 1, 2], [3, 4, 5], [6, 7, 8],
		[0, 3, 6], [1, 4, 7], [2, 5, 8],
		[0, 4, 8], [2, 4, 6],
	]
	for line in lines:
		var count := 0
		var empty := -1
		for idx in line:
			if board[idx] == mark:
				count += 1
			elif board[idx] == 0:
				empty = idx
		if count == 2 and empty >= 0:
			return empty
	return -1
