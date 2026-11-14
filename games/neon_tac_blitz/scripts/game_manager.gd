extends Control
## Neon Tac Blitz — arcade tic-tac-toe with glass neon look + chaos powers.

const UI = preload("res://scripts/ui_style.gd")
const AIScript = preload("res://scripts/ai.gd")
const SfxScript = preload("res://scripts/sfx.gd")
const ProgressScript = preload("res://scripts/progress.gd")

const MARK_EMPTY := 0
const MARK_X := 1
const MARK_O := 2
const POWER_NONE := 0
const POWER_BOMB := 1
const POWER_WARP := 2
const POWER_FREEZE := 3

const TURN_TIME := 5.0
const POWER_SPAWN_CHANCE := 0.42

const TEX_BG := "res://assets/generated/bg_nebula.png"
const TEX_CELL := "res://assets/generated/cell_empty.png"
const TEX_BOMB := "res://assets/generated/cell_bomb.png"
const TEX_WARP := "res://assets/generated/cell_warp.png"
const TEX_ICE := "res://assets/generated/cell_ice.png"
const TEX_X := "res://assets/generated/mark_x.png"
const TEX_O := "res://assets/generated/mark_o.png"
const TEX_CHIP_BOMB := "res://assets/generated/chip_bomb.png"
const TEX_CHIP_WARP := "res://assets/generated/chip_warp.png"
const TEX_CHIP_ICE := "res://assets/generated/chip_ice.png"
const TEX_CHIP_LOCK := "res://assets/generated/chip_lock.png"
const TEX_LOGO := "res://assets/generated/logo_mark.png"
const TEX_ORB_P := "res://assets/generated/orb_purple.png"
const TEX_ORB_C := "res://assets/generated/orb_cyan.png"

var board: Array = []
var powers: Array = []
var frozen: Array = []
var cells: Array = []
var cell_bgs: Array = []
var mark_rects: Array = []
var power_chips: Array = []

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
var _time: float = 0.0

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
var progress
var daily_btn: Button
var home_btn: Button
var win_line: Array = []
var gem_label: Label
var orbs: Array = []
var again_btn: Button
var hud_chip: PanelContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	progress = ProgressScript.new()
	progress.load_save()
	sfx = SfxScript.new()
	add_child(sfx)
	_build_ui()
	_show_menu()

func _tex(path: String) -> Texture2D:
	return load(path) as Texture2D

