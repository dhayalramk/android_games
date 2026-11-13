extends Node3D
## Neon Sky Roller 3D — solo leveling flow-state arcade.

const LevelConfigScript = preload("res://scripts/level_config.gd")
const PlayerScript = preload("res://scripts/player.gd")
const ProgressScript = preload("res://scripts/progress.gd")
const MetaHubScript = preload("res://scripts/meta_hub.gd")
const UI = preload("res://scripts/ui_style.gd")
const SfxScript = preload("res://scripts/sfx.gd")

@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var sun: DirectionalLight3D = $DirectionalLight3D
@onready var camera: Camera3D = $CameraRig/Camera3D
@onready var camera_rig: Node3D = $CameraRig
@onready var track: Node3D = $Track
@onready var player: CharacterBody3D = $Player
@onready var clouds: Node3D = $CloudField
@onready var fill_light: OmniLight3D = $FillLight
@onready var canvas: CanvasLayer = $CanvasLayer

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
@onready var hud: Control = $CanvasLayer/HUD

var progress
var hub: Control
var in_hub: bool = true
var level: int = 1
var score: int = 0
var run_gems: int = 0
var used_supernova: bool = false
var used_turbo: bool = false
var cfg
var dragging: bool = false
var camera_shake: float = 0.0
var fov_pulse: float = 0.0
var base_fov: float = 70.0
var cam_offset: Vector3 = Vector3(0, 5.2, 7.8)
var started: bool = false
var banner_timer: float = 0.0
var _theme: Dictionary = {}
var _sky_mat: ProceduralSkyMaterial
var speed_label: Label
var speed_bar: ProgressBar
var turbo_hint: Label
var home_btn: Button
var sfx: Node
var sun_disk: MeshInstance3D
var horizon_glow: MeshInstance3D

func _ready() -> void:
	progress = ProgressScript.new()
	progress.load_save()
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
	sfx = SfxScript.new()
	add_child(sfx)
	_setup_speed_hud()
	_setup_home_button()
	_polish_hud()
	_setup_sky()
	_build_world_dressing()
	_build_clouds()
	_setup_hub()
	player.apply_skin(progress.skin_data())
	_show_hub()

func _polish_hud() -> void:
	UI.label_outline(level_label, Color(1, 0.96, 0.88), 30, Color(0, 0, 0, 0.7), 8)
	UI.label_outline(title_label, Color(1.0, 0.65, 0.28), 18, Color(0, 0, 0, 0.65), 5)
	UI.label_outline(score_label, Color(1, 1, 1), 52, Color(0, 0, 0, 0.55), 10)
	UI.label_outline(gem_label, Color(0.45, 1.0, 0.95), 22, Color(0, 0, 0, 0.55), 5)
	UI.label_outline(hint_label, Color(1, 1, 1, 0.95), 18, Color(0, 0, 0, 0.6), 5)
	UI.label_outline(fever_label, Color(1.0, 0.55, 0.15), 44, Color(0.25, 0.05, 0, 0.85), 10)
	UI.label_outline(banner_title, Color(1, 0.95, 0.8), 36, Color(0, 0, 0, 0.7), 8)
	UI.label_outline(banner_sub, Color(0.85, 0.95, 1.0), 16, Color(0, 0, 0, 0.55), 4)
	var wash: ColorRect = hud.get_node_or_null("TopWash")
	if wash:
		wash.color = Color(0.02, 0.03, 0.08, 0.55)
	var banner_bg: ColorRect = banner.get_node_or_null("BannerBg")
	if banner_bg:
		banner_bg.color = Color(0.04, 0.05, 0.1, 0.82)

