extends Control
## Загадка «Скрытое имя» (Глава 4, GDD §5 #4): в тексте письма часть
## букв чуть светится — это слово, которое нельзя было написать.
## Кликать по порядку появления. Слово и письмо — в data/custom/letters.json
## (hidden_name.word / hidden_name.letter_id) — редактируются без кода.

signal solved

const UITheme := preload("res://scripts/ui/theme_builder.gd")

var _word := "МИРА"
var _letter_id := "letter_02"
var _progress := 0
var _done := false
var _hint: Label
var _found: Label


func _ready() -> void:
	theme = UITheme.build()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_load_config()
	_build_ui()
	if DisplayServer.get_name() == "headless":
		await get_tree().create_timer(0.2).timeout
		for ch in _word:
			_on_glyph(ch)


func _load_config() -> void:
	var path := "res://data/custom/letters.json"
	if not FileAccess.file_exists(path):
		return
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (raw is Dictionary):
		return
	var hn: Dictionary = (raw as Dictionary).get("hidden_name", {})
	_word = LocalizationManager.field(hn.get("word", {"ru": "МИРА"}))
	_letter_id = str(hn.get("letter_id", "letter_02"))


func _letter_text() -> String:
	var path := "res://data/custom/letters.json"
	if not FileAccess.file_exists(path):
		return ""
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (raw is Dictionary):
		return ""
	for l: Variant in (raw as Dictionary).get("ch4_letters", []):
		if l is Dictionary and str(l.get("id", "")) == _letter_id:
			return LocalizationManager.field((l as Dictionary).get("text", {}))
	return ""


func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.015, 0.035, 0.9)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 170.0
	panel.offset_right = -170.0
	panel.offset_top = 60.0
	panel.offset_bottom = -60.0
	add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)

	var title := Label.new()
	title.text = LocalizationManager.t("hidden.title", "В БУМАГЕ ЕСТЬ ТО, ЧЕГО НЕТ В СЛОВАХ")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", UITheme.COL_ACCENT_SOFT)
	v.add_child(title)

	var sub := Label.new()
	sub.text = LocalizationManager.t("hidden.sub", "Некоторые буквы чуть светятся. Нажимай их по порядку появления.")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.add_theme_font_size_override("font_size", 13)
	sub.add_theme_color_override("font_color", Color(UITheme.COL_TEXT, 0.6))
	v.add_child(sub)

	# Текст письма: поток «букв-кнопок». Светятся только нужные.
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	var flow := HFlowContainer.new()
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(flow)

	var text := _letter_text()
	var chars := _targets_in_text(text)
	for item: Array in chars:
		var ch := str(item[0])
		var target := bool(item[1])
		var l := Label.new()
		l.text = ch
		l.add_theme_font_size_override("font_size", 18)
		if target:
			l.add_theme_color_override("font_color", UITheme.COL_ACCENT)
			l.mouse_filter = Control.MOUSE_FILTER_STOP
			l.gui_input.connect(_on_glyph_input.bind(ch))
			l.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		else:
			l.add_theme_color_override("font_color", Color(UITheme.COL_TEXT, 0.66))
			l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		flow.add_child(l)

	_found = Label.new()
	_found.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_found.add_theme_font_size_override("font_size", 22)
	_found.add_theme_color_override("font_color", UITheme.COL_ACCENT)
	v.add_child(_found)

	_hint = Label.new()
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.add_theme_font_size_override("font_size", 13)
	_hint.add_theme_color_override("font_color", Color(UITheme.COL_ACCENT_SOFT, 0.75))
	v.add_child(_hint)


## Разметка: массив [символ, это_цель]. Цели — буквы слова по порядку,
## встречающиеся в тексте (регистр и Ё/Е не важны).
func _targets_in_text(text: String) -> Array:
	var word_pos := 0
	var out: Array = []
	for ch in text:
		var is_target := false
		if word_pos < _word.length():
			if _norm_char(ch) == _norm_char(_word[word_pos]):
				is_target = true
				word_pos += 1
		out.append([ch, is_target])
	return out


func _norm_char(ch: String) -> String:
	var up := ch.to_upper().replace("Ё", "Е")
	return up if up.length() == 1 else ch


func _on_glyph_input(event: InputEvent, ch: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_glyph(ch)


func _on_glyph(ch: String) -> void:
	if _done:
		return
	if _norm_char(ch) == _norm_char(_word[_progress]):
		_progress += 1
		_found.text += ch
		AudioManager.play_sfx("click", 1.0 + 0.12 * _progress)
		if _progress >= _word.length():
			_solve()
	else:
		_progress = 0
		_found.text = ""
		_hint.text = LocalizationManager.t("hidden.hint", "Старик: «Светящиеся. По порядку. Имя появится само.»")
		AudioManager.play_sfx("click", 0.6)


func _solve() -> void:
	_done = true
	AudioManager.play_sfx("puzzle_solved")
	_hint.text = LocalizationManager.t("hidden.done", "Вот оно. Имя, которое не решались написать целиком.")
	var t := get_tree().create_timer(0.05 if DisplayServer.get_name() == "headless" else 2.2)
	t.timeout.connect(func() -> void:
		solved.emit()
		queue_free()
	)
