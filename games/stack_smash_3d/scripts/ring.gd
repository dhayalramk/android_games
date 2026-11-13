extends Node3D

const RingSlice = preload("res://scripts/ring_slice.gd")

signal ring_destroyed(ring_node, is_black_hit)

var slices: Array = []
var is_bottom_goal: bool = false
var floor_index: int = 0
var ring_color: Color = Color(0.1, 0.8, 1.0)

func setup(p_index: int, p_is_bottom: bool, p_color: Color, black_slice_count: int, num_slices: int = 8):
	floor_index = p_index
	is_bottom_goal = p_is_bottom
	ring_color = p_color
	
	var slice_angle = 360.0 / float(num_slices)
	
	# Decide which slices are black
	var black_indices: Array[int] = []
	if not is_bottom_goal and black_slice_count > 0:
		var start_idx = randi() % num_slices
		for b in range(black_slice_count):
			black_indices.append((start_idx + b) % num_slices)
	
	for i in range(num_slices):
		var slice = RingSlice.new()
		var is_blk = false
		if is_bottom_goal:
			p_color = Color(1.0, 0.84, 0.0)
		elif i in black_indices:
			is_blk = true
		
		var slice_color = p_color
		slice.setup(is_blk, slice_color, slice_angle - 1.5, 1.05, 2.5, 0.45)
		slice.rotation.y = deg_to_rad(i * slice_angle)
		add_child(slice)
		slices.append(slice)

func smash(impact_point: Vector3, is_supernova: bool) -> bool:
	var hit_black = false
	
	for slice in slices:
		var slice_rot = fposmod(rad_to_deg(slice.rotation.y), 360.0)
		var angle_diff = abs(angle_difference(deg_to_rad(slice_rot), deg_to_rad(90.0)))
		if angle_diff < deg_to_rad(30.0):
			if slice.is_black:
				hit_black = true
	
	if hit_black and not is_supernova:
		emit_signal("ring_destroyed", self, true)
		return false
	
	for slice in slices:
		slice.explode(impact_point)
	
	emit_signal("ring_destroyed", self, false)
	return true
