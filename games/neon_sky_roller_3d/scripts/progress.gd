extends RefCounted
## Persistent progress — the reasons players come back.

const SAVE_PATH := "user://neon_sky_roller.save"

var max_unlocked: int = 1
var gems: int = 0
var xp: int = 0
var rank: int = 1
var selected_skin: int = 0
var unlocked_skins: Array = [0] # skin indices
var level_stars: Dictionary = {} # "1" -> 0..3
var login_streak: int = 0
var last_claim_day: int = -1
var last_open_day: int = -1
var daily_mission_id: String = "clear_2"
var daily_mission_progress: int = 0
var daily_mission_done: bool = false
var daily_mission_day: int = -1
var total_clears: int = 0
var best_score: int = 0
var comeback_pending: bool = false

const SKINS := [
	{"name": "Cyber Neon", "cost": 0, "albedo": Color(0.8, 0.92, 1.0), "emission": Color(0.25, 0.75, 1.0), "energy": 1.8},
	{"name": "Liquid Chrome", "cost": 35, "albedo": Color(0.92, 0.94, 0.98), "emission": Color(0.7, 0.8, 0.9), "energy": 1.2},
	{"name": "Solar Core", "cost": 70, "albedo": Color(1.0, 0.85, 0.4), "emission": Color(1.0, 0.5, 0.1), "energy": 3.2},
	{"name": "Dark Matter", "cost": 110, "albedo": Color(0.12, 0.1, 0.18), "emission": Color(0.55, 0.2, 1.0), "energy": 2.8},
	{"name": "Aurora Pulse", "cost": 160, "albedo": Color(0.45, 1.0, 0.8), "emission": Color(0.2, 1.0, 0.65), "energy": 3.0},
	{"name": "Crimson Nova", "cost": 220, "albedo": Color(1.0, 0.35, 0.4), "emission": Color(1.0, 0.15, 0.25), "energy": 3.4},
]

const MISSIONS := [
	{"id": "clear_2", "title": "Clear 2 levels today", "target": 2, "reward": 25},
	{"id": "gems_15", "title": "Collect 15 gems today", "target": 15, "reward": 20},
	{"id": "star_3", "title": "Earn one ★★★ clear", "target": 1, "reward": 40},
	{"id": "turbo_clear", "title": "Clear a level using Turbo", "target": 1, "reward": 22},
	{"id": "supernova", "title": "Trigger Supernova once", "target": 1, "reward": 30},
]

static func xp_for_rank(r: int) -> int:
	return 40 + (r - 1) * 35

func today() -> int:
	return int(Time.get_unix_time_from_system() / 86400.0)

func load_save() -> void:
	var f := ConfigFile.new()
	if f.load(SAVE_PATH) != OK:
		_roll_daily_mission(true)
		return
	max_unlocked = int(f.get_value("progress", "max_unlocked", 1))
	gems = int(f.get_value("progress", "gems", 0))
	xp = int(f.get_value("progress", "xp", 0))
	rank = int(f.get_value("progress", "rank", 1))
	selected_skin = int(f.get_value("progress", "selected_skin", 0))
	unlocked_skins = f.get_value("progress", "unlocked_skins", [0])
	level_stars = f.get_value("progress", "level_stars", {})
	login_streak = int(f.get_value("progress", "login_streak", 0))
	last_claim_day = int(f.get_value("progress", "last_claim_day", -1))
	last_open_day = int(f.get_value("progress", "last_open_day", -1))
	daily_mission_id = str(f.get_value("progress", "daily_mission_id", "clear_2"))
	daily_mission_progress = int(f.get_value("progress", "daily_mission_progress", 0))
	daily_mission_done = bool(f.get_value("progress", "daily_mission_done", false))
	daily_mission_day = int(f.get_value("progress", "daily_mission_day", -1))
	total_clears = int(f.get_value("progress", "total_clears", 0))
	best_score = int(f.get_value("progress", "best_score", 0))
	_on_open_day()

func save() -> void:
	var f := ConfigFile.new()
	f.set_value("progress", "max_unlocked", max_unlocked)
	f.set_value("progress", "gems", gems)
	f.set_value("progress", "xp", xp)
	f.set_value("progress", "rank", rank)
	f.set_value("progress", "selected_skin", selected_skin)
	f.set_value("progress", "unlocked_skins", unlocked_skins)
	f.set_value("progress", "level_stars", level_stars)
	f.set_value("progress", "login_streak", login_streak)
	f.set_value("progress", "last_claim_day", last_claim_day)
	f.set_value("progress", "last_open_day", last_open_day)
	f.set_value("progress", "daily_mission_id", daily_mission_id)
	f.set_value("progress", "daily_mission_progress", daily_mission_progress)
	f.set_value("progress", "daily_mission_done", daily_mission_done)
	f.set_value("progress", "daily_mission_day", daily_mission_day)
	f.set_value("progress", "total_clears", total_clears)
	f.set_value("progress", "best_score", best_score)
	f.save(SAVE_PATH)

func _on_open_day() -> void:
	var d := today()
	if last_open_day >= 0 and d > last_open_day + 1:
		comeback_pending = true
	if daily_mission_day != d:
		_roll_daily_mission(true)
	last_open_day = d
	save()

