extends Node3D

const RingFloor = preload("res://scripts/ring.gd")

signal ring_smashed(floor_index, was_black)
signal level_completed

@export var ring_count: int = 35
@export var floor_spacing: float = 0.8
@export var base_rotation_speed: float = 1.2

var rings: Array = []
var current_floor_index: int = 0
var rotate_speed: float = 1.2
var rotate_dir: float = 1.0
var dir_timer: float = 0.0

var level_colors: Array[Color] = [
	Color(0.0, 0.9, 1.0),   # Neon Cyan
	Color(1.0, 0.2, 0.6),   # Neon Pink
	Color(0.3, 1.0, 0.3),   # Neon Green
	Color(1.0, 0.6, 0.0),   # Neon Orange
	Color(0.8, 0.3, 1.0)    # Neon Violet
]

func setup_level(level: int):
	for r in rings:
		if is_instance_valid(r):
			r.queue_free()
	rings.clear()
	
	for child in get_children():
		if child.name != "CentralPillar":
			child.queue_free()
	
	current_floor_index = 0
	rotate_speed = base_rotation_speed + min(level * 0.1, 1.5)
	
	var chosen_color = level_colors[(level - 1) % level_colors.size()]
	var total_floors = ring_count + min(level * 3, 30)
	var black_density = min(1 + int(level / 2), 4)
	
	for i in range(total_floors):
		var ring = RingFloor.new()
		var is_bottom = (i == total_floors - 1)
		var black_count = 0 if is_bottom or i < 2 else (randi() % black_density + 1)
		
		ring.setup(i, is_bottom, chosen_color, black_count, 8)
		ring.position.y = -float(i) * floor_spacing
		add_child(ring)
		rings.append(ring)
		ring.ring_destroyed.connect(_on_ring_destroyed)

func _process(delta: float):
	rotation.y += rotate_speed * rotate_dir * delta
	dir_timer += delta
	if dir_timer > randf_range(3.0, 6.0):
		dir_timer = 0.0
		rotate_dir *= -1.0

func get_current_ring():
	if current_floor_index < rings.size():
		return rings[current_floor_index]
	return null

func get_current_ring_y() -> float:
	return -float(current_floor_index) * floor_spacing

func smash_current_ring(impact_point: Vector3, is_supernova: bool) -> bool:
	var ring = get_current_ring()
	if ring != null:
		var success = ring.smash(impact_point, is_supernova)
		if success:
			current_floor_index += 1
			if ring.is_bottom_goal or current_floor_index >= rings.size():
				emit_signal("level_completed")
		return success
	return false

func _on_ring_destroyed(ring_node, hit_black: bool):
	emit_signal("ring_smashed", ring_node.floor_index, hit_black)
