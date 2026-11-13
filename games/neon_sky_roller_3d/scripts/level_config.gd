extends RefCounted
## Solo-leveling difficulty curve for Neon Sky Roller 3D.

var level: int = 1
var title: String = "Awakening"
var track_length: float = 80.0
var track_width: float = 6.0
var base_speed: float = 12.0
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
	# Customer-first curve: Level 1 = ~20s guaranteed-feel win, then ramp
	if cfg.level == 1:
		cfg.track_length = 52.0
		cfg.track_width = 7.2
		cfg.base_speed = 11.0
		cfg.gem_spacing = 4.2
		cfg.gap_chance = 0.0
		cfg.curve_strength = 0.35  # gentle weave teach
		cfg.obstacle_count = 0
		cfg.boost_count = 2
		cfg.spinner_count = 0
		cfg.theme_index = 0
		cfg.finish_bonus = 150
	elif cfg.level == 2:
		cfg.track_length = 68.0
		cfg.track_width = 6.6
		cfg.base_speed = 12.0
		cfg.gem_spacing = 5.0
		cfg.gap_chance = 0.0
		cfg.curve_strength = 0.9
		cfg.obstacle_count = 2
		cfg.boost_count = 2
		cfg.spinner_count = 0
		cfg.theme_index = 0
		cfg.finish_bonus = 180
	elif cfg.level == 3:
		cfg.track_length = 80.0
		cfg.track_width = 6.2
		cfg.base_speed = 12.8
		cfg.gem_spacing = 5.2
		cfg.gap_chance = 0.06
		cfg.curve_strength = 1.4
		cfg.obstacle_count = 4
		cfg.boost_count = 2
		cfg.spinner_count = 0
		cfg.theme_index = 0
		cfg.finish_bonus = 210
	else:
		cfg.track_length = clampf(65.0 + t * 16.0, 65.0, 250.0)
		cfg.track_width = clampf(6.8 - t * 0.16, 3.6, 6.8)
		cfg.base_speed = clampf(11.5 + t * 1.15, 11.5, 32.0)
		cfg.gem_spacing = clampf(7.5 - t * 0.2, 3.8, 7.5)
		cfg.gap_chance = 0.0 if cfg.level < 3 else clampf(0.04 + (t - 2.0) * 0.03, 0.0, 0.38)
		cfg.curve_strength = 0.0 if cfg.level < 2 else clampf((t - 0.5) * 0.5, 0.4, 5.8)
		cfg.obstacle_count = mini(1 + int(t * 1.1), 26)
		cfg.boost_count = mini(1 + int(t / 2.0), 8)
		cfg.spinner_count = 0 if cfg.level < 4 else mini(int((t - 2.0) * 0.85), 12)
		cfg.theme_index = mini(int(t / 3.0), 3)
		cfg.finish_bonus = 100 + cfg.level * 45
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
				"sky_top": Color(0.35, 0.22, 0.55),
				"sky": Color(0.98, 0.52, 0.32),
				"horizon": Color(1.0, 0.62, 0.38),
				"fog": Color(0.72, 0.4, 0.45),
				"ground": Color(0.18, 0.12, 0.28),
				"track": Color(0.1, 0.08, 0.16),
				"edge": Color(1.0, 0.55, 0.18),
				"ambient": Color(0.65, 0.4, 0.45),
				"light": Color(1.0, 0.78, 0.55),
				"cloud": Color(1.0, 0.82, 0.7, 0.55),
			}
		1: # Cyber Midnight
			return {
				"sky_top": Color(0.02, 0.04, 0.14),
				"sky": Color(0.08, 0.16, 0.42),
				"horizon": Color(0.1, 0.55, 0.75),
				"fog": Color(0.12, 0.28, 0.48),
				"ground": Color(0.04, 0.06, 0.12),
				"track": Color(0.05, 0.07, 0.12),
				"edge": Color(0.25, 0.95, 1.0),
				"ambient": Color(0.28, 0.45, 0.75),
				"light": Color(0.55, 0.88, 1.0),
				"cloud": Color(0.55, 0.75, 1.0, 0.4),
			}
		2: # Magma Veil
			return {
				"sky_top": Color(0.2, 0.02, 0.06),
				"sky": Color(0.65, 0.12, 0.1),
				"horizon": Color(1.0, 0.35, 0.08),
				"fog": Color(0.45, 0.14, 0.08),
				"ground": Color(0.12, 0.04, 0.05),
				"track": Color(0.12, 0.05, 0.06),
				"edge": Color(1.0, 0.4, 0.12),
				"ambient": Color(0.6, 0.22, 0.15),
				"light": Color(1.0, 0.58, 0.32),
				"cloud": Color(1.0, 0.45, 0.25, 0.45),
			}
		_: # Aurora Borealis
			return {
				"sky_top": Color(0.02, 0.12, 0.18),
				"sky": Color(0.06, 0.28, 0.32),
				"horizon": Color(0.25, 0.95, 0.65),
				"fog": Color(0.15, 0.4, 0.42),
				"ground": Color(0.04, 0.1, 0.12),
				"track": Color(0.05, 0.1, 0.12),
				"edge": Color(0.4, 1.0, 0.78),
				"ambient": Color(0.28, 0.58, 0.52),
				"light": Color(0.65, 1.0, 0.88),
				"cloud": Color(0.55, 1.0, 0.85, 0.42),
			}
