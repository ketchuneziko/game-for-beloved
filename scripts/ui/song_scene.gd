extends Control
## Сцена песни (Глава 5, GDD «THE SONG»): строки появляются строго по
## позиции аудио — БЕЗ ТАЙМЕРОВ. Формула синхронизации:
##   t = player.get_playback_position() + AudioServer.get_time_since_last_mix()
##       - AudioServer.get_output_latency()
## Данные — data/custom/song.json (track + lines[{time,text,translation}]).
## Под куполом строки переливаются, перевод — светло-розовым под оригиналом.
## «Закрыть глаза» (выбор в главе) затемняет купол — остаются только текст и музыка.
## Дослушал до конца — достижение LISTENER; скромная кнопка пропуска — без ачивки.
## В headless/без звука — симуляция часов, чтобы автотест проходил сцену.

signal finished(listened: bool)

const UITheme := preload("res://scripts/ui/theme_builder.gd")

var _lines: Array = []          # {time, text, translation}
var _duration := 0.0
var _player: AudioStreamPlayer
var _cur := -1
var _done := false
var _sim_t := 0.0
var _time := 0.0
var _headless := false

var _dome: TextureRect
var _dim: ColorRect
var _line_label: Label
var _trans_label: Label
var _fade_tw: Tween


func _ready() -> void:
	theme = UITheme.build()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_headless = DisplayServer.get_name() == "headless"
	_build_ui()
	_load_song()
	_start_audio()


func _build_ui() -> void:
	# Купол — с медленным дрейфом (в _process).
	_dome = TextureRect.new()
	for p in ["res://assets/backgrounds/bg_dome_stars.jpg", "res://assets/backgrounds/bg_dome_stars.png"]:
		if ResourceLoader.exists(p):
			_dome.texture = load(p)
			break
	_dome.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_dome.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_dome.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dome.offset_left = -30.0
	_dome.offset_right = 30.0
	_dome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dome)

	_dim = ColorRect.new()
	_dim.color = Color(0.03, 0.02, 0.06, 0.45)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dim)

	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.offset_top = -40.0
	v.offset_bottom = -40.0
	v.add_theme_constant_override("separation", 14)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(v)

	_line_label = Label.new()
	_line_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_line_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_line_label.add_theme_font_size_override("font_size", 26)
	_line_label.add_theme_color_override("font_color", UITheme.COL_TEXT)
	_line_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(_line_label)

	_trans_label = Label.new()
	_trans_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_trans_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_trans_label.add_theme_font_size_override("font_size", 17)
	_trans_label.add_theme_color_override("font_color", Color(UITheme.COL_ACCENT_SOFT, 0.85))
	_trans_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(_trans_label)

	# Скромный пропуск в углу (без ачивки).
	if not _headless:
		var skip := Button.new()
		skip.text = LocalizationManager.t("song.skip", "пропустить ▸▸")
		skip.modulate = Color(1.0, 1.0, 1.0, 0.35)
		skip.focus_mode = Control.FOCUS_NONE
		skip.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		skip.offset_left = -190.0
		skip.offset_right = -20.0
		skip.offset_top = -64.0
		skip.offset_bottom = -24.0
		skip.pressed.connect(func() -> void: _finish(false))
		add_child(skip)

	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 1.2)


func _load_song() -> void:
	var path := "res://data/custom/song.json"
	if not FileAccess.file_exists(path):
		return
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (raw is Dictionary):
		return
	var lines: Array = (raw as Dictionary).get("lines", [])
	_lines = lines.duplicate()
	_lines.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.get("time", 0.0)) < float(b.get("time", 0.0)))
	_track_path = str((raw as Dictionary).get("track", "res://assets/music/song.ogg"))


var _track_path := ""


func _start_audio() -> void:
	var stream := _load_stream(_track_path)
	if stream == null:
		_line_label.text = LocalizationManager.t("song.missing",
			"(Здесь должна играть ваша песня. Положи трек и строки в data/custom/song.json — Глава 5 ждёт.)")
		_trans_label.text = ""
		var wait := 0.2 if _headless else 4.0
		var t := get_tree().create_timer(wait)
		t.timeout.connect(func() -> void: _finish(false))
		return
	_player = AudioStreamPlayer.new()
	_player.stream = stream
	_player.bus = "Song"
	add_child(_player)
	_duration = stream.get_length()
	if not _headless:
		_player.play()


