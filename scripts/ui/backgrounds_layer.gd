extends Control
## Слой фонов (GDD §9.4): смена фонов с переходами fade / dissolve /
## slide / blur / white_flash (белая и «мягкая» — по настройке доступности).
## Живёт под персонажами; на смене — tween'ы, ничего не рвёт кадр.
## Цветная заглушка (когда файла фона нет) хранится явно в _placeholder,
## чтобы не путаться с транзитными вспышками.

var _current: Control
var _incoming: Control
var _placeholder: Control
var _current_id := ""
var _busy := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_current = _make_rect()
	_incoming = _make_rect()


func _make_rect() -> TextureRect:
	var r := TextureRect.new()
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.modulate.a = 0.0
	add_child(r)
	return r


func current_id() -> String:
	return _current_id


## Основной вход: id фона (assets/backgrounds/<id>.jpg) + вид перехода.
func set_background(id: String, kind: String = "fade", duration: float = 1.1) -> void:
	if id == _current_id:
		return
	_current_id = id
	_placeholder = null
	var tex := _load_texture(id)
	if tex == null:
		# Файла нет (плейсхолдер-фаза) — глухой цвет, чтобы сцена не «дыралась».
		var c := ColorRect.new()
		c.color = Color("#181226")
		c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_placeholder = c
		add_child(c)
		_swap_to(c, kind, duration)
		return
	(_incoming as TextureRect).texture = tex
	_swap_to(_incoming, kind, duration)


func _load_texture(id: String) -> Texture2D:
	for ext in [".jpg", ".png", ".webp"]:
		var p := "res://assets/backgrounds/%s%s" % [id, ext]
		if ResourceLoader.exists(p):
			return load(p)
	return null


## Универсальная «подмена»: node — уже готовый визуал поверх текущего.
func _swap_to(node: Control, kind: String, duration: float) -> void:
	if _busy:
		# Предыдущий переход не успел — мгновенно завершаем его.
		_finish_pending()
	_busy = true
	var soft: bool = SettingsManager.soft_flashes
	var d := maxf(duration, 0.05)

	match kind:
		"dissolve":
			node.modulate.a = 0.0
			var tw := create_tween()
			tw.tween_property(node, "modulate:a", 1.0, d)
			tw.tween_callback(_finish_pending)
		"slide":
			node.modulate.a = 1.0
			var w := maxf(size.x, 1.0)
			node.position = Vector2(w, 0.0)
			var tw2 := create_tween()
			tw2.set_parallel(true)
			tw2.tween_property(node, "position:x", 0.0, d).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			if _current != null and is_instance_valid(_current):
				tw2.tween_property(_current, "position:x", -w * 0.35, d).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tw2.chain().tween_callback(_finish_pending)
		"blur":
			# Мягкое «расфокусное» появление: рост яркости+масштаб вместо
			# тяжёлого шейдера (gl_compatibility — бережём слабые устройства).
			node.modulate.a = 0.0
			node.scale = Vector2(1.06, 1.06)
			node.pivot_offset = size * 0.5
			var tw3 := create_tween()
			tw3.set_parallel(true)
			tw3.tween_property(node, "modulate:a", 1.0, d)
			tw3.tween_property(node, "scale", Vector2.ONE, d).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tw3.chain().tween_callback(_finish_pending)
		"white_flash":
			var flash := ColorRect.new()
			flash.color = Color(1.0, 0.97, 0.99) if not soft else Color(0.95, 0.9, 0.95)
			flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(flash)
			node.modulate.a = 1.0
			flash.modulate.a = 0.0
			var tw4 := create_tween()
			tw4.tween_property(flash, "modulate:a", 1.0, d * 0.35)
			tw4.tween_callback(func() -> void: _promote(node))
			tw4.tween_property(flash, "modulate:a", 0.0, d * 0.65)
			tw4.tween_callback(func() -> void:
				flash.queue_free()
				# Новый фон уже «продвинут» выше — просто открываем слою дорогу.
				_busy = false
			)
			return
		_:
			# fade — по умолчанию.
			node.modulate.a = 0.0
			var tw5 := create_tween()
			tw5.tween_property(node, "modulate:a", 1.0, d)
			tw5.tween_callback(_finish_pending)


## Сделать node текущим фоном, убрать прежний, сбросить трансформации.
func _promote(node: Control) -> void:
	if _current != null and is_instance_valid(_current) and _current != node:
		_current.queue_free()
	_current = node
	_incoming = _make_rect()
	if is_instance_valid(_current):
		_current.position = Vector2.ZERO
		_current.scale = Vector2.ONE


## Завершить переход: продвинуть заглушку (если это она), отпустить слой.
func _finish_pending() -> void:
	if _placeholder != null and is_instance_valid(_placeholder):
		_promote(_placeholder)
		_placeholder = null
	_busy = false


## Мгновенный чёрный фон (конец главы, финал).
func to_black(duration: float = 0.8) -> void:
	var c := ColorRect.new()
	c.color = Color("#060409")
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.modulate.a = 0.0
	add_child(c)
	_placeholder = null
	var tw := create_tween()
	tw.tween_property(c, "modulate:a", 1.0, maxf(duration, 0.05))
	tw.tween_callback(func() -> void:
		if _current != null and is_instance_valid(_current):
			_current.queue_free()
		_current = c
		_incoming = _make_rect()
		_current_id = "black"
	)
