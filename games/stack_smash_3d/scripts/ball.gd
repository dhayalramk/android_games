extends Node3D

signal bounced
signal smashed_floor
signal entered_supernova
signal exited_supernova
signal hit_black_failed
signal reached_goal

enum State { BOUNCING, SMASHING, DEAD, WIN }

@export var bounce_height: float = 1.3
@export var bounce_speed: float = 12.0
@export var smash_speed: float = 28.0

var state: State = State.BOUNCING
var bounce_timer: float = 0.0
var base_y: float = 0.35
var streak: int = 0
var is_supernova: bool = false
var supernova_timer: float = 0.0

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

var normal_mat: StandardMaterial3D
var supernova_mat: StandardMaterial3D

func _ready():
	_setup_materials()

func _setup_materials():
	normal_mat = StandardMaterial3D.new()
	normal_mat.albedo_color = Color(1.0, 0.95, 0.2)
	normal_mat.metallic = 0.8
	normal_mat.roughness = 0.15
	normal_mat.emission_enabled = true
	normal_mat.emission = Color(1.0, 0.7, 0.1) * 0.5
	
	supernova_mat = StandardMaterial3D.new()
	supernova_mat.albedo_color = Color(1.0, 0.1, 0.3)
	supernova_mat.metallic = 0.3
	supernova_mat.roughness = 0.1
	supernova_mat.emission_enabled = true
	supernova_mat.emission = Color(1.0, 0.2, 0.0) * 1.5
	
	if mesh_instance:
		mesh_instance.material_override = normal_mat

func set_smashing(smash: bool):
	if state == State.DEAD or state == State.WIN:
		return
	
	if smash:
		state = State.SMASHING
	else:
		state = State.BOUNCING
		bounce_timer = 0.0
		if not is_supernova:
			streak = 0

func update_ball(delta: float, current_floor_y: float, tower_ref: Node3D):
	if state == State.DEAD or state == State.WIN:
		return
	
	if is_supernova:
		supernova_timer -= delta
		if supernova_timer <= 0:
			_exit_supernova()
	
	match state:
		State.BOUNCING:
			bounce_timer += delta * bounce_speed
			var rel_y = abs(sin(bounce_timer)) * bounce_height
			position.y = current_floor_y + 0.35 + rel_y
			
			if rel_y < 0.15:
				var squish = 1.0 - (rel_y / 0.15) * 0.35
				mesh_instance.scale = Vector3(1.0 + squish * 0.3, 1.0 - squish * 0.35, 1.0 + squish * 0.3)
				if rel_y < 0.05:
					emit_signal("bounced")
			else:
				mesh_instance.scale = mesh_instance.scale.lerp(Vector3.ONE, delta * 15.0)
		
		State.SMASHING:
			position.y -= smash_speed * delta
			mesh_instance.scale = Vector3(0.85, 1.3, 0.85)
			
			var ring_target_y = tower_ref.get_current_ring_y() + 0.3
			if position.y <= ring_target_y:
				var success = tower_ref.smash_current_ring(global_position, is_supernova)
				if success:
					streak += 1
					emit_signal("smashed_floor")
					
					if streak >= 5 and not is_supernova:
						_enter_supernova()
					
					position.y = ring_target_y
				else:
					_die()

func _enter_supernova():
	is_supernova = true
	supernova_timer = 4.0
	if mesh_instance:
		mesh_instance.material_override = supernova_mat
	emit_signal("entered_supernova")

func _exit_supernova():
	is_supernova = false
	streak = 0
	if mesh_instance:
		mesh_instance.material_override = normal_mat
	emit_signal("exited_supernova")

func _die():
	state = State.DEAD
	mesh_instance.visible = false
	emit_signal("hit_black_failed")

func set_win():
	state = State.WIN
	emit_signal("reached_goal")
