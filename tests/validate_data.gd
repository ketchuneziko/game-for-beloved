extends SceneTree
## Валидатор данных игры. Запуск:
##   godot --headless --path . --script tests/validate_data.gd
##
## Проверяет: парсинг всех JSON, схему глав (шаги, персонажи, фоны,
## музыка, фрагменты, ачивки, метки/прыжки), выборы, достижения,
## локали, личные файлы (data/custom), таймкоды песни.
## Код выхода: 0 — всё чисто, 1 — есть ошибки.
## Не зависит от автолоадов — можно гонять на любом этапе.

const KNOWN_STEP_TYPES := [
	"line", "choice", "bg", "music", "sfx", "show", "hide", "expr",
	"transition", "wait", "fragment", "achievement",
	"unlock_photo", "unlock_memory", "unlock_letter", "unlock_secret",
	"puzzle", "minigame", "label", "jump", "if_flag", "chapter_end", "title_card", "set_flag", "song", "ui", "constellation", "final_question",
]
const KNOWN_BG := [
	"black", "bg_planetarium_night", "bg_dome_stars", "bg_rain_window",
	"bg_street_night", "bg_rooftop_dawn", "bg_bedroom_morning", "memory",
]
const KNOWN_MUSIC := [
	"menu", "prologue", "chapter1", "chapter2", "chapter4_piano",
	"chapter6", "memory", "puzzle", "song", "final", "credits",
]
const FRAGMENTS_TOTAL := 7

var errors := 0
var warnings := 0


func _initialize() -> void:
	print("=== Валидация данных: TO ETERNITY AND BEYOND ===")
	_check_core_files()
	var choice_ids := _check_choices()
	var ach_ids := _check_achievements()
	var char_ids := _check_characters()
	_check_chapters(choice_ids, ach_ids, char_ids)
	_check_locales()
	_check_custom()
	if errors == 0:
		print("=== VALIDATION OK (%d предупреждений) ===" % warnings)
		quit(0)
	else:
		print("=== VALIDATION FAILED: %d ошибок, %d предупреждений ===" % [errors, warnings])
		quit(1)


func _err(path: String, msg: String) -> void:
	errors += 1
	print("  [ERR ] %s — %s" % [path, msg])


func _warn(path: String, msg: String) -> void:
	warnings += 1
	print("  [WARN] %s — %s" % [path, msg])


