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
const GRAVITY := 38.0
const STEER_RESPONSIVENESS := 18.0
const MAX_STEER := 16.0
const SUPERNOVA_STREAK_TIME := 4.5
const AIR_CONTROL := 0.55

var state: State = State.READY
var base_speed: float = 14.0
var speed: float = 14.0
var steer_input: float = 0.0 # -1 .. 1 target lane bias
var lane_x: float = 0.0
var track_half_width: float = 3.0
var is_supernova: bool = false
var safe_streak: float = 0.0
var gem_streak: int = 0
var boost_timer: float = 0.0
var air_time: float = 0.0
var spin: float = 0.0
var mesh: MeshInstance3D
var trail: GPUParticles3D
var aura: MeshInstance3D
var _mat: StandardMaterial3D
var _aura_mat: StandardMaterial3D

func _ready() -> void:
	_build_visuals()
	collision_layer = 2
	collision_mask = 1

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
	_mat.albedo_color = Color(0.75, 0.9, 1.0)
	_mat.metallic = 1.0
	_mat.roughness = 0.08
	_mat.emission_enabled = true
	_mat.emission = Color(0.2, 0.7, 1.0)
	_mat.emission_energy_multiplier = 1.4
	mesh.material_override = _mat
	add_child(mesh)

	aura = MeshInstance3D.new()
	var am := SphereMesh.new()
	am.radius = RADIUS * 1.35
	am.height = RADIUS * 2.7
	aura.mesh = am
	_aura_mat = StandardMaterial3D.new()
	_aura_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_aura_mat.albedo_color = Color(0.3, 0.85, 1.0, 0.18)
	_aura_mat.emission_enabled = true
	_aura_mat.emission = Color(0.3, 0.9, 1.0)
	_aura_mat.emission_energy_multiplier = 0.8
	_aura_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	aura.material_override = _aura_mat
	aura.visible = false
	add_child(aura)

	trail = GPUParticles3D.new()
	trail.amount = 48
	trail.lifetime = 0.45
	trail.emitting = false
	var proc := ParticleProcessMaterial.new()
	proc.direction = Vector3(0, 0.2, 1)
	proc.spread = 18.0
	proc.initial_velocity_min = 1.0
	proc.initial_velocity_max = 3.5
	proc.gravity = Vector3(0, 1.5, 0)
	proc.scale_min = 0.08
	proc.scale_max = 0.22
	proc.color = Color(0.4, 0.9, 1.0, 0.8)
	trail.process_material = proc
	var pmesh := SphereMesh.new()
	pmesh.radius = 0.08
	pmesh.height = 0.16
	trail.draw_pass_1 = pmesh
	trail.position = Vector3(0, 0, 0.35)
	add_child(trail)

func reset_for_level(start_pos: Vector3, cfg) -> void:
	state = State.READY
	global_position = start_pos
	velocity = Vector3.ZERO
	lane_x = start_pos.x
	steer_input = 0.0
	base_speed = cfg.base_speed
	speed = cfg.base_speed
	track_half_width = cfg.track_width * 0.5 - RADIUS - 0.15
	is_supernova = false
	safe_streak = 0.0
	gem_streak = 0
	boost_timer = 0.0
	air_time = 0.0
	spin = 0.0
	visible = true
	mesh.visible = true
	aura.visible = false
	trail.emitting = false
	_apply_normal_look()

func start_rolling() -> void:
	if state == State.READY:
		state = State.ROLLING
		trail.emitting = true

func set_steer(amount: float) -> void:
	steer_input = clampf(amount, -1.0, 1.0)

func update_ball(delta: float) -> void:
	if state != State.ROLLING:
		return

	if boost_timer > 0.0:
		boost_timer = maxf(0.0, boost_timer - delta)
		speed = lerpf(speed, base_speed * 1.85, delta * 6.0)
	else:
		speed = lerpf(speed, base_speed * (1.35 if is_supernova else 1.0), delta * 3.0)

	var target_x := lane_x + steer_input * MAX_STEER * delta * 10.0
	# Soft edge pressure — near miss when hugging rails
	var edge_limit := track_half_width
	if absf(target_x) > edge_limit * 0.82 and is_on_floor():
		if randf() < delta * 2.5:
			near_miss.emit()
	lane_x = clampf(target_x, -edge_limit * 1.35, edge_limit * 1.35)

	var control := 1.0 if is_on_floor() else AIR_CONTROL
	velocity.x = lerpf(velocity.x, (lane_x - global_position.x) * STEER_RESPONSIVENESS * control, delta * 12.0)
	velocity.z = -speed
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
		air_time += delta
	else:
		if air_time > 0.35:
			# soft landing bounce juice
			velocity.y = 2.8
		else:
			velocity.y = -4.0 # keep floor contact / snap
		air_time = 0.0

	move_and_slide()
	floor_snap_length = 0.35

	spin += speed * delta * 2.2
	mesh.rotation_degrees = Vector3(spin * 40.0, 0.0, -steer_input * 22.0)

	# Fall death
	if global_position.y < -6.0:
		_die("fall")
		return

	# Off-track while grounded too far sideways
	if is_on_floor() and absf(global_position.x) > track_half_width + 1.1:
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

func break_streak() -> void:
	safe_streak = 0.0
	if is_supernova:
		_exit_supernova()

func collect_gem(value: int = 10) -> void:
	gem_streak += 1
	safe_streak = minf(safe_streak + 0.35, SUPERNOVA_STREAK_TIME)
	gem_collected.emit(value * mini(gem_streak, 8), gem_streak)

func hit_boost() -> void:
	boost_timer = 1.4
	safe_streak = minf(safe_streak + 0.8, SUPERNOVA_STREAK_TIME)
	boost_hit.emit()

func hit_hazard() -> void:
	if is_supernova:
		safe_streak = SUPERNOVA_STREAK_TIME
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
	_mat.emission = Color(1.0, 0.55, 0.15)
	_mat.emission_energy_multiplier = 4.0
	_mat.albedo_color = Color(1.0, 0.85, 0.4)
	_aura_mat.albedo_color = Color(1.0, 0.45, 0.1, 0.35)
	_aura_mat.emission = Color(1.0, 0.5, 0.1)
	_aura_mat.emission_energy_multiplier = 3.0
	var pm := trail.process_material as ParticleProcessMaterial
	if pm:
		pm.color = Color(1.0, 0.55, 0.15, 0.9)
	supernova_started.emit()

func _exit_supernova() -> void:
	is_supernova = false
	aura.visible = false
	_apply_normal_look()
	supernova_ended.emit()

func _apply_normal_look() -> void:
	_mat.albedo_color = Color(0.75, 0.9, 1.0)
	_mat.emission = Color(0.2, 0.7, 1.0)
	_mat.emission_energy_multiplier = 1.4
	var pm := trail.process_material as ParticleProcessMaterial
	if pm:
		pm.color = Color(0.4, 0.9, 1.0, 0.8)