func _roll_daily_mission(force: bool = false) -> void:
	var d := today()
	if not force and daily_mission_day == d:
		return
	var pick: Dictionary = MISSIONS[d % MISSIONS.size()]
	daily_mission_id = str(pick["id"])
	daily_mission_progress = 0
	daily_mission_done = false
	daily_mission_day = d

func can_claim_daily() -> bool:
	return last_claim_day != today()

func claim_daily() -> Dictionary:
	# Returns {gems, streak, comeback}
	if not can_claim_daily():
		return {"gems": 0, "streak": login_streak, "comeback": 0}
	var d := today()
	if last_claim_day == d - 1:
		login_streak += 1
	else:
		login_streak = 1
	last_claim_day = d
	var gift: int = 15 + mini(login_streak, 7) * 5
	var comeback: int = 0
	if comeback_pending:
		comeback = 40
		comeback_pending = false
	gems += gift + comeback
	save()
	return {"gems": gift, "streak": login_streak, "comeback": comeback}

func current_mission() -> Dictionary:
	for m in MISSIONS:
		if str(m["id"]) == daily_mission_id:
			return m
	return MISSIONS[0]

func add_mission_progress(kind: String, amount: int = 1) -> int:
	# Returns gems rewarded if mission just completed, else 0
	if daily_mission_done or daily_mission_day != today():
		return 0
	var m := current_mission()
	var mid := str(m["id"])
	var matched := false
	match mid:
		"clear_2":
			matched = kind == "clear"
		"gems_15":
			matched = kind == "gem"
		"star_3":
			matched = kind == "star3"
		"turbo_clear":
			matched = kind == "turbo_clear"
		"supernova":
			matched = kind == "supernova"
	if not matched:
		return 0
	daily_mission_progress = mini(int(m["target"]), daily_mission_progress + amount)
	if daily_mission_progress >= int(m["target"]):
		daily_mission_done = true
		var reward: int = int(m["reward"])
		gems += reward
		save()
		return reward
	save()
	return 0

func stars_for(level: int) -> int:
	return int(level_stars.get(str(level), 0))

func total_stars() -> int:
	var n := 0
	for k in level_stars.keys():
		n += int(level_stars[k])
	return n

func record_clear(level: int, score: int, gems_run: int, used_supernova: bool, used_turbo: bool) -> Dictionary:
	# Returns awards summary
	var stars := 1
	if gems_run >= 8 or score >= 150:
		stars = 2
	if used_supernova or gems_run >= 14 or score >= 280:
		stars = 3
	var prev: int = stars_for(level)
	var new_best_stars: bool = stars > prev
	if new_best_stars:
		level_stars[str(level)] = stars
	max_unlocked = maxi(max_unlocked, level + 1)
	total_clears += 1
	best_score = maxi(best_score, score)

	var gained_xp: int = 20 + level * 4 + stars * 8
	if new_best_stars:
		gained_xp += (stars - prev) * 12
	var ranked_up := add_xp(gained_xp)

	var mission_gems := add_mission_progress("clear", 1)
	if stars >= 3:
		mission_gems += add_mission_progress("star3", 1)
	if used_turbo:
		mission_gems += add_mission_progress("turbo_clear", 1)

	var clear_gems: int = 5 + stars * 3
	gems += clear_gems
	save()
	return {
		"stars": stars,
		"prev_stars": prev,
		"xp": gained_xp,
		"rank_up": ranked_up,
		"clear_gems": clear_gems,
		"mission_gems": mission_gems,
		"new_best_stars": new_best_stars,
	}

func add_xp(amount: int) -> bool:
	xp += amount
	var ranked := false
	while xp >= xp_for_rank(rank):
		xp -= xp_for_rank(rank)
		rank += 1
		ranked = true
		gems += 10 + rank # rank-up gift
	return ranked

func is_skin_unlocked(idx: int) -> bool:
	return unlocked_skins.has(idx) or unlocked_skins.has(float(idx)) or unlocked_skins.has(str(idx))

func buy_skin(idx: int) -> bool:
	if idx < 0 or idx >= SKINS.size():
		return false
	if is_skin_unlocked(idx):
		selected_skin = idx
		save()
		return true
	var cost: int = int(SKINS[idx]["cost"])
	if gems < cost:
		return false
	gems -= cost
	unlocked_skins.append(idx)
	selected_skin = idx
	save()
	return true

func skin_data() -> Dictionary:
	return SKINS[clampi(selected_skin, 0, SKINS.size() - 1)]

func reason_to_return() -> String:
	if can_claim_daily():
		return "Your Daily Gift is waiting (+gems & streak)"
	if not daily_mission_done:
		var m := current_mission()
		return "Daily Mission: %s" % str(m["title"])
	var next_skin := -1
	for i in range(SKINS.size()):
		if not is_skin_unlocked(i):
			next_skin = i
			break
	if next_skin >= 0:
		var s: Dictionary = SKINS[next_skin]
		return "Save ◆%d more for %s" % [maxi(0, int(s["cost"]) - gems), str(s["name"])]
	# Find first non-3-star cleared level
	for lvl in range(1, max_unlocked):
		if stars_for(lvl) < 3:
			return "Replay Level %d for ★★★ mastery" % lvl
	return "Climb Solo Rank %d — keep ascending" % (rank + 1)
