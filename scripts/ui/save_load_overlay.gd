extends Control
## Оверлей сохранений/загрузок (Фаза 5, GDD §8.4/§9.6):
## 5 слотов + autosave + quick; превью-скриншот, глава, время игры, дата.
## mode: "save" (запись в слот) | "load" (чтение). Используется из паузы
## VN-сцены и из главного меню.

const UITheme := preload("res://scripts/ui/theme_builder.gd")

signal closed

var mode := "save"
var _grid: VBoxContainer


func _ready() -> void:
	theme = UITheme.build()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.015, 0.035, 0.9)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 220.0
	panel.offset_right = -220.0
	panel.offset_top = 40.0
	panel.offset_bottom = -40.0
	add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)

	var head := HBoxContainer.new()
	v.add_child(head)
	var title := Label.new()
	title.text = LocalizationManager.t("saveload.save", "СОХРАНИТЬ") if mode == "save" \
		else LocalizationManager.t("saveload.load", "ЗАГРУЗИТЬ")
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", UITheme.COL_ACCENT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var close := Button.new()
	close.text = LocalizationManager.t("history.close", "ЗАКРЫТЬ")
	close.pressed.connect(func() -> void: closed.emit(); queue_free())
	head.add_child(close)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_grid = VBoxContainer.new()
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("separation", 8)
	scroll.add_child(_grid)

	_build_rows()


func _build_rows() -> void:
	for child in _grid.get_children():
		child.queue_free()
	var ids: Array = []
	for i in SaveManager.SLOT_COUNT:
		ids.append(str(i))
	if mode == "load":
		ids.push_front("quick")
		ids.push_front("auto")
	for id: String in ids:
		_grid.add_child(_make_row(id))
	if mode == "save":
		var hint := Label.new()
		hint.text = LocalizationManager.t("saveload.hint", "autosave и quick доступны: F5 — быстрый сейв, Esc — меню с автосейвом")
		hint.add_theme_font_size_override("font_size", 11)
		hint.add_theme_color_override("font_color", Color(UITheme.COL_TEXT, 0.3))
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_grid.add_child(hint)


func _make_row(id: String) -> Control:
	var data := SaveManager.read_save(id)
	var row := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(UITheme.COL_PANEL, 0.6)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(8)
	sb.content_margin_left = 14.0
	sb.content_margin_right = 14.0
	row.add_theme_stylebox_override("panel", sb)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	row.add_child(h)

	# Превью (если есть PNG).
	var tex := _load_preview(id)
	if tex != null:
		var prev := TextureRect.new()
		prev.texture = tex
		prev.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		prev.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		prev.custom_minimum_size = Vector2(128, 72)
		h.add_child(prev)

	# Текст слота.
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 0)
	h.add_child(col)
	var name_label := Label.new()
	name_label.text = _slot_title(id)
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.add_theme_color_override("font_color", UITheme.COL_ACCENT_SOFT if not data.is_empty() else Color(UITheme.COL_TEXT, 0.4))
	col.add_child(name_label)
	var info := Label.new()
	info.text = _slot_info(data)
	info.add_theme_font_size_override("font_size", 12)
	info.add_theme_color_override("font_color", Color(UITheme.COL_TEXT, 0.55))
	col.add_child(info)

	# Действия.
	if mode == "save":
		var b := Button.new()
		b.text = LocalizationManager.t("saveload.write", "ЗАПИСАТЬ")
		b.custom_minimum_size = Vector2(140, 40)
		b.pressed.connect(_on_save_clicked.bind(id))
		h.add_child(b)
	else:
		var b := Button.new()
		b.text = LocalizationManager.t("saveload.read", "ЗАГРУЗИТЬ")
		b.custom_minimum_size = Vector2(140, 40)
		b.disabled = data.is_empty()
		b.pressed.connect(_on_load_clicked.bind(id))
		h.add_child(b)
	if not data.is_empty() and id != "auto":
		var del := Button.new()
		del.text = "✕"
		del.custom_minimum_size = Vector2(40, 40)
		del.tooltip_text = LocalizationManager.t("saveload.delete", "удалить")
		del.pressed.connect(_on_delete_clicked.bind(id))
		h.add_child(del)
	return row


func _slot_title(id: String) -> String:
	if id == "auto":
		return LocalizationManager.t("saveload.autosave", "АВТОСОХРАНЕНИЕ")
	if id == "quick":
		return LocalizationManager.t("saveload.quick", "БЫСТРЫЙ СЛОТ (F5/F9)")
	return LocalizationManager.t("saveload.slot", "СЛОТ %d") % (int(id) + 1)


func _slot_info(data: Dictionary) -> String:
	if data.is_empty():
		return LocalizationManager.t("saveload.empty", "пусто")
	var chapter := int(data.get("chapter", -1))
	var ch_title := DialogueManager.chapter_title(chapter)
	var secs := float(data.get("play_seconds", 0.0))
	var minutes := int(secs) / 60
	var frags: Array = data.get("fragments", [])
	var time_str := str(data.get("timestamp", "")).replace("T", " ")
	return "%s · %s %dмин · ✦%d/7 · %s" % [ch_title, LocalizationManager.t("saveload.played", "время:"), minutes, frags.size(), time_str]


func _on_save_clicked(id: String) -> void:
	SaveManager.write_save(id, SaveManager.capture_state({"kind": "slot"}))
	AudioManager.play_sfx("click")
	_build_rows()


func _on_load_clicked(id: String) -> void:
	var data := SaveManager.read_save(id)
	if data.is_empty():
		return
	AudioManager.play_sfx("page")
	SaveManager.restore_state(data)
	closed.emit()
	queue_free()
	GameManager.change_scene_faded(GameManager.SCENE_VN, 0.45, 0.6)


func _on_delete_clicked(id: String) -> void:
	SaveManager.delete_save(id)
	AudioManager.play_sfx("click")
	_build_rows()


func _load_preview(id: String) -> Texture2D:
	if DisplayServer.get_name() == "headless":
		return null
	var path := SaveManager.SAVES_DIR + "save_%s.png" % id
	if not FileAccess.file_exists(path):
		return null
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	if img == null:
		return null
	return ImageTexture.create_from_image(img)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_pause"):
		closed.emit()
		queue_free()
