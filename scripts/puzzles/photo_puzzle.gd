extends Control
## Мини-игра «Фото-пазл» (GDD §6 #2): сетка 3×3, обмен плиток (без
## «пустого слота» — перемешивание всегда решаемо). Источник:
## assets/photos/puzzle_photo.jpg (твоё фото), иначе — плейсхолдер-фон.
## Кнопка ПОДСКАЗКА на 1.2 сек показывает оригинал.

signal solved

const UITheme := preload("res://scripts/ui/theme_builder.gd")

const GRID := 3
const TILE := 132

var _texture: Texture2D
var _tiles: Array = []          # индекс плитки -> позиция в сетке (текстуры)
var _selected := -1
var _buttons: Array[Button] = []
var _hint_button: Button


func _ready() -> void:
	theme = UITheme.build()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_texture = _load_texture()
	if _texture == null:
		push_warning("PhotoPuzzle: нет картинки — пропускаю")
		solved.emit()
		queue_free()
		return
	_build_ui()
	_shuffle()
	if DisplayServer.get_name() == "headless":
		await get_tree().create_timer(0.2).timeout
		_solve_directly()


func _load_texture() -> Texture2D:
	for p in [
		"res://assets/photos/puzzle_photo.jpg",
		"res://assets/photos/puzzle_photo.png",
		"res://assets/backgrounds/bg_dome_stars.png",
		"res://assets/backgrounds/bg_dome_stars.jpg",
	]:
		if ResourceLoader.exists(p):
			return load(p)
	return null


func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.015, 0.035, 0.9)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 360.0
	panel.offset_right = -360.0
	panel.offset_top = 60.0
	panel.offset_bottom = -60.0
	add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)

	var title := Label.new()
	title.text = LocalizationManager.t("photop.title", "СОБЕРИ ФОТОГРАФИЮ")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", UITheme.COL_ACCENT_SOFT)
	v.add_child(title)

	var sub := Label.new()
	sub.text = LocalizationManager.t("photop.sub", "Нажми две плитки — они поменяются местами.")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 13)
	sub.add_theme_color_override("font_color", Color(UITheme.COL_TEXT, 0.6))
	v.add_child(sub)

	var grid := GridContainer.new()
	grid.columns = GRID
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(grid)

	var tex_size := _texture.get_size()
	for i in GRID * GRID:
		var b := Button.new()
		b.custom_minimum_size = Vector2(TILE, TILE)
		b.icon = _tile_texture(i, tex_size)
		b.expand_icon = true
		b.pressed.connect(_on_tile.bind(i))
		grid.add_child(b)
		_buttons.append(b)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	v.add_child(row)
	_hint_button = Button.new()
	_hint_button.text = LocalizationManager.t("photop.hint", "ПОДСКАЗКА")
	_hint_button.custom_minimum_size = Vector2(150, 40)
	_hint_button.pressed.connect(_show_original)
	row.add_child(_hint_button)


## Атлас-плитка i (слева направо, сверху вниз).
func _tile_texture(i: int, tex_size: Vector2) -> AtlasTexture:
	var col := i % GRID
	var row := i / GRID
	var at := AtlasTexture.new()
	at.atlas = _texture
	at.region = Rect2(Vector2(col, row) * tex_size / float(GRID), tex_size / float(GRID))
	return at


func _shuffle() -> void:
	_tiles = range(GRID * GRID)
	_tiles.shuffle()
	while _is_solved():
		_tiles.shuffle()
	_apply()


func _is_solved() -> bool:
	for i in _tiles.size():
		if int(_tiles[i]) != i:
			return false
	return true


func _apply() -> void:
	for slot in _buttons.size():
		_buttons[slot].icon = _tile_texture(int(_tiles[slot]), _texture.get_size())
		_buttons[slot].modulate = Color.WHITE


func _on_tile(slot: int) -> void:
	if _selected < 0:
		_selected = slot
		_buttons[slot].modulate = Color(1.5, 1.2, 1.4)
		AudioManager.play_sfx("click")
		return
	if slot == _selected:
		_selected = -1
		_buttons[slot].modulate = Color.WHITE
		return
	# Обмен.
	var tmp: Variant = _tiles[slot]
	_tiles[slot] = _tiles[_selected]
	_tiles[_selected] = tmp
	_selected = -1
	_apply()
	AudioManager.play_sfx("page")
	if _is_solved():
		_finish()


func _show_original() -> void:
	AudioManager.play_sfx("click")
	_hint_button.disabled = true
	for b: Button in _buttons:
		b.disabled = true
	for slot in _buttons.size():
		_buttons[slot].icon = _tile_texture(slot, _texture.get_size())
	var t := get_tree().create_timer(1.2)
	t.timeout.connect(func() -> void:
		_apply()
		for b: Button in _buttons:
			b.disabled = false
		_hint_button.disabled = false
	)


func _finish() -> void:
	AudioManager.play_sfx("puzzle_solved")
	var t := get_tree().create_timer(0.05 if DisplayServer.get_name() == "headless" else 1.5)
	t.timeout.connect(func() -> void:
		solved.emit()
		queue_free()
	)


func _solve_directly() -> void:
	_tiles = range(GRID * GRID)
	_apply()
	_finish()
