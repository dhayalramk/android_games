extends Control
## Neon Tac Blitz — arcade tic-tac-toe with blitz timer + chaos powers.

const UI = preload("res://scripts/ui_style.gd")
const AIScript = preload("res://scripts/ai.gd")
const SfxScript = preload("res://scripts/sfx.gd")

const MARK_EMPTY := 0
const MARK_X := 1
const MARK_O := 2
const POWER_NONE := 0
const POWER_BOMB := 1
const POWER_WARP := 2
const POWER_FREEZE := 3

const TURN_TIME := 5.0
const POWER_SPAWN_CHANCE := 0.42

var board: Array = []  # 9 ints
var powers: Array = []  # 9 ints
var frozen: Array = []  # 9 bools — locked marks
var cells: Array = []  # Button nodes
var power_badges: Array = []  # Label overlays
var mark_labels: Array = []

var player_turn: bool = true
var game_over: bool = false
var in_menu: bool = true
var ult_ready: bool = false
var ult_armed: bool = false
var win_streak: int = 0
var match_wins: int = 0
var match_losses: int = 0
var turn_left: float = TURN_TIME
var ai_thinking: bool = false

var sfx: Node
var brand: Label
var status: Label
var timer_bar: ProgressBar
var streak_label: Label
var score_label: Label
var ult_btn: Button
var play_btn: Button
var menu_layer: Control
var board_wrap: GridContainer
var banner: Label
var flash: ColorRect
var tip: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sfx = SfxScript.new()
	add_child(sfx)
	_build_ui()
	_show_menu()

