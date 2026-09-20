extends Node
## AudioManager (autoload)
## Музыка с кроссфейдом (fade out -> change -> fade in), эмбиент, пул SFX
## и отдельный плеер для сцены песни (Chapter 5, синхронизация по аудио-часам).
##
## Файлы лежат по финальным путям (assets/music/*.ogg, assets/sounds/*.ogg).
## На ранних фазах ассетов ещё нет: отсутствие файла — одноразовое
## предупреждение и тихий пропуск, игра не падает.

signal music_changed(track_id: String)

const MUSIC_DIR := "res://assets/music/"
const SOUNDS_DIR := "res://assets/sounds/"
const DEFAULT_FADE := 1.2
const SFX_POOL_SIZE := 6
const MUTE_DB := -50.0

var _bgm_a: AudioStreamPlayer
var _bgm_b: AudioStreamPlayer
var _bgm_active: AudioStreamPlayer
var _ambience: AudioStreamPlayer
var _song: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_next := 0
var _current_track := ""
var _fade_tween: Tween
var _warned_missing: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_bgm_a = _make_player("Music")
	_bgm_b = _make_player("Music")
	_bgm_active = _bgm_a
	_ambience = _make_player("Ambience")
	_song = _make_player("Song")
	for i in SFX_POOL_SIZE:
		_sfx_pool.append(_make_player("SFX"))
	apply_volumes()
	SettingsManager.settings_changed.connect(apply_volumes)


func _make_player(bus: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus
	add_child(p)
	return p


func apply_volumes() -> void:
	_set_bus_volume("Master", SettingsManager.master_volume)
	_set_bus_volume("Music", SettingsManager.music_volume)
	_set_bus_volume("Ambience", SettingsManager.ambience_volume)
	_set_bus_volume("SFX", SettingsManager.sfx_volume)


func _set_bus_volume(bus_name: String, v: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	var vol := clampf(v, 0.0, 1.0)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(vol, 0.0001)))
	AudioServer.set_bus_mute(idx, vol <= 0.001)


## Главное переключение музыки: fade out текущего трека, смена, fade in.
func play_music(track_id: String, fade: float = DEFAULT_FADE) -> void:
	if track_id == _current_track:
		return
	_current_track = track_id
	var stream := _load_stream(MUSIC_DIR + track_id + ".ogg", "music:" + track_id)
	var from := _bgm_active
	var to := _bgm_b if from == _bgm_a else _bgm_a
	_bgm_active = to
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.set_parallel(true)
	if from.playing:
		_fade_tween.tween_property(from, "volume_db", MUTE_DB, maxf(fade, 0.05))
	if stream != null:
		to.stream = stream
		to.volume_db = MUTE_DB
		to.play()
		_fade_tween.tween_property(to, "volume_db", 0.0, maxf(fade, 0.05))
	_fade_tween.set_parallel(false)
	_fade_tween.tween_callback(_stop_if_inactive.bind(from))
	if stream == null:
		_current_track = ""  # файла пока нет — трек останется «свободным»
	music_changed.emit(track_id)


func stop_music(fade: float = 1.0) -> void:
	_current_track = ""
	var from := _bgm_active
	if not from.playing:
		return
	var tw := create_tween()
	tw.tween_property(from, "volume_db", MUTE_DB, maxf(fade, 0.05))
	tw.tween_callback(_stop_if_inactive.bind(from))


func current_track() -> String:
	return _current_track


func play_ambience(id: String, fade: float = 1.0) -> void:
	var stream := _load_stream(SOUNDS_DIR + "ambience_" + id + ".ogg", "sounds:ambience_" + id)
	if stream == null:
		return
	if _ambience.playing and _ambience.stream == stream:
		return
	_ambience.stream = stream
	_ambience.volume_db = MUTE_DB
	_ambience.play()
	var tw := create_tween()
	tw.tween_property(_ambience, "volume_db", 0.0, maxf(fade, 0.05))


func stop_ambience(fade: float = 1.0) -> void:
	if not _ambience.playing:
		return
	var tw := create_tween()
	tw.tween_property(_ambience, "volume_db", MUTE_DB, maxf(fade, 0.05))
	tw.tween_callback(_ambience.stop)


## Короткие звуки: кнопки, клики, фото, страница, пазл и т.д.
func play_sfx(id: String, pitch: float = 1.0) -> void:
	var stream := _load_stream(SOUNDS_DIR + id + ".ogg", "sounds:" + id)
	if stream == null:
		return
	var p := _sfx_pool[_sfx_next]
	_sfx_next = (_sfx_next + 1) % _sfx_pool.size()
	p.stream = stream
	p.pitch_scale = pitch
	p.play()


## Плеер для музыкальной главы (Chapter 5): позиция берётся только
## из аудио-часов этого плеера, без таймеров (см. GDD §9.5).
func song_player() -> AudioStreamPlayer:
	return _song


func _stop_if_inactive(p: AudioStreamPlayer) -> void:
	if p != _bgm_active:
		p.stop()


func _load_stream(path: String, label: String) -> AudioStream:
	if not ResourceLoader.exists(path):
		if not _warned_missing.has(label):
			_warned_missing[label] = true
			push_warning("AudioManager: нет файла '%s' (%s) — плейсхолдер-фаза, пропускаю" % [label, path])
		return null
	var res := load(path)
	return res as AudioStream
