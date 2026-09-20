extends Control
## Слой персонажей (GDD §9.4): владеет спрайтами, знает позиции
## (left/center/right), проксирует команды show/hide/expr.

const CharacterSprite := preload("res://scripts/ui/character_sprite.gd")

var _sprites: Dictionary = {}   # id -> CharacterSprite


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Позиция: "center" (по умолчанию), "left", "right".
func show_character(id: String, expr: String, pos_hint: String = "center", animated: bool = true) -> void:
	var sp: CharacterSprite = _sprites.get(id)
	if sp == null:
		sp = CharacterSprite.new()
		sp.character_id = id
		sp.set_anchors_preset(Control.PRESET_FULL_RECT)
		sp.offset_bottom = -190.0  # спрайт над диалоговым окном
		_sprites[id] = sp
		add_child(sp)
		_apply_position(sp, pos_hint)
		sp.set_expression(expr, false)
		sp.show_on_stage(animated)
	else:
		_apply_position(sp, pos_hint)
		sp.set_expression(expr, animated)
		if not sp.visible:
			sp.show_on_stage(animated)


func _apply_position(sp: CharacterSprite, pos_hint: String) -> void:
	var w := maxf(size.x, 1.0)
	var target_scale := 1.0
	match pos_hint:
		"left":
			sp.position.x = w * 0.08
			target_scale = 0.92
		"right":
			sp.position.x = w * 0.56
			target_scale = 0.92
		_:
			sp.position.x = w * 0.30
			target_scale = 1.0
	# Держим пропорцию по высоте сцены.
	var target_h := size.y * 0.82
	if sp.size.y > 0:
		target_scale = minf(target_scale, target_h / sp.size.y)
	sp.scale = Vector2(target_scale, target_scale)


func hide_character(id: String, animated: bool = true) -> void:
	var sp: CharacterSprite = _sprites.get(id)
	if sp != null and sp.visible:
		sp.hide_from_stage(animated)


func set_expression(id: String, expr: String, animated: bool = true) -> void:
	var sp: CharacterSprite = _sprites.get(id)
	if sp != null:
		sp.set_expression(expr, animated)


func clear_stage(animated: bool = true) -> void:
	for id: String in _sprites.keys():
		hide_character(id, animated)
