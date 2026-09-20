extends Control
## Главное меню — PHASE 2 SCAFFOLD.
## Работает навигация (PLAY / CONTINUE / EXIT), остальные пункты честно
## сообщают, в какой фазе появятся. Живое меню (звёзды, частицы, свечение,
## рассветная версия после финала) — Фаза 3 (GDD §8.2).

const UITheme := preload("res://scripts/ui/theme_builder.gd")

const MENU_ACTIONS := [
	["play", "menu.play"],
	["continue", "menu.continue"],
	["chapters", "menu.chapters"],
	["gallery", "menu.gallery"],
	["achievements", "menu.achievements"],
	["settings", "menu.settings"],
	["credits", "menu.credits"],
	["exit", "menu.exit"],
]

var _note: Label


func _ready() -> void:
	theme = UITheme.build()
	_build_background()
	_build_ui()


func _build_background() -> void:
	var bg := ColorRect.new()
	bg.color = UITheme.COL_SHADOW
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Плейсхолдер-звёзды; живое звёздное поле — Фаза 3.
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260920
	for i in 90:
		var star := Label.new()
		star.text = "·" if rng.randf() < 0.72 else "✦"
		star.add_theme_color_override("font_color", Color(UITheme.COL_TEXT, rng.randf_range(0.08, 0.4)))
		star.add_theme_font_size_override("font_size", rng.randi_range(10, 18))
		star.position = Vector2(rng.randf_range(0.0, 1280.0), rng.randf_range(0.0, 720.0))
		star.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(star)


func _build_ui() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 8)
	center.add_child(box)

	var title := Label.new()
	title.text = "TO ETERNITY AND BEYOND"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", UITheme.COL_ACCENT_SOFT)
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = LocalizationManager.t("menu.subtitle")
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(UITheme.COL_TEXT, 0.55))
	box.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 26)
	box.add_child(spacer)

	var has_progress: bool = SaveManager.has_save("auto") or SaveManager.has_save("quick")
	var first_button: Button = null
	for action: Array in MENU_ACTIONS:
		var btn := Button.new()
		btn.text = LocalizationManager.t(str(action[1]))
		btn.custom_minimum_size = Vector2(320, 42)
		btn.pressed.connect(_on_action.bind(str(action[0])))
		if str(action[0]) == "continue" and not has_progress:
			btn.disabled = true
		if str(action[0]) == "exit" and _is_mobile():
			btn.visible = false
		if first_button == null and btn.visible and not btn.disabled:
			first_button = btn
		box.add_child(btn)

	_note = Label.new()
	_note.add_theme_font_size_override("font_size", 13)
	_note.add_theme_color_override("font_color", Color(UITheme.COL_ACCENT_SOFT, 0.75))
	_note.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	add_child(_note)
	_note.position = Vector2(18.0, 690.0)
	_note.text = "PHASE 2 SCAFFOLD · навигация работает; живое меню и экраны — Фазы 3–9"

	if first_button != null:
		first_button.call_deferred("grab_focus")


func _on_action(action: String) -> void:
	AudioManager.play_sfx("button")
	match action:
		"play":
			GameManager.start_new_game()
		"continue":
			if not GameManager.continue_game():
				_flash("Нет сохранений")
		"chapters":
			_flash("CHAPTER SELECT — Фаза 5")
		"gallery":
			_flash("GALLERY — Фаза 9")
		"achievements":
			_flash("ACHIEVEMENTS — Фаза 9")
		"settings":
			_flash("SETTINGS — Фаза 3")
		"credits":
			_flash("CREDITS — Фаза 10")
		"exit":
			get_tree().quit()


func _flash(msg: String) -> void:
	_note.text = msg


func _is_mobile() -> bool:
	return OS.has_feature("android") or OS.has_feature("ios")
