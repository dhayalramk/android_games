extends Node3D
## Procedural suspended sky highway for each solo level.

signal gem_taken(gem: Node3D, value: int)
signal boost_taken(pad: Node3D)
signal hazard_hit(obstacle: Node3D)
signal finish_reached

const SpinnerScript = preload("res://scripts/spinner.gd")
const SEGMENT_LEN := 8.0
const RADIUS_SPAWN := 0.42

var cfg
var finish_z: float = -80.0
var edge_color: Color = Color(1.0, 0.55, 0.2)
var track_color: Color = Color(0.12, 0.1, 0.18)
var _rng := RandomNumberGenerator.new()
var _pickups: Array[Node3D] = []

func clear_track() -> void:
	for c in get_children():
		c.queue_free()
	_pickups.clear()

func center_at_z(z: float) -> float:
	if cfg == null:
		return 0.0
	var progress: float = clampf((-z) / maxf(float(cfg.track_length), 1.0), 0.0, 1.0)
	return sin(progress * TAU * (0.35 + float(cfg.curve_strength) * 0.08)) * float(cfg.curve_strength)

func width_at_z(z: float) -> float:
	if cfg == null:
		return 6.0
	var progress: float = clampf((-z) / maxf(float(cfg.track_length), 1.0), 0.0, 1.0)
	var width: float = float(cfg.track_width) * (1.0 - progress * 0.08 * float(cfg.level > 4))
	return maxf(width, 3.4)

func build(level_cfg, theme: Dictionary) -> Vector3:
	clear_track()
	cfg = level_cfg
	_rng.seed = 9000 + level_cfg.level * 97
	edge_color = theme.get("edge", edge_color)
	track_color = theme.get("track", track_color)

	var z := 0.0
	var x_center := 0.0
	var segments := int(ceil(cfg.track_length / SEGMENT_LEN))
	finish_z = -cfg.track_length

	# Long safe runway
	_add_platform(Vector3(0, 0, 2.0), cfg.track_width + 2.0, 8.0, true)
	_add_edge_rails(0.0, 8.0, cfg.track_width + 2.0, 2.0)
	_add_support(0.0, 2.0)

	var gem_budget: int = int(cfg.track_length / cfg.gem_spacing)
	var gems_placed: int = 0
	var obstacles_left: int = int(cfg.obstacle_count)
	var boosts_left: int = int(cfg.boost_count)
	var spinners_left: int = int(cfg.spinner_count)

	for i in range(segments):
		var progress: float = float(i) / float(maxi(segments - 1, 1))
		x_center = center_at_z(-(i + 0.5) * SEGMENT_LEN)
		var width: float = float(cfg.track_width) * (1.0 - progress * 0.08 * float(cfg.level > 4))
		width = maxf(width, 3.4)

		var is_gap := false
		# Never gap the first 3 segments; keep landings generous
		if i > 3 and i < segments - 3 and _rng.randf() < float(cfg.gap_chance):
			is_gap = true

		if is_gap:
			_add_ramp(Vector3(x_center, 0.0, z - 1.2), width * 0.95)
			z -= SEGMENT_LEN * 0.9
			var land_z: float = z - SEGMENT_LEN * 0.4
			_add_platform(Vector3(x_center, 0.0, land_z), width + 0.4, SEGMENT_LEN * 0.85, true)
			_add_edge_rails(x_center, SEGMENT_LEN * 0.85, width + 0.4, land_z)
			_add_support(x_center, land_z)
			z -= SEGMENT_LEN
		else:
			var seg_z: float = z - SEGMENT_LEN * 0.5
			_add_platform(Vector3(x_center, 0.0, seg_z), width, SEGMENT_LEN + 0.15, true)
			_add_edge_rails(x_center, SEGMENT_LEN + 0.15, width, seg_z)
			if i % 2 == 0:
				_add_support(x_center, seg_z)
			z -= SEGMENT_LEN

		# Gems weave but stay collectible
		if gems_placed < gem_budget and i > 0 and not is_gap:
			var gx: float = x_center + sin(i * 0.9) * (width * 0.22)
			_add_gem(Vector3(gx, 0.9, z + SEGMENT_LEN * 0.5))
			gems_placed += 1

		if boosts_left > 0 and i > 2 and i % maxi(segments / maxi(int(cfg.boost_count), 1), 3) == 0:
			_add_boost(Vector3(x_center, 0.06, z + SEGMENT_LEN * 0.55), width * 0.5)
			boosts_left -= 1

		# Side hazards only — keep center lane open for flow
		if obstacles_left > 0 and i > 3 and i < segments - 2 and _rng.randf() < 0.4:
			var side: float = -1.0 if _rng.randf() < 0.5 else 1.0
			var ox: float = x_center + side * (width * 0.36)
			_add_obstacle(Vector3(ox, 0.75, z + SEGMENT_LEN * 0.4), false)
			obstacles_left -= 1

		if spinners_left > 0 and i > 5 and i < segments - 3 and _rng.randf() < 0.35:
			var side2: float = -1.0 if _rng.randf() < 0.5 else 1.0
			_add_obstacle(Vector3(x_center + side2 * width * 0.15, 0.95, z + SEGMENT_LEN * 0.25), true)
			spinners_left -= 1

	# Finish runway
	_add_platform(Vector3(x_center, 0.0, finish_z - 4.0), cfg.track_width + 2.4, 14.0, true)
	_add_edge_rails(x_center, 14.0, cfg.track_width + 2.4, finish_z - 4.0)
	_add_finish_gate(Vector3(x_center, 0.0, finish_z - 2.0), cfg.track_width + 1.8)

	return Vector3(0, 0.35 * 0.5 + RADIUS_SPAWN + 0.08, 3.5)