func _build_ui() -> void:
	# Nebula atmosphere
	var bg := TextureRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.texture = _tex(TEX_BG)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Soft floating orbs
	for i in range(4):
		var orb := TextureRect.new()
		orb.texture = _tex(TEX_ORB_P if i % 2 == 0 else TEX_ORB_C)
		orb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		orb.stretch_mode = TextureRect.STRETCH_SCALE
		orb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		orb.modulate = Color(1, 1, 1, 0.55)
		orb.size = Vector2(220, 220)
		orb.position = Vector2(40.0 + i * 90.0, 120.0 + (i % 3) * 180.0)
		add_child(orb)
		orbs.append({"n": orb, "base": orb.position, "phase": i * 1.3, "amp": 18.0 + i * 6.0})

	flash = ColorRect.new()
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(1, 1, 1, 0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	margin.add_child(col)

	brand = Label.new()
	brand.text = "NEON TAC"
	brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.label_outline(brand, UI.CYAN, 40, Color(0.05, 0.2, 0.35, 0.9), 12)
	col.add_child(brand)

	var sub := Label.new()
	sub.text = "BLITZ"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.label_outline(sub, UI.MAGENTA, 22, Color(0.25, 0.05, 0.15, 0.85), 8)
	col.add_child(sub)

	# Glass HUD chip
	hud_chip = PanelContainer.new()
	hud_chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hud_chip.add_theme_stylebox_override(
		"panel",
		UI.glass_panel(Color(0.08, 0.09, 0.18, 0.42), 22, Color(0.55, 0.9, 1.0, 0.4), Color(0.35, 0.75, 1.0, 0.28))
	)
	col.add_child(hud_chip)
	var hud_col := VBoxContainer.new()
	hud_col.add_theme_constant_override("separation", 4)
	hud_chip.add_child(hud_col)

	score_label = Label.new()
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.label_outline(score_label, Color(0.95, 0.97, 1.0), 16, Color(0, 0, 0, 0.45), 3)
	hud_col.add_child(score_label)

	gem_label = Label.new()
	gem_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.label_outline(gem_label, Color(0.55, 1.0, 0.95), 14, Color(0, 0, 0, 0.4), 3)
	hud_col.add_child(gem_label)

	streak_label = Label.new()
	streak_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.label_outline(streak_label, Color(1.0, 0.82, 0.55), 13, Color(0, 0, 0, 0.4), 3)
	hud_col.add_child(streak_label)

	status = Label.new()
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI.label_outline(status, Color(0.88, 0.94, 1.0), 17, Color(0.02, 0.04, 0.1, 0.55), 5)
	col.add_child(status)

	timer_bar = ProgressBar.new()
	timer_bar.max_value = TURN_TIME
	timer_bar.value = TURN_TIME
	timer_bar.show_percentage = false
	timer_bar.custom_minimum_size = Vector2(0, 12)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.35, 0.95, 1.0)
	fill.set_corner_radius_all(8)
	fill.shadow_color = Color(0.3, 0.9, 1.0, 0.45)
	fill.shadow_size = 6
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.08, 0.1, 0.18, 0.85)
	bg_style.set_corner_radius_all(8)
	bg_style.set_border_width_all(1)
	bg_style.border_color = Color(0.4, 0.7, 0.9, 0.25)
	timer_bar.add_theme_stylebox_override("fill", fill)
	timer_bar.add_theme_stylebox_override("background", bg_style)
	col.add_child(timer_bar)

	# Board glass frame
	var board_panel := PanelContainer.new()
	board_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_panel.add_theme_stylebox_override(
		"panel",
		UI.glass_panel(Color(0.06, 0.07, 0.14, 0.38), 34, Color(0.45, 0.92, 1.0, 0.55), Color(0.3, 0.75, 1.0, 0.45))
	)
	col.add_child(board_panel)

	var board_margin := MarginContainer.new()
	board_margin.add_theme_constant_override("margin_left", 14)
	board_margin.add_theme_constant_override("margin_right", 14)
	board_margin.add_theme_constant_override("margin_top", 14)
	board_margin.add_theme_constant_override("margin_bottom", 14)
	board_panel.add_child(board_margin)

	board_wrap = GridContainer.new()
	board_wrap.columns = 3
	board_wrap.add_theme_constant_override("h_separation", 12)
	board_wrap.add_theme_constant_override("v_separation", 12)
	board_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_margin.add_child(board_wrap)

	cells.clear()
	cell_bgs.clear()
	mark_rects.clear()
	power_chips.clear()
	for i in range(9):
		var cell := Button.new()
		cell.custom_minimum_size = Vector2(0, 148)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.size_flags_vertical = Control.SIZE_EXPAND_FILL
		cell.focus_mode = Control.FOCUS_NONE
		cell.flat = true
		cell.clip_contents = true
		# Invisible hit target; visuals live in children
		var invis := StyleBoxEmpty.new()
		cell.add_theme_stylebox_override("normal", invis)
		cell.add_theme_stylebox_override("hover", invis)
		cell.add_theme_stylebox_override("pressed", invis)
		cell.add_theme_stylebox_override("focus", invis)
		cell.add_theme_stylebox_override("disabled", invis)
		var idx := i
		cell.pressed.connect(func(): _on_cell(idx))
		board_wrap.add_child(cell)

		var cbg := TextureRect.new()
		cbg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		cbg.texture = _tex(TEX_CELL)
		cbg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		cbg.stretch_mode = TextureRect.STRETCH_SCALE
		cbg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(cbg)

		var mark := TextureRect.new()
		mark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mark.offset_left = 12
		mark.offset_top = 12
		mark.offset_right = -12
		mark.offset_bottom = -12
		mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mark.visible = false
		cell.add_child(mark)

		var chip := TextureRect.new()
		chip.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		chip.offset_left = -92
		chip.offset_top = 8
		chip.offset_right = -8
		chip.offset_bottom = 36
		chip.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		chip.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.visible = false
		cell.add_child(chip)

		cells.append(cell)
		cell_bgs.append(cbg)
		mark_rects.append(mark)
		power_chips.append(chip)

	ult_btn = Button.new()
	ult_btn.text = "ULT  ×2 PLACE  (win streak 2)"
	ult_btn.custom_minimum_size = Vector2(0, 54)
	ult_btn.disabled = true
	UI.apply_button(ult_btn, Color(0.35, 0.12, 0.4, 0.75), Color(1.0, 0.55, 0.95, 0.55), Color(1, 1, 1), 15, 20)
	ult_btn.pressed.connect(_on_ult)
	col.add_child(ult_btn)

	tip = Label.new()
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI.label_outline(tip, Color(0.75, 0.88, 1.0, 0.9), 12, Color(0, 0, 0, 0.4), 3)
	tip.text = "BOMB clears neighbors · WARP extra mark · ICE locks a cell"
	col.add_child(tip)

	banner = Label.new()
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI.label_outline(banner, Color(1, 0.95, 0.85), 30, Color(0.05, 0.02, 0.1, 0.8), 10)
	banner.visible = false
	col.add_child(banner)

	again_btn = Button.new()
	again_btn.name = "AgainBtn"
	again_btn.text = "PLAY AGAIN"
	again_btn.custom_minimum_size = Vector2(0, 58)
	again_btn.visible = false
	UI.apply_button(again_btn, Color(0.15, 0.65, 0.85, 0.9), Color(0.65, 1.0, 1.0), Color(0.02, 0.08, 0.14), 22, 22)
	again_btn.pressed.connect(_start_round)
	col.add_child(again_btn)

	_build_menu()

	home_btn = Button.new()
	home_btn.text = "⌂  HOME"
	home_btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
	home_btn.offset_left = 16
	home_btn.offset_top = 16
	home_btn.offset_right = 128
	home_btn.offset_bottom = 56
	home_btn.visible = false
	UI.apply_button(home_btn, Color(0.08, 0.1, 0.18, 0.75), Color(0.55, 0.85, 1.0, 0.45), Color(1, 1, 1), 13, 16)
	home_btn.pressed.connect(_show_menu)
	add_child(home_btn)