func _build_ui() -> void:
	# Atmosphere
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.06, 0.1)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var wash := ColorRect.new()
	wash.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	wash.offset_bottom = 340
	wash.color = Color(0.05, 0.55, 0.7, 0.18)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wash)

	var wash2 := ColorRect.new()
	wash2.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	wash2.offset_top = -280
	wash2.color = Color(1.0, 0.4, 0.15, 0.12)
	wash2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wash2)

	flash = ColorRect.new()
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(1, 1, 1, 0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 36)
	margin.add_theme_constant_override("margin_bottom", 28)
	add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	margin.add_child(col)

	brand = Label.new()
	brand.text = "NEON TAC"
	brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.label_outline(brand, Color(0.35, 0.95, 1.0), 42, Color(0.02, 0.15, 0.2, 0.85), 10)
	col.add_child(brand)

	var sub := Label.new()
	sub.text = "BLITZ"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.label_outline(sub, Color(1.0, 0.55, 0.2), 26, Color(0.2, 0.05, 0.0, 0.8), 7)
	col.add_child(sub)

	score_label = Label.new()
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.label_outline(score_label, Color(1, 0.95, 0.85), 16, Color(0, 0, 0, 0.55), 4)
	col.add_child(score_label)

	streak_label = Label.new()
	streak_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.label_outline(streak_label, Color(1.0, 0.85, 0.4), 15, Color(0, 0, 0, 0.5), 3)
	col.add_child(streak_label)

	status = Label.new()
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI.label_outline(status, Color(0.9, 0.95, 1.0), 18, Color(0, 0, 0, 0.55), 5)
	col.add_child(status)

	timer_bar = ProgressBar.new()
	timer_bar.max_value = TURN_TIME
	timer_bar.value = TURN_TIME
	timer_bar.show_percentage = false
	timer_bar.custom_minimum_size = Vector2(0, 14)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.25, 0.9, 1.0)
	fill.set_corner_radius_all(8)
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.12, 0.18)
	bg_style.set_corner_radius_all(8)
	timer_bar.add_theme_stylebox_override("fill", fill)
	timer_bar.add_theme_stylebox_override("background", bg_style)
	col.add_child(timer_bar)

	# Board
	var board_panel := PanelContainer.new()
	board_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_panel.add_theme_stylebox_override("panel", UI.panel(Color(0.07, 0.09, 0.14, 0.95), 24, Color(0.3, 0.85, 1.0, 0.35)))
	col.add_child(board_panel)

	var board_margin := MarginContainer.new()
	board_margin.add_theme_constant_override("margin_left", 12)
	board_margin.add_theme_constant_override("margin_right", 12)
	board_margin.add_theme_constant_override("margin_top", 12)
	board_margin.add_theme_constant_override("margin_bottom", 12)
	board_panel.add_child(board_margin)

	board_wrap = GridContainer.new()
	board_wrap.columns = 3
	board_wrap.add_theme_constant_override("h_separation", 10)
	board_wrap.add_theme_constant_override("v_separation", 10)
	board_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_margin.add_child(board_wrap)

	cells.clear()
	mark_labels.clear()
	power_badges.clear()
	for i in range(9):
		var cell := Button.new()
		cell.custom_minimum_size = Vector2(0, 150)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.focus_mode = Control.FOCUS_NONE
		cell.clip_text = true
		UI.apply_button(cell, Color(0.1, 0.13, 0.2), Color(0.35, 0.7, 0.9, 0.4), Color(1, 1, 1), 48)
		var idx := i
		cell.pressed.connect(func(): _on_cell(idx))
		board_wrap.add_child(cell)

		var overlay := Label.new()
		overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		overlay.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		overlay.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UI.label_outline(overlay, Color(0.4, 0.95, 1.0), 56, Color(0, 0, 0, 0.55), 8)
		cell.add_child(overlay)

		var badge := Label.new()
		badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		badge.offset_left = -70
		badge.offset_top = 6
		badge.offset_right = -8
		badge.offset_bottom = 34
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UI.label_outline(badge, Color(1.0, 0.85, 0.35), 14, Color(0, 0, 0, 0.6), 3)
		cell.add_child(badge)

		cells.append(cell)
		mark_labels.append(overlay)
		power_badges.append(badge)

	ult_btn = Button.new()
	ult_btn.text = "ULT  ×2 PLACE  (win streak 2)"
	ult_btn.custom_minimum_size = Vector2(0, 56)
	ult_btn.disabled = true
	UI.apply_button(ult_btn, Color(0.55, 0.2, 0.55), Color(1.0, 0.7, 1.0, 0.5), Color(1, 1, 1), 16)
	ult_btn.pressed.connect(_on_ult)
	col.add_child(ult_btn)

	tip = Label.new()
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI.label_outline(tip, Color(0.75, 0.88, 1.0, 0.95), 13, Color(0, 0, 0, 0.45), 3)
	tip.text = "BOMB clears neighbors · WARP extra mark · ICE locks a cell"
	col.add_child(tip)

	banner = Label.new()
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI.label_outline(banner, Color(1, 0.95, 0.75), 28, Color(0, 0, 0, 0.7), 8)
	banner.visible = false
	col.add_child(banner)

	var again := Button.new()
	again.name = "AgainBtn"
	again.text = "PLAY AGAIN"
	again.custom_minimum_size = Vector2(0, 58)
	again.visible = false
	UI.apply_button(again, Color(0.15, 0.7, 0.85), Color(0.7, 1.0, 1.0), Color(0.02, 0.08, 0.12), 22)
	again.pressed.connect(_start_round)
	col.add_child(again)

	# Menu overlay
	menu_layer = Control.new()
	menu_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(menu_layer)

	var menu_bg := ColorRect.new()
	menu_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_bg.color = Color(0.03, 0.05, 0.09, 0.92)
	menu_layer.add_child(menu_bg)

	var menu_col := VBoxContainer.new()
	menu_col.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	menu_col.offset_left = -260
	menu_col.offset_right = 260
	menu_col.offset_top = -220
	menu_col.offset_bottom = 220
	menu_col.add_theme_constant_override("separation", 14)
	menu_layer.add_child(menu_col)

	var m_brand := Label.new()
	m_brand.text = "NEON TAC"
	m_brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.label_outline(m_brand, Color(0.4, 0.95, 1.0), 48, Color(0.02, 0.12, 0.18, 0.9), 12)
	menu_col.add_child(m_brand)

	var m_sub := Label.new()
	m_sub.text = "BLITZ"
	m_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.label_outline(m_sub, Color(1.0, 0.55, 0.22), 30, Color(0.15, 0.04, 0, 0.85), 8)
	menu_col.add_child(m_sub)

	var blurb := Label.new()
	blurb.text = "Not regular tic-tac-toe.\n5s blitz clock · chaos power cells · streak Ult."
	blurb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI.label_outline(blurb, Color(0.85, 0.92, 1.0), 16, Color(0, 0, 0, 0.55), 4)
	menu_col.add_child(blurb)

	play_btn = Button.new()
	play_btn.text = "▶  START BLITZ"
	play_btn.custom_minimum_size = Vector2(0, 72)
	play_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	play_btn.focus_mode = Control.FOCUS_ALL
	UI.apply_button(play_btn, Color(0.15, 0.75, 0.9), Color(0.7, 1.0, 1.0), Color(0.02, 0.08, 0.12), 26)
	play_btn.pressed.connect(_start_from_menu)
	menu_col.add_child(play_btn)

	var how := Label.new()
	how.text = "You are ✕  ·  AI is ○\nWin 2 rounds in a row to unlock Ult (place twice)."
	how.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	how.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI.label_outline(how, Color(0.7, 0.85, 1.0), 14, Color(0, 0, 0, 0.5), 3)
	menu_col.add_child(how)

