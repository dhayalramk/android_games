extends CharacterBody3D
## Chrome energy sphere — auto-rolls forward, drag to steer.

signal died(reason: String)
signal finished
signal gem_collected(value: int, streak: int)
signal boost_hit
signal supernova_started
signal supernova_ended
signal near_miss

enum State { READY, ROLLING, DEAD, WIN }

const RADIUS := 0.42
const GRAVITY := 34.0
const STEER_RESPONSIVENESS := 22.0
const MAX_LANE_SPEED := 14.0
const SUPERNOVA_STREAK_TIME := 4.0
const AIR_CONTROL := 0.65
const START_GRACE := 1.1

var state: State = State.READY
var base_speed: float = 12.0
var speed: float = 12.0
var steer_input: float = 0.0 # -1 .. 1
var throttle: float = 0.0 # -1 brake .. 0 cruise .. +1 full turbo (player-controlled)
var lane_x: float = 0.0
var track_half_width: float = 3.0
var is_supernova: bool = false
var safe_streak: float = 0.0
var gem_streak: int = 0
var boost_timer: float = 0.0
var air_time: float = 0.0
var spin: float = 0.0
var grace_timer: float = 0.0
var track_ref: Node3D = null
var finger_held: bool = false
var mesh: MeshInstance3D
var trail: GPUParticles3D
var aura: MeshInstance3D
var _mat: StandardMaterial3D
var _aura_mat: StandardMaterial3D

func _ready() -> void:
	_build_visuals()
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 0.45
	safe_margin = 0.08

func _build_visuals() -> void:
	var col := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = RADIUS
	col.shape = sphere
	add_child(col)

	mesh = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = RADIUS
	sm.height = RADIUS * 2.0
	mesh.mesh = sm
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color(0.8, 0.92, 1.0)
	_mat.metallic = 1.0
	_mat.roughness = 0.06
	_mat.emission_enabled = true
	_mat.emission = Color(0.25, 0.75, 1.0)
	_mat.emission_energy_multiplier = 1.8
	mesh.material_override = _mat
	add_child(mesh)

	aura = MeshInstance3D.new()
	var am := SphereMesh.new()
	am.radius = RADIUS * 1.4
	am.height = RADIUS * 2.8
	aura.mesh = am
	_aura_mat = StandardMaterial3D.new()
	_aura_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_aura_mat.albedo_color = Color(0.3, 0.85, 1.0, 0.22)
	_aura_mat.emission_enabled = true
	_aura_mat.emission = Color(0.3, 0.9, 1.0)
	_aura_mat.emission_energy_multiplier = 1.2
	_aura_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	aura.material_override = _aura_mat
	aura.visible = false
	add_child(aura)

	trail = GPUParticles3D.new()
	trail.amount = 64
	trail.lifetime = 0.5
	trail.emitting = false
	var proc := ParticleProcessMaterial.new()
	proc.direction = Vector3(0, 0.15, 1)
	proc.spread = 22.0
	proc.initial_velocity_min = 1.2
	proc.initial_velocity_max = 4.0
	proc.gravity = Vector3(0, 1.2, 0)
	proc.scale_min = 0.07
	proc.scale_max = 0.2
	proc.color = Color(0.45, 0.92, 1.0, 0.85)
	trail.process_material = proc
	var pmesh := SphereMesh.new()
	pmesh.radius = 0.07
	pmesh.height = 0.14
	trail.draw_pass_1 = pmesh
	trail.position = Vector3(0, 0, 0.4)
	add_child(trail)

func reset_for_level(start_pos: Vector3, cfg, track: Node3D = null) -> void:
	state = State.READY
	track_ref = track
	global_position = start_pos
	velocity = Vector3.ZERO
	lane_x = start_pos.x
	steer_input = 0.0
	throttle = 0.0
	finger_held = false
	base_speed = cfg.base_speed
	speed = cfg.base_speed
	track_half_width = cfg.track_width * 0.5 - RADIUS - 0.2
	is_supernova = false
	safe_streak = 0.0
	gem_streak = 0
	boost_timer = 0.0
	air_time = 0.0
	spin = 0.0
	grace_timer = START_GRACE
	visible = true
	mesh.visible = true
	aura.visible = false
	trail.emitting = false
	_apply_normal_look()

func start_rolling() -> void:
	if state == State.READY:
		state = State.ROLLING
		trail.emitting = true
		grace_timer = START_GRACE

func set_steer(amount: float) -> void:
	steer_input = clampf(amount, -1.0, 1.0)

func set_throttle(amount: float) -> void:
	throttle = clampf(amount, -1.0, 1.0)

func set_finger_held(held: bool) -> void:
	finger_held = held
	if not held:
		# Ease toward cruise when finger lifts
		throttle = lerpf(throttle, 0.0, 0.65)

func get_speed_ratio() -> float:
	# 0..1-ish for HUD (relative to base)
	return clampf(speed / maxf(base_speed, 0.1), 0.5, 2.2)

func is_player_turbo() -> bool:
	return throttle > 0.35 or boost_timer > 0.0

func _track_center() -> float:
	if track_ref and track_ref.has_method("center_at_z"):
		return float(track_ref.call("center_at_z", global_position.z))
	return 0.0

func _track_half() -> float:
	if track_ref and track_ref.has_method("width_at_z"):
		return float(track_ref.call("width_at_z", global_position.z)) * 0.5 - RADIUS - 0.15
	return track_half_width

