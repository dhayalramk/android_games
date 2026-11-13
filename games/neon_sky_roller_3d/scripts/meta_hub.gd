extends Control
## Premium home hub — looks like a real mobile game menu, not a debug panel.

signal play_pressed(level: int)
signal skin_changed

const UI = preload("res://scripts/ui_style.gd")

var progress
var _rank_label: Label
var _gem_label: Label
var _mission_label: Label
var _reason_label: Label
var _daily_btn: Button
var _play_btn: Button
var _skin_btns: Array = []
var _level_row: HBoxContainer
var _toast: Label
var _toast_timer: float = 0.0
var _hero_orb: ColorRect
var _play_lock: bool = false

func setup(p) -> void:
	progress = p
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	refresh()

func _build() -> void:
	for c in get_children():
		c.queue_free()
	_skin_btns.clear()

	# Atmospheric backdrop — IGNORE so buttons above always receive taps
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.03, 0.04, 0.09, 1)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var glow := ColorRect.new()
	glow.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	glow.offset_bottom = 280
	glow.color = Color(1.0, 0.45, 0.2, 0.18)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)

	var glow2 := ColorRect.new()
	glow2.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	glow2.offset_top = -320
	glow2.color = Color(0.15, 0.45, 1.0, 0.12)
	glow2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow2)

	# Full-screen hit catcher behind content (blocks 3D world taps)
	var catcher := Control.new()
	catcher.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	catcher.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(catcher)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_STOP
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 22)
	add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	margin.add_child(col)

	# Brand
	var brand := Label.new()
	brand.text = "NEON SKY"
	brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.label_outline(brand, Color(1, 0.95, 0.82), 38, Color(0.35, 0.12, 0.05, 0.8), 10)
	col.add_child(brand)

	var brand2 := Label.new()
	brand2.text = "ROLLER 3D"
	brand2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.label_outline(brand2, Color(1.0, 0.55, 0.2), 22, Color(0.2, 0.05, 0.0, 0.75), 6)
	col.add_child(brand2)

	# Rank / gems strip
	var strip := PanelContainer.new()
	strip.add_theme_stylebox_override("panel", UI.panel(Color(0.08, 0.1, 0.18, 0.92), 18, Color(1, 0.7, 0.3, 0.25)))
	col.add_child(strip)
	var strip_row := HBoxContainer.new()
	strip_row.alignment = BoxContainer.ALIGNMENT_CENTER
	strip_row.add_theme_constant_override("separation", 18)
	strip.add_child(strip_row)

	_rank_label = Label.new()
	UI.label_outline(_rank_label, Color(1.0, 0.78, 0.4), 15, Color(0, 0, 0, 0.55), 4)
	strip_row.add_child(_rank_label)

	_gem_label = Label.new()
	UI.label_outline(_gem_label, Color(0.45, 1.0, 0.95), 16, Color(0, 0, 0, 0.55), 4)
	strip_row.add_child(_gem_label)

	# Comeback reason card
	var reason_card := PanelContainer.new()
	reason_card.add_theme_stylebox_override("panel", UI.panel(Color(0.12, 0.08, 0.2, 0.9), 18, Color(1.0, 0.45, 0.25, 0.35)))
	col.add_child(reason_card)
	_reason_label = Label.new()
	_reason_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reason_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.label_outline(_reason_label, Color(1, 0.9, 0.8), 14, Color(0, 0, 0, 0.5), 3)
	reason_card.add_child(_reason_label)

	# Mission card
	var mission_card := PanelContainer.new()
	mission_card.add_theme_stylebox_override("panel", UI.panel(Color(0.06, 0.12, 0.22, 0.9), 18, Color(0.3, 0.75, 1.0, 0.3)))
	col.add_child(mission_card)
	_mission_label = Label.new()
	_mission_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mission_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.label_outline(_mission_label, Color(0.75, 0.95, 1.0), 14, Color(0, 0, 0, 0.5), 3)
	mission_card.add_child(_mission_label)

	_daily_btn = Button.new()
	_daily_btn.custom_minimum_size = Vector2(0, 54)
	_daily_btn.focus_mode = Control.FOCUS_ALL
	_daily_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	_daily_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	UI.apply_button(_daily_btn, Color(0.95, 0.45, 0.15), Color(1.0, 0.85, 0.4), Color(1, 1, 1), 18)
	_daily_btn.pressed.connect(_on_daily)
	col.add_child(_daily_btn)

	_play_btn = Button.new()
	_play_btn.name = "PlayButton"
	_play_btn.custom_minimum_size = Vector2(0, 76)
	_play_btn.focus_mode = Control.FOCUS_ALL
	_play_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	_play_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	UI.apply_button(_play_btn, Color(0.15, 0.75, 0.95), Color(0.7, 1.0, 1.0), Color(0.02, 0.08, 0.12), 28)
	_play_btn.pressed.connect(_on_play)
	# Extra safety: also accept gui click/touch on the button area
	_play_btn.gui_input.connect(_on_play_gui_input)
	col.add_child(_play_btn)

	var replay := Button.new()
	replay.text = "REPLAY FOR ★★★"
	replay.custom_minimum_size = Vector2(0, 48)
	replay.mouse_filter = Control.MOUSE_FILTER_STOP
	replay.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	UI.apply_button(replay, Color(0.18, 0.14, 0.32), Color(1.0, 0.85, 0.4, 0.55), Color(1, 0.92, 0.7), 16)
	replay.pressed.connect(_on_replay_stars)
	col.add_child(replay)

	var garage := Label.new()
	garage.text = "GARAGE"
	garage.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.label_outline(garage, Color(1, 0.85, 0.55), 16, Color(0, 0, 0, 0.5), 4)
	col.add_child(garage)

	var skin_scroll := ScrollContainer.new()
	skin_scroll.custom_minimum_size = Vector2(0, 86)
	skin_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	skin_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(skin_scroll)

	var skin_row := HBoxContainer.new()
	skin_row.add_theme_constant_override("separation", 10)
	skin_scroll.add_child(skin_row)
	for i in range(progress.SKINS.size()):
		var s: Dictionary = progress.SKINS[i]
		var wrap := PanelContainer.new()
		wrap.custom_minimum_size = Vector2(108, 78)
		var em: Color = s["emission"]
		wrap.add_theme_stylebox_override("panel", UI.panel(Color(0.08, 0.09, 0.14, 0.95), 16, Color(em.r, em.g, em.b, 0.65)))
		var b := Button.new()
		b.text = str(s["name"])
		b.custom_minimum_size = Vector2(100, 70)
		UI.apply_button(b, Color(em.r, em.g, em.b, 0.22), Color(em.r, em.g, em.b, 0.8), Color(1, 1, 1), 11)
		var idx := i
		b.pressed.connect(func(): _on_skin(idx))
		wrap.add_child(b)
		skin_row.add_child(wrap)
		_skin_btns.append(b)

	var levels_cap := Label.new()
	levels_cap.text = "YOUR ROAD"
	levels_cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.label_outline(levels_cap, Color(0.85, 0.9, 1.0), 14, Color(0, 0, 0, 0.45), 3)
	col.add_child(levels_cap)

	_level_row = HBoxContainer.new()
	_level_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_level_row.add_theme_constant_override("separation", 8)
	col.add_child(_level_row)

	var tip := Label.new()
	tip.name = "TipLabel"
	tip.text = "Come back daily · Master ★★★ · Unlock legendary balls"
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI.label_outline(tip, Color(0.7, 0.8, 0.95, 0.9), 12, Color(0, 0, 0, 0.4), 2)
	col.add_child(tip)

	_toast = Label.new()
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.label_outline(_toast, Color(1, 0.95, 0.7), 18, Color(0, 0, 0, 0.7), 8)
	_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_toast.offset_left = -220
	_toast.offset_right = 220
	_toast.offset_top = -28
	_toast.offset_bottom = 28
	_toast.modulate.a = 0.0
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_toast)