func _show_menu() -> void:
	in_menu = true
	menu_layer.visible = true
	_reset_board_state(false)
	_refresh_hud()

func _start_from_menu() -> void:
	if sfx:
		sfx.tap()
	in_menu = false
	menu_layer.visible = false
	match_wins = 0
	match_losses = 0
	win_streak = 0
	ult_ready = false
	_start_round()

func _start_round() -> void:
	var again: Button = find_child("AgainBtn", true, false) as Button
	if again:
		again.visible = false
	banner.visible = false
	game_over = false
	player_turn = true
	ai_thinking = false
	ult_armed = false
	_reset_board_state(true)
	_spawn_opening_powers()
	_refresh_board()
	_refresh_hud()
	status.text = "Your move — beat the clock"
	turn_left = TURN_TIME
	if sfx:
		sfx.tap()

func _reset_board_state(with_powers: bool) -> void:
	board = []
	powers = []
	frozen = []
	for i in range(9):
		board.append(MARK_EMPTY)
		powers.append(POWER_NONE if with_powers else POWER_NONE)
		frozen.append(false)

func _spawn_opening_powers() -> void:
	# Seed 1–2 chaos cells so first game already feels different
	var slots := [0, 1, 2, 3, 4, 5, 6, 7, 8]
	slots.shuffle()
	var count := 1 + randi() % 2
	for i in range(count):
		powers[slots[i]] = [POWER_BOMB, POWER_WARP, POWER_FREEZE][randi() % 3]

func _unhandled_input(event: InputEvent) -> void:
	# Desktop helpers
	if event is InputEventKey and event.pressed:
		if in_menu and (event.keycode == KEY_ENTER or event.keycode == KEY_SPACE or event.keycode == KEY_S):
			_start_from_menu()
			get_viewport().set_input_as_handled()
		elif (not in_menu) and game_over and (event.keycode == KEY_ENTER or event.keycode == KEY_SPACE or event.keycode == KEY_R):
			_start_round()
			get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if flash.color.a > 0.0:
		flash.color.a = maxf(0.0, flash.color.a - delta * 2.2)
	if in_menu or game_over or ai_thinking:
		return
	if player_turn:
		turn_left -= delta
		timer_bar.value = turn_left
		if turn_left <= 1.2 and int(turn_left * 10) % 3 == 0:
			pass
		if turn_left <= 0.0:
			_timeout_player()

func _timeout_player() -> void:
	# Auto-place randomly so blitz hurts
	var empties: Array[int] = []
	for i in range(9):
		if board[i] == MARK_EMPTY:
			empties.append(i)
	if empties.is_empty():
		_end_draw()
		return
	status.text = "Time’s up — random drop!"
	if sfx:
		sfx.tick()
	_place(empties[randi() % empties.size()], MARK_X, true)

func _on_cell(idx: int) -> void:
	if in_menu or game_over or not player_turn or ai_thinking:
		return
	if board[idx] != MARK_EMPTY:
		return
	_place(idx, MARK_X, true)

func _on_ult() -> void:
	if not ult_ready or game_over or not player_turn:
		return
	ult_armed = true
	ult_ready = false
	win_streak = 0
	status.text = "ULT ARMED — place twice this turn"
	if sfx:
		sfx.ult()
	_refresh_hud()

