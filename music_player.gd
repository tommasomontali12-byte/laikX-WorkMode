extends Control

## Configuration
@export_dir var music_directory: String = "assets/music/"
@export var fade_duration: float = 1.2

## Icons
const ICON_PAUSE = preload("res://assets/icons/pause_24dp_E3E3E3_FILL0_wght400_GRAD0_opsz24.svg")
const ICON_PLAY = preload("res://assets/icons/play_arrow_24dp_E3E3E3_FILL0_wght400_GRAD0_opsz24.svg")

## Node References
@onready var audio_player: AudioStreamPlayer2D = $audioPlayer
@onready var slider: HSlider = $slider
@onready var song_label: Label = $songName
@onready var duration_label: Label = $duration
@onready var play_button: Button = $play
@onready var next_button: Button = $next

var playlist: Array[String] = []
var played_songs: Array[String] = []
var is_fading: bool = false
var user_is_dragging: bool = false
var manually_paused: bool = false
var _last_music_source: String = ""

func _ready() -> void:
	load_music_from_dir()

	audio_player.finished.connect(_on_finished)
	next_button.pressed.connect(_on_next_pressed)
	play_button.pressed.connect(_on_play_pressed)

	slider.drag_started.connect(func(): user_is_dragging = true)
	slider.drag_ended.connect(_on_slider_drag_ended)

	audio_player.volume_db = -80

func _process(_delta: float) -> void:
	_check_music_source_changed()
	_handle_productivity_logic()
	_update_ui()

## --- Core Logic ---

func _get_active_music_directory() -> String:
	if Global.isCustomMusicEnabled and Global.customMusicDirectory != "":
		return Global.customMusicDirectory
	return music_directory

func _check_music_source_changed() -> void:
	var current_source = _get_active_music_directory()
	if current_source != _last_music_source:
		_last_music_source = current_source
		load_music_from_dir()
		if audio_player.playing and not is_fading:
			fade_out_and_stop()

func _handle_productivity_logic() -> void:
	if Global.isProductivityActive:
		# Only auto-start if the user hasn't manually paused
		if not audio_player.playing and not is_fading and not manually_paused:
			play_random_song()
	elif audio_player.playing and not is_fading:
		fade_out_and_stop()

func load_music_from_dir() -> void:
	playlist.clear()
	played_songs.clear()

	var active_directory = _get_active_music_directory()

	if not active_directory.ends_with("/") and not active_directory.ends_with("\\"):
		active_directory += "/"

	var dir = DirAccess.open(active_directory)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				var ext = file_name.get_extension().to_lower()
				if ext in ["mp3", "ogg", "wav"]:
					playlist.append(active_directory + file_name)
			file_name = dir.get_next()
		dir.list_dir_end()

	if playlist.is_empty():
		song_label.text = "No music found in " + active_directory

func _load_audio_stream(path: String) -> AudioStream:
	if path.begins_with("res://"):
		return load(path)

	var ext = path.get_extension().to_lower()
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_warning("MusicPlayer: Could not open file: %s" % path)
		return null

	var bytes = file.get_buffer(file.get_length())
	file.close()

	match ext:
		"mp3":
			var stream = AudioStreamMP3.new()
			stream.data = bytes
			return stream
		"ogg":
			return AudioStreamOggVorbis.load_from_buffer(bytes)
		"wav":
			push_warning("MusicPlayer: WAV from external paths is not supported.")
			return null
		_:
			push_warning("MusicPlayer: Unsupported audio format: %s" % ext)
			return null

## Plays a random song. Does NOT check isProductivityActive so buttons always work.
func play_random_song() -> void:
	if playlist.is_empty():
		return

	if played_songs.size() >= playlist.size():
		played_songs.clear()

	var available = playlist.filter(func(s): return not played_songs.has(s))
	var next_track = available.pick_random()

	var stream_res = _load_audio_stream(next_track)
	if stream_res:
		audio_player.stream_paused = false
		audio_player.stream = stream_res
		played_songs.append(next_track)
		audio_player.play()
		manually_paused = false
		song_label.text = next_track.get_file().get_basename().capitalize()
		slider.max_value = audio_player.stream.get_length()
		fade_in()
	else:
		# Skip broken/unsupported file and try the next one
		played_songs.append(next_track)
		play_random_song()

## --- UI & Transitions ---

func _update_ui() -> void:
	if audio_player.playing and not audio_player.stream_paused:
		play_button.icon = ICON_PAUSE
	else:
		play_button.icon = ICON_PLAY

	if audio_player.playing and not user_is_dragging:
		var pos = audio_player.get_playback_position()
		var length = audio_player.stream.get_length()
		slider.value = pos
		duration_label.text = "%s / %s" % [_format_time(pos), _format_time(length)]

func _format_time(seconds: float) -> String:
	return "%02d:%02d" % [int(seconds / 60), int(seconds) % 60]

func fade_in() -> void:
	var tween = create_tween()
	audio_player.volume_db = -40
	tween.tween_property(audio_player, "volume_db", 0.0, fade_duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func fade_out_and_stop() -> void:
	is_fading = true
	var tween = create_tween()
	tween.tween_property(audio_player, "volume_db", -80.0, fade_duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func():
		audio_player.stop()
		is_fading = false
	)

func fade_out_and_next() -> void:
	if is_fading:
		return
	is_fading = true
	var tween = create_tween()
	tween.tween_property(audio_player, "volume_db", -80.0, fade_duration * 0.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func():
		audio_player.stop()
		is_fading = false
		play_random_song()
	)

## --- Signal Handlers ---

func _on_play_pressed() -> void:
	if audio_player.playing:
		# Toggle pause/resume
		audio_player.stream_paused = not audio_player.stream_paused
		manually_paused = audio_player.stream_paused
	elif audio_player.stream != null and audio_player.stream_paused:
		# Resume from a stopped+paused state
		audio_player.stream_paused = false
		audio_player.play()
		manually_paused = false
	else:
		# Nothing loaded or playing — start fresh
		play_random_song()

func _on_next_pressed() -> void:
	if playlist.is_empty():
		return
	if audio_player.playing and not is_fading:
		fade_out_and_next()
	else:
		play_random_song()

func _on_slider_drag_ended(value_changed: bool) -> void:
	user_is_dragging = false
	if value_changed:
		audio_player.seek(slider.value)

func _on_finished() -> void:
	if Global.isProductivityActive:
		play_random_song()
