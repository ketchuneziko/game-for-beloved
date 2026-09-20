extends Control
## Спрайт персонажа (GDD «CHARACTER SPRITES»): плавная смена выражений
## (кроссфейд двух TextureRect), вход/выход сцены, лёгкое «дыхание».
##
## Грейсфолбэк: нет текстуры выражения — берём neutral; нет neutral —
## любую имеющуюся; нет совсем — рисуем «силуэт» (цветная капсула),
## чтобы сцена оставалась читаемой до появления ассетов.

const UITheme := preload("res://scripts/ui/theme_builder.gd")

signal clicked

var character_id := ""
var expression := ""
var _front: TextureRect
var _back: TextureRect
var _silhouette: Control
var _base_scale := 1.0
var _breath_t := 0.0
var _available: Array[String] = []
var _fallback_chosen := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_front = _make_rect()
	_back = _make_rect()
	_silhouette = _make_silhouette()
	_silhouette.visible = false
	_rescan()
	# Лёгкое «дыхание» живости (не анимация позы — только микросдвиг).
	breath()


func _make_rect() -> TextureRect:
	var r := TextureRect.new()
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)
	return r


func _make_silhouette() -> Control:
	var holder := Control.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel := Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = size.x * 0.32 if size.x > 0 else 320.0
	panel.offset_right = -panel.offset_left
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#241a2b")
	sb.set_corner_radius_all(80)
	panel.add_theme_stylebox_override("panel", sb)
	holder.add_child(panel)
	add_child(holder)
	return holder


func _rescan() -> void:
	_available.clear()
	var dir := DirAccess.open("res://assets/characters/%s" % character_id)
	if dir != null:
		for f in dir.get_files():
			if f.ends_with(".png") or f.ends_with(".jpg") or f.ends_with(".webp"):
				_available.append(f.get_basename())
	_available.sort()


func set_character(id: String) -> void:
	character_id = id
	_rescan()


## Смена выражения (кроссфейд ~0.35 c). Неизвестное выражение -> fallback.
func set_expression(expr: String, animated: bool = true) -> void:
	if expr == expression and _front.texture != null:
		return
	expression = expr
	var tex := _texture_for(expr)
	if tex == null:
		_front.texture = null
		_back.texture = null
		_silhouette.visible = true
		return
	_silhouette.visible = false
	if animated:
		_back.texture = tex
		_back.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(_back, "modulate.a", 1.0, 0.35)
		tw.tween_callback(func() -> void:
			_front.texture = tex
			_back.texture = null
		)
	else:
		_front.texture = tex


func _texture_for(expr: String) -> Texture2D:
	if _available.is_empty():
		return null
	var candidates := [expr, "neutral", _available[0]]
	for cand: String in candidates:
		for ext in [".png", ".jpg", ".webp"]:
			var p := "res://assets/characters/%s/%s%s" % [character_id, cand, ext]
			if ResourceLoader.exists(p):
				return load(p)
	return null


func show_on_stage(animated: bool = true) -> void:
	visible = true
	if not animated:
		modulate.a = 1.0
		return
	modulate.a = 0.0
	var start_x := position.x
	position.x = start_x + 26.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.5)
	tw.tween_property(self, "position:x", start_x, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func hide_from_stage(animated: bool = true) -> void:
	if not animated:
		visible = false
		return
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func() -> void: visible = false)


## Микро-дыхание: очень лёгкое, чтобы спрайт не выглядел «мёртвой картинкой».
func breath() -> void:
	_breath_t = 0.0


func _process(delta: float) -> void:
	_breath_t += delta
	if visible:
		var s := _base_scale + 0.006 * sin(_breath_t * 1.1)
		scale = Vector2(s, s)