func update_ball(delta: float) -> void:
	if state != State.ROLLING:
		return

	grace_timer = maxf(0.0, grace_timer - delta)

	# Player throttle: -1 brake (0.65x) … 0 cruise … +1 turbo (1.7x)
	# Boost pads and Supernova stack on top.
	var throttle_mult: float = 1.0 + throttle * (0.7 if throttle >= 0.0 else 0.35)
	var target_mult: float = throttle_mult
	if is_supernova:
		target_mult *= 1.22
	if boost_timer > 0.0:
		boost_timer = maxf(0.0, boost_timer - delta)
		target_mult *= 1.55
	# Hold finger at least keeps a tiny push so rolling feels alive
	if finger_held and throttle > -0.1:
		target_mult = maxf(target_mult, 1.05)
	speed = lerpf(speed, base_speed * target_mult, delta * 5.5)

	var center_x: float = _track_center()
	var half: float = _track_half()
	# Absolute lane target relative to moving track center
	var desired_x: float = center_x + steer_input * half * 0.92
	lane_x = lerpf(lane_x, desired_x, delta * 10.0)
	lane_x = clampf(lane_x, center_x - half * 1.05, center_x + half * 1.05)

	var edge_dist: float = absf(global_position.x - center_x) / maxf(half, 0.1)
	if edge_dist > 0.85 and is_on_floor() and randf() < delta * 3.0:
		near_miss.emit()

	var control := 1.0 if is_on_floor() else AIR_CONTROL
	velocity.x = lerpf(velocity.x, (lane_x - global_position.x) * STEER_RESPONSIVENESS * control, delta * 14.0)
	velocity.x = clampf(velocity.x, -MAX_LANE_SPEED, MAX_LANE_SPEED)
	velocity.z = -speed
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
		air_time += delta
	else:
		if air_time > 0.3:
			velocity.y = 2.4
		else:
			velocity.y = -5.0
		air_time = 0.0

	move_and_slide()

	# Soft edge bounce instead of instant death
	var lim: float = half + 0.35
	if absf(global_position.x - center_x) > lim:
		global_position.x = center_x + signf(global_position.x - center_x) * lim
		velocity.x *= -0.35
		lane_x = global_position.x

	spin += speed * delta * 2.4
	mesh.rotation_degrees = Vector3(spin * 42.0, 0.0, -steer_input * 28.0)
	if aura.visible:
		aura.rotate_y(delta * 4.0)

	if global_position.y < -8.0:
		if grace_timer > 0.0:
			# Rescue during start grace
			global_position = Vector3(center_x, 1.0, global_position.z)
			velocity = Vector3(0, 0, -speed)
			return
		_die("fall")
		return

	# Only punish deep off-track if not in grace and truly off floor for a bit
	if grace_timer <= 0.0 and not is_on_floor() and air_time > 1.6 and absf(global_position.x - center_x) > half + 1.8:
		_die("edge")
		return

	_update_supernova(delta)

func _update_supernova(delta: float) -> void:
	if state != State.ROLLING:
		return
	if is_supernova:
		safe_streak = SUPERNOVA_STREAK_TIME
		return
	safe_streak += delta
	if safe_streak >= SUPERNOVA_STREAK_TIME:
		_enter_supernova()

func collect_gem(value: int = 10) -> void:
	gem_streak += 1
	safe_streak = minf(safe_streak + 0.4, SUPERNOVA_STREAK_TIME)
	gem_collected.emit(value * mini(gem_streak, 8), gem_streak)

func hit_boost() -> void:
	boost_timer = 1.5
	safe_streak = minf(safe_streak + 0.9, SUPERNOVA_STREAK_TIME)
	boost_hit.emit()

func hit_hazard() -> void:
	if is_supernova or grace_timer > 0.0:
		return
	_die("hazard")

func reach_finish() -> void:
	if state != State.ROLLING:
		return
	state = State.WIN
	velocity = Vector3.ZERO
	trail.emitting = false
	finished.emit()

func _die(reason: String) -> void:
	if state != State.ROLLING:
		return
	state = State.DEAD
	velocity = Vector3.ZERO
	trail.emitting = false
	if is_supernova:
		_exit_supernova()
	mesh.visible = false
	died.emit(reason)

func _enter_supernova() -> void:
	is_supernova = true
	aura.visible = true
	_mat.emission = Color(1.0, 0.55, 0.12)
	_mat.emission_energy_multiplier = 5.0
	_mat.albedo_color = Color(1.0, 0.88, 0.45)
	_aura_mat.albedo_color = Color(1.0, 0.45, 0.1, 0.4)
	_aura_mat.emission = Color(1.0, 0.5, 0.1)
	_aura_mat.emission_energy_multiplier = 4.0
	var pm := trail.process_material as ParticleProcessMaterial
	if pm:
		pm.color = Color(1.0, 0.55, 0.12, 0.95)
	supernova_started.emit()

func _exit_supernova() -> void:
	is_supernova = false
	aura.visible = false
	_apply_normal_look()
	supernova_ended.emit()

var _skin_albedo: Color = Color(0.8, 0.92, 1.0)
var _skin_emission: Color = Color(0.25, 0.75, 1.0)
var _skin_energy: float = 1.8

func apply_skin(data: Dictionary) -> void:
	_skin_albedo = data.get("albedo", Color(0.8, 0.92, 1.0))
	_skin_emission = data.get("emission", Color(0.25, 0.75, 1.0))
	_skin_energy = float(data.get("energy", 1.8))
	if not is_supernova:
		_apply_normal_look()

func _apply_normal_look() -> void:
	if _mat == null:
		return
	_mat.albedo_color = _skin_albedo
	_mat.emission = _skin_emission
	_mat.emission_energy_multiplier = _skin_energy
	if trail and trail.process_material is ParticleProcessMaterial:
		var pm := trail.process_material as ParticleProcessMaterial
		pm.color = Color(_skin_emission.r, _skin_emission.g, _skin_emission.b, 0.85)
