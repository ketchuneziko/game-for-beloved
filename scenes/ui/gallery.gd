extends Control
## Галерея (Фаза 9, GDD §8.1): PHOTOS / MEMORIES / LETTERS / SECRETS.
## Содержимое — из данных: memories.json, letters.json, накопленные
## unlock_* из глав. Секреты — известный список с подсказками («???»).
## Открытая фотография открывается на весь экран (рамка, подпись с оборота).

const UITheme := preload("res://scripts/ui/theme_builder.gd")

## Известные секреты (id -> подписи). Незакрытые показываются как «???».
const SECRET_INFO := {
	"secret_photo": {
		"title": {"ru": "Чужое лето", "en": "Someone else's summer"},
		"desc": {"ru": "Фотография, которая не из нашей коробки. Всем нужен лишний кусочек лета.", "en": "A photo that isn't from our box. Everyone needs a spare piece of summer."},
	},
	"menu_code": {
		"title": {"ru": "Слово в меню", "en": "The word in the menu"},
		"desc": {"ru": "Иногда стоит произнести её имя там, где никто не спрашивал.", "en": "Sometimes it's worth saying her name where nobody asked."},
	},
	"silence": {
		"title": {"ru": "Сцена тишины", "en": "The silence scene"},
		"desc": {"ru": "Под дождём иногда лучше просто ничего не нажимать.", "en": "Under the rain, sometimes it's better not to press anything at all."},
	},
	"postscript": {
		"title": {"ru": "P.S.", "en": "P.S."},
		"desc": {"ru": "Дождись конца титров. И подожди ещё немного.", "en": "Wait for the credits to end. Then wait a little more."},
	},
}

var _tab := "photos"
var _content_scroll: ScrollContainer
var _content: VBoxContainer
var _viewer: Control


func _ready() -> void:
	theme = UITheme.build()
	_build_ui()
	_show_tab("photos")


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = UITheme.COL_SHADOW
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 60.0
	v.offset_right = -60.0
	v.offset_top = 20.0
	v.offset_bottom = -20.0
	v.add_theme_constant_override("separation", 10)
	add_child(v)

	var head := HBoxContainer.new()
	v.add_child(head)
	var title := Label.new()
	title.text = LocalizationManager.t("gallery.title", "ГАЛЕРЕЯ")
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", UITheme.COL_ACCENT_SOFT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var back := Button.new()
	back.text = LocalizationManager.t("settings.back", "НАЗАД")
	back.custom_minimum_size = Vector2(140, 40)
	back.pressed.connect(_back)
	head.add_child(back)

	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 8)
	v.add_child(tabs)
	for pair: Array in [["photos", "gallery.photos", "ФОТО"], ["memories", "gallery.memories", "ВОСПОМИНАНИЯ"], ["letters", "gallery.letters", "ПИСЬМА"], ["secrets", "gallery.secrets", "СЕКРЕТЫ"]]:
		var b := Button.new()
		b.text = LocalizationManager.t(str(pair[1]), str(pair[2]))
		b.custom_minimum_size = Vector2(190, 38)
		b.pressed.connect(_show_tab.bind(str(pair[0])))
		tabs.add_child(b)

	_content_scroll = ScrollContainer.new()
	_content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(_content_scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 10)
	_content_scroll.add_child(_content)


func _show_tab(tab: String) -> void:
	_tab = tab
	AudioManager.play_sfx("click")
	for c in _content.get_children():
		c.queue_free()
	match tab:
		"photos":
			_build_photos()
		"memories":
			_build_memories()
		"letters":
			_build_letters()
		"secrets":
			_build_secrets()


func _row(bg_alpha: float = 0.5) -> Dictionary:
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(UITheme.COL_PANEL, bg_alpha)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(10)
	sb.content_margin_left = 14.0
	sb.content_margin_right = 14.0
	panel.add_theme_stylebox_override("panel", sb)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	panel.add_child(h)
	_content.add_child(panel)
	return {"panel": panel, "box": h}


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _build_photos() -> void:
	var mems: Array = []
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/memories/memories.json")) if FileAccess.file_exists("res://data/memories/memories.json") else null
	if raw is Dictionary:
		mems = (raw as Dictionary).get("memories", [])
	for m: Variant in mems:
		if not (m is Dictionary):
			continue
		var id := str(m.get("id", ""))
		var unlocked := GalleryManager.is_unlocked("memories", id)
		var r := _row()
		var prev := _photo_tile(_photo_path_for(id), unlocked, Vector2(160, 100))
		r["box"].add_child(prev)
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 2)
		r["box"].add_child(col)
		if unlocked:
			col.add_child(_label(str(m.get("date", "")), 12, Color(UITheme.COL_ACCENT_SOFT, 0.8)))
			col.add_child(_label(LocalizationManager.field(m.get("caption", {})), 16, UITheme.COL_TEXT))
			prev.gui_input.connect(_on_tile_click.bind(_photo_path_for(id), m))
			prev.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		else:
			col.add_child(_label("—", 12, Color(UITheme.COL_TEXT, 0.3)))
			col.add_child(_label(LocalizationManager.t("gallery.locked", "ещё не найдено"), 15, Color(UITheme.COL_TEXT, 0.4)))