func _track_material(emissive: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = track_color
	m.metallic = 0.7
	m.roughness = 0.28
	if emissive:
		m.emission_enabled = true
		m.emission = edge_color
		m.emission_energy_multiplier = 1.8
	return m

func _add_platform(pos: Vector3, width: float, length: float, collides: bool) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = pos

	var mesh_i := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(width, 0.35, length)
	mesh_i.mesh = box
	mesh_i.material_override = _track_material()
	body.add_child(mesh_i)

	# Center neon strip
	var strip := MeshInstance3D.new()
	var sb := BoxMesh.new()
	sb.size = Vector3(maxf(0.16, width * 0.05), 0.06, length * 0.98)
	strip.mesh = sb
	strip.position = Vector3(0, 0.2, 0)
	var sm := StandardMaterial3D.new()
	sm.albedo_color = edge_color
	sm.emission_enabled = true
	sm.emission = edge_color
	sm.emission_energy_multiplier = 4.0
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	strip.material_override = sm
	body.add_child(strip)

	# Soft under-glow slab
	var glow := MeshInstance3D.new()
	var gb := BoxMesh.new()
	gb.size = Vector3(width * 0.92, 0.08, length * 0.95)
	glow.mesh = gb
	glow.position = Vector3(0, -0.22, 0)
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(edge_color.r, edge_color.g, edge_color.b, 0.35)
	gm.emission_enabled = true
	gm.emission = edge_color
	gm.emission_energy_multiplier = 1.2
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.material_override = gm
	body.add_child(glow)

	if collides:
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(width, 0.35, length)
		col.shape = shape
		body.add_child(col)

	add_child(body)

func _add_support(x_center: float, z_center: float) -> void:
	var pillar := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.18
	cyl.bottom_radius = 0.35
	cyl.height = 14.0
	pillar.mesh = cyl
	pillar.position = Vector3(x_center, -7.2, z_center)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.08, 0.08, 0.12)
	m.metallic = 0.8
	m.roughness = 0.4
	m.emission_enabled = true
	m.emission = edge_color * 0.35
	m.emission_energy_multiplier = 0.6
	pillar.material_override = m
	add_child(pillar)

func _add_edge_rails(x_center: float, length: float, width: float, z_center: float) -> void:
	for side in [-1.0, 1.0]:
		var rail := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.14, 0.28, length)
		rail.mesh = box
		rail.position = Vector3(x_center + side * (width * 0.5), 0.3, z_center)
		var m := StandardMaterial3D.new()
		m.albedo_color = edge_color
		m.emission_enabled = true
		m.emission = edge_color
		m.emission_energy_multiplier = 3.0
		rail.material_override = m
		add_child(rail)

func _add_ramp(pos: Vector3, width: float) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.position = pos
	body.rotation_degrees = Vector3(-16, 0, 0)

	var mesh_i := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(width, 0.3, 4.0)
	mesh_i.mesh = box
	var m := _track_material(true)
	m.emission = Color(1.0, 0.9, 0.35)
	m.emission_energy_multiplier = 3.5
	mesh_i.material_override = m
	body.add_child(mesh_i)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(width, 0.3, 4.0)
	col.shape = shape
	body.add_child(col)
	add_child(body)

func _add_gem(pos: Vector3) -> void:
	var area := Area3D.new()
	area.position = pos
	area.collision_layer = 0
	area.collision_mask = 2
	area.monitoring = true
	area.set_meta("kind", "gem")
	area.set_meta("value", 10)

	var mesh_i := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(0.5, 0.6, 0.5)
	mesh_i.mesh = prism
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.45, 1.0, 0.95)
	m.emission_enabled = true
	m.emission = Color(0.35, 1.0, 0.92)
	m.emission_energy_multiplier = 5.0
	m.metallic = 0.55
	m.roughness = 0.15
	mesh_i.material_override = m
	area.add_child(mesh_i)

	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.6
	col.shape = shape
	area.add_child(col)

	area.body_entered.connect(_on_pickup_body.bind(area))
	add_child(area)
	_pickups.append(area)