func refresh() -> void:
	if progress == null:
		return
	_rank_label.text = "RANK %d   XP %d/%d   ★%d" % [
		progress.rank, progress.xp, progress.xp_for_rank(progress.rank), progress.total_stars()
	]
	_gem_label.text = "◆ %d" % progress.gems
	_reason_label.text = progress.reason_to_return()
	var m: Dictionary = progress.current_mission()
	if progress.daily_mission_done:
		_mission_label.text = "Daily Mission complete ✓  — new mission tomorrow"
	else:
		_mission_label.text = "%s\n%d / %d" % [str(m["title"]), progress.daily_mission_progress, int(m["target"])]
	_daily_btn.disabled = not progress.can_claim_daily()
	_daily_btn.text = "✦  CLAIM DAILY GIFT" if progress.can_claim_daily() else "✓  CLAIMED  ·  streak %d" % progress.login_streak
	_play_btn.text = "▶  PLAY LEVEL %d" % progress.max_unlocked
	var tip: Label = find_child("TipLabel", true, false) as Label
	if tip:
		if progress.total_clears == 0:
			tip.text = "New here? Level 1 is a short sky run — grab gems, hit the gate."
		elif progress.total_clears < 3:
			tip.text = "You’re leveling up — claim Daily Gift, then chase ★★★."
		else:
			tip.text = "Come back daily · Master ★★★ · Unlock legendary balls"

	for i in range(_skin_btns.size()):
		var s: Dictionary = progress.SKINS[i]
		var owned: bool = progress.is_skin_unlocked(i)
		var selected: bool = progress.selected_skin == i
		var tag := "EQUIPPED" if selected else ("OWNED" if owned else "◆%d" % int(s["cost"]))
		_skin_btns[i].text = "%s\n%s" % [str(s["name"]).substr(0, 10), tag]

	for c in _level_row.get_children():
		c.queue_free()
	var start_lvl: int = maxi(1, progress.max_unlocked - 4)
	var end_lvl: int = progress.max_unlocked
	for lvl in range(start_lvl, end_lvl + 1):
		var b := Button.new()
		var stars: int = progress.stars_for(lvl)
		var star_txt := ""
		for i in range(3):
			star_txt += "★" if i < stars else "☆"
		b.text = "%d\n%s" % [lvl, star_txt]
		b.custom_minimum_size = Vector2(68, 62)
		var edge := Color(1.0, 0.7, 0.3, 0.7) if lvl == progress.max_unlocked else Color(0.4, 0.7, 1.0, 0.35)
		UI.apply_button(b, Color(0.1, 0.12, 0.2, 0.95), edge, Color(1, 1, 1), 13)
		var captured := lvl
		b.pressed.connect(func(): play_pressed.emit(captured))
		_level_row.add_child(b)

