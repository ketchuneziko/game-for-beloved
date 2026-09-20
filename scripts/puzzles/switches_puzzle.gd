extends Control
## Загадка-туториал «Последний запуск» (Глава 1, GDD §5 #0): три тумблера
## проектора. Порядок произносится в диалоге («левый — центральный —
## правый»), промах сбрасывает прогресс с мягкой подсказкой. Провал
## невозможен. Headless-автотест решает сам.

signal solved

const UITheme := preload("res://scripts/ui/theme_builder.gd")

## Правильный порядок индексов тумблеров (0 = левый).
const ORDER := [0, 1, 2]

var _progress := 0
var _done := false
var _switches: Array[Button] = []
var _hint: Label


func _ready() -> void:
	theme = UITheme.build()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	if DisplayServer.get_name() == "headless":
		await get_tree().create_timer(0.2).timeout
		for idx: int in ORDER:
			_on_switch(idx)


func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.015, 0.035, 0.88)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 320.0
	panel.offset_right = -320.0
	panel.offset_top = 180.0
	panel.offset_bottom = -180.0
	add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	panel.add_child(v)

	var title := Label.new()
	title.text = LocalizationManager.t("sw.title", "ЩИТОК ПРОЕКТОРА")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", UITheme.COL_ACCENT_SOFT)
	v.add_child(title)

	var sub := Label.new()
	sub.text = LocalizationManager.t("sw.sub", "Запусти тумблеры по порядку: левый — центральный — правый.")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.add_theme_font_size_override("font_size", 13)
	sub.add_theme_color_override("font_color", Color(UITheme.COL_TEXT, 0.6))
	v.add_child(sub)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 26)
	v.add_child(row)
	for i in 3:
		var b := Button.new()
		b.text = ["I", "II", "III"][i]
		b.custom_minimum_size = Vector2(110, 130)
		b.pressed.connect(_on_switch.bind(i))
		row.add_child(b)
		_switches.append(b)

	_hint = Label.new()
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.add_theme_font_size_override("font_size", 13)
	_hint.add_theme_color_override("font_color", Color(UITheme.COL_ACCENT_SOFT, 0.75))
	v.add_child(_hint)


func _on_switch(idx: int) -> void:
	if _done:
		return
	if idx == int(ORDER[_progress]):
		_progress += 1
		_switches[idx].modulate = Color(1.5, 1.15, 1.4)
		_switches[idx].text += " ✓"
		AudioManager.play_sfx("click", 0.9 + 0.15 * _progress)
		if _progress >= ORDER.size():
			_solve()
	else:
		_progress = 0
		for s: Button in _switches:
			s.modulate = Color.WHITE
			s.text = s.text.trim_suffix(" ✓")
		AudioManager.play_sfx("click", 0.6)
		_hint.text = LocalizationManager.t("sw.hint", "Старик: «Левый. Центральный. Правый. Как вальс: раз-два-три.»")


func _solve() -> void:
	_done = true
	AudioManager.play_sfx("puzzle_solved")
	_hint.text = LocalizationManager.t("sw.done", "Щёлк. Гул. Купол просыпается.")
	var t := get_tree().create_timer(0.05 if DisplayServer.get_name() == "headless" else 1.8)
	t.timeout.connect(func() -> void:
		solved.emit()
		queue_free()
	)
