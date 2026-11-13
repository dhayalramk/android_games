extends Node3D
## Neon Sky Roller 3D — solo leveling flow-state arcade.

const LevelConfigScript = preload("res://scripts/level_config.gd")
const PlayerScript = preload("res://scripts/player.gd")

@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var sun: DirectionalLight3D = $DirectionalLight3D
@onready var camera: Camera3D = $CameraRig/Camera3D
@onready var camera_rig: Node3D = $CameraRig
@onready var track: Node3D = $Track
@onready var player: CharacterBody3D = $Player
@onready var clouds: Node3D = $CloudField
@onready var fill_light: OmniLight3D = $FillLight

@onready var level_label: Label = $CanvasLayer/HUD/LevelLabel
@onready var title_label: Label = $CanvasLayer/HUD/TitleLabel
@onready var score_label: Label = $CanvasLayer/HUD/ScoreLabel
@onready var gem_label: Label = $CanvasLayer/HUD/GemLabel
@onready var streak_bar: ProgressBar = $CanvasLayer/HUD/StreakBar
@onready var hint_label: Label = $CanvasLayer/HUD/HintLabel
@onready var fever_label: Label = $CanvasLayer/HUD/FeverLabel
@onready var banner: Control = $CanvasLayer/Banner
@onready var banner_title: Label = $CanvasLayer/Banner/BannerTitle
@onready var banner_sub: Label = $CanvasLayer/Banner/BannerSub

var level: int = 1
var max_unlocked: int = 1
var score: int = 0
var gems: int = 0
var cfg
var dragging: bool = false
var drag_origin_x: float = 0.0
var camera_shake: float = 0.0
var fov_pulse: float = 0.0
var base_fov: float = 68.0
var cam_offset: Vector3 = Vector3(0, 4.8, 7.2)
var started: bool = false
var banner_timer: float = 0.0
var save_path := "user://neon_sky_roller.save"

func _ready() -> void:
	_load_progress()
	player.died.connect(_on_died)
	player.finished.connect(_on_finished)
	player.gem_collected.connect(_on_gem)
	player.boost_hit.connect(_on_boost)
	player.supernova_started.connect(_on_supernova_start)
	player.supernova_ended.connect(_on_supernova_end)
	player.near_miss.connect(_on_near_miss)
	track.gem_taken.connect(_on_gem_taken)
	track.boost_taken.connect(_on_boost_taken)
	track.hazard_hit.connect(_on_hazard)
	track.finish_reached.connect(_on_finish_gate)
	fever_label.visible = false
	_build_clouds()
	_start_level(maxi(1, max_unlocked))

func _build_clouds() -> void:
	for c in clouds.get_children():
		c.queue_free()
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in range(28):
		var puff := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = rng.randf_range(2.5, 6.0)
		sphere.height = sphere.radius * 1.4
		puff.mesh = sphere
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(1, 1, 1, 0.55)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.proximity_fade_enabled = true
		puff.material_override = m
		puff.position = Vector3(
			rng.randf_range(-40, 40),
			rng.randf_range(-18, -8),
			rng.randf_range(-220, 40)
		)
		clouds.add_child(puff)

func _start_level(lvl: int) -> void:
	level = lvl
	cfg = LevelConfigScript.for_level(level)
	var theme: Dictionary = LevelConfigScript.theme_colors(cfg.theme_index)
	_apply_theme(theme)

	var spawn: Vector3 = track.build(cfg, theme)
	player.reset_for_level(spawn, cfg)
	started = false
	score = 0
	_update_hud()

	banner.visible = true
	banner_title.text = "LEVEL %d" % level
	banner_sub.text = cfg.title
	banner_timer = 1.6
	hint_label.text = "Drag to steer · Tap to roll"
	hint_label.visible = true
	fever_label.visible = false

	camera_rig.global_position = player.global_position + cam_offset
	camera.fov = base_fov
	camera.look_at(player.global_position + Vector3(0, 0.4, -3), Vector3.UP)

