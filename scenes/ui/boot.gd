extends Control
## Boot — короткий шёпот перед меню («for M.»), затем главное меню.
## Фаза 2: минимальная версия. Полноценный BOOT-экран с логотипом
## и плавным переходом — вместе с Фазой 3.

const UITheme := preload("res://scripts/ui/theme_builder.gd")

var _done := false


func _ready() -> void:
	theme = UITheme.build()

	var bg := ColorRect.new()
	bg.color = UITheme.COL_SHADOW
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var label := Label.new()
	label.text = "for M."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", UITheme.COL_ACCENT)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)

	label.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(label, "modulate:a", 1.0, 0.7)
	tw.tween_interval(0.8)
	tw.tween_property(label, "modulate:a", 0.0, 0.6)
	tw.tween_callback(_to_menu)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("vn_advance") or event.is_action_pressed("ui_pause"):
		_to_menu()


func _to_menu() -> void:
	if _done:
		return
	_done = true
	GameManager.change_scene_faded(GameManager.SCENE_MENU, 0.7, 0.9)
