extends Control
## Загадка «Звёздный каталог» (Глава 3, GDD §5 #3): каждое число — номер
## буквы алфавита. Фраза берётся из data/custom/letters.json
## (ch3_cipher.phrase), числа генерируются из неё же на лету —
## правишь фразу, и шифр сам остаётся согласованным.
## Подсказки: динамические, без штрафов (полная система подсказок
## «Старика» — Фаза 7). Headless-автотест решает сам.

signal solved

const UITheme := preload("res://scripts/ui/theme_builder.gd")

## Алфавит без Ё (Ё слита с Е) — классический A1Z26 для русского.
const ALPHABET := "АБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ"

var _phrase := ""
var _attempts := 0
var _done := false
var _input: LineEdit
var _hint: Label
var _result: RichTextLabel
var _check: Button


func _ready() -> void:
	theme = UITheme.build()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_phrase = _load_phrase()
	if _phrase == "":
		# Нет фразы — не блокируем главу.
		push_warning("CipherPuzzle: пустая фраза, пропускаю загадку")
		_finish()
		return
	_build_ui()
	if DisplayServer.get_name() == "headless":
		await get_tree().create_timer(0.2).timeout
		_solve()


func _load_phrase() -> String:
	var path := "res://data/custom/letters.json"
	if not FileAccess.file_exists(path):
		return ""
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if raw is Dictionary:
		var c: Dictionary = (raw as Dictionary).get("ch3_cipher", {})
		return LocalizationManager.field(c.get("phrase", {}))
	return ""


func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.015, 0.035, 0.88)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 240.0
	panel.offset_right = -240.0
	panel.offset_top = 70.0
	panel.offset_bottom = -70.0
	add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)

	var title := Label.new()
	title.text = LocalizationManager.t("cipher.title", "ШИФР «ЗВЁЗДНОГО КАТАЛОГА»")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", UITheme.COL_ACCENT_SOFT)
	v.add_child(title)

	var sub := Label.new()
	sub.text = LocalizationManager.t("cipher.sub", "Каждое число — номер буквы алфавита. Собери фразу и впиши её.")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 13)
	sub.add_theme_color_override("font_color", Color(UITheme.COL_TEXT, 0.55))
	v.add_child(sub)

	_result = RichTextLabel.new()
	_result.fit_content = true
	_result.scroll_active = false
	_result.custom_minimum_size = Vector2(0, 40)
	_result.add_theme_font_size_override("normal_font_size", 17)
	v.add_child(_result)

	var numbers := Label.new()
	numbers.text = _numbers_text()
	numbers.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	numbers.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	numbers.add_theme_font_size_override("font_size", 16)
	numbers.add_theme_color_override("font_color", Color(UITheme.COL_TEXT, 0.8))
	v.add_child(numbers)

	_input = LineEdit.new()
	_input.placeholder_text = LocalizationManager.t("cipher.placeholder", "впиши фразу…")
	_input.custom_minimum_size = Vector2(0, 44)
	_input.text_submitted.connect(func(_t: String) -> void: _on_check())
	v.add_child(_input)

	_check = Button.new()
	_check.text = LocalizationManager.t("cipher.check", "ПРОВЕРИТЬ")
	_check.custom_minimum_size = Vector2(240, 44)
	_check.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_check.pressed.connect(_on_check)
	v.add_child(_check)

	_hint = Label.new()
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.add_theme_font_size_override("font_size", 13)
	_hint.add_theme_color_override("font_color", Color(UITheme.COL_ACCENT_SOFT, 0.75))
	v.add_child(_hint)

	_input.call_deferred("grab_focus")


func _norm(s: String) -> String:
	var up := s.to_upper().replace("Ё", "Е")
	var out := ""
	for ch in up:
		if ALPHABET.find(ch) >= 0:
			out += ch
	return out


func _numbers_text() -> String:
	var groups: PackedStringArray = []
	for word in _phrase.split(" ", false):
		var nums := PackedStringArray()
		for ch in word.to_upper().replace("Ё", "Е"):
			var idx := ALPHABET.find(ch)
			if idx >= 0:
				nums.append(str(idx + 1))
		if not nums.is_empty():
			groups.append("-".join(nums))
	return "   ".join(groups)


func _on_check() -> void:
	if _done:
		return
	if _norm(_input.text) == _norm(_phrase):
		_solve()
	else:
		_attempts += 1
		AudioManager.play_sfx("click")
		match _attempts:
			1:
				_hint.text = LocalizationManager.t("cipher.hint1", "Каждое число — номер буквы: 1 = А, 2 = Б, 3 = В…")
			2:
				var first_num := _first_number()
				var first_letter := ALPHABET.substr(first_num - 1, 1) if first_num >= 1 and first_num <= ALPHABET.length() else "?"
				_hint.text = LocalizationManager.t("cipher.hint2", "Первое число — %d. Это буква «%s».") % [first_num, first_letter]
			_:
				var w: PackedStringArray = []
				for word in _phrase.split(" ", false):
					if not word.is_empty():
						w.append(word[0])
				_hint.text = LocalizationManager.t("cipher.hint3", "Первые буквы слов: %s") % " ".join(w)


func _first_number() -> int:
	for word in _phrase.split(" ", false):
		for ch in word.to_upper().replace("Ё", "Е"):
			var idx := ALPHABET.find(ch)
			if idx >= 0:
				return idx + 1
	return 1


func _solve() -> void:
	if _done:
		return
	_done = true
	AudioManager.play_sfx("puzzle_solved")
	_input.visible = false
	_check.visible = false
	_hint.visible = false
	_result.text = "[center][color=#ff8fbd]%s[/color][/center]" % _phrase
	var t := get_tree().create_timer(0.05 if DisplayServer.get_name() == "headless" else 2.4)
	t.timeout.connect(_finish)


func _finish() -> void:
	solved.emit()
	queue_free()