func _add_boost(pos: Vector3, width: float) -> void:
	var area := Area3D.new()
	area.position = pos
	area.collision_layer = 0
	area.collision_mask = 2
	area.set_meta("kind", "boost")

	var mesh_i := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(width, 0.08, 1.8)
	mesh_i.mesh = box
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 0.88, 0.25)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.85, 0.15)
	m.emission_energy_multiplier = 6.0
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_i.material_override = m
	area.add_child(mesh_i)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(width, 0.9, 1.8)
	col.shape = shape
	area.add_child(col)

	area.body_entered.connect(_on_pickup_body.bind(area))
	add_child(area)

func _add_obstacle(pos: Vector3, spinning: bool) -> void:
	var root := Node3D.new()
	root.position = pos
	root.set_meta("kind", "hazard")
	root.set_meta("spinning", spinning)

	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	area.set_meta("kind", "hazard")

	var mesh_i := MeshInstance3D.new()
	if spinning:
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.16
		cyl.bottom_radius = 0.16
		cyl.height = 2.6
		mesh_i.mesh = cyl
		mesh_i.rotation_degrees = Vector3(0, 0, 90)
	else:
		var box := BoxMesh.new()
		box.size = Vector3(0.95, 1.35, 0.65)
		mesh_i.mesh = box

	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.9, 0.12, 0.38)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.18, 0.4)
	m.emission_energy_multiplier = 3.0
	m.metallic = 0.55
	mesh_i.material_override = m
	area.add_child(mesh_i)

	var col := CollisionShape3D.new()
	if spinning:
		var shape := BoxShape3D.new()
		shape.size = Vector3(2.5, 0.4, 0.4)
		col.shape = shape
	else:
		var shape := BoxShape3D.new()
		shape.size = Vector3(0.95, 1.35, 0.65)
		col.shape = shape
	area.add_child(col)

	area.body_entered.connect(_on_hazard_body.bind(root))
	root.add_child(area)

	if spinning:
		root.set_script(SpinnerScript)

	add_child(root)

func _add_finish_gate(pos: Vector3, width: float) -> void:
	var area := Area3D.new()
	area.position = pos + Vector3(0, 1.5, 0)
	area.collision_layer = 0
	area.collision_mask = 2
	area.set_meta("kind", "finish")

	for side in [-1.0, 1.0]:
		var pillar := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.22
		cyl.bottom_radius = 0.28
		cyl.height = 3.8
		pillar.mesh = cyl
		pillar.position = Vector3(side * width * 0.45, 0.0, 0)
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.55, 1.0, 0.55)
		m.emission_enabled = true
		m.emission = Color(0.4, 1.0, 0.55)
		m.emission_energy_multiplier = 4.5
		pillar.material_override = m
		area.add_child(pillar)

	var beam := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(width * 0.92, 0.28, 0.28)
	beam.mesh = box
	beam.position = Vector3(0, 1.75, 0)
	var bm := StandardMaterial3D.new()
	bm.albedo_color = Color(0.7, 1.0, 0.65)
	bm.emission_enabled = true
	bm.emission = Color(0.55, 1.0, 0.6)
	bm.emission_energy_multiplier = 6.0
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beam.material_override = bm
	area.add_child(beam)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(width, 3.8, 1.4)
	col.shape = shape
	area.add_child(col)

	area.body_entered.connect(_on_finish_body)
	add_child(area)

func _on_pickup_body(body: Node3D, area: Area3D) -> void:
	if not body is CharacterBody3D:
		return
	if not is_instance_valid(area):
		return
	var kind: String = str(area.get_meta("kind", ""))
	if kind == "gem":
		var value: int = int(area.get_meta("value", 10))
		gem_taken.emit(area, value)
		area.queue_free()
	elif kind == "boost":
		boost_taken.emit(area)
		area.set_meta("kind", "used")
		area.monitoring = false
		for c in area.get_children():
			if c is MeshInstance3D and c.material_override is StandardMaterial3D:
				(c.material_override as StandardMaterial3D).emission_energy_multiplier = 0.4

func _on_hazard_body(body: Node3D, root: Node3D) -> void:
	if body is CharacterBody3D:
		hazard_hit.emit(root)

func _on_finish_body(body: Node3D) -> void:
	if body is CharacterBody3D:
		finish_reached.emit()

func _process(delta: float) -> void:
	var alive: Array[Node3D] = []
	for p in _pickups:
		if not is_instance_valid(p):
			continue
		alive.append(p)
		if str(p.get_meta("kind", "")) == "gem":
			p.rotate_y(delta * 3.2)
			p.position.y = 0.9 + sin(Time.get_ticks_msec() * 0.006 + p.position.z) * 0.14
	_pickups = alive
