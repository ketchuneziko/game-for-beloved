extends Control
## Выбор глав (Фаза 5, GDD §8.1 CHAPTER SELECT): список глав, открытые —
## кликабельны, непройденные — с замком. Пролог в этой игре — «нулевая»
## глава (data/dialogue/chapter_00.json).

const UITheme := preload("res://scripts/ui/theme_builder.gd")

const CHAPTER_COUNT := 8   # 0..7 (файлы глав, которых ещё нет — скрыты)


func _ready() -> void:
	theme = UITheme.build()
	_build_ui()
	AudioManager.play_music("menu")


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = UITheme.COL_SHADOW
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 8)
	add_child(box)

	var title := Label.new()
	title.text = LocalizationManager.t("menu.chapters", "ГЛАВЫ")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", UITheme.COL_ACCENT_SOFT)
	box.add_child(title)
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 14)
	box.add_child(sp)

	var unlocked := SaveManager.unlocked_chapter()
	for n in CHAPTER_COUNT:
		if not DialogueManager.chapter_exists(n):
			continue
		var b := Button.new()
		var label_text := DialogueManager.chapter_title(n)
		if label_text == "":
			label_text = "%d" % n
		if n > unlocked:
			b.text = "🔒  %s" % label_text
			b.disabled = true
		else:
			var date := _chapter_date(n)
			if date != "":
				b.text = "%s   ·   %s" % [label_text, date]
			else:
				b.text = label_text
			b.pressed.connect(_on_chapter.bind(n))
		b.custom_minimum_size = Vector2(560, 42)
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		box.add_child(b)

	var sp2 := Control.new()
	sp2.custom_minimum_size = Vector2(0, 14)
	box.add_child(sp2)
	var back := Button.new()
	back.text = LocalizationManager.t("settings.back", "НАЗАД")
	back.custom_minimum_size = Vector2(330, 44)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(_back)
	box.add_child(back)
	back.call_deferred("grab_focus")


func _chapter_date(n: int) -> String:
	var path := "res://data/dialogue/chapter_%02d.json" % n
	if not FileAccess.file_exists(path):
		return ""
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if raw is Dictionary:
		return LocalizationManager.field((raw as Dictionary).get("chapters", {}))
	return ""


func _on_chapter(n: int) -> void:
	AudioManager.play_sfx("click")
	SaveManager.unlock_chapter(n)
	GameManager.reset_run_state()
	GameManager.goto_chapter(n, "", 0, true)


func _back() -> void:
	GameManager.change_scene_faded(GameManager.SCENE_MENU)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_pause"):
		_back()