func _build_menu() -> void:
	menu_layer = Control.new()
	menu_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(menu_layer)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.04, 0.02, 0.1, 0.35)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	menu_layer.add_child(dim)

	var card := PanelContainer.new()
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -280
	card.offset_right = 280
	card.offset_top = -310
	card.offset_bottom = 310
	card.add_theme_stylebox_override(
		"panel",
		UI.glass_panel(Color(0.1, 0.08, 0.2, 0.72), 36, Color(0.5, 0.92, 1.0, 0.62), Color(0.4, 0.7, 1.0, 0.5))
	)
	menu_layer.add_child(card)

	var menu_col := VBoxContainer.new()
	menu_col.add_theme_constant_override("separation", 12)
	card.add_child(menu_col)

	var logo := TextureRect.new()
	logo.texture = _tex(TEX_LOGO)
	logo.custom_minimum_size = Vector2(0, 120)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_col.add_child(logo)

	var m_brand := Label.new()
	m_brand.text = "NEON TAC"
	m_brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.label_outline(m_brand, UI.CYAN, 44, Color(0.05, 0.18, 0.28, 0.9), 12)
	menu_col.add_child(m_brand)

	var m_sub := Label.new()
	m_sub.text = "BLITZ"
	m_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.label_outline(m_sub, UI.MAGENTA, 26, Color(0.2, 0.05, 0.12, 0.85), 8)
	menu_col.add_child(m_sub)

	var blurb := Label.new()
	blurb.text = "Survive every move.\n5s blitz · chaos gems · streak Ult."
	blurb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI.label_outline(blurb, Color(0.88, 0.92, 1.0), 15, Color(0, 0, 0, 0.5), 4)
	menu_col.add_child(blurb)

	daily_btn = Button.new()
	daily_btn.custom_minimum_size = Vector2(0, 52)
	UI.apply_button(daily_btn, Color(0.85, 0.35, 0.2, 0.88), Color(1.0, 0.75, 0.45), Color(1, 1, 1), 17, 20)
	daily_btn.pressed.connect(_on_daily)
	menu_col.add_child(daily_btn)

	play_btn = Button.new()
	play_btn.text = "START BLITZ"
	play_btn.custom_minimum_size = Vector2(0, 70)
	play_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	play_btn.focus_mode = Control.FOCUS_ALL
	UI.apply_button(play_btn, Color(0.12, 0.7, 0.88, 0.92), Color(0.7, 1.0, 1.0), Color(0.02, 0.08, 0.14), 24, 24)
	play_btn.pressed.connect(_start_from_menu)
	menu_col.add_child(play_btn)

	var how := Label.new()
	how.text = "You are ✕  ·  AI is ○\nWin 2 in a row to unlock Ult."
	how.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	how.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI.label_outline(how, Color(0.72, 0.84, 1.0), 13, Color(0, 0, 0, 0.45), 3)
	menu_col.add_child(how)

func _show_menu() -> void:
	in_menu = true
	menu_layer.visible = true
	if home_btn:
		home_btn.visible = false
	_reset_board_state(false)
	_refresh_hud()
	_refresh_daily_btn()

