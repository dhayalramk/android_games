extends Node3D
class_name RingSlice

@export var is_black: bool = false
@export var slice_angle_deg: float = 45.0
@export var inner_radius: float = 1.0
@export var outer_radius: float = 2.4
@export var height: float = 0.45

var mesh_instance: MeshInstance3D
var is_broken: bool = false
var velocity: Vector3 = Vector3.ZERO
var angular_velocity: Vector3 = Vector3.ZERO

func setup(p_is_black: bool, p_color: Color, p_angle_deg: float, p_inner_r: float, p_outer_r: float, p_height: float):
	is_black = p_is_black
	slice_angle_deg = p_angle_deg
	inner_radius = p_inner_r
	outer_radius = p_outer_r
	height = p_height
	
	_build_mesh(p_color)

func _build_mesh(color: Color):
	mesh_instance = MeshInstance3D.new()
	var arr_mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()
	
	var segments: int = 4
	var angle_step = deg_to_rad(slice_angle_deg) / float(segments)
	var half_h = height * 0.5
	
	# Generate top and bottom vertices for each step
	for i in range(segments + 1):
		var a = i * angle_step
		var cos_a = cos(a)
		var sin_a = sin(a)
		
		var in_x = inner_radius * cos_a
		var in_z = inner_radius * sin_a
		var out_x = outer_radius * cos_a
		var out_z = outer_radius * sin_a
		
		# Top Inner
		vertices.append(Vector3(in_x, half_h, in_z))
		normals.append(Vector3.UP)
		uvs.append(Vector2(float(i) / segments, 0.0))
		
		# Top Outer
		vertices.append(Vector3(out_x, half_h, out_z))
		normals.append(Vector3.UP)
		uvs.append(Vector2(float(i) / segments, 1.0))
		
		# Bottom Inner
		vertices.append(Vector3(in_x, -half_h, in_z))
		normals.append(Vector3.DOWN)
		uvs.append(Vector2(float(i) / segments, 0.0))
		
		# Bottom Outer
		vertices.append(Vector3(out_x, -half_h, out_z))
		normals.append(Vector3.DOWN)
		uvs.append(Vector2(float(i) / segments, 1.0))
	
	# Generate faces
	for i in range(segments):
		var base = i * 4
		var nxt = (i + 1) * 4
		
		# Top Face
		indices.append(base + 0)
		indices.append(nxt + 0)
		indices.append(base + 1)
		
		indices.append(nxt + 0)
		indices.append(nxt + 1)
		indices.append(base + 1)
		
		# Outer Face
		indices.append(base + 1)
		indices.append(nxt + 1)
		indices.append(base + 3)
		
		indices.append(nxt + 1)
		indices.append(nxt + 3)
		indices.append(base + 3)
		
		# Bottom Face
		indices.append(base + 2)
		indices.append(base + 3)
		indices.append(nxt + 2)
		
		indices.append(nxt + 2)
		indices.append(base + 3)
		indices.append(nxt + 3)
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh_instance.mesh = arr_mesh
	
	var mat = StandardMaterial3D.new()
	mat.roughness = 0.2
	mat.metallic = 0.3
	
	if is_black:
		mat.albedo_color = Color(0.08, 0.08, 0.1)
		mat.roughness = 0.5
		mat.metallic = 0.8
	else:
		mat.albedo_color = color
		mat.emission_enabled = true
		mat.emission = color * 0.35
	
	mesh_instance.material_override = mat
	add_child(mesh_instance)

func explode(explosion_origin: Vector3):
	is_broken = true
	var dir = (global_position - explosion_origin).normalized()
	dir.y = randf_range(0.2, 0.8)
	dir = dir.normalized()
	velocity = dir * randf_range(8.0, 16.0)
	angular_velocity = Vector3(randf_range(-10, 10), randf_range(-10, 10), randf_range(-10, 10))
	
	# Fade out and clean up
	var tween = create_tween()
	tween.tween_property(mesh_instance, "scale", Vector3.ZERO, 0.7).set_delay(0.4)
	tween.tween_callback(queue_free)

func _process(delta: float):
	if is_broken:
		global_position += velocity * delta
		velocity.y -= 25.0 * delta # Gravity
		mesh_instance.rotate_x(angular_velocity.x * delta)
		mesh_instance.rotate_y(angular_velocity.y * delta)
		mesh_instance.rotate_z(angular_velocity.z * delta)