func _apply_theme(theme: Dictionary) -> void:
	var env := world_env.environment
	env.background_mode = Environment.BG_COLOR
	env.background_color = theme["sky"]
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = theme["ambient"]
	env.ambient_light_energy = 0.85
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = true
	env.glow_intensity = 1.1
	env.glow_bloom = 0.35
	env.fog_enabled = true
	env.fog_light_color = theme["fog"]
	env.fog_density = 0.012
	env.fog_aerial_perspective = 0.4
	sun.light_color = theme["light"]
	sun.light_energy = 1.35

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_press(event.pressed, event.position)
	elif event is InputEventScreenTouch:
		_handle_press(event.pressed, event.position)
	elif event is InputEventMouseMotion and dragging:
		_handle_drag(event.position)
	elif event is InputEventScreenDrag:
		_handle_drag(event.position)

func _handle_press(pressed: bool, pos: Vector2) -> void:
	if pressed:
		if player.state == PlayerScript.State.DEAD:
			_start_level(level)
			return
		if player.state == PlayerScript.State.WIN:
			_start_level(level + 1)
			return
		if player.state == PlayerScript.State.READY:
			player.start_rolling()
			started = true
			hint_label.visible = false
			banner_timer = minf(banner_timer, 0.35)
		dragging = true
		drag_origin_x = pos.x
	else:
		dragging = false
		player.set_steer(0.0)

func _handle_drag(pos: Vector2) -> void:
	if not dragging or player.state != PlayerScript.State.ROLLING:
		return
	var dx := (pos.x - drag_origin_x) / (get_viewport().get_visible_rect().size.x * 0.28)
	player.set_steer(clampf(dx, -1.0, 1.0))
	drag_origin_x = lerpf(drag_origin_x, pos.x, 0.35)

func _process(delta: float) -> void:
	if banner_timer > 0.0:
		banner_timer -= delta
		banner.modulate.a = clampf(banner_timer * 2.0, 0.0, 1.0)
		if banner_timer <= 0.0:
			banner.visible = false

	player.update_ball(delta)
	_update_camera(delta)
	_update_streak_ui()
	fill_light.global_position = player.global_position + Vector3(0, 3.5, 1.5)
	fill_light.light_color = Color(1.0, 0.55, 0.2) if player.is_supernova else Color(0.4, 0.7, 1.0)
	fill_light.light_energy = 3.2 if player.is_supernova else 1.8

	# Drift clouds slowly for depth
	clouds.position.z = lerpf(clouds.position.z, -player.global_position.z * 0.15, delta * 0.8)

func _update_camera(delta: float) -> void:
	var speed_t := clampf((player.speed - 12.0) / 25.0, 0.0, 1.0)
	var desired_offset := cam_offset + Vector3(0, -0.6 * speed_t, 1.4 * speed_t)
	if player.air_time > 0.2:
		desired_offset += Vector3(0, 1.2, 2.0)
		fov_pulse = maxf(fov_pulse, 8.0)
	if player.is_supernova:
		desired_offset += Vector3(0, -0.4, 1.0)

	var target := player.global_position + desired_offset
	camera_rig.global_position = camera_rig.global_position.lerp(target, delta * 7.5)

	var look := player.global_position + Vector3(player.steer_input * 0.8, 0.3, -5.0)
	camera.look_at(look, Vector3.UP)

	var target_fov := base_fov + speed_t * 10.0 + fov_pulse
	if player.boost_timer > 0.0:
		target_fov += 6.0
	camera.fov = lerpf(camera.fov, target_fov, delta * 6.0)
	fov_pulse = maxf(0.0, fov_pulse - delta * 14.0)

	if camera_shake > 0.0:
		camera.position = Vector3(
			randf_range(-camera_shake, camera_shake),
			randf_range(-camera_shake, camera_shake),
			randf_range(-camera_shake * 0.4, camera_shake * 0.4)
		)
		camera_shake = maxf(0.0, camera_shake - delta * 5.0)
	else:
		camera.position = Vector3.ZERO

