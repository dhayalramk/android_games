extends Node
## Production audio — sampled SFX + looping sky-highway music bed.

const SFX_DIR := "res://audio/"

var _players: Dictionary = {}  # name -> AudioStreamPlayer
var _music: AudioStreamPlayer
var _bus_ready := false

func _ready() -> void:
	_load_sfx("ui", "sfx_ui.wav", -6.0)
	_load_sfx("gem", "sfx_gem.wav", -4.0)
	_load_sfx("boost", "sfx_boost.wav", -5.0)
	_load_sfx("die", "sfx_die.wav", -3.0)
	_load_sfx("clear", "sfx_clear.wav", -4.0)
	_load_sfx("supernova", "sfx_supernova.wav", -2.0)
	_music = AudioStreamPlayer.new()
	_music.name = "Music"
	var music_stream := _load_stream("music_sky_highway.wav")
	if music_stream:
		if music_stream is AudioStreamWAV:
			var wav := music_stream as AudioStreamWAV
			wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
			wav.loop_begin = 0
			# 16-bit PCM: frame count = bytes / (2 * channels)
			var channels: int = 2 if wav.stereo else 1
			wav.loop_end = int(wav.data.size() / (2.0 * channels))
		_music.stream = music_stream
		_music.volume_db = -14.0
		_music.bus = "Master"
		_music.finished.connect(play_music)  # belt-and-suspenders if loop_end ignored
	add_child(_music)
	_bus_ready = true
	play_music()

func _load_stream(file_name: String) -> AudioStream:
	var path := SFX_DIR + file_name
	if not ResourceLoader.exists(path):
		push_warning("Missing audio: " + path)
		return null
	return load(path)

func _load_sfx(key: String, file_name: String, vol_db: float) -> void:
	var stream := _load_stream(file_name)
	var p := AudioStreamPlayer.new()
	p.name = "Sfx_" + key
	p.volume_db = vol_db
	if stream:
		p.stream = stream
	add_child(p)
	_players[key] = p

func _play(key: String) -> void:
	var p: AudioStreamPlayer = _players.get(key)
	if p == null or p.stream == null:
		return
	# Allow overlapping one-shots by restarting; for gems use poly via duplicate briefly
	if p.playing and key == "gem":
		var echo := p.duplicate() as AudioStreamPlayer
		add_child(echo)
		echo.play()
		echo.finished.connect(echo.queue_free)
		return
	p.play()

func play_music() -> void:
	if _music and _music.stream and not _music.playing:
		_music.play()

func stop_music() -> void:
	if _music and _music.playing:
		_music.stop()

func set_music_playing(on: bool) -> void:
	if on:
		play_music()
	else:
		stop_music()

func gem(streak: int = 1) -> void:
	_play("gem")
	# Pitch-up illusion via duplicate at slightly higher volume for streaks
	if streak >= 4 and _players.has("gem"):
		(_players["gem"] as AudioStreamPlayer).volume_db = -4.0 + mini(streak, 8) * 0.3

func boost() -> void:
	_play("boost")

func clear() -> void:
	_play("clear")

func die() -> void:
	_play("die")

func supernova() -> void:
	_play("supernova")

func ui() -> void:
	_play("ui")
