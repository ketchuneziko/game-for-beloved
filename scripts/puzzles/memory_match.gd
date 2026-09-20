extends Control
## Мини-игра «Пары» (GDD §6 #1, глава 2): 12 карточек / 6 пар с мотивами
## фотографий. Без таймера и провала; после 6 промахов Старик «случайно»
## подсвечивает пару. ≤5 промахов — достижение PERFECT PAIRS.

signal solved

const UITheme := preload("res://scripts/ui/theme_builder.gd")

const GLYPHS := ["✦", "★", "♥", "☾", "♪", "✧"]
const HINT_AFTER := 6

var _deck: Array = []           # глифы в порядке сетки
var _open: Array = []           # открытые сейчас индексы
var _matched := 0
var _misses := 0
var _busy := false
var _done := false
var _buttons: Array[Button] = []
var _hint: Label


func _ready() -> void:
	theme = UITheme.build()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_deck()
	_build_ui()
	if DisplayServer.get_name() == "headless":
		await get_tree().create_timer(0.2).timeout
		_solve_directly()


func _build_deck() -> void:
	_deck = GLYPHS + GLYPHS
	_deck.shuffle()


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
	panel.offset_top = 80.0
	panel.offset_bottom = -80.0
	add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)

	var title := Label.new()
	title.text = LocalizationManager.t("pairs.title", "НАЙДИ ПАРЫ")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", UITheme.COL_ACCENT_SOFT)
	v.add_child(title)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(grid)
	for i in _deck.size():
		var b := Button.new()
		b.text = "·"
		b.custom_minimum_size = Vector2(96, 96)
		b.pressed.connect(_on_card.bind(i))
		grid.add_child(b)
		_buttons.append(b)

	_hint = Label.new()
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 13)
	_hint.add_theme_color_override("font_color", Color(UITheme.COL_ACCENT_SOFT, 0.75))
	_hint.text = LocalizationManager.t("pairs.sub", "Все пары — мотивы из нашей коробки.")
	v.add_child(_hint)


func _on_card(i: int) -> void:
	if _done or _busy or _buttons[i].disabled:
		return
	_buttons[i].text = str(_deck[i])
	_buttons[i].modulate = Color(1.4, 1.2, 1.4)
	_open.append(i)
	AudioManager.play_sfx("page", randf_range(0.95, 1.05))
	if _open.size() < 2:
		return
	_busy = true
	var a: int = _open[0]
	var b: int = _open[1]
	_open.clear()
	if _deck[a] == _deck[b]:
		await get_tree().create_timer(0.35).timeout
		_buttons[a].disabled = true
		_buttons[b].disabled = true
		_buttons[a].modulate = Color(1.6, 1.3, 1.5)
		_buttons[b].modulate = Color(1.6, 1.3, 1.5)
		AudioManager.play_sfx("click", 1.2)
		_matched += 1
		_busy = false
		if _matched >= GLYPHS.size():
			_finish()
	else:
		_misses += 1
		await get_tree().create_timer(0.75).timeout
		_buttons[a].text = "·"
		_buttons[b].text = "·"
		_buttons[a].modulate = Color.WHITE
		_buttons[b].modulate = Color.WHITE
		_busy = false
		if _misses == HINT_AFTER:
			_hint_pair()
		elif _misses > HINT_AFTER:
			_hint.text = LocalizationManager.t("pairs.hint", "Старик: «Я ничего не подсказываю. Совсем. Ни капли.»")


func _hint_pair() -> void:
	# «Случайно» подсвечиваем первую ещё не найденную пару.
	var first_idx := -1
	for i in _deck.size():
		if not _buttons[i].disabled:
			first_idx = i
			break
	if first_idx < 0:
		return
	for i in range(first_idx + 1, _deck.size()):
		if not _buttons[i].disabled and _deck[i] == _deck[first_idx]:
			_flash(_buttons[first_idx])
			_flash(_buttons[i])
			break
	_hint.text = LocalizationManager.t("pairs.old_hint", "Старик: «Ой. Кнопка сама нажалась. Бывает.»")


func _flash(b: Button) -> void:
	b.text = str(_deck[_buttons.find(b)])
	var tw := create_tween()
	tw.tween_interval(0.9)
	tw.tween_callback(func() -> void:
		if not b.disabled:
			b.text = "·"
	)


func _finish() -> void:
	_done = true
	if _misses <= 5:
		AchievementManager.unlock("perfect_pairs")
	AudioManager.play_sfx("puzzle_solved")
	_hint.text = LocalizationManager.t("pairs.done", "Всё сошлось. Как в тот вечер.")
	var t := get_tree().create_timer(0.05 if DisplayServer.get_name() == "headless" else 1.8)
	t.timeout.connect(func() -> void:
		solved.emit()
		queue_free()
	)


func _solve_directly() -> void:
	# Автотест: решить мгновенно.
	for b: Button in _buttons:
		b.disabled = true
	_finish()
