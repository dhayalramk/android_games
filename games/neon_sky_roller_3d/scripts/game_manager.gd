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
var camera_shake: float = 0.0
var fov_pulse: float = 0.0
var base_fov: float = 70.0
var cam_offset: Vector3 = Vector3(0, 5.2, 7.8)
var started: bool = false
var banner_timer: float = 0.0
var save_path := "user://neon_sky_roller.save"
var _theme: Dictionary = {}
var _sky_mat: ProceduralSkyMaterial

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
	_setup_sky()
	_build_clouds()
	# Always offer the climb from the furthest unlocked stage
	_start_level(clampi(max_unlocked, 1, 99))

func _setup_sky() -> void:
	var env := world_env.environment
	var sky := Sky.new()
	_sky_mat = ProceduralSkyMaterial.new()
	sky.sky_material = _sky_mat
	env.sky = sky
	env.background_mode = Environment.BG_SKY

func _build_clouds() -> void:
	for c in clouds.get_children():
		c.queue_free()
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var cloud_col: Color = _theme.get("cloud", Color(1, 0.85, 0.75, 0.5))
	for i in range(36):
		var puff := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = rng.randf_range(3.0, 7.5)
		sphere.height = sphere.radius * 1.35
		puff.mesh = sphere
		var m := StandardMaterial3D.new()
		m.albedo_color = cloud_col
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		puff.material_override = m
		puff.position = Vector3(
			rng.randf_range(-55, 55),
			rng.randf_range(-22, -9),
			rng.randf_range(-260, 50)
		)
		clouds.add_child(puff)

func _start_level(lvl: int) -> void:
	level = lvl
	cfg = LevelConfigScript.for_level(level)
	_theme = LevelConfigScript.theme_colors(cfg.theme_index)
	_apply_theme(_theme)
	_build_clouds()

	var spawn: Vector3 = track.build(cfg, _theme)
	player.reset_for_level(spawn, cfg, track)
	started = false
	score = 0
	_update_hud()

	banner.visible = true
	banner_title.text = "LEVEL %d" % level
	banner_sub.text = cfg.title
	banner_timer = 1.45
	banner.modulate.a = 1.0
	hint_label.text = "Drag to steer · Tap to roll"
	hint_label.visible = true
	fever_label.visible = false

	camera_rig.global_position = player.global_position + cam_offset
	camera.fov = base_fov
	camera.look_at(player.global_position + Vector3(0, 0.5, -4), Vector3.UP)

