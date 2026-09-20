extends Control
## Загадка «Хронология» (Глава 2, GDD §5 #2): разложить три события
## в правильном порядке (кликать карточки по очереди). Даты/порядок
## звучат в диалогах; промах — мягкая подсказка. Провал невозможен.

signal solved

const UITheme := preload("res://scripts/ui/theme_builder.gd")

## Правильный порядок: лекция -> кафе -> дождь.
const ORDER := [0, 1, 2]
const CARDS := [
	{"glyph": "🎞", "title": {"ru": "Лекция для одного", "en": "The lecture for one"}},
	{"glyph": "☕", "title": {"ru": "Чай с двумя ложками", "en": "Tea, two spoons"}},
	{"glyph": "🌧", "title": {"ru": "Скамейка под дождём", "en": "Bench in the rain"}},
]

var _progress := 0
var _done := false
var _buttons: Array[Button] = []
var _hint: Label


func _ready() -> void:
	theme = UITheme.build()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	if DisplayServer.get_name() == "headless":
		await get_tree().create_timer(0.2).timeout
		for idx: int in ORDER:
			_on_card(idx)


func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.015, 0.035, 0.88)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 220.0
	panel.offset_right = -220.0
	panel.offset_top = 150.0
	panel.offset_bottom = -150.0
	add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	panel.add_child(v)

	var title := Label.new()
	title.text = LocalizationManager.t("chrono.title", "РАЗЛОЖИТЬ ПО ДНЯМ")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", UITheme.COL_ACCENT_SOFT)
	v.add_child(title)

	var sub := Label.new()
	sub.text = LocalizationManager.t("chrono.sub", "Что было раньше? Нажимай карточки в хронологическом порядке.")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.add_theme_font_size_override("font_size", 13)
	sub.add_theme_color_override("font_color", Color(UITheme.COL_TEXT, 0.6))
	v.add_child(sub)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	v.add_child(row)
	for i in CARDS.size():
		var card: Dictionary = CARDS[i]
		var b := Button.new()
		b.text = "%s\n%s" % [str(card["glyph"]), LocalizationManager.field(card["title"])]
		b.custom_minimum_size = Vector2(200, 110)
		b.pressed.connect(_on_card.bind(i))
		row.add_child(b)
		_buttons.append(b)

	_hint = Label.new()
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.add_theme_font_size_override("font_size", 13)
	_hint.add_theme_color_override("font_color", Color(UITheme.COL_ACCENT_SOFT, 0.75))
	v.add_child(_hint)


func _on_card(idx: int) -> void:
	if _done:
		return
	if idx == int(ORDER[_progress]):
		_progress += 1
		_buttons[idx].modulate = Color(1.5, 1.15, 1.4)
		_buttons[idx].disabled = true
		AudioManager.play_sfx("page")
		if _progress >= ORDER.size():
			_solve()
	else:
		_hint.text = LocalizationManager.t("chrono.hint", "Старик: «Сначала я рассказывал. Потом мы пили чай. Дождь пришёл последним — он всегда приходит последним.»")
		AudioManager.play_sfx("click", 0.6)


func _solve() -> void:
	_done = true
	AudioManager.play_sfx("puzzle_solved")
	_hint.text = LocalizationManager.t("chrono.done", "Так и было. День за днём.")
	var t := get_tree().create_timer(0.05 if DisplayServer.get_name() == "headless" else 1.8)
	t.timeout.connect(func() -> void:
		solved.emit()
		queue_free()
	)
