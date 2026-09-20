extends RefCounted
## Единая минималистичная тема UI, собранная кодом (GDD §8.6).
## Подключение в сценах: const UITheme := preload("res://scripts/ui/theme_builder.gd")
## (без class_name — чтобы не зависеть от кэша глобальных классов редактора).
##
## Шрифты: JetBrains Mono (основной текст — читаемая кириллица) и
## Press Start 2P (крупные латинские заголовки). Оба — SIL OFL, лежат в
## assets/fonts/. Загружаются двумя путями: обычный load() (если проект
## открывался в редакторе и шрифты импортированы) либо напрямую через
## FontFile.load_dynamic_font() — работает всегда, даже в headless.

const COL_SHADOW := Color("#110d15")
const COL_PANEL := Color("#1c1521")
const COL_PANEL_2 := Color("#241a2b")
const COL_ACCENT := Color("#ff8fbd")
const COL_ACCENT_SOFT := Color("#ffb9d5")
const COL_TEXT := Color("#fff2f6")

const FONT_REGULAR_PATHS := [
	"res://assets/fonts/JetBrainsMono-Regular.ttf",
	"res://assets/fonts/PTMono-Regular.ttf",
]
const FONT_BOLD_PATHS := [
	"res://assets/fonts/JetBrainsMono-Bold.ttf",
	"res://assets/fonts/PTMono-Bold.ttf",
]
const FONT_DISPLAY_PATHS := [
	"res://assets/fonts/PressStart2P-Regular.ttf",
	"res://assets/fonts/PressStart2P-Regular.woff2",
]


static func build() -> Theme:
	var th := Theme.new()

	var regular := font(FONT_REGULAR_PATHS)
	if regular != null:
		th.default_font = regular
	th.default_font_size = 20

	# Label: тихий светлый текст.
	th.set_color("font_color", "Label", COL_TEXT)

	# Button: спокойная панель, розовеет при наведении.
	var bn := StyleBoxFlat.new()
	bn.bg_color = Color(COL_PANEL, 0.55)
	bn.set_corner_radius_all(10)
	bn.set_content_margin_all(10)
	bn.content_margin_left = 22
	bn.content_margin_right = 22
	bn.border_width_bottom = 1
	bn.border_color = Color(COL_ACCENT, 0.22)

	var bh := bn.duplicate() as StyleBoxFlat
	bh.bg_color = Color(COL_PANEL_2, 0.85)
	bh.set_border_width_all(1)
	bh.border_color = Color(COL_ACCENT, 0.65)

	var bp := bn.duplicate() as StyleBoxFlat
	bp.bg_color = Color(COL_SHADOW, 0.85)
	bp.border_color = Color(COL_ACCENT, 0.9)

	var bd := bn.duplicate() as StyleBoxFlat
	bd.bg_color = Color(COL_PANEL, 0.2)

	th.set_stylebox("normal", "Button", bn)
	th.set_stylebox("hover", "Button", bh)
	th.set_stylebox("pressed", "Button", bp)
	th.set_stylebox("disabled", "Button", bd)
	th.set_stylebox("focus", "Button", bh)
	th.set_color("font_color", "Button", COL_TEXT)
	th.set_color("font_hover_color", "Button", COL_ACCENT)
	th.set_color("font_pressed_color", "Button", COL_ACCENT)
	th.set_color("font_focus_color", "Button", COL_ACCENT_SOFT)
	th.set_color("font_disabled_color", "Button", Color(COL_TEXT, 0.3))

	# CheckButton/Slider: акцент при наведении.
	th.set_color("font_hover_color", "CheckButton", COL_ACCENT)

	# PanelContainer: диалоговое окно, панели оверлеев.
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(COL_PANEL, 0.92)
	panel.set_corner_radius_all(14)
	panel.set_content_margin_all(18)
	panel.border_width_top = 1
	panel.border_color = Color(COL_ACCENT, 0.18)
	th.set_stylebox("panel", "PanelContainer", panel)

	# RichTextLabel (реплики, история).
	th.set_color("default_color", "RichTextLabel", COL_TEXT)

	# HSlider: розовый «ползунок».
	th.set_stylebox("grabber_area", "HSlider", _flat_sb(Color(COL_ACCENT, 0.55), 3))
	th.set_stylebox("grabber_area_highlight", "HSlider", _flat_sb(COL_ACCENT, 3))

	return th


static func _flat_sb(color: Color, radius: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	return sb


## Первый найденный шрифт из списка путей.
static func font(paths: Array) -> FontFile:
	for p: String in paths:
		var f := _load_font_file(p)
		if f != null:
			return f
	return null


static func display_font() -> FontFile:
	return font(FONT_DISPLAY_PATHS)


static func bold_font() -> FontFile:
	return font(FONT_BOLD_PATHS)


static func _load_font_file(path: String) -> FontFile:
	if not FileAccess.file_exists(path):
		return null
	if ResourceLoader.exists(path):
		var res := load(path)
		if res is FontFile:
			return res
	# Импорта редактора ещё не было (или проект только склонирован) —
	# грузим шрифт напрямую в рантайме.
	var f := FontFile.new()
	if f.load_dynamic_font(path) == OK:
		f.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
		f.hinting = TextServer.HINTING_LIGHT
		return f
	return null
