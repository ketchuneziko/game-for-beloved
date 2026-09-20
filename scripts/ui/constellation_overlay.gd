extends Control
## «Созвездие имени» (Глава 7): звёзды выстраиваются в слово буква за
## буквой, между ними прочерчиваются тонкие линии. Не интерактивно
## (клик только ускоряет), само исчезает. Слово — из шага или about.json.

signal done

const UITheme := preload("res://scripts/ui/theme_builder.gd")

var word := ""            # задаётся из главы
var _points: Array = []   # {pos, phase}
var _links: Array = []    # [i, j]
var _letters_shown := 0
var _t := 0.0
var _alive := true
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	theme = UITheme.build()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if word == "":
		word = str(LocalizationManager.field(GameManager.custom_about().get("her_name", {"ru": "МАРИЯ"}))).to_upper()
	_rng.randomize()
	_build_constellation()
	var hold := 0.05 if DisplayServer.get_name() == "headless" else 4.6
	var t := get_tree().create_timer(hold)
	t.timeout.connect(func() -> void:
		_alive = false
		done.emit()
		queue_free()
	)


## Для каждой буквы — «кластер» из 4–6 звёзд в форме буквы (грубая сетка
## 3×5, точки берём из примитивного пиксельного шрифта 3×5).
func _build_constellation() -> void:
	var glyphs := {
		"А": ["010", "101", "111", "101", "101"],
		"Б": ["110", "100", "110", "101", "110"],
		"В": ["110", "101", "110", "101", "110"],
		"Г": ["111", "100", "100", "100", "100"],
		"Д": ["011", "101", "101", "101", "111"],
		"Е": ["111", "100", "110", "100", "111"],
		"Ж": ["101", "101", "111", "101", "101"],
		"З": ["111", "001", "010", "100", "111"],
		"И": ["101", "101", "101", "111", "101"],
		"Й": ["101", "111", "101", "111", "101"],
		"К": ["101", "101", "110", "101", "101"],
		"Л": ["011", "101", "101", "101", "101"],
		"М": ["101", "111", "111", "101", "101"],
		"Н": ["101", "101", "111", "101", "101"],
		"О": ["010", "101", "101", "101", "010"],
		"П": ["111", "101", "101", "101", "101"],
		"Р": ["110", "101", "110", "100", "100"],
		"С": ["011", "100", "100", "100", "011"],
		"Т": ["111", "010", "010", "010", "010"],
		"У": ["101", "101", "111", "001", "110"],
		"Ф": ["010", "111", "111", "010", "010"],
		"Х": ["101", "101", "010", "101", "101"],
		"Ц": ["101", "101", "101", "111", "011"],
		"Ч": ["101", "101", "011", "001", "001"],
		"Ш": ["101", "101", "101", "101", "111"],
		"Щ": ["101", "101", "101", "111", "111"],
		"Ъ": ["110", "010", "110", "101", "110"],
		"Ы": ["101", "101", "111", "101", "101"],
		"Ь": ["100", "100", "110", "101", "110"],
		"Э": ["011", "001", "111", "001", "011"],
		"Ю": ["101", "110", "111", "110", "101"],
		"Я": ["011", "101", "011", "010", "010"],
		" ": ["000", "000", "000", "000", "000"],
	}
	var letters := word.replace("Ё", "Е")
	var letter_w := 120.0
	var total_w := letters.length() * letter_w
	var x0 := (1280.0 - total_w) * 0.5 + letter_w * 0.5
	var y0 := 300.0
	var prev_centers: Array = []
	for li in letters.length():
		var g: Array = glyphs.get(letters[li], glyphs[" "])
		var cx := x0 + li * letter_w
		var center_idx := -1
		var pts: Array = []
		for row in 5:
			for col in 3:
				if str(g[row][col]) == "1":
					var p := Vector2(cx + (col - 1) * 16.0 + _rng.randf_range(-4, 4), y0 + row * 18.0 + _rng.randf_range(-4, 4))
					pts.append({"pos": p, "phase": _rng.randf() * TAU, "born": _points.size()})
					_points.append(pts[pts.size() - 1])
					if row == 2 and col == 1:
						center_idx = _points.size() - 1
		if center_idx >= 0:
			prev_centers.append(center_idx)
	# Линии между центрами соседних букв.
	for i in range(prev_centers.size() - 1):
		_links.append([int(prev_centers[i]), int(prev_centers[i + 1])])
	# Буквы проявляются по очереди.
	var t := get_tree().create_timer(0.05 if DisplayServer.get_name() == "headless" else 0.01)
	t.timeout.connect(_reveal_letters)


func _reveal_letters() -> void:
	var per_letter := 5
	if _letters_shown * per_letter < _points.size():
		_letters_shown += 1
		var delay := get_tree().create_timer(0.05 if DisplayServer.get_name() == "headless" else 0.55)
		delay.timeout.connect(_reveal_letters)


func _visible_points() -> int:
	return mini(_letters_shown * 5, _points.size())


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var limit := _visible_points()
	# Линии — только между уже проявленными точками.
	for l: Array in _links:
		if l[0] < limit and l[1] < limit:
			draw_line(_points[l[0]]["pos"], _points[l[1]]["pos"], Color(UITheme.COL_ACCENT, 0.22), 1.0)
	for i in limit:
		var p: Dictionary = _points[i]
		var tw: float = 0.7 + 0.3 * sin(_t * 2.0 + float(p["phase"]))
		draw_circle(p["pos"], 2.4 * tw, Color(UITheme.COL_TEXT, 0.95 * tw))
		draw_circle(p["pos"], 5.5, Color(UITheme.COL_ACCENT_SOFT, 0.10 * tw))
