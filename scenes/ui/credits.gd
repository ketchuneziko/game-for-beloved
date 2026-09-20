extends Control
## Титры — минимальная версия Фазы 3 (полная — Фаза 10, GDD §8.1).
## Посвящение берётся из data/custom/about.json — там же меняй имя автора.

const UITheme := preload("res://scripts/ui/theme_builder.gd")


func _ready() -> void:
	theme = UITheme.build()
	AudioManager.play_music("credits")
	_build_ui()


func _build_ui() -> void:
	var about := GameManager.custom_about()

	var bg := ColorRect.new()
	bg.color = UITheme.COL_SHADOW
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	add_child(box)

	var title := Label.new()
	title.text = "TO ETERNITY AND BEYOND"
	var display := UITheme.display_font()
	if display != null:
		title.add_theme_font_override("font", display)
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", UITheme.COL_ACCENT_SOFT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	box.add_child(_spacer(16))

	for line: String in [
		LocalizationManager.t("credits.made_by", "сценарий, код, дизайн — твой автор"),
		LocalizationManager.field(about.get("dedication", {})),
		LocalizationManager.t("credits.engine", "сделано на Godot Engine"),
		LocalizationManager.t("credits.fonts", "шрифты: JetBrains Mono, Press Start 2P — SIL OFL"),
	]:
		var l := Label.new()
		l.text = line
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", 14)
		l.add_theme_color_override("font_color", Color(UITheme.COL_TEXT, 0.65))
		box.add_child(l)

	box.add_child(_spacer(24))
	var back := Button.new()
	back.text = LocalizationManager.t("settings.back", "НАЗАД")
	back.custom_minimum_size = Vector2(330, 44)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(_back)
	box.add_child(back)
	back.call_deferred("grab_focus")


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_pause"):
		_back()


func _back() -> void:
	GameManager.change_scene_faded(GameManager.SCENE_MENU)


func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c
