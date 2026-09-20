extends Control
## Редкие сердечки, всплывающие над меню (GDD §8.2: частицы-сердца).
## Учитывается настройка доступности «Частицы»: выключена — не спавнимся.

const UITheme := preload("res://scripts/ui/theme_builder.gd")

const MAX_HEARTS := 6

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rng.randomize()
	SettingsManager.settings_changed.connect(_apply_toggle)
	_apply_toggle()
	_schedule()


func _apply_toggle() -> void:
	visible = SettingsManager.particles
	if not visible:
		for c in get_children():
			c.queue_free()


func _schedule() -> void:
	var t := get_tree().create_timer(_rng.randf_range(2.6, 6.5))
	t.timeout.connect(_tick)


func _tick() -> void:
	if not is_inside_tree():
		return
	if visible and get_child_count() < MAX_HEARTS:
		_spawn_one()
	_schedule()


func _spawn_one() -> void:
	var l := Label.new()
	l.text = "♥"
	l.add_theme_font_size_override("font_size", _rng.randi_range(14, 26))
	l.add_theme_color_override("font_color", Color(UITheme.COL_ACCENT_SOFT, _rng.randf_range(0.22, 0.45)))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var start_x := _rng.randf_range(0.06, 0.94) * size.x
	l.position = Vector2(start_x, size.y + 30.0)
	add_child(l)

	var dur := _rng.randf_range(7.0, 11.0)
	var tw := l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", -40.0, dur)
	tw.tween_property(l, "position:x", start_x + _rng.randf_range(-70.0, 70.0), dur) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(l, "modulate:a", 0.0, dur) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(l.queue_free)