func _place(idx: int, mark: int, from_player: bool) -> void:
	if board[idx] != MARK_EMPTY:
		return
	var power: int = powers[idx]
	powers[idx] = POWER_NONE
	board[idx] = mark
	if power == POWER_FREEZE:
		frozen[idx] = true
	_pulse_cell(idx, mark)
	if sfx:
		if mark == MARK_X:
			sfx.place_x()
		else:
			sfx.place_o()
	_apply_power(idx, mark, power)
	_refresh_board()

	var winner := _check_winner()
	if winner != MARK_EMPTY:
		_end_round(winner)
		return
	if _board_full():
		_end_draw()
		return

	if from_player and ult_armed:
		ult_armed = false
		status.text = "Ult — place one more!"
		turn_left = TURN_TIME
		_maybe_spawn_power()
		_refresh_board()
		_refresh_hud()
		return

	if from_player:
		player_turn = false
		status.text = "AI thinking…"
		turn_left = TURN_TIME
		timer_bar.value = TURN_TIME
		_maybe_spawn_power()
		_refresh_board()
		ai_thinking = true
		get_tree().create_timer(0.45 + randf() * 0.35).timeout.connect(_ai_turn)
	else:
		player_turn = true
		status.text = "Your move"
		turn_left = TURN_TIME
		_maybe_spawn_power()
		_refresh_board()
		_refresh_hud()

func _apply_power(idx: int, mark: int, power: int) -> void:
	match power:
		POWER_BOMB:
			if sfx:
				sfx.bomb()
			flash.color = Color(1.0, 0.55, 0.2, 0.35)
			status.text = "BOMB! Adjacent marks cleared"
			var neighbors := _neighbors(idx)
			for n in neighbors:
				if frozen[n]:
					continue
				if board[n] != MARK_EMPTY:
					board[n] = MARK_EMPTY
					powers[n] = POWER_NONE
		POWER_WARP:
			flash.color = Color(0.4, 0.9, 1.0, 0.3)
			status.text = "WARP! Extra mark elsewhere"
			var empties: Array[int] = []
			for i in range(9):
				if board[i] == MARK_EMPTY and i != idx:
					empties.append(i)
			if empties.size() > 0:
				var j: int = empties[randi() % empties.size()]
				board[j] = mark
				powers[j] = POWER_NONE
				_pulse_cell(j, mark)
		POWER_FREEZE:
			flash.color = Color(0.6, 0.85, 1.0, 0.28)
			status.text = "FREEZE! This mark is locked"
		_:
			pass

func _neighbors(idx: int) -> Array[int]:
	var r: int = int(idx / 3)
	var c: int = idx % 3
	var out: Array[int] = []
	for dr in [-1, 0, 1]:
		for dc in [-1, 0, 1]:
			if dr == 0 and dc == 0:
				continue
			var rr: int = r + dr
			var cc: int = c + dc
			if rr >= 0 and rr < 3 and cc >= 0 and cc < 3:
				out.append(rr * 3 + cc)
	return out

func _maybe_spawn_power() -> void:
	if randf() > POWER_SPAWN_CHANCE:
		return
	var empties: Array[int] = []
	for i in range(9):
		if board[i] == MARK_EMPTY and powers[i] == POWER_NONE:
			empties.append(i)
	if empties.is_empty():
		return
	var pick: int = empties[randi() % empties.size()]
	powers[pick] = [POWER_BOMB, POWER_WARP, POWER_FREEZE][randi() % 3]

func _ai_turn() -> void:
	ai_thinking = false
	if game_over or player_turn:
		return
	var move: int = AIScript.pick_move(board, powers, MARK_O, MARK_X)
	if move < 0:
		_end_draw()
		return
	_place(move, MARK_O, false)

func _check_winner() -> int:
	var lines := [
		[0, 1, 2], [3, 4, 5], [6, 7, 8],
		[0, 3, 6], [1, 4, 7], [2, 5, 8],
		[0, 4, 8], [2, 4, 6],
	]
	for line in lines:
		var a: int = board[line[0]]
		if a != MARK_EMPTY and a == board[line[1]] and a == board[line[2]]:
			return a
	return MARK_EMPTY

func _board_full() -> bool:
	for v in board:
		if v == MARK_EMPTY:
			return false
	return true

