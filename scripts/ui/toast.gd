extends Control
## Деликатный тост-нотификатор (GDD §8.4): плашка сверху для достижений,
## найденных фрагментов и системных сообщений. Мягкий колокольчик —
## решает вызывающий (AchievementManager уже умеет).

const UITheme := preload("res://scripts/ui/theme_builder.gd")

var _panel: PanelContainer
var _label: Label
var _tw: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_TOP_WIDE)
	offset_top = 18.0
	offset_bottom = 74.0
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(UITheme.COL_PANEL_2, 0.94)
	sb.set_corner_radius_all(12)
	sb.set_content_margin_all(10)
	sb.content_margin_left = 20.0
	sb.content_margin_right = 20.0
	sb.border_width_top = 1
	sb.border_color = Color(UITheme.COL_ACCENT, 0.4)
	_panel.add_theme_stylebox_override("panel", sb)
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 15)
	_label.add_theme_color_override("font_color", UITheme.COL_ACCENT_SOFT)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_label)
	add_child(_panel)
	_panel.visible = false
	modulate.a = 0.0


func show_toast(text: String, hold: float = 2.2) -> void:
	_label.text = text
	_panel.visible = true
	_panel.reset_size()
	await get_tree().process_frame
	# Центрируем плашку по фактической ширине.
	_panel.position.x = (size.x - _panel.size.x) * 0.5
	if _tw != null and _tw.is_valid():
		_tw.kill()
	_tw = create_tween()
	_tw.tween_property(self, "modulate:a", 1.0, 0.25)
	_tw.tween_interval(hold)
	_tw.tween_property(self, "modulate:a", 0.0, 0.5)
	_tw.tween_callback(func() -> void: _panel.visible = false)
