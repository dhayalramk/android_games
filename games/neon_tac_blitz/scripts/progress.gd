extends RefCounted
## Light retention — daily gift + best streak.

const SAVE_PATH := "user://neon_tac_blitz.save"

var best_streak: int = 0
var total_wins: int = 0
var total_losses: int = 0
var gems: int = 0
var last_claim_day: int = -1
var login_streak: int = 0

func today() -> int:
	return int(Time.get_unix_time_from_system() / 86400.0)

func load_save() -> void:
	var f := ConfigFile.new()
	if f.load(SAVE_PATH) != OK:
		return
	best_streak = int(f.get_value("p", "best_streak", 0))
	total_wins = int(f.get_value("p", "total_wins", 0))
	total_losses = int(f.get_value("p", "total_losses", 0))
	gems = int(f.get_value("p", "gems", 0))
	last_claim_day = int(f.get_value("p", "last_claim_day", -1))
	login_streak = int(f.get_value("p", "login_streak", 0))

func save() -> void:
	var f := ConfigFile.new()
	f.set_value("p", "best_streak", best_streak)
	f.set_value("p", "total_wins", total_wins)
	f.set_value("p", "total_losses", total_losses)
	f.set_value("p", "gems", gems)
	f.set_value("p", "last_claim_day", last_claim_day)
	f.set_value("p", "login_streak", login_streak)
	f.save(SAVE_PATH)

func can_claim_daily() -> bool:
	return last_claim_day != today()

func claim_daily() -> Dictionary:
	if not can_claim_daily():
		return {"gems": 0, "streak": login_streak}
	var d := today()
	if last_claim_day == d - 1:
		login_streak += 1
	else:
		login_streak = 1
	last_claim_day = d
	var gift: int = 15 + mini(login_streak, 7) * 5
	gems += gift
	save()
	return {"gems": gift, "streak": login_streak}

func record_win(streak: int) -> void:
	total_wins += 1
	gems += 5
	if streak > best_streak:
		best_streak = streak
	save()

func record_loss() -> void:
	total_losses += 1
	save()