func _end_round(winner: int) -> void:
	game_over = true
	ult_armed = false
	banner.visible = true
	var again: Button = find_child("AgainBtn", true, false) as Button
	if again:
		again.visible = true
	if winner == MARK_X:
		match_wins += 1
		win_streak += 1
		if win_streak >= 2:
			ult_ready = true
		banner.text = "YOU WIN"
		status.text = "Line locked — nice"
		flash.color = Color(0.4, 1.0, 0.85, 0.4)
		if sfx:
			sfx.win()
		_vibrate(80)
	else:
		match_losses += 1
		win_streak = 0
		ult_ready = false
		banner.text = "AI WINS"
		status.text = "Shake it off — rematch"
		flash.color = Color(1.0, 0.35, 0.25, 0.35)
		if sfx:
			sfx.lose()
		_vibrate(140)
	_refresh_hud()

func _end_draw() -> void:
	game_over = true
	ult_armed = false
	win_streak = 0
	banner.visible = true
	banner.text = "DRAW — CHAOS TIE"
	status.text = "Board full. Go again."
	var again: Button = find_child("AgainBtn", true, false) as Button
	if again:
		again.visible = true
	flash.color = Color(1.0, 0.85, 0.4, 0.3)
	_refresh_hud()

func _pulse_cell(idx: int, mark: int) -> void:
	var cell: Button = cells[idx]
	cell.pivot_offset = cell.size * 0.5
	cell.scale = Vector2(1.12, 1.12)
	var tw := create_tween()
	tw.tween_property(cell, "scale", Vector2.ONE, 0.18).set_ease(Tween.EASE_OUT)

func _refresh_board() -> void:
	for i in range(9):
		var overlay: Label = mark_labels[i]
		var badge: Label = power_badges[i]
		var cell: Button = cells[i]
		match board[i]:
			MARK_X:
				overlay.text = "✕"
				UI.label_outline(overlay, Color(0.35, 0.95, 1.0), 56, Color(0.02, 0.15, 0.2, 0.75), 8)
			MARK_O:
				overlay.text = "○"
				UI.label_outline(overlay, Color(1.0, 0.55, 0.25), 56, Color(0.2, 0.05, 0.0, 0.75), 8)
			_:
				overlay.text = ""
		match powers[i]:
			POWER_BOMB:
				badge.text = "BOMB"
			POWER_WARP:
				badge.text = "WARP"
			POWER_FREEZE:
				badge.text = "ICE"
			_:
				badge.text = ""
		if frozen[i] and board[i] != MARK_EMPTY:
			badge.text = "LOCK"
		var border := Color(0.35, 0.7, 0.9, 0.4)
		var bg := Color(0.1, 0.13, 0.2)
		if powers[i] == POWER_BOMB:
			border = Color(1.0, 0.5, 0.15, 0.85)
			bg = Color(0.22, 0.12, 0.08)
		elif powers[i] == POWER_WARP:
			border = Color(0.4, 0.95, 1.0, 0.85)
			bg = Color(0.08, 0.16, 0.22)
		elif powers[i] == POWER_FREEZE:
			border = Color(0.7, 0.9, 1.0, 0.8)
			bg = Color(0.1, 0.14, 0.22)
		UI.apply_button(cell, bg, border, Color(1, 1, 1), 48)
		cell.disabled = game_over or board[i] != MARK_EMPTY or not player_turn

func _refresh_hud() -> void:
	score_label.text = "YOU  %d   —   AI  %d" % [match_wins, match_losses]
	if ult_ready:
		streak_label.text = "ULT READY — tap the Ult button"
	elif win_streak > 0:
		streak_label.text = "Win streak %d / 2 for Ult" % win_streak
	else:
		streak_label.text = "Win 2 in a row → Ult (place twice)"
	ult_btn.disabled = not ult_ready or game_over or in_menu
	if ult_ready:
		UI.apply_button(ult_btn, Color(0.85, 0.35, 0.15), Color(1.0, 0.85, 0.4), Color(1, 1, 1), 18)
		ult_btn.text = "⚡  ARM ULT — PLACE TWICE"
	else:
		UI.apply_button(ult_btn, Color(0.2, 0.22, 0.3), Color(0.45, 0.5, 0.6, 0.4), Color(0.75, 0.8, 0.9), 16)
		ult_btn.text = "ULT  ×2 PLACE  (win streak 2)"

func _vibrate(ms: int) -> void:
	if OS.has_feature("android") or OS.has_feature("mobile"):
		Input.vibrate_handheld(ms)