func _setup_speed_hud() -> void:
	speed_label = Label.new()
	speed_label.name = "SpeedLabel"
	speed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	speed_label.add_theme_font_size_override("font_size", 18)
	speed_label.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0, 0.95))
	speed_label.text = "SPEED"
	speed_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	speed_label.offset_left = 24
	speed_label.offset_top = 44
	speed_label.offset_right = 160
	speed_label.offset_bottom = 72
	speed_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(speed_label)

	speed_bar = ProgressBar.new()
	speed_bar.name = "SpeedBar"
	speed_bar.max_value = 2.0
	speed_bar.value = 1.0
	speed_bar.show_percentage = false
	speed_bar.set_anchors_preset(Control.PRESET_TOP_LEFT)
	speed_bar.offset_left = 24
	speed_bar.offset_top = 72
	speed_bar.offset_right = 170
	speed_bar.offset_bottom = 88
	speed_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(speed_bar)

	turbo_hint = Label.new()
	turbo_hint.name = "TurboHint"
	turbo_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turbo_hint.add_theme_font_size_override("font_size", 16)
	turbo_hint.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35, 0.0))
	turbo_hint.text = "TURBO"
	turbo_hint.set_anchors_preset(Control.PRESET_CENTER_TOP)
	turbo_hint.offset_left = -80
	turbo_hint.offset_top = 168
	turbo_hint.offset_right = 80
	turbo_hint.offset_bottom = 196
	turbo_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(turbo_hint)

func _setup_home_button() -> void:
	home_btn = Button.new()
	home_btn.text = "⌂ HOME"
	home_btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
	home_btn.offset_left = 20
	home_btn.offset_top = 100
	home_btn.offset_right = 128
	home_btn.offset_bottom = 136
	home_btn.visible = false
	UI.apply_button(home_btn, Color(0.1, 0.12, 0.2, 0.85), Color(0.5, 0.8, 1.0, 0.45), Color(1, 1, 1), 14)
	home_btn.pressed.connect(_show_hub)
	hud.add_child(home_btn)

func _setup_hub() -> void:
	hub = MetaHubScript.new()
	hub.z_index = 20
	canvas.add_child(hub)
	hub.setup(progress)
	hub.play_pressed.connect(_on_hub_play)
	hub.skin_changed.connect(_on_skin_changed)

func _show_hub() -> void:
	in_hub = true
	hub.visible = true
	hub.refresh()
	hud.visible = false
	banner.visible = false
	home_btn.visible = false
	player.state = PlayerScript.State.READY
	player.velocity = Vector3.ZERO
	dragging = false

func _on_hub_play(lvl: int) -> void:
	in_hub = false
	hub.visible = false
	hud.visible = true
	home_btn.visible = true
	_start_level(clampi(lvl, 1, 999))

func _on_skin_changed() -> void:
	player.apply_skin(progress.skin_data())

func _setup_sky() -> void:
	var env := world_env.environment
	var sky := Sky.new()
	_sky_mat = ProceduralSkyMaterial.new()
	sky.sky_material = _sky_mat
	env.sky = sky
	env.background_mode = Environment.BG_SKY

func _build_world_dressing() -> void:
	if sun_disk and is_instance_valid(sun_disk):
		sun_disk.queue_free()
	if horizon_glow and is_instance_valid(horizon_glow):
		horizon_glow.queue_free()

	sun_disk = MeshInstance3D.new()
	var sun_mesh := SphereMesh.new()
	sun_mesh.radius = 18.0
	sun_mesh.height = 36.0
	sun_disk.mesh = sun_mesh
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.albedo_color = Color(1.0, 0.85, 0.45)
	sm.emission_enabled = true
	sm.emission = Color(1.0, 0.7, 0.25)
	sm.emission_energy_multiplier = 8.0
	sun_disk.material_override = sm
	add_child(sun_disk)

	horizon_glow = MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 22.0
	ring.outer_radius = 34.0
	horizon_glow.mesh = ring
	horizon_glow.rotation_degrees = Vector3(90, 0, 0)
	var hm := StandardMaterial3D.new()
	hm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hm.albedo_color = Color(1.0, 0.55, 0.2, 0.35)
	hm.emission_enabled = true
	hm.emission = Color(1.0, 0.45, 0.15)
	hm.emission_energy_multiplier = 3.0
	horizon_glow.material_override = hm
	add_child(horizon_glow)