func _load(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		_err(path, "файл не найден")
		return null
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if raw == null:
		_err(path, "JSON не парсится")
		return null
	return raw


func _has_ru(value: Variant) -> bool:
	if value is Dictionary:
		return value.has("ru") and str(value["ru"]) != ""
	if value is String:
		return value != ""
	return false


func _check_core_files() -> void:
	for path in [
		"res://data/characters.json",
		"res://data/choices/choices.json",
		"res://data/memories/memories.json",
		"res://data/achievements/achievements.json",
		"res://data/custom/about.json",
		"res://data/custom/song.json",
		"res://data/custom/letters.json",
		"res://data/locales/ru.json",
		"res://data/locales/en.json",
	]:
		if _load(path) == null:
			continue
	# Воспоминания: базовая схема.
	var mem = _load("res://data/memories/memories.json")
	if mem is Dictionary:
		var list: Array = mem.get("memories", [])
		if list.is_empty():
			_warn("res://data/memories/memories.json", "список воспоминаний пуст")
		var ids := {}
		for m: Variant in list:
			if not (m is Dictionary):
				_err("memories.json", "элемент memories не объект")
				continue
			var id := str(m.get("id", ""))
			if id == "" or ids.has(id):
				_err("memories.json", "пустой или дублирующийся id '%s'" % id)
			ids[id] = true
			if str(m.get("photo", "")) == "":
				_err("memories.json", "%s: нет photo" % id)
			if not _has_ru(m.get("caption", {})):
				_err("memories.json", "%s: caption без ru" % id)


func _check_choices() -> Dictionary:
	var ids := {}
	var data = _load("res://data/choices/choices.json")
	if not (data is Dictionary):
		return ids
	var choices: Dictionary = data.get("choices", {})
	for id: String in choices.keys():
		ids[id] = true
		var c: Dictionary = choices[id]
		var options: Array = c.get("options", [])
		if options.is_empty():
			_err("choices.json", "%s: нет options" % id)
			continue
		var opt_ids := {}
		for o: Variant in options:
			if not (o is Dictionary):
				_err("choices.json", "%s: option не объект" % id)
				continue
			var oid := str(o.get("id", ""))
			if oid == "" or opt_ids.has(oid):
				_err("choices.json", "%s: пустой/дублирующийся option id '%s'" % [id, oid])
			opt_ids[oid] = true
			if not _has_ru(o.get("text", {})):
				_err("choices.json", "%s/%s: text без ru" % [id, oid])
	return ids


func _check_achievements() -> Dictionary:
	var ids := {}
	var data = _load("res://data/achievements/achievements.json")
	if not (data is Dictionary):
		return ids
	var list: Array = data.get("achievements", [])
	if list.size() < 8 or list.size() > 12:
		_warn("achievements.json", "achievements: %d штук (ожидается 8–12)" % list.size())
	for a: Variant in list:
		if not (a is Dictionary):
			_err("achievements.json", "элемент не объект")
			continue
		var id := str(a.get("id", ""))
		if id == "" or ids.has(id):
			_err("achievements.json", "пустой/дублирующийся id '%s'" % id)
		ids[id] = true
		if not _has_ru(a.get("name", {})):
			_err("achievements.json", "%s: name без ru" % id)
		if not _has_ru(a.get("desc", {})):
			_err("achievements.json", "%s: desc без ru" % id)
	return ids


func _check_characters() -> Dictionary:
	var ids := {}
	var data = _load("res://data/characters.json")
	if not (data is Dictionary):
		return ids
	var chars: Dictionary = data.get("characters", {})
	for id: String in chars.keys():
		ids[id] = true
		var c: Dictionary = chars[id]
		if not _has_ru(c.get("name", {})) and not bool(c.get("plate_hidden", false)):
			_err("characters.json", "%s: нет имени и нет plate_hidden" % id)
	return ids


func _check_chapters(choice_ids: Dictionary, ach_ids: Dictionary, char_ids: Dictionary) -> void:
	var dir := DirAccess.open("res://data/dialogue")
	if dir == null:
		_err("res://data/dialogue", "каталог не открывается")
		return
	var files := dir.get_files()
	files.sort()
	if files.is_empty():
		_warn("res://data/dialogue", "нет ни одной главы (пока норм для ранних фаз)")
	for f: String in files:
		if not f.ends_with(".json"):
			continue
		var path := "res://data/dialogue/" + f
		var data = _load(path)
		if not (data is Dictionary):
			continue
		var steps: Array = data.get("steps", [])
		if steps.is_empty():
			_warn(path, "пустой steps")
		var labels := {}
		for s: Variant in steps:
			if s is Dictionary and str(s.get("type", "")) == "label":
				labels[str(s.get("id", ""))] = true
		for i in steps.size():
			var s: Variant = steps[i]
			if not (s is Dictionary):
				_err(f, "шаг %d не объект" % i)
				continue
			var step: Dictionary = s
			var t := str(step.get("type", ""))
			if not KNOWN_STEP_TYPES.has(t):
				_err(f, "шаг %d: неизвестный тип '%s'" % [i, t])
			match t:
				"line":
					if not char_ids.has(str(step.get("who", ""))):
						_err(f, "шаг %d: неизвестный персонаж '%s'" % [i, step.get("who", "")])
					if not _has_ru(step.get("text", {})):
						_err(f, "шаг %d: line без ru-текста" % i)
				"choice":
					if not choice_ids.has(str(step.get("id", ""))):
						_err(f, "шаг %d: выбор '%s' отсутствует в choices.json" % [i, step.get("id", "")])
				"bg":
					if not KNOWN_BG.has(str(step.get("id", ""))):
						_warn(f, "шаг %d: фон '%s' не из списка (плейсхолдер?)" % [i, step.get("id", "")])
				"music":
					if not KNOWN_MUSIC.has(str(step.get("id", ""))):
						_warn(f, "шаг %d: трек '%s' не из списка" % [i, step.get("id", "")])
				"sfx":
					if str(step.get("id", "")) == "":
						_err(f, "шаг %d: sfx без id" % i)
				"show", "hide", "expr":
					if not char_ids.has(str(step.get("who", ""))):
						_err(f, "шаг %d: неизвестный персонаж '%s'" % [i, step.get("who", "")])
				"fragment":
					var fid := int(step.get("id", 0))
					if fid < 1 or fid > FRAGMENTS_TOTAL:
						_err(f, "шаг %d: fragment id вне 1..%d" % [i, FRAGMENTS_TOTAL])
				"achievement":
					if not ach_ids.has(str(step.get("id", ""))):
						_err(f, "шаг %d: неизвестное достижение '%s'" % [i, step.get("id", "")])
				"set_flag":
					if str(step.get("flag", "")) == "":
						_err(f, "шаг %d: set_flag без flag" % i)
				"puzzle", "minigame":
					if str(step.get("id", "")) == "":
						_err(f, "шаг %d: %s без id" % [i, t])
				"jump":
					if not labels.has(str(step.get("label", ""))):
						_err(f, "шаг %d: jump на несуществующую метку '%s'" % [i, step.get("label", "")])
				"if_flag":
					for key in ["jump_if_true", "jump_if_false"]:
						if step.has(key) and not labels.has(str(step[key])):
							_err(f, "шаг %d: if_flag %s на несуществующую метку '%s'" % [i, key, step[key]])
				"chapter_end":
					var nxt := int(step.get("next", -1))
					if nxt >= 0:
						var npath := "res://data/dialogue/chapter_%02d.json" % nxt
						if not FileAccess.file_exists(npath):
							_warn(f, "next=%d: файла главы ещё нет (норм на ранних фазах)" % nxt)


func _check_locales() -> void:
	var ru = _load("res://data/locales/ru.json")
	var en = _load("res://data/locales/en.json")
	if not (ru is Dictionary) or not (en is Dictionary):
		return
	var ru_keys: Array = (ru as Dictionary).keys()
	var en_keys: Array = (en as Dictionary).keys()
	for k: String in ru_keys:
		if not en_keys.has(k):
			_warn("locales", "ключ '%s' есть в ru, нет в en" % k)
	for k: String in en_keys:
		if not ru_keys.has(k):
			_warn("locales", "ключ '%s' есть в en, нет в ru" % k)


func _check_custom() -> void:
	var about = _load("res://data/custom/about.json")
	if about is Dictionary:
		for key in ["her_name", "final_question", "dedication"]:
			if not _has_ru((about as Dictionary).get(key, {})):
				_err("about.json", "нет ключа/ru: %s" % key)
	var song = _load("res://data/custom/song.json")
	if song is Dictionary:
		var lines: Array = (song as Dictionary).get("lines", [])
		var last_t := -1.0
		for i in lines.size():
			var l: Variant = lines[i]
			if not (l is Dictionary) or not l.has("time"):
				_err("song.json", "строка %d без time" % i)
				continue
			var tt := float(l["time"])
			if tt < last_t:
				_err("song.json", "строка %d: time %.2f меньше предыдущего (%.2f)" % [i, tt, last_t])
			last_t = tt
	var letters = _load("res://data/custom/letters.json")
	if letters is Dictionary:
		if not _has_ru((letters as Dictionary).get("final_message", {})) and not (letters.get("final_message", null) is Array):
			pass  # final_message — массив строк; просто проверим, что он есть
		if not letters.has("final_message"):
			_err("letters.json", "нет final_message")