func _photo_path_for(id: String) -> String:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/memories/memories.json")) if FileAccess.file_exists("res://data/memories/memories.json") else null
	if raw is Dictionary:
		for m: Variant in (raw as Dictionary).get("memories", []):
			if m is Dictionary and str(m.get("id", "")) == id:
				return str(m.get("photo", ""))
	return ""


func _photo_tile(path: String, unlocked: bool, tile_size: Vector2) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = tile_size
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if unlocked and path != "" and FileAccess.file_exists(path):
		var t := TextureRect.new()
		t.texture = load(path)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		t.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		t.mouse_filter = Control.MOUSE_FILTER_STOP
		holder.add_child(t)
	else:
		var c := ColorRect.new()
		c.color = Color(UITheme.COL_PANEL_2, 0.7)
		c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		holder.add_child(c)
		var q := Label.new()
		q.text = "✧"
		q.add_theme_font_size_override("font_size", 28)
		q.add_theme_color_override("font_color", Color(UITheme.COL_ACCENT_SOFT, 0.4))
		q.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		q.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		q.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(q)
	return holder


func _on_tile_click(event: InputEvent, path: String, mem: Dictionary) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_open_photo(path, LocalizationManager.field(mem.get("caption", {})), str(mem.get("date", "")))


func _open_photo(path: String, caption: String, date: String) -> void:
	if _viewer != null:
		return
	AudioManager.play_sfx("photo")
	var GalleryViewer: GDScript = load("res://scripts/ui/photo_viewer.gd")
	_viewer = GalleryViewer.new()
	_ui_add(_viewer, path, caption, date)


func _ui_add(viewer: Control, path: String, caption: String, date: String) -> void:
	add_child(viewer)
	viewer.setup(path, caption, date)
	viewer.closed.connect(func() -> void: _viewer = null)


func _build_memories() -> void:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/memories/memories.json")) if FileAccess.file_exists("res://data/memories/memories.json") else null
	if not (raw is Dictionary):
		return
	for m: Variant in (raw as Dictionary).get("memories", []):
		if not (m is Dictionary):
			continue
		var id := str(m.get("id", ""))
		var unlocked := GalleryManager.is_unlocked("memories", id)
		var r := _row()
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 2)
		r["box"].add_child(col)
		if unlocked:
			col.add_child(_label(str(m.get("date", "")), 12, Color(UITheme.COL_ACCENT_SOFT, 0.8)))
			col.add_child(_label(LocalizationManager.field(m.get("caption", {})), 16, UITheme.COL_TEXT))
		else:
			col.add_child(_label("???", 16, Color(UITheme.COL_TEXT, 0.4)))


func _build_letters() -> void:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/custom/letters.json")) if FileAccess.file_exists("res://data/custom/letters.json") else null
	if not (raw is Dictionary):
		return
	var letters: Array = (raw as Dictionary).get("ch4_letters", [])
	var secret_letter: Variant = (raw as Dictionary).get("secret_letter", null)
	if secret_letter is Dictionary:
		letters.append(secret_letter)
	for l: Variant in letters:
		if not (l is Dictionary):
			continue
		var id := str(l.get("id", ""))
		var unlocked: bool = GalleryManager.is_unlocked("secrets", "menu_code") if id == "letter_secret" else GalleryManager.is_unlocked("letters", id)
		var r := _row()
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 4)
		r["box"].add_child(col)
		if unlocked:
			col.add_child(_label(LocalizationManager.field(l.get("title", {})), 14, UITheme.COL_ACCENT_SOFT))
			col.add_child(_label(LocalizationManager.field(l.get("text", {})), 15, UITheme.COL_TEXT))
		else:
			col.add_child(_label(LocalizationManager.t("gallery.sealed", "запечатано"), 14, Color(UITheme.COL_TEXT, 0.35)))


func _build_secrets() -> void:
	var found := 0
	for id: String in SECRET_INFO.keys():
		var info: Dictionary = SECRET_INFO[id]
		var unlocked := GalleryManager.is_unlocked("secrets", id)
		if unlocked:
			found += 1
		var r := _row()
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 2)
		r["box"].add_child(col)
		if unlocked:
			col.add_child(_label(LocalizationManager.field(info.get("title", {})), 15, UITheme.COL_ACCENT_SOFT))
			col.add_child(_label(LocalizationManager.field(info.get("desc", {})), 14, UITheme.COL_TEXT))
		else:
			col.add_child(_label("???", 15, Color(UITheme.COL_TEXT, 0.4)))
			col.add_child(_label(LocalizationManager.field(info.get("hint", {"ru": "откроется, если искать", "en": "unlocks if you look for it"})), 12, Color(UITheme.COL_TEXT, 0.25)))
	var counter := _label("%d/%d" % [found, SECRET_INFO.size()], 13, Color(UITheme.COL_ACCENT_SOFT, 0.7))
	_content.add_child(counter)


func _back() -> void:
	AudioManager.play_sfx("click")
	GameManager.change_scene_faded(GameManager.SCENE_MENU)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_pause"):
		if _viewer != null and is_instance_valid(_viewer):
			_viewer.close()
		else:
			_back()