func _refresh_daily_btn() -> void:
	if daily_btn == null or progress == null:
		return
	daily_btn.disabled = not progress.can_claim_daily()
	if progress.can_claim_daily():
		daily_btn.text = "✦  CLAIM DAILY  +gems"
	else:
		daily_btn.text = "✓  CLAIMED  ·  streak %d" % progress.login_streak

func _on_daily() -> void:
	if progress == null:
		return
	var r: Dictionary = progress.claim_daily()
	if int(r["gems"]) <= 0:
		status.text = "Come back tomorrow"
	else:
		status.text = "+◆%d daily  ·  streak %d" % [int(r["gems"]), int(r["streak"])]
		if sfx:
			sfx.win()
	_refresh_hud()
	_refresh_daily_btn()

func _start_from_menu() -> void:
	if sfx:
		sfx.tap()
	in_menu = false
	menu_layer.visible = false
	if home_btn:
		home_btn.visible = true
	if match_wins == 0 and match_losses == 0:
		win_streak = 0
		ult_ready = false
	_start_round()

func _start_round() -> void:
	if again_btn:
		again_btn.visible = false
	banner.visible = false
	game_over = false
	player_turn = true
	ai_thinking = false
	ult_armed = false
	win_line.clear()
	_reset_board_state(true)
	_spawn_opening_powers()
	_refresh_board()
	_refresh_hud()
	status.text = "Your move — beat the clock"
	turn_left = TURN_TIME
	if home_btn:
		home_btn.visible = true
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
	var slots := [0, 1, 2, 3, 4, 5, 6, 7, 8]
	slots.shuffle()
	var count := 1 + randi() % 2
	for i in range(count):
		powers[slots[i]] = [POWER_BOMB, POWER_WARP, POWER_FREEZE][randi() % 3]

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if in_menu and (event.keycode == KEY_ENTER or event.keycode == KEY_SPACE or event.keycode == KEY_S):
			_start_from_menu()
			get_viewport().set_input_as_handled()
		elif (not in_menu) and game_over and (event.keycode == KEY_ENTER or event.keycode == KEY_SPACE or event.keycode == KEY_R):
			_start_round()
			get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	_time += delta
	for o in orbs:
		var n: TextureRect = o["n"]
		var base: Vector2 = o["base"]
		var phase: float = o["phase"]
		var amp: float = o["amp"]
		n.position = base + Vector2(sin(_time * 0.55 + phase) * amp, cos(_time * 0.4 + phase) * amp * 0.7)
		n.modulate.a = 0.4 + 0.2 * sin(_time * 0.7 + phase)

	if flash.color.a > 0.0:
		flash.color.a = maxf(0.0, flash.color.a - delta * 2.2)
	if in_menu or game_over or ai_thinking:
		return
	if player_turn:
		turn_left -= delta
		timer_bar.value = turn_left
		# Urgency tint on timer
		var fill: StyleBoxFlat = timer_bar.get_theme_stylebox("fill") as StyleBoxFlat
		if fill:
			if turn_left < 1.5:
				fill.bg_color = Color(1.0, 0.4, 0.45)
			else:
				fill.bg_color = Color(0.35, 0.95, 1.0)
		if turn_left <= 0.0:
			_timeout_player()

func _timeout_player() -> void:
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
			flash.color = Color(1.0, 0.4, 0.3, 0.35)
			status.text = "BOMB! Adjacent marks cleared"
			var neighbors := _neighbors(idx)
			for n in neighbors:
				if frozen[n]:
					continue
				if board[n] != MARK_EMPTY:
					board[n] = MARK_EMPTY
					powers[n] = POWER_NONE
		POWER_WARP:
			flash.color = Color(0.35, 0.9, 1.0, 0.3)
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
			flash.color = Color(0.55, 0.8, 1.0, 0.28)
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
			win_line = line.duplicate()
			return a
	win_line.clear()
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
	if again_btn:
		again_btn.visible = true
	if winner == MARK_X:
		match_wins += 1
		win_streak += 1
		if win_streak >= 2:
			ult_ready = true
		if progress:
			progress.record_win(win_streak)
		banner.text = "YOU WIN"
		status.text = "Line locked — +◆5"
		flash.color = Color(0.4, 1.0, 0.85, 0.4)
		if sfx:
			sfx.win()
		_vibrate(80)
		_highlight_win_line(true)
	else:
		match_losses += 1
		win_streak = 0
		ult_ready = false
		if progress:
			progress.record_loss()
		banner.text = "AI WINS"
		status.text = "Shake it off — rematch"
		flash.color = Color(1.0, 0.35, 0.45, 0.35)
		if sfx:
			sfx.lose()
		_vibrate(140)
		_highlight_win_line(false)
	_refresh_hud()

