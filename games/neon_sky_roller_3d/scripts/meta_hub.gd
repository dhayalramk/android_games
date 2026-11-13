extends Control
## Home hub — daily gift, missions, garage, play. Retention front door.

signal play_pressed(level: int)
signal skin_changed

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

func setup(p) -> void:
	progress = p
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	refresh()

func _build() -> void:
	for c in get_children():
		c.queue_free()
	_skin_btns.clear()

	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.06, 0.12, 0.94)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 36)
	margin.add_theme_constant_override("margin_bottom", 28)
	add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	margin.add_child(col)

	var title := Label.new()
	title.text = "NEON SKY ROLLER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1, 0.92, 0.75))
	col.add_child(title)

	_rank_label = Label.new()
	_rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rank_label.add_theme_font_size_override("font_size", 18)
	_rank_label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.35))
	col.add_child(_rank_label)

	_gem_label = Label.new()
	_gem_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gem_label.add_theme_font_size_override("font_size", 22)
	_gem_label.add_theme_color_override("font_color", Color(0.45, 1.0, 0.95))
	col.add_child(_gem_label)

	_reason_label = Label.new()
	_reason_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reason_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reason_label.add_theme_font_size_override("font_size", 15)
	_reason_label.add_theme_color_override("font_color", Color(0.9, 0.93, 1.0))
	_reason_label.custom_minimum_size = Vector2(0, 48)
	col.add_child(_reason_label)

	_mission_label = Label.new()
	_mission_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mission_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mission_label.add_theme_font_size_override("font_size", 15)
	_mission_label.add_theme_color_override("font_color", Color(0.7, 0.92, 1.0))
	_mission_label.custom_minimum_size = Vector2(0, 44)
	col.add_child(_mission_label)

	_daily_btn = Button.new()
	_daily_btn.custom_minimum_size = Vector2(0, 52)
	_daily_btn.add_theme_font_size_override("font_size", 18)
	_daily_btn.pressed.connect(_on_daily)
	col.add_child(_daily_btn)

	_play_btn = Button.new()
	_play_btn.custom_minimum_size = Vector2(0, 64)
	_play_btn.add_theme_font_size_override("font_size", 26)
	_play_btn.pressed.connect(_on_play)
	col.add_child(_play_btn)

	var replay := Button.new()
	replay.text = "REPLAY FOR ★★★"
	replay.custom_minimum_size = Vector2(0, 48)
	replay.add_theme_font_size_override("font_size", 16)
	replay.pressed.connect(_on_replay_stars)
	col.add_child(replay)

	var garage := Label.new()
	garage.text = "GARAGE — unlock balls with gems"
	garage.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	garage.add_theme_font_size_override("font_size", 15)
	garage.add_theme_color_override("font_color", Color(1, 0.85, 0.55))
	col.add_child(garage)

	var skin_scroll := ScrollContainer.new()
	skin_scroll.custom_minimum_size = Vector2(0, 78)
	skin_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	skin_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(skin_scroll)

	var skin_row := HBoxContainer.new()
	skin_row.add_theme_constant_override("separation", 8)
	skin_scroll.add_child(skin_row)
	for i in range(progress.SKINS.size()):
		var s: Dictionary = progress.SKINS[i]
		var b := Button.new()
		b.custom_minimum_size = Vector2(100, 70)
		b.text = str(s["name"])
		b.add_theme_font_size_override("font_size", 11)
		var idx := i
		b.pressed.connect(func(): _on_skin(idx))
		skin_row.add_child(b)
		_skin_btns.append(b)

	var levels_cap := Label.new()
	levels_cap.text = "YOUR LEVELS"
	levels_cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	levels_cap.add_theme_font_size_override("font_size", 14)
	levels_cap.add_theme_color_override("font_color", Color(0.8, 0.85, 1.0))
	col.add_child(levels_cap)

	_level_row = HBoxContainer.new()
	_level_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_level_row.add_theme_constant_override("separation", 8)
	col.add_child(_level_row)

	var tip := Label.new()
	tip.text = "Daily gifts · Missions · ★ mastery · New balls · Solo Rank"
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.add_theme_font_size_override("font_size", 13)
	tip.add_theme_color_override("font_color", Color(0.65, 0.75, 0.95, 0.9))
	col.add_child(tip)

	_toast = Label.new()
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_font_size_override("font_size", 18)
	_toast.add_theme_color_override("font_color", Color(1, 0.95, 0.7))
	_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_toast.offset_left = -200
	_toast.offset_right = 200
	_toast.offset_top = -24
	_toast.offset_bottom = 24
	_toast.modulate.a = 0.0
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_toast)

func refresh() -> void:
	if progress == null:
		return
	_rank_label.text = "SOLO RANK %d  ·  XP %d/%d  ·  ★ %d" % [
		progress.rank, progress.xp, progress.xp_for_rank(progress.rank), progress.total_stars()
	]
	_gem_label.text = "◆ %d gems" % progress.gems
	_reason_label.text = "🔥 %s" % progress.reason_to_return()
	var m: Dictionary = progress.current_mission()
	if progress.daily_mission_done:
		_mission_label.text = "Daily Mission ✓ done — new mission tomorrow"
	else:
		_mission_label.text = "Mission: %s (%d/%d)" % [
			str(m["title"]), progress.daily_mission_progress, int(m["target"])
		]
	_daily_btn.disabled = not progress.can_claim_daily()
	if progress.can_claim_daily():
		_daily_btn.text = "CLAIM DAILY GIFT"
	else:
		_daily_btn.text = "DAILY CLAIMED ✓  streak %d" % progress.login_streak
	_play_btn.text = "PLAY LEVEL %d" % progress.max_unlocked

	for i in range(_skin_btns.size()):
		var s: Dictionary = progress.SKINS[i]
		var owned: bool = progress.is_skin_unlocked(i)
		var selected: bool = progress.selected_skin == i
		var tag := "ON" if selected else ("OWN" if owned else "◆%d" % int(s["cost"]))
		_skin_btns[i].text = "%s\n%s" % [str(s["name"]).substr(0, 11), tag]

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
		b.text = "L%d\n%s" % [lvl, star_txt]
		b.custom_minimum_size = Vector2(70, 60)
		b.add_theme_font_size_override("font_size", 12)
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
		show_toast("Already claimed — come back tomorrow!")
		refresh()
		return
	var msg := "Daily +◆%d  ·  Streak %d" % [int(r["gems"]), int(r["streak"])]
	if int(r.get("comeback", 0)) > 0:
		msg += "  ·  Comeback +◆%d!" % int(r["comeback"])
	show_toast(msg)
	refresh()

func _on_play() -> void:
	play_pressed.emit(progress.max_unlocked)

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
		show_toast("Need ◆%d more — clear levels & claim daily!" % maxi(need, 1))
