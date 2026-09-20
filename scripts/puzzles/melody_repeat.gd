extends Control
## Мини-игра «Пластинка заела» (GDD §6 #3): повторить мелодию на пяти
## клавишах. Два раунда (4 и 5 нот). Промах — раунд повторяется; после
## двух промахов ноты показываются медленно. Провал невозможен.
## Ноты — тона через SFX-пул (pitch), когда будет настоящая мелодия
## (Глава 5) — последовательность читается из data/custom/song.json.

signal solved

const UITheme := preload("res://scripts/ui/theme_builder.gd")

const ROUNDS := [
	[1, 3, 0, 2],
	[4, 2, 0, 3, 1],
]
const NOTE_GLYPHS := ["●", "▲", "■", "◆", "★"]
const NOTE_COLORS := [
	Color("#ff8fbd"), Color("#ffb9d5"), Color("#b9a8ff"),
	Color("#8fd0ff"), Color("#ffe08f"),
]

var _round := 0
var _input_pos := 0
var _fails := 0
var _busy := true
var _done := false
var _keys: Array[Button] = []
var _hint: Label


func _ready() -> void:
	theme = UITheme.build()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	await get_tree().create_timer(0.4).timeout
	_play_round()
	if DisplayServer.get_name() == "headless":
		await get_tree().create_timer(0.3).timeout
		for r in ROUNDS.size():
			for n: int in ROUNDS[r]:
				_on_note(n)


func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.015, 0.035, 0.9)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 300.0
	panel.offset_right = -300.0
	panel.offset_top = 200.0
	panel.offset_bottom = -200.0
	add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	panel.add_child(v)

	var title := Label.new()
	title.text = LocalizationManager.t("melody.title", "ПЛАСТИНКА ЗАЕЛА")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", UITheme.COL_ACCENT_SOFT)
	v.add_child(title)

	var sub := Label.new()
	sub.text = LocalizationManager.t("melody.sub", "Проигрыватель старый: подтверди мелодию. Слушай и повторяй.")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.add_theme_font_size_override("font_size", 13)
	sub.add_theme_color_override("font_color", Color(UITheme.COL_TEXT, 0.6))
	v.add_child(sub)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	v.add_child(row)
	for i in 5:
		var b := Button.new()
		b.text = NOTE_GLYPHS[i]
		b.add_theme_color_override("font_color", NOTE_COLORS[i])
		b.add_theme_font_size_override("font_size", 26)
		b.custom_minimum_size = Vector2(84, 96)
		b.pressed.connect(_on_note.bind(i))
		row.add_child(b)
		_keys.append(b)

	_hint = Label.new()
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 13)
	_hint.add_theme_color_override("font_color", Color(UITheme.COL_ACCENT_SOFT, 0.75))
	v.add_child(_hint)


func _seq() -> Array:
	return ROUNDS[_round]


func _play_round(slow: bool = false) -> void:
	_busy = true
	_input_pos = 0
	_hint.text = LocalizationManager.t("melody.listen", "Слушай…")
	var step := 0.85 if slow else 0.5
	for n: int in _seq():
		_flash_key(n)
		_tone(n)
		await get_tree().create_timer(step).timeout
	_hint.text = LocalizationManager.t("melody.repeat", "Твоя очередь.")
	_busy = false


func _flash_key(i: int) -> void:
	_keys[i].modulate = Color(1.8, 1.5, 1.7)
	var tw := create_tween()
	tw.tween_property(_keys[i], "modulate", Color.WHITE, step_delay())


func step_delay() -> float:
	return 0.45


func _tone(i: int) -> void:
	AudioManager.play_sfx("click", 0.8 + 0.12 * i)


func _on_note(i: int) -> void:
	if _done or _busy:
		return
	_flash_key(i)
	_tone(i)
	if i == int(_seq()[_input_pos]):
		_input_pos += 1
		if _input_pos >= _seq().size():
			_round += 1
			if _round >= ROUNDS.size():
				_finish()
			else:
				_hint.text = LocalizationManager.t("melody.next", "Так держать. Вторая часть…")
				_play_round.call_deferred()
	else:
		_fails += 1
		AudioManager.play_sfx("click", 0.55)
		_hint.text = LocalizationManager.t("melody.miss", "Старик: «Ты слушала. Просто не пальцами. Ещё раз.»")
		_play_round.call_deferred(_fails >= 2)


func _finish() -> void:
	_done = true
	AudioManager.play_sfx("puzzle_solved")
	_hint.text = LocalizationManager.t("melody.done", "Пластинка оживает.")
	var t := get_tree().create_timer(0.05 if DisplayServer.get_name() == "headless" else 1.8)
	t.timeout.connect(func() -> void:
		solved.emit()
		queue_free()
	)
