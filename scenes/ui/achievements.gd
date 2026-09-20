extends Control
## Экран достижений (Фаза 9, GDD §8.4): 12 штук, скрытые до разблокировки
## — «???». Счётчик сверху. Тосты в игре уже работают (Фаза 4).

const UITheme := preload("res://scripts/ui/theme_builder.gd")


func _ready() -> void:
	theme = UITheme.build()
	_build_ui()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = UITheme.COL_SHADOW
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 240.0
	v.offset_right = -240.0
	v.offset_top = 26.0
	v.offset_bottom = -26.0
	v.add_theme_constant_override("separation", 8)
	add_child(v)

	var head := HBoxContainer.new()
	v.add_child(head)
	var title := Label.new()
	title.text = LocalizationManager.t("ach.title", "ДОСТИЖЕНИЯ")
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", UITheme.COL_ACCENT_SOFT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var counter := Label.new()
	counter.text = "%d/%d" % [AchievementManager.unlock_count(), AchievementManager.total_count()]
	counter.add_theme_font_size_override("font_size", 18)
	counter.add_theme_color_override("font_color", UITheme.COL_ACCENT)
	head.add_child(counter)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)

	for def: Variant in AchievementManager.definitions:
		if not (def is Dictionary):
			continue
		var d: Dictionary = def
		var id := str(d.get("id", ""))
		var hidden := bool(d.get("hidden", false))
		var unlocked := AchievementManager.is_unlocked(id)
		var row := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(UITheme.COL_PANEL, 0.75 if unlocked else 0.35)
		sb.set_corner_radius_all(10)
		sb.set_content_margin_all(8)
		sb.content_margin_left = 14.0
		sb.content_margin_right = 14.0
		row.add_theme_stylebox_override("panel", sb)
		list.add_child(row)

		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 14)
		row.add_child(h)

		var icon := Label.new()
		icon.text = "★" if unlocked else "·"
		icon.add_theme_font_size_override("font_size", 22)
		icon.add_theme_color_override("font_color", UITheme.COL_ACCENT if unlocked else Color(UITheme.COL_TEXT, 0.2))
		h.add_child(icon)

		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 0)
		h.add_child(col)

		if unlocked or not hidden:
			var name_label := Label.new()
			name_label.text = LocalizationManager.field(d.get("name", id))
			name_label.add_theme_font_size_override("font_size", 15)
			name_label.add_theme_color_override("font_color", UITheme.COL_ACCENT_SOFT if unlocked else Color(UITheme.COL_TEXT, 0.55))
			col.add_child(name_label)
			var desc := Label.new()
			desc.text = LocalizationManager.field(d.get("desc", {}))
			desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			desc.add_theme_font_size_override("font_size", 12)
			desc.add_theme_color_override("font_color", Color(UITheme.COL_TEXT, 0.6 if unlocked else 0.3))
			col.add_child(desc)
		else:
			var name_label := Label.new()
			name_label.text = "???"
			name_label.add_theme_font_size_override("font_size", 15)
			name_label.add_theme_color_override("font_color", Color(UITheme.COL_TEXT, 0.35))
			col.add_child(name_label)
			var desc := Label.new()
			desc.text = LocalizationManager.t("ach.hidden_hint", "скрытое достижение — раскроется, если искать")
			desc.add_theme_font_size_override("font_size", 12)
			desc.add_theme_color_override("font_color", Color(UITheme.COL_TEXT, 0.2))
			col.add_child(desc)

	var back := Button.new()
	back.text = LocalizationManager.t("settings.back", "НАЗАД")
	back.custom_minimum_size = Vector2(330, 44)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(_back)
	v.add_child(back)
	back.call_deferred("grab_focus")


func _back() -> void:
	AudioManager.play_sfx("click")
	GameManager.change_scene_faded(GameManager.SCENE_MENU)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_pause"):
		_back()