## Рантайм-загрузка аудио без редактора: импорт -> ogg -> мой wav-парсер.
func _load_stream(path: String) -> AudioStream:
	if path == "" or not FileAccess.file_exists(path):
		return null
	if ResourceLoader.exists(path):
		var res := load(path)
		if res is AudioStream:
			return res
	if path.ends_with(".ogg"):
		var ogg := AudioStreamOggVorbis.load_from_file(ProjectSettings.globalize_path(path))
		return ogg
	if path.ends_with(".wav"):
		return _parse_wav(path)
	return null


## Минимальный WAV-парсер (PCM16, моно/стерео) — надёжнее любого API-предположения.
func _parse_wav(path: String) -> AudioStream:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var data := f.get_buffer(f.get_length())
	if data.size() < 44 or data.slice(0, 4) != "RIFF".to_ascii_buffer() or data.slice(8, 12) != "WAVE".to_ascii_buffer():
		return null
	var pos := 12
	var fmt := {}
	var pcm := PackedByteArray()
	while pos + 8 <= data.size():
		var chunk_id := data.slice(pos, pos + 4).get_string_from_ascii()
		var chunk_size := data.decode_u32(pos + 4)
		var body := data.slice(pos + 8, mini(pos + 8 + chunk_size, data.size()))
		if chunk_id == "fmt " and body.size() >= 16:
			fmt = {
				"channels": body.decode_u16(2),
				"rate": body.decode_u32(4),
				"bits": body.decode_u16(14),
			}
		elif chunk_id == "data":
			pcm = body
		pos += 8 + chunk_size + (chunk_size % 2)
	if fmt.is_empty() or pcm.is_empty() or int(fmt.get("bits", 16)) != 16:
		return null
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(fmt.get("rate", 22050))
	stream.stereo = int(fmt.get("channels", 1)) == 2
	stream.data = pcm
	return stream


## Текущее время песни ТОЛЬКО из аудио-часов (GDD: не Timer).
func _song_time(delta: float) -> float:
	if _headless or _player == null or not _player.playing:
		# Плейсхолдер/беззвучный режим: симулируем часы (в headless — x10,
		# чтобы автотест не слушал все 82 секунды).
		_sim_t += delta * (10.0 if _headless else 1.0)
		return _sim_t
	var t := _player.get_playback_position() \
		+ AudioServer.get_time_since_last_mix() \
		- AudioServer.get_output_latency()
	return maxf(t, 0.0)


func _process(delta: float) -> void:
	if _done:
		return
	_time += delta
	# Медленный дрейф купола.
	_dome.position.x = -30.0 + 24.0 * sin(_time * TAU / 48.0)

	var t := _song_time(delta)
	_update_lyrics(t)
	if _duration > 0.0 and t >= _duration - 0.05:
		_finish(true)
	elif _duration <= 0.0 and _player != null and not _player.playing and not _headless:
		_finish(true)


func _update_lyrics(t: float) -> void:
	var idx := -1
	for i in _lines.size():
		if t + 0.02 >= float(_lines[i].get("time", 0.0)):
			idx = i
		else:
			break
	if idx == _cur:
		return
	_cur = idx
	if idx < 0:
		_line_label.text = ""
		_trans_label.text = ""
		return
	var line: Dictionary = _lines[idx]
	_fade_line(_line_label, LocalizationManager.field(line.get("text", "")))
	_fade_line(_trans_label, LocalizationManager.field(line.get("translation", {})))


func _fade_line(label: Label, text: String) -> void:
	if _fade_tw != null and _fade_tw.is_valid():
		_fade_tw.kill()
	label.text = text
	label.modulate.a = 0.0
	_fade_tw = create_tween()
	_fade_tw.tween_property(label, "modulate:a", 1.0, 0.45)


func _finish(listened: bool) -> void:
	if _done:
		return
	_done = true
	if listened and not _headless:
		AchievementManager.unlock("listener")
	if _player != null:
		_player.stop()
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 1.0)
	tw.tween_callback(func() -> void:
		finished.emit(listened)
		queue_free()
	)


func _unhandled_input(event: InputEvent) -> void:
	# Esc во время песни = пауза не нужна, но выйти из сцены можно (без ачивки).
	if event.is_action_pressed("ui_cancel"):
		_finish(false)