func _build_clouds() -> void:
	for c in clouds.get_children():
		c.queue_free()
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var cloud_col: Color = _theme.get("cloud", Color(1, 0.85, 0.75, 0.5))
	for i in range(42):
		var puff := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		var r: float = rng.randf_range(4.0, 10.0)
		sphere.radius = r
		sphere.height = r * 0.55 # flattened pancake clouds
		puff.mesh = sphere
		var m := StandardMaterial3D.new()
		m.albedo_color = cloud_col
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		puff.material_override = m
		puff.position = Vector3(
			rng.randf_range(-70, 70),
			rng.randf_range(-26, -10),
			rng.randf_range(-280, 60)
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
	player.apply_skin(progress.skin_data())
	started = false
	score = 0
	run_gems = 0
	used_supernova = false
	used_turbo = false
	_update_hud()

	banner.visible = true
	banner_title.text = "LEVEL %d" % level
	var stars: int = progress.stars_for(level)
	var star_txt := ""
	for i in range(3):
		star_txt += "★" if i < stars else "☆"
	banner_sub.text = "%s  %s" % [cfg.title, star_txt]
	banner_timer = 1.45
	banner.modulate.a = 1.0
	hint_label.text = "Drag ←→ steer · ↑ turbo · ↓ brake"
	hint_label.visible = true
	fever_label.visible = false
	if turbo_hint:
		turbo_hint.modulate.a = 0.0

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
	if in_hub:
		return
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
	# Dev/desktop helper: P starts play from hub
	if event is InputEventKey and event.pressed and event.keycode == KEY_P:
		if in_hub:
			_on_hub_play(progress.max_unlocked)
		return
	if in_hub:
		return
	if event is InputEventMouseButton and event.pressed:
		if player.state == PlayerScript.State.DEAD or player.state == PlayerScript.State.WIN:
			_handle_press(true, event.position)
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and event.pressed:
		if player.state == PlayerScript.State.DEAD or player.state == PlayerScript.State.WIN:
			_handle_press(true, event.position)
			get_viewport().set_input_as_handled()

func _handle_press(pressed: bool, pos: Vector2) -> void:
	if in_hub:
		return
	if pressed:
		if player.state == PlayerScript.State.DEAD:
			_start_level(level)
			return
		if player.state == PlayerScript.State.WIN:
			# After clear: next level, or home if they want the meta loop
			_start_level(level + 1)
			return
		if player.state == PlayerScript.State.READY:
			player.start_rolling()
			started = true
			hint_label.visible = false
			banner_timer = minf(banner_timer, 0.3)
		dragging = true
		player.set_finger_held(true)
		_apply_controls_from_pos(pos)
	else:
		dragging = false
		player.set_finger_held(false)
		# Ease back toward center when finger lifts
		player.set_steer(player.steer_input * 0.35)

func _apply_steer_from_pos(pos: Vector2) -> void:
	_apply_controls_from_pos(pos)

func _apply_controls_from_pos(pos: Vector2) -> void:
	if player.state != PlayerScript.State.ROLLING and player.state != PlayerScript.State.READY:
		return
	var rect := get_viewport().get_visible_rect().size
	var w: float = maxf(rect.x, 1.0)
	var h: float = maxf(rect.y, 1.0)
	# Absolute finger X → lane (-1 left … +1 right)
	var nx: float = clampf((pos.x / w) * 2.0 - 1.0, -1.0, 1.0)
	player.set_steer(nx)
	# Finger Y → speed: top = turbo (+1), mid = cruise (0), bottom = brake (-1)
	var ny: float = clampf(1.0 - (pos.y / h) * 2.0, -1.0, 1.0)
	player.set_throttle(ny)

func _process(delta: float) -> void:
	if in_hub:
		return
	if banner_timer > 0.0:
		banner_timer -= delta
		if player.state == PlayerScript.State.READY:
			banner.modulate.a = clampf(banner_timer * 2.0, 0.0, 1.0)
			if banner_timer <= 0.0:
				banner.visible = false

	if player.throttle > 0.4:
		used_turbo = true

	player.update_ball(delta)
	_update_camera(delta)
	_update_streak_ui()
	_update_speed_hud(delta)
	fill_light.global_position = player.global_position + Vector3(0, 3.2, 1.2)
	fill_light.light_color = Color(1.0, 0.55, 0.2) if player.is_supernova else Color(0.45, 0.75, 1.0)
	fill_light.light_energy = 3.6 if player.is_supernova else 2.1

	clouds.global_position.x = lerpf(clouds.global_position.x, player.global_position.x * 0.25, delta)
	clouds.global_position.z = player.global_position.z * 0.2

	# Sun hangs on the horizon ahead of the player
	if sun_disk:
		sun_disk.global_position = player.global_position + Vector3(0, 14.0, -120.0)
		var sc: Color = _theme.get("horizon", Color(1.0, 0.6, 0.3))
		var smat := sun_disk.material_override as StandardMaterial3D
		if smat:
			smat.albedo_color = sc
			smat.emission = sc
	if horizon_glow:
		horizon_glow.global_position = player.global_position + Vector3(0, 2.0, -95.0)

func _update_speed_hud(delta: float) -> void:
	if speed_bar == null or speed_label == null:
		return
	var ratio: float = player.get_speed_ratio()
	speed_bar.value = ratio
	var kmh: int = int(round(player.speed * 4.2))
	if player.is_player_turbo():
		speed_label.text = "TURBO  %d" % kmh
		speed_label.add_theme_color_override("font_color", Color(1.0, 0.75, 0.25, 1.0))
		turbo_hint.modulate.a = lerpf(turbo_hint.modulate.a, 1.0, delta * 8.0)
		if player.throttle > 0.55 and player.state == PlayerScript.State.ROLLING:
			fov_pulse = maxf(fov_pulse, 6.0 + player.throttle * 6.0)
	elif player.throttle < -0.35:
		speed_label.text = "BRAKE  %d" % kmh
		speed_label.add_theme_color_override("font_color", Color(0.55, 0.85, 1.0, 1.0))
		turbo_hint.modulate.a = lerpf(turbo_hint.modulate.a, 0.0, delta * 6.0)
	else:
		speed_label.text = "SPEED  %d" % kmh
		speed_label.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0, 0.95))
		turbo_hint.modulate.a = lerpf(turbo_hint.modulate.a, 0.0, delta * 6.0)