func _apply_theme(theme: Dictionary) -> void:
	var env := world_env.environment
	if _sky_mat:
		_sky_mat.sky_top_color = theme.get("sky_top", theme["sky"])
		_sky_mat.sky_horizon_color = theme["horizon"]
		_sky_mat.ground_bottom_color = theme.get("ground", theme["fog"])
		_sky_mat.ground_horizon_color = theme["fog"]
		_sky_mat.sky_curve = 0.08
		_sky_mat.ground_curve = 0.12
		_sky_mat.sun_angle_max = 30.0
		_sky_mat.sun_curve = 0.15
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_color = theme["ambient"]
	env.ambient_light_energy = 0.95
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.05
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_bloom = 0.18
	env.glow_hdr_threshold = 0.85
	env.fog_enabled = true
	env.fog_light_color = theme["fog"]
	env.fog_density = 0.0065
	env.fog_aerial_perspective = 0.55
	env.fog_sky_affect = 0.35
	sun.light_color = theme["light"]
	sun.light_energy = 1.25
	RenderingServer.set_default_clear_color(theme["sky"])

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_press(event.pressed, event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		_handle_press(event.pressed, event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and dragging:
		_apply_steer_from_pos(event.position)
	elif event is InputEventScreenDrag:
		_apply_steer_from_pos(event.position)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if player.state == PlayerScript.State.DEAD or player.state == PlayerScript.State.WIN:
			_handle_press(true, event.position)
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and event.pressed:
		if player.state == PlayerScript.State.DEAD or player.state == PlayerScript.State.WIN:
			_handle_press(true, event.position)
			get_viewport().set_input_as_handled()

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
			banner_timer = minf(banner_timer, 0.3)
		dragging = true
		_apply_steer_from_pos(pos)
	else:
		dragging = false
		# Ease back toward center when finger lifts
		player.set_steer(player.steer_input * 0.35)

func _apply_steer_from_pos(pos: Vector2) -> void:
	if player.state != PlayerScript.State.ROLLING and player.state != PlayerScript.State.READY:
		return
	var w: float = maxf(get_viewport().get_visible_rect().size.x, 1.0)
	# Absolute finger X → lane (-1 left … +1 right)
	var nx: float = clampf((pos.x / w) * 2.0 - 1.0, -1.0, 1.0)
	player.set_steer(nx)

func _process(delta: float) -> void:
	if banner_timer > 0.0:
		banner_timer -= delta
		if player.state == PlayerScript.State.READY:
			banner.modulate.a = clampf(banner_timer * 2.0, 0.0, 1.0)
			if banner_timer <= 0.0:
				banner.visible = false

	player.update_ball(delta)
	_update_camera(delta)
	_update_streak_ui()
	fill_light.global_position = player.global_position + Vector3(0, 3.2, 1.2)
	fill_light.light_color = Color(1.0, 0.55, 0.2) if player.is_supernova else Color(0.45, 0.75, 1.0)
	fill_light.light_energy = 3.6 if player.is_supernova else 2.1

	clouds.global_position.x = lerpf(clouds.global_position.x, player.global_position.x * 0.25, delta)
	clouds.global_position.z = player.global_position.z * 0.2

func _update_camera(delta: float) -> void:
	var speed_t := clampf((player.speed - 11.0) / 22.0, 0.0, 1.0)
	var desired_offset := cam_offset + Vector3(0, -0.7 * speed_t, 1.6 * speed_t)
	if player.air_time > 0.2:
		desired_offset += Vector3(0, 1.4, 2.2)
		fov_pulse = maxf(fov_pulse, 9.0)
	if player.is_supernova:
		desired_offset += Vector3(0, -0.5, 1.2)

	var center_bias := 0.0
	if track.has_method("center_at_z"):
		center_bias = float(track.call("center_at_z", player.global_position.z))
	var target := player.global_position + desired_offset + Vector3(center_bias * 0.15, 0, 0)
	camera_rig.global_position = camera_rig.global_position.lerp(target, delta * 8.0)

	var look := player.global_position + Vector3(player.steer_input * 1.1 + center_bias * 0.2, 0.35, -6.0)
	camera.look_at(look, Vector3.UP)

	var target_fov := base_fov + speed_t * 12.0 + fov_pulse
	if player.boost_timer > 0.0:
		target_fov += 7.0
	camera.fov = lerpf(camera.fov, target_fov, delta * 6.0)
	fov_pulse = maxf(0.0, fov_pulse - delta * 14.0)

	if camera_shake > 0.0:
		camera.position = Vector3(
			randf_range(-camera_shake, camera_shake),
			randf_range(-camera_shake, camera_shake),
			randf_range(-camera_shake * 0.35, camera_shake * 0.35)
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
	get_tree().create_timer(0.5).timeout.connect(func():
		if hint_label.text.begins_with("COMBO"):
			hint_label.visible = false
	)

func _on_boost_taken(_pad: Node3D) -> void:
	player.hit_boost()

func _on_boost() -> void:
	fov_pulse = 14.0
	camera_shake = 0.12
	_vibrate(35)
	hint_label.visible = true
	hint_label.text = "BOOST!"
	get_tree().create_timer(0.45).timeout.connect(func():
		if hint_label.text == "BOOST!":
			hint_label.visible = false
	)

func _on_hazard(_obs: Node3D) -> void:
	if player.is_supernova:
		camera_shake = 0.4
		score += 60
		_update_hud()
		_vibrate(90)
		if is_instance_valid(_obs):
			_spawn_shatter(_obs.global_position)
			_obs.queue_free()
		return
	player.hit_hazard()

func _spawn_shatter(pos: Vector3) -> void:
	var bits := GPUParticles3D.new()
	bits.position = pos
	bits.amount = 28
	bits.lifetime = 0.7
	bits.one_shot = true
	bits.emitting = true
	var proc := ParticleProcessMaterial.new()
	proc.direction = Vector3(0, 1, 0)
	proc.spread = 180.0
	proc.initial_velocity_min = 4.0
	proc.initial_velocity_max = 10.0
	proc.gravity = Vector3(0, -12, 0)
	proc.scale_min = 0.08
	proc.scale_max = 0.22
	proc.color = Color(1.0, 0.4, 0.2, 1)
	bits.process_material = proc
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.18, 0.18, 0.18)
	bits.draw_pass_1 = mesh
	add_child(bits)
	get_tree().create_timer(1.0).timeout.connect(bits.queue_free)

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
	camera_shake = 0.22
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
	fov_pulse = 16.0
	camera_shake = 0.2
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
