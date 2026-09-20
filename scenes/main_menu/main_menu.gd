extends Control
## Главное меню (Фаза 3, GDD §8.2): живой фон — дрейфующие и падающие
## звёзды, редкие сердечки; название «дышит» свечением; при PLAY экран
## плавно затемняется. После завершения игры — рассветная палитра и
## пункт «ЕЩЁ РАЗ ♥». Личные строки (название, посвящение) — из
## data/custom/about.json.

const UITheme := preload("res://scripts/ui/theme_builder.gd")
const Starfield := preload("res://scripts/ui/starfield.gd")
const FloatingHearts := preload("res://scripts/ui/floating_hearts.gd")

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
var _title_glow: Label
var _title: Label
var _time := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	theme = UITheme.build()
	_build_background()
	_build_ui()
	AudioManager.play_music("menu")


func _finished() -> bool:
	return bool(SaveManager.progress.get("finished", false))


func _build_background() -> void:
	# Градиентное небо: ночное — или рассветное после финала.
	var grad := Gradient.new()
	if _finished():
		grad.colors = PackedColorArray([Color("#3b2547"), Color("#7a4a58"), Color("#c98a6a")])
		grad.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	else:
		grad.colors = PackedColorArray([Color("#0b0812"), Color("#110d15"), Color("#241a2b")])
		grad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0.35, 0.0)
	gt.fill_to = Vector2(0.65, 1.0)
	var bg := TextureRect.new()
	bg.texture = gt
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var stars := Starfield.new()
	stars.warm = _finished()
	stars.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(stars)

	var hearts := FloatingHearts.new()
	hearts.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(hearts)


func _build_ui() -> void:
	var about := GameManager.custom_about()

	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 6)
	add_child(column)

	# --- название со свечением (два слоя в одном «стеке») ---
	var title_stack := Control.new()
	title_stack.custom_minimum_size = Vector2(0, 96)
	title_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(title_stack)

	var display := UITheme.display_font()
	var title_text := LocalizationManager.field(about.get("title", "TO ETERNITY AND BEYOND"))

	_title_glow = Label.new()
	_title_glow.text = title_text
	if display != null:
		_title_glow.add_theme_font_override("font", display)
	_title_glow.add_theme_font_size_override("font_size", 34)
	_title_glow.add_theme_color_override("font_color", UITheme.COL_ACCENT)
	_title_glow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_glow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_title_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_stack.add_child(_title_glow)

	_title = Label.new()
	_title.text = title_text
	if display != null:
		_title.add_theme_font_override("font", display)
	_title.add_theme_font_size_override("font_size", 28)
	_title.add_theme_color_override("font_color", UITheme.COL_ACCENT_SOFT)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_stack.add_child(_title)

	var subtitle := Label.new()
	subtitle.text = LocalizationManager.field(about.get("subtitle", {"ru": "ИГРА, СДЕЛАННАЯ ДЛЯ МАРИИ"}))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color(UITheme.COL_TEXT, 0.5))
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 30)
	column.add_child(spacer)

	# --- пункты меню ---
	var has_progress: bool = SaveManager.has_save("auto") or SaveManager.has_save("quick")
	var first_button: Button = null
	for action: Array in MENU_ACTIONS:
		var id := str(action[0])
		if id == "exit" and _is_mobile():
			continue
		var btn := Button.new()
		btn.text = LocalizationManager.t(str(action[1]))
		btn.custom_minimum_size = Vector2(330, 42)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.pressed.connect(_on_action.bind(id))
		if id == "continue" and not has_progress:
			btn.disabled = true
		if first_button == null and not btn.disabled:
			first_button = btn
		column.add_child(btn)

	# После финала — особый пункт (GDD §8.2).
	if _finished():
		var again := Button.new()
		again.text = LocalizationManager.t("menu.again", "ЕЩЁ РАЗ ♥")
		again.custom_minimum_size = Vector2(330, 42)
		again.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		again.pressed.connect(_on_action.bind("again"))
		if first_button == null:
			first_button = again
		column.add_child(again)

	# --- подвал: посвящение и статус ---
	var dedication := Label.new()
	dedication.text = LocalizationManager.field(about.get("dedication", {}))
	dedication.add_theme_font_size_override("font_size", 12)
	dedication.add_theme_color_override("font_color", Color(UITheme.COL_ACCENT_SOFT, 0.45))
	dedication.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	dedication.position = Vector2(16.0, 688.0)
	dedication.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dedication)

	_note = Label.new()
	_note.add_theme_font_size_override("font_size", 12)
	_note.add_theme_color_override("font_color", Color(UITheme.COL_TEXT, 0.4))
	_note.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_note.position = Vector2(640.0, 688.0)
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_note.size = Vector2(624.0, 24.0)
	_note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_note)

	if first_button != null:
		first_button.call_deferred("grab_focus")


func _process(delta: float) -> void:
	# Дыхание свечения названия.
	_time += delta
	var k := 0.5 + 0.5 * sin(_time * 1.35)
	_title_glow.modulate.a = 0.16 + 0.22 * k
	if _title != null:
		_title.modulate = Color(1.0, 1.0, 1.0, 0.9 + 0.1 * k)


func _on_action(action: String) -> void:
	AudioManager.play_sfx("button")
	match action:
		"play":
			GameManager.start_new_game(true)
		"again":
			AchievementManager.unlock("once_more")
			GameManager.start_new_game(true)
		"continue":
			if not GameManager.continue_game():
				_flash("Сохранений пока нет")
			else:
				GameManager.change_scene_faded(GameManager.SCENE_VN, 0.45, 0.45)
		"chapters":
			_flash("Выбор глав появится в Фазе 5")
		"gallery":
			_flash("Галерея откроется в Фазе 9")
		"achievements":
			_flash("Достижения появятся в Фазе 9")
		"settings":
			GameManager.change_scene_faded(GameManager.SCENE_SETTINGS)
		"credits":
			GameManager.change_scene_faded(GameManager.SCENE_CREDITS)
		"exit":
			get_tree().quit()


func _flash(msg: String) -> void:
	_note.text = msg
	var tw := create_tween()
	tw.tween_property(_note, "modulate:a", 1.0, 0.1)


func _is_mobile() -> bool:
	return OS.has_feature("android") or OS.has_feature("ios")