func _update_camera(delta: float) -> void:
	var speed_t := clampf((player.speed - 11.0) / 22.0, 0.0, 1.0)
	var desired_offset := cam_offset + Vector3(0, -0.7 * speed_t, 1.6 * speed_t)
	if player.air_time > 0.2:
		desired_offset += Vector3(0, 1.4, 2.2)
		fov_pulse = maxf(fov_pulse, 9.0)
	if player.is_supernova:
		desired_offset += Vector3(0, -0.5, 1.2)
	if player.throttle > 0.4:
		desired_offset += Vector3(0, -0.35 * player.throttle, 0.9 * player.throttle)

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
	gem_label.text = "◆ %d" % progress.gems

func _on_gem_taken(_gem: Node3D, value: int) -> void:
	player.collect_gem(value)

func _on_gem(value: int, streak: int) -> void:
	score += value
	run_gems += 1
	progress.gems += 1
	progress.add_mission_progress("gem", 1)
	_update_hud()
	_vibrate(12)
	if sfx:
		sfx.gem(streak)
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
	if sfx:
		sfx.boost()
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
	var awards: Dictionary = progress.record_clear(level, score, run_gems, used_supernova, used_turbo)
	_update_hud()
	var star_txt := ""
	for i in range(3):
		star_txt += "★" if i < int(awards["stars"]) else "☆"
	banner.visible = true
	banner_title.text = "LEVEL CLEAR  %s" % star_txt
	var sub := "+◆%d  XP+%d  ·  Tap → L%d" % [int(awards["clear_gems"]), int(awards["xp"]), level + 1]
	if bool(awards.get("rank_up", false)):
		sub += "  ·  RANK UP!"
	if int(awards.get("mission_gems", 0)) > 0:
		sub += "  ·  Mission +◆%d" % int(awards["mission_gems"])
	sub += "\n%s" % progress.reason_to_return()
	banner_sub.text = sub
	banner_timer = 99.0
	banner.modulate.a = 1.0
	camera_shake = 0.22
	_vibrate(120)
	if sfx:
		sfx.clear()

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
	banner_sub.text += "\n%s" % progress.reason_to_return()
	banner_timer = 99.0
	banner.modulate.a = 1.0
	camera_shake = 0.45
	_vibrate(220)
	if sfx:
		sfx.die()

func _on_supernova_start() -> void:
	used_supernova = true
	progress.add_mission_progress("supernova", 1)
	fever_label.visible = true
	fever_label.text = "SUPERNOVA"
	fov_pulse = 16.0
	camera_shake = 0.2
	_vibrate(100)
	if sfx:
		sfx.supernova()

func _on_supernova_end() -> void:
	fever_label.visible = false

func _on_near_miss() -> void:
	score += 5
	_update_hud()
	_vibrate(8)

func _vibrate(ms: int) -> void:
	if OS.has_feature("android") or OS.has_feature("mobile"):
		Input.vibrate_handheld(ms)