func _highlight_win_line(player_won: bool) -> void:
	for idx in win_line:
		var cell: Button = cells[idx]
		var cbg: TextureRect = cell_bgs[idx]
		cbg.modulate = Color(1.25, 1.25, 1.25, 1.0) if player_won else Color(1.2, 0.9, 0.9, 1.0)
		cell.pivot_offset = cell.size * 0.5
		var tw := create_tween()
		tw.tween_property(cell, "scale", Vector2(1.08, 1.08), 0.15)
		tw.tween_property(cell, "scale", Vector2.ONE, 0.22)

func _end_draw() -> void:
	game_over = true
	ult_armed = false
	win_streak = 0
	banner.visible = true
	banner.text = "DRAW — CHAOS TIE"
	status.text = "Board full. Go again."
	if again_btn:
		again_btn.visible = true
	flash.color = Color(1.0, 0.85, 0.4, 0.3)
	_refresh_hud()

func _pulse_cell(idx: int, _mark: int) -> void:
	var cell: Button = cells[idx]
	cell.pivot_offset = cell.size * 0.5
	cell.scale = Vector2(1.14, 1.14)
	var tw := create_tween()
	tw.tween_property(cell, "scale", Vector2.ONE, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	var mark: TextureRect = mark_rects[idx]
	mark.modulate.a = 0.0
	var tw2 := create_tween()
	tw2.tween_property(mark, "modulate:a", 1.0, 0.18)

func _refresh_board() -> void:
	for i in range(9):
		var cbg: TextureRect = cell_bgs[i]
		var mark: TextureRect = mark_rects[i]
		var chip: TextureRect = power_chips[i]
		var cell: Button = cells[i]

		match powers[i]:
			POWER_BOMB:
				cbg.texture = _tex(TEX_BOMB)
			POWER_WARP:
				cbg.texture = _tex(TEX_WARP)
			POWER_FREEZE:
				cbg.texture = _tex(TEX_ICE)
			_:
				cbg.texture = _tex(TEX_CELL)
		cbg.modulate = Color.WHITE

		match board[i]:
			MARK_X:
				mark.texture = _tex(TEX_X)
				mark.visible = true
				mark.modulate = Color.WHITE
			MARK_O:
				mark.texture = _tex(TEX_O)
				mark.visible = true
				mark.modulate = Color.WHITE
			_:
				mark.visible = false

		chip.visible = false
		if frozen[i] and board[i] != MARK_EMPTY:
			chip.texture = _tex(TEX_CHIP_LOCK)
			chip.visible = true
		elif powers[i] == POWER_BOMB:
			chip.texture = _tex(TEX_CHIP_BOMB)
			chip.visible = true
		elif powers[i] == POWER_WARP:
			chip.texture = _tex(TEX_CHIP_WARP)
			chip.visible = true
		elif powers[i] == POWER_FREEZE:
			chip.texture = _tex(TEX_CHIP_ICE)
			chip.visible = true

		cell.disabled = game_over or board[i] != MARK_EMPTY or not player_turn

func _refresh_hud() -> void:
	score_label.text = "YOU  %d     AI  %d" % [match_wins, match_losses]
	if progress:
		gem_label.text = "◆ %d   ·   best streak %d" % [progress.gems, progress.best_streak]
	if ult_ready:
		streak_label.text = "ULT READY — tap below"
	elif win_streak > 0:
		streak_label.text = "Win streak %d / 2 for Ult" % win_streak
	else:
		streak_label.text = "Win 2 in a row → Ult"
	ult_btn.disabled = not ult_ready or game_over or in_menu
	if ult_ready:
		UI.apply_button(ult_btn, Color(0.9, 0.35, 0.2, 0.9), Color(1.0, 0.85, 0.45), Color(1, 1, 1), 17, 20)
		ult_btn.text = "⚡  ARM ULT — PLACE TWICE"
	else:
		UI.apply_button(ult_btn, Color(0.14, 0.15, 0.22, 0.7), Color(0.45, 0.5, 0.6, 0.35), Color(0.75, 0.8, 0.9), 14, 20)
		ult_btn.text = "ULT  ×2 PLACE  (win streak 2)"

func _vibrate(ms: int) -> void:
	if OS.has_feature("android") or OS.has_feature("mobile"):
		Input.vibrate_handheld(ms)
