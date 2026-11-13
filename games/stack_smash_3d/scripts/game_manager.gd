extends Node3D

const Tower = preload("res://scripts/tower.gd")
const PlayerBall = preload("res://scripts/ball.gd")

@onready var tower = $Tower
@onready var ball = $Ball
@onready var camera: Camera3D = $Camera3D
@onready var score_label: Label = $CanvasLayer/HUD/ScoreLabel
@onready var level_label: Label = $CanvasLayer/HUD/LevelLabel
@onready var progress_bar: ProgressBar = $CanvasLayer/HUD/ProgressBar
@onready var streak_label: Label = $CanvasLayer/HUD/StreakLabel
@onready var game_over_panel: Control = $CanvasLayer/GameOverPanel
@onready var win_panel: Control = $CanvasLayer/WinPanel

var score: int = 0
var level: int = 1
var is_pressing: bool = false
var camera_shake: float = 0.0
var base_cam_offset: Vector3 = Vector3(0, 4.2, 5.8)

func _ready():
	_start_level(1)
	ball.bounced.connect(_on_ball_bounced)
	ball.smashed_floor.connect(_on_floor_smashed)
	ball.entered_supernova.connect(_on_supernova_start)
	ball.exited_supernova.connect(_on_supernova_end)
	ball.hit_black_failed.connect(_on_game_over)
	tower.level_completed.connect(_on_level_win)

func _start_level(lvl: int):
	level = lvl
	level_label.text = "LEVEL " + str(level)
	game_over_panel.visible = false
	win_panel.visible = false
	streak_label.visible = false
	
	tower.setup_level(level)
	ball.state = PlayerBall.State.BOUNCING
	ball.position = Vector3(0, 1.2, 1.8)
	ball.mesh_instance.visible = true
	ball._exit_supernova()
	
	progress_bar.max_value = tower.rings.size()
	progress_bar.value = 0
	
	camera.position = ball.position + base_cam_offset
	camera.look_at(Vector3(0, ball.position.y - 0.5, 0), Vector3.UP)

func _input(event: InputEvent):
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		if event.pressed:
			if ball.state == PlayerBall.State.DEAD:
				_start_level(level)
				return
			elif ball.state == PlayerBall.State.WIN:
				_start_level(level + 1)
				return
			
			is_pressing = true
			ball.set_smashing(true)
		else:
			is_pressing = false
			ball.set_smashing(false)

func _process(delta: float):
	ball.update_ball(delta, tower.get_current_ring_y(), tower)
	progress_bar.value = tower.current_floor_index
	
	var target_cam_y = ball.position.y + base_cam_offset.y
	camera.position.y = lerp(camera.position.y, target_cam_y, delta * 8.0)
	camera.position.x = base_cam_offset.x
	camera.position.z = base_cam_offset.z
	
	if camera_shake > 0:
		camera.position += Vector3(randf_range(-camera_shake, camera_shake), randf_range(-camera_shake, camera_shake), 0)
		camera_shake = max(0.0, camera_shake - delta * 4.0)
	
	camera.look_at(Vector3(0, ball.position.y - 0.5, 0), Vector3.UP)

func _on_ball_bounced():
	_vibrate(15)

func _on_floor_smashed():
	score += 10 * (3 if ball.is_supernova else 1)
	score_label.text = str(score)
	camera_shake = 0.12 if not ball.is_supernova else 0.28
	_vibrate(30 if not ball.is_supernova else 60)

func _on_supernova_start():
	streak_label.visible = true
	streak_label.text = "🔥 SUPERNOVA! 🔥"
	_vibrate(100)

func _on_supernova_end():
	streak_label.visible = false

func _on_game_over():
	game_over_panel.visible = true
	camera_shake = 0.4
	_vibrate(250)

func _on_level_win():
	ball.set_win()
	win_panel.visible = true
	_vibrate(150)

func _vibrate(duration_ms: int):
	if OS.has_feature("android") or OS.has_feature("mobile"):
		Input.vibrate_handheld(duration_ms)
