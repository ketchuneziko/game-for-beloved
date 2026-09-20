extends Control
## Просмотр фотографии на весь экран (GDD «PHOTOGRAPHS»): пропорции
## сохранены, тёмная виньетка, рамка, подпись и дата «с оборота».

signal closed

const UITheme := preload("res://scripts/ui/theme_builder.gd")

var _path := ""
var _caption := ""
var _date := ""


func setup(path: String, caption: String, date: String) -> void:
	_path = path
	_caption = caption
	_date = date
	_build()


func _ready() -> void:
	if _path == "":
		_build()


func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var dim := ColorRect.new()
	dim.color = Color(0.015, 0.01, 0.03, 0.96)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	dim.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			close()
	)

	if _path != "" and FileAccess.file_exists(_path):
		var t: Texture2D = load(_path)
		var frame := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(UITheme.COL_PANEL_2, 1.0)
		sb.set_corner_radius_all(6)
		sb.set_content_margin_all(10)
		frame.add_theme_stylebox_override("panel", sb)
		frame.set_anchors_preset(Control.PRESET_CENTER)
		frame.custom_minimum_size = Vector2(0, 0)
		add_child(frame)
		var img := TextureRect.new()
		img.texture = t
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		# Вписываем в экран с сохранением пропорций.
		var tex_size: Vector2 = t.get_size()
		var max_size := Vector2(980.0, 540.0)
		var k: float = minf(max_size.x / maxf(tex_size.x, 1.0), max_size.y / maxf(tex_size.y, 1.0))
		img.custom_minimum_size = tex_size * k
		frame.add_child(img)
		frame.reset_size()
		frame.position = (Vector2(1280, 720) - frame.size) * 0.5

	var info := VBoxContainer.new()
	info.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	info.offset_top = -110.0
	info.offset_bottom = -30.0
	info.add_theme_constant_override("separation", 4)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(info)
	var cap := Label.new()
	cap.text = _caption
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cap.add_theme_font_size_override("font_size", 17)
	cap.add_theme_color_override("font_color", UITheme.COL_TEXT)
	info.add_child(cap)
	var d := Label.new()
	d.text = _date
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	d.add_theme_font_size_override("font_size", 12)
	d.add_theme_color_override("font_color", Color(UITheme.COL_ACCENT_SOFT, 0.7))
	info.add_child(d)
	var hint := Label.new()
	hint.text = LocalizationManager.t("viewer.close_hint", "клик — закрыть")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(UITheme.COL_TEXT, 0.3))
	info.add_child(hint)


func close() -> void:
	AudioManager.play_sfx("click")
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		close()
