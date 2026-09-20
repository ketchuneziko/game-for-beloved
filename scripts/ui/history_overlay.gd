extends Control
## История диалогов (GDD §8.4): весь текст текущей главы, скролл,
## только чтение (по GDD клик по строке не прыгает). Открытие: кнопка
## LOG или клавиша H. Добавляет записи через add_entry().

const UITheme := preload("res://scripts/ui/theme_builder.gd")

var _list: VBoxContainer
var _scroll: ScrollContainer
var _entries: Array = []


func _ready() -> void:
	theme = UITheme.build()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.015, 0.035, 0.86)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 180.0
	panel.offset_right = -180.0
	panel.offset_top = 46.0
	panel.offset_bottom = -100.0
	add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)

	var head := HBoxContainer.new()
	v.add_child(head)
	var title := Label.new()
	title.text = LocalizationManager.t("history.title", "ИСТОРИЯ")
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", UITheme.COL_ACCENT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var close := Button.new()
	close.text = LocalizationManager.t("history.close", "ЗАКРЫТЬ (H)")
	close.pressed.connect(close_history)
	head.add_child(close)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(_scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 10)
	_scroll.add_child(_list)


func add_entry(who_display: String, color: Color, text: String) -> void:
	_entries.append([who_display, color, text])
	if _list == null:
		return
	var row := VBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 0)
	var name_label := Label.new()
	name_label.text = who_display
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_color_override("font_color", color)
	row.add_child(name_label)
	var body := RichTextLabel.new()
	body.bbcode_enabled = false
	body.fit_content = true
	body.scroll_active = false
	body.text = text
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.custom_minimum_size = Vector2(0, 24)
	body.add_theme_font_size_override("normal_font_size", SettingsManager.base_font_size())
	body.add_theme_color_override("default_color", Color(UITheme.COL_TEXT, 0.88))
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(body)
	_list.add_child(row)


func open() -> void:
	if _entries.is_empty():
		return
	visible = true
	await get_tree().process_frame
	_scroll.scroll_vertical = int(_list.size.y)


func close_history() -> void:
	visible = false


func clear_entries() -> void:
	_entries.clear()
	if _list != null:
		for c in _list.get_children():
			c.queue_free()
