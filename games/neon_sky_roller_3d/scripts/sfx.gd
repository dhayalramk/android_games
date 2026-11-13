extends Node
## Tiny procedural SFX — enough juice that the game doesn't feel mute.

var _player: AudioStreamPlayer
var _gen: AudioStreamGenerator
var _playback: AudioStreamGeneratorPlayback
var _hz: float = 0.0
var _amp: float = 0.0
var _phase: float = 0.0
var _samples_left: int = 0

func _ready() -> void:
	_gen = AudioStreamGenerator.new()
	_gen.mix_rate = 22050
	_gen.buffer_length = 0.1
	_player = AudioStreamPlayer.new()
	_player.stream = _gen
	_player.volume_db = -8.0
	add_child(_player)
	_player.play()
	_playback = _player.get_stream_playback()

func _process(_delta: float) -> void:
	if _playback == null:
		return
	var to_fill: int = _playback.get_frames_available()
	if to_fill <= 0:
		return
	for i in range(to_fill):
		var sample := 0.0
		if _samples_left > 0:
			sample = sin(_phase * TAU) * _amp
			_phase += _hz / 22050.0
			if _phase > 1.0:
				_phase -= 1.0
			_samples_left -= 1
			_amp *= 0.9985
		_playback.push_frame(Vector2(sample, sample))

func _beep(hz: float, ms: float, amp: float = 0.22) -> void:
	_hz = hz
	_amp = amp
	_samples_left = int(22050.0 * (ms / 1000.0))
	_phase = 0.0

func gem(streak: int = 1) -> void:
	_beep(660.0 + mini(streak, 8) * 40.0, 70.0, 0.18)

func boost() -> void:
	_beep(220.0, 40.0, 0.2)
	# second tick shortly after via timer
	get_tree().create_timer(0.05).timeout.connect(func(): _beep(440.0, 80.0, 0.2))

func clear() -> void:
	_beep(523.0, 90.0, 0.22)
	get_tree().create_timer(0.09).timeout.connect(func(): _beep(659.0, 90.0, 0.2))
	get_tree().create_timer(0.18).timeout.connect(func(): _beep(784.0, 140.0, 0.22))

func die() -> void:
	_beep(140.0, 220.0, 0.25)

func supernova() -> void:
	_beep(180.0, 120.0, 0.28)
	get_tree().create_timer(0.1).timeout.connect(func(): _beep(360.0, 160.0, 0.24))

func ui() -> void:
	_beep(520.0, 50.0, 0.12)