func show_toast(msg: String) -> void:
	_toast.text = msg
	_toast.modulate.a = 1.0
	_toast_timer = 2.2

func _process(delta: float) -> void:
	if _toast_timer > 0.0:
		_toast_timer -= delta
		if _toast_timer <= 0.6:
			_toast.modulate.a = maxf(0.0, _toast_timer / 0.6)

func _on_daily() -> void:
	var r: Dictionary = progress.claim_daily()
	if int(r["gems"]) <= 0 and int(r.get("comeback", 0)) <= 0:
		show_toast("Come back tomorrow for the next gift")
		refresh()
		return
	var msg := "+◆%d Daily  ·  Streak %d" % [int(r["gems"]), int(r["streak"])]
	if int(r.get("comeback", 0)) > 0:
		msg += "  ·  Comeback +◆%d" % int(r["comeback"])
	show_toast(msg)
	refresh()

func _on_play() -> void:
	if _play_lock or progress == null:
		return
	_play_lock = true
	play_pressed.emit(progress.max_unlocked)
	# Unlock next frame so rapid double-signals don't re-enter
	get_tree().create_timer(0.35).timeout.connect(func(): _play_lock = false)

func _on_play_gui_input(event: InputEvent) -> void:
	# Fallback only when pressed signal fails under touch-emulation
	if _play_lock:
		return
	var tap := false
	if event is InputEventScreenTouch and event.pressed:
		tap = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Prefer the normal pressed signal for mouse; only use fallback for touch
		return
	if tap:
		_on_play()
		accept_event()

func _on_replay_stars() -> void:
	for lvl in range(1, progress.max_unlocked + 1):
		if progress.stars_for(lvl) < 3:
			play_pressed.emit(lvl)
			return
	play_pressed.emit(maxi(1, progress.max_unlocked - 1))

func _on_skin(idx: int) -> void:
	if progress.is_skin_unlocked(idx):
		progress.selected_skin = idx
		progress.save()
		show_toast("Equipped %s" % str(progress.SKINS[idx]["name"]))
		skin_changed.emit()
		refresh()
		return
	if progress.buy_skin(idx):
		show_toast("Unlocked %s!" % str(progress.SKINS[idx]["name"]))
		skin_changed.emit()
		refresh()
	else:
		var need: int = int(progress.SKINS[idx]["cost"]) - progress.gems
		show_toast("Need ◆%d more gems" % maxi(need, 1))
