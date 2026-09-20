extends Control
## Финальная сборка сообщения (GDD §5 #6, глава 6): 7 фрагментов из
## data/custom/letters.json (final_message) — кликать в правильном
## порядке, фраза собирается построчно. Подсказка после 2 промахов:
## следующая верная карточка пульсирует. Провал невозможен.

signal solved

const UITheme := preload("res://scripts/ui/theme_builder.gd")

var _parts: Array = []          # строки фразы (по порядку)
var _order: Array = []          # перемешанные индексы
var _progress := 0
var _misses := 0
var _done := false
var _tiles: Array[Button] = []
var _hint: Label


func _ready() -> void:
	theme = UITheme.build()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_load_parts()
	if _parts.is_empty():
		push_warning("FragmentsPuzzle: нет final_message — пропускаю")
		solved.emit()
		queue_free()
		return
	_build_ui()
	if DisplayServer.get_name() == "headless":
		await get_tree().create_timer(0.2).timeout
		for i in _parts.size():
			_on_tile(_parts[i])


func _load_parts() -> void:
	var path := "res://data/custom/letters.json"
	if not FileAccess.file_exists(path):
		return
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (raw is Dictionary):
		return
	for p: Variant in (raw as Dictionary).get("final_message", []):
		_parts.append(LocalizationManager.field(p))


func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.015, 0.035, 0.9)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 140.0
	panel.offset_right = -140.0
	panel.offset_top = 70.0
	panel.offset_bottom = -70.0
	add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)

	var title := Label.new()
	title.text = LocalizationManager.t("frag.title", "СОБЕРИ СООБЩЕНИЕ")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", UITheme.COL_ACCENT_SOFT)
	v.add_child(title)

	var sub := Label.new()
	sub.text = LocalizationManager.t("frag.sub", "Все обрывки, которые попадались тебе всю игру. Нажимай в порядке чтения.")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.add_theme_font_size_override("font_size", 13)
	sub.add_theme_color_override("font_color", Color(UITheme.COL_TEXT, 0.6))
	v.add_child(sub)

	# Строка собранного сообщения.
	var message := Label.new()
	message.name = "Message"
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_font_size_override("font_size", 19)
	message.add_theme_color_override("font_color", UITheme.COL_ACCENT)
	v.add_child(message)

	# Перемешанные карточки.
	_order = range(_parts.size())
	_order.shuffle()
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(grid)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for idx: int in _order:
		var b := Button.new()
		b.text = "✦ %s" % str(_parts[idx])
		b.custom_minimum_size = Vector2(360, 52)
		b.pressed.connect(_on_tile.bind(str(_parts[idx])))
		grid.add_child(b)
		_tiles.append(b)

	_hint = Label.new()
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.add_theme_font_size_override("font_size", 13)
	_hint.add_theme_color_override("font_color", Color(UITheme.COL_ACCENT_SOFT, 0.75))
	v.add_child(_hint)


func _on_tile(text: String) -> void:
	if _done:
		return
	if text == str(_parts[_progress]):
		AudioManager.play_sfx("page", 1.0 + 0.06 * _progress)
		for b: Button in _tiles:
			if b.text == "✦ %s" % text and not b.disabled:
				b.disabled = true
				b.modulate = Color(1.4, 1.15, 1.35)
				break
		var msg := _hint.get_parent().get_node("Message") as Label
		msg.text = msg.text + (" " if msg.text != "" else "") + text
		_progress += 1
		_misses = 0
		if _progress >= _parts.size():
			_solve()
	else:
		_misses += 1
		AudioManager.play_sfx("click", 0.6)
		if _misses >= 2:
			var next_text := "✦ %s" % str(_parts[_progress])
			for b: Button in _tiles:
				if b.text == next_text and not b.disabled:
					var tw := create_tween()
					tw.set_loops(3)
					tw.tween_property(b, "modulate", Color(1.7, 1.4, 1.6), 0.3)
					tw.tween_property(b, "modulate", Color.WHITE, 0.3)
					break
			_hint.text = LocalizationManager.t("frag.hint", "Старик: «Та, что светится, — следующая. Я вижу тебя, Мария. Ты справляешься.»")
		else:
			_hint.text = LocalizationManager.t("frag.try", "Не тот кусочек. Читай фразу про себя — чувствуй ритм.")


func _solve() -> void:
	_done = true
	AudioManager.play_sfx("puzzle_solved")
	_hint.text = LocalizationManager.t("frag.done", "Семь обрывков. Одно сообщение.")
	var t := get_tree().create_timer(0.05 if DisplayServer.get_name() == "headless" else 2.6)
	t.timeout.connect(func() -> void:
		solved.emit()
		queue_free()
	)
