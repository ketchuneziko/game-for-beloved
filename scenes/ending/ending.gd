extends Control
## Positive Ending + титры (Фаза 10, GDD §1.10): рассвет, сердечки,
## «THEN IT'S OFFICIAL. / THIS IS OUR BEGINNING.», строки признания из
## about.json, THE END → «OUR STORY — BEGINNING», титры, чёрный экран
## с секретом (ждать 10 секунд — P.S.), затем «мир меню» (глава 8):
## рассветное меню с пунктом «ЕЩЁ РАЗ ♥».

const UITheme := preload("res://scripts/ui/theme_builder.gd")
const FloatingHearts := preload("res://scripts/ui/floating_hearts.gd")

var _label: Label
var _tw: Tween
var _phase := 0
var _can_exit := false
var _headless := false
var _hint: Label


func _ready() -> void:
	theme = UITheme.build()
	_headless = DisplayServer.get_name() == "headless"
	SaveManager.finish_game()
	_build_ui()
	AudioManager.play_music("credits", 2.0)
	_run_sequence()


func _build_ui() -> void:
	# Рассветное небо (пиксельный фон под тёплой вуалью).
	for p in ["res://assets/backgrounds/bg_rooftop_dawn.png", "res://assets/backgrounds/bg_rooftop_dawn.jpg"]:
		if ResourceLoader.exists(p):
			var bgr := TextureRect.new()
			bgr.texture = load(p)
			bgr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			bgr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			bgr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			bgr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			bgr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(bgr)
			break
	var warm := ColorRect.new()
	warm.color = Color(1.0, 0.75, 0.6, 0.18)
	warm.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	warm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(warm)

	var hearts := FloatingHearts.new()
	hearts.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(hearts)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.custom_minimum_size = Vector2(900, 0)
	_label.add_theme_font_size_override("font_size", 30)
	_label.add_theme_color_override("font_color", UITheme.COL_TEXT)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(_label)

	_hint = Label.new()
	_hint.text = LocalizationManager.t("ending.continue_hint", "клик — дальше")
	_hint.add_theme_font_size_override("font_size", 12)
	_hint.add_theme_color_override("font_color", Color(UITheme.COL_TEXT, 0.0))
	_hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_hint.position = Vector2(1100.0, 690.0)
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hint)

	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 1.6)


func _build_about_lines() -> Array:
	var about := GameManager.custom_about()
	var lines: Array = [
		{"t": "THEN IT'S OFFICIAL.", "big": true, "pause": 0.4},
		{"t": "THIS IS OUR BEGINNING.", "big": true, "pause": 0.8},
	]
	for l: Variant in about.get("ending_lines", []):
		if l is Dictionary:
			lines.append({"t": LocalizationManager.field(l), "big": false, "pause": 0.5})
	lines.append({"t": "THE END", "big": true, "pause": 0.4})
	return lines


func _wait(seconds: float) -> void:
	if _headless:
		seconds = 0.05
	await get_tree().create_timer(seconds).timeout


func _show(text: String, big: bool, fade: float = 0.6) -> void:
	if _tw != null and _tw.is_valid():
		_tw.kill()
	_label.text = text
	var display := UITheme.display_font()
	if big and display != null:
		_label.add_theme_font_override("font", display)
	else:
		_label.remove_theme_font_override("font")
	_label.add_theme_font_size_override("font_size", 34 if big else 22)
	_label.add_theme_color_override("font_color", UITheme.COL_ACCENT_SOFT if big else UITheme.COL_TEXT)
	_label.modulate.a = 0.0
	_tw = create_tween()
	_tw.tween_property(_label, "modulate:a", 1.0, fade)


func _hide(fade: float = 0.5) -> void:
	if _tw != null and _tw.is_valid():
		_tw.kill()
	_tw = create_tween()
	_tw.tween_property(_label, "modulate:a", 0.0, fade)
	await _tw.finished


func _run_sequence() -> void:
	# Основная последовательность признания.
	for line: Dictionary in _build_about_lines():
		_show(str(line["t"]), bool(line["big"]))
		await _wait(1.6 if not _headless else 0.06)
		# «THE END» превращаем в «OUR STORY — BEGINNING».
		if str(line["t"]) == "THE END":
			await _wait(1.4)
			await _hide(0.8)
			_show("OUR STORY — BEGINNING", true, 0.9)
			await _wait(2.2)
			await _hide(0.8)
			continue
		await _wait(float(line.get("pause", 0.4)))

	# Титры.
	var about := GameManager.custom_about()
	var credits: Array = [
		"TO ETERNITY AND BEYOND",
		LocalizationManager.t("credits.made_by", "сценарий, код, дизайн — твой автор"),
		LocalizationManager.field(about.get("dedication", {})),
		LocalizationManager.t("credits.engine", "сделано на Godot Engine"),
		LocalizationManager.t("credits.fonts", "шрифты: JetBrains Mono, Press Start 2P — SIL OFL"),
	]
	_phase = 1
	for c: String in credits:
		_show(c, c.begins_with("TO ETERNITY"))
		await _wait(2.0)
	# Пауза-секрет: подожди на чёрном — и увидишь P.S. (GDD «Секреты» #5).
	await _hide(1.0)
	AudioManager.stop_music(2.0)
	_phase = 2
	await _wait(10.0)
	GalleryManager.unlock("secrets", "postscript")
	AudioManager.play_sfx("notification")
	_show(LocalizationManager.t("ending.ps", "P.S. Это не конец. Это самая первая страница."), false, 1.2)
	_can_exit = true
	_hint.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_hint, "modulate:a", 0.5, 1.0)
	await _wait(4.0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("vn_advance"):
		if _phase >= 2 and _can_exit:
			_can_exit = false
			GameManager.goto_menu()
