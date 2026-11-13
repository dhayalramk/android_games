extends RefCounted
## Solo-leveling difficulty curve for Neon Sky Roller 3D.

var level: int = 1
var title: String = "Awakening"
var track_length: float = 80.0
var track_width: float = 6.0
var base_speed: float = 14.0
var gem_spacing: float = 8.0
var gap_chance: float = 0.0
var curve_strength: float = 0.0
var obstacle_count: int = 0
var boost_count: int = 1
var spinner_count: int = 0
var theme_index: int = 0
var finish_bonus: int = 100

static func for_level(lvl: int):
	var cfg = new()
	cfg.level = max(1, lvl)
	var t: float = float(cfg.level - 1)

	cfg.title = _title_for(cfg.level)
	cfg.track_length = clampf(70.0 + t * 18.0, 70.0, 260.0)
	cfg.track_width = clampf(6.2 - t * 0.18, 3.4, 6.2)
	cfg.base_speed = clampf(13.0 + t * 1.35, 13.0, 34.0)
	cfg.gem_spacing = clampf(8.5 - t * 0.25, 4.0, 8.5)
	cfg.gap_chance = clampf(0.02 + t * 0.035, 0.0, 0.42)
	cfg.curve_strength = clampf(t * 0.55, 0.0, 6.5)
	cfg.obstacle_count = mini(2 + int(t * 1.2), 28)
	cfg.boost_count = mini(1 + int(t / 2.0), 8)
	cfg.spinner_count = 0 if cfg.level < 3 else mini(int((t - 1.0) * 0.9), 14)
	cfg.theme_index = mini(int(t / 3.0), 3)
	cfg.finish_bonus = 100 + cfg.level * 40
	return cfg

static func _title_for(lvl: int) -> String:
	match lvl:
		1:
			return "First Horizon"
		2:
			return "Warm Currents"
		3:
			return "Gate Breaker"
		4:
			return "Sky Needles"
		5:
			return "Neon Veins"
		6:
			return "Pulse Storm"
		7:
			return "Cloud Knives"
		8:
			return "Supernova Trial"
		9:
			return "Midnight Rails"
		10:
			return "Aurora Crown"
		_:
			if lvl < 15:
				return "Ascension %d" % lvl
			if lvl < 25:
				return "Overdrive %d" % lvl
			return "Solo Level %d" % lvl

static func theme_colors(theme_index: int) -> Dictionary:
	match theme_index:
		0: # Sunset Horizon
			return {
				"sky": Color(0.95, 0.45, 0.28),
				"horizon": Color(0.35, 0.18, 0.45),
				"fog": Color(0.55, 0.32, 0.42),
				"track": Color(0.12, 0.1, 0.18),
				"edge": Color(1.0, 0.55, 0.2),
				"ambient": Color(0.55, 0.35, 0.4),
				"light": Color(1.0, 0.75, 0.55),
			}
		1: # Cyber Midnight
			return {
				"sky": Color(0.08, 0.12, 0.35),
				"horizon": Color(0.05, 0.35, 0.55),
				"fog": Color(0.1, 0.2, 0.4),
				"track": Color(0.06, 0.08, 0.14),
				"edge": Color(0.2, 0.95, 1.0),
				"ambient": Color(0.25, 0.4, 0.7),
				"light": Color(0.55, 0.85, 1.0),
			}
		2: # Magma Veil
			return {
				"sky": Color(0.55, 0.08, 0.12),
				"horizon": Color(0.9, 0.25, 0.05),
				"fog": Color(0.4, 0.12, 0.08),
				"track": Color(0.12, 0.05, 0.06),
				"edge": Color(1.0, 0.35, 0.1),
				"ambient": Color(0.55, 0.2, 0.15),
				"light": Color(1.0, 0.55, 0.3),
			}
		_: # Aurora Borealis
			return {
				"sky": Color(0.05, 0.22, 0.28),
				"horizon": Color(0.15, 0.85, 0.55),
				"fog": Color(0.12, 0.35, 0.4),
				"track": Color(0.05, 0.1, 0.12),
				"edge": Color(0.35, 1.0, 0.75),
				"ambient": Color(0.25, 0.55, 0.5),
				"light": Color(0.65, 1.0, 0.85),
			}
