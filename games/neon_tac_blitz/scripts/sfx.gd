extends Node
## Tiny procedural SFX — no asset pipeline required.

var _player: AudioStreamPlayer
var _gen: AudioStreamGenerator
var _playback: AudioStreamGeneratorPlayback
var _hz: float = 0.0
var _amp: float = 0.0
var _phase: float = 0.0
var _left: int = 0

func _ready() -> void:
	_gen = AudioStreamGenerator.new()
	_gen.mix_rate = 22050
	_gen.buffer_length = 0.12
	_player = AudioStreamPlayer.new()
	_player.stream = _gen
	_player.volume_db = -6.0
	add_child(_player)
	_player.play()
	_playback = _player.get_stream_playback()

func _process(_d: float) -> void:
	if _playback == null:
		return
	var n: int = _playback.get_frames_available()
	for i in range(n):
		var s := 0.0
		if _left > 0:
			s = sin(_phase * TAU) * _amp
			_phase += _hz / 22050.0
			if _phase > 1.0:
				_phase -= 1.0
			_amp *= 0.997
			_left -= 1
		_playback.push_frame(Vector2(s, s))

func _beep(hz: float, ms: float, amp: float = 0.22) -> void:
	_hz = hz
	_amp = amp
	_left = int(22050.0 * ms / 1000.0)
	_phase = 0.0

func tap() -> void:
	_beep(520, 45, 0.16)

func place_x() -> void:
	_beep(660, 70, 0.22)
	get_tree().create_timer(0.06).timeout.connect(func(): _beep(880, 60, 0.16))

func place_o() -> void:
	_beep(320, 80, 0.2)

func bomb() -> void:
	_beep(90, 140, 0.3)
	get_tree().create_timer(0.08).timeout.connect(func(): _beep(180, 120, 0.22))

func win() -> void:
	_beep(523, 90, 0.24)
	get_tree().create_timer(0.1).timeout.connect(func(): _beep(659, 90, 0.22))
	get_tree().create_timer(0.2).timeout.connect(func(): _beep(784, 160, 0.24))

func lose() -> void:
	_beep(200, 180, 0.25)
	get_tree().create_timer(0.12).timeout.connect(func(): _beep(140, 200, 0.22))

func ult() -> void:
	_beep(440, 80, 0.24)
	get_tree().create_timer(0.08).timeout.connect(func(): _beep(660, 100, 0.22))

func tick() -> void:
	_beep(900, 30, 0.1)