func _update_streak_ui() -> void:
	streak_bar.max_value = PlayerScript.SUPERNOVA_STREAK_TIME
	streak_bar.value = player.safe_streak if player.state == PlayerScript.State.ROLLING else 0.0

func _update_hud() -> void:
	level_label.text = "LEVEL %d" % level
	title_label.text = cfg.title if cfg else ""
	score_label.text = str(score)
	gem_label.text = "◆ %d" % gems

func _on_gem_taken(_gem: Node3D, value: int) -> void:
	player.collect_gem(value)

func _on_gem(value: int, streak: int) -> void:
	score += value
	gems += 1
	_update_hud()
	_vibrate(12)
	hint_label.visible = true
	hint_label.text = "COMBO x%d" % mini(streak, 8)
	# brief combo flash
	get_tree().create_timer(0.55).timeout.connect(func():
		if hint_label.text.begins_with("COMBO"):
			hint_label.visible = false
	)

func _on_boost_taken(_pad: Node3D) -> void:
	player.hit_boost()

func _on_boost() -> void:
	fov_pulse = 12.0
	camera_shake = 0.1
	_vibrate(35)
	hint_label.visible = true
	hint_label.text = "BOOST!"
	get_tree().create_timer(0.5).timeout.connect(func():
		if hint_label.text == "BOOST!":
			hint_label.visible = false
	)

func _on_hazard(_obs: Node3D) -> void:
	if player.is_supernova:
		camera_shake = 0.35
		score += 50
		_update_hud()
		_vibrate(80)
		# shatter juice — hide obstacle
		if is_instance_valid(_obs):
			_obs.queue_free()
		return
	player.hit_hazard()

func _on_finish_gate() -> void:
	player.reach_finish()

func _on_finished() -> void:
	score += cfg.finish_bonus
	gems += 5
	_update_hud()
	max_unlocked = maxi(max_unlocked, level + 1)
	_save_progress()
	banner.visible = true
	banner_title.text = "LEVEL CLEAR"
	banner_sub.text = "+%d  ·  Tap for Level %d" % [cfg.finish_bonus, level + 1]
	banner_timer = 99.0
	banner.modulate.a = 1.0
	camera_shake = 0.2
	_vibrate(120)

func _on_died(reason: String) -> void:
	banner.visible = true
	banner_title.text = "WIPEOUT"
	match reason:
		"fall":
			banner_sub.text = "Fell into the clouds · Tap to retry"
		"edge":
			banner_sub.text = "Slipped off the rail · Tap to retry"
		_:
			banner_sub.text = "Hit a barrier · Tap to retry"
	banner_timer = 99.0
	banner.modulate.a = 1.0
	camera_shake = 0.45
	_vibrate(220)

func _on_supernova_start() -> void:
	fever_label.visible = true
	fever_label.text = "SUPERNOVA"
	fov_pulse = 14.0
	camera_shake = 0.18
	_vibrate(100)

func _on_supernova_end() -> void:
	fever_label.visible = false

func _on_near_miss() -> void:
	score += 5
	_update_hud()
	_vibrate(8)

func _vibrate(ms: int) -> void:
	if OS.has_feature("android") or OS.has_feature("mobile"):
		Input.vibrate_handheld(ms)

func _save_progress() -> void:
	var f := ConfigFile.new()
	f.set_value("progress", "max_unlocked", max_unlocked)
	f.set_value("progress", "gems", gems)
	f.save(save_path)

func _load_progress() -> void:
	var f := ConfigFile.new()
	if f.load(save_path) == OK:
		max_unlocked = int(f.get_value("progress", "max_unlocked", 1))
		gems = int(f.get_value("progress", "gems", 0))
