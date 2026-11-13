extends Node3D
## Rotating hazard arm on the sky highway.

@export var spin_speed: float = 2.4

func _ready() -> void:
	spin_speed = 1.8 + randf() * 2.2
	if randf() < 0.5:
		spin_speed *= -1.0

func _process(delta: float) -> void:
	rotate_y(spin_speed * delta)
