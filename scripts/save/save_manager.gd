extends Node
## SaveManager (autoload)
## 5 ручных слотов + autosave + quicksave (F5/F9 и ⌘S/⌘L), PNG-превью,
## плюс глобальный прогресс между запусками: user://progress.json
## (увиденные строки, достижения, галерея, секреты, открытые главы).
##
## Схема слота: глава, метка сцены, индекс шага диалога, флаги/выборы,
## найденные фрагменты, время игры, дата, meta. Совместимость версий —
## через SAVE_VERSION (см. GDD §9.6).

signal saved(save_id: String)
signal loaded(data: Dictionary)

const SLOT_COUNT := 5
const SAVES_DIR := "user://saves/"
const PROGRESS_PATH := "user://progress.json"
const SAVE_VERSION := 1

## Глобальный прогресс (между запусками и прохождениями).
var progress: Dictionary = {}


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVES_DIR)
	_load_progress()


# ---------- прогресс (мета-данные) ----------

func _load_progress() -> void:
	progress = {
		"seen_lines": [],
		"achievements": {},
		"gallery": {},
		"chapters_unlocked": 0,
		"finished": false,
	}
	if FileAccess.file_exists(PROGRESS_PATH):
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(PROGRESS_PATH))
		if raw is Dictionary:
			for key: String in progress.keys():
				if raw.has(key):
					progress[key] = raw[key]


## Пакетная запись прогресса (вызывается на концах глав и точках сохранения).
func flush() -> void:
	var f := FileAccess.open(PROGRESS_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(progress, "  "))


func mark_progress(key: String, value: Variant) -> void:
	progress[key] = value
	flush()


## Отметка «строка видена» — нужна для SKIP только прочитанного.
## В памяти — сразу, на диск — пакетно (flush на концах глав).
func mark_seen(line_id: String) -> void:
	var seen: Array = progress.get("seen_lines", [])
	if not seen.has(line_id):
		seen.append(line_id)
		progress["seen_lines"] = seen


func is_seen(line_id: String) -> bool:
	return progress.get("seen_lines", []).has(line_id)


# ---------- слоты ----------

func _path(id: String) -> String:
	return SAVES_DIR + "save_%s.json" % id


func has_save(id: String) -> bool:
	return FileAccess.file_exists(_path(id))


## id: "0".."4" (слоты), "quick", "auto".
func write_save(id: String, data: Dictionary) -> bool:
	DirAccess.make_dir_recursive_absolute(SAVES_DIR)
	data["version"] = SAVE_VERSION
	data["timestamp"] = Time.get_datetime_string_from_system(false)
	var f := FileAccess.open(_path(id), FileAccess.WRITE)
	if f == null:
		push_error("SaveManager: не могу записать %s" % _path(id))
		return false
	f.store_string(JSON.stringify(data, "  "))
	_write_preview(id)
	flush()
	saved.emit(id)
	return true


func read_save(id: String) -> Dictionary:
	if not has_save(id):
		return {}
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(_path(id)))
	return raw if raw is Dictionary else {}


func delete_save(id: String) -> void:
	if has_save(id):
		DirAccess.remove_absolute(_path(id))


## Полный слепок текущего состояния игры для слота.
func capture_state(meta: Dictionary = {}) -> Dictionary:
	return {
		"chapter": GameManager.current_chapter,
		"label": GameManager.current_label,
		"step_index": GameManager.dialogue_step_index,
		"flags": GameManager.flags.duplicate(),
		"fragments": GameManager.fragments.duplicate(),
		"play_seconds": GameManager.play_seconds,
		"finished": GameManager.finished_game,
		"meta": meta,
	}


## Применить слепок к живому состоянию (навигацию выполняет вызывающий).
func restore_state(data: Dictionary) -> void:
	GameManager.current_chapter = int(data.get("chapter", -1))
	GameManager.current_label = str(data.get("label", ""))
	GameManager.dialogue_step_index = int(data.get("step_index", 0))
	var flags: Dictionary = data.get("flags", {})
	GameManager.flags = flags.duplicate()
	var frags: Array = []
	for v: Variant in data.get("fragments", []):
		frags.append(int(v))
	GameManager.fragments = frags
	GameManager.play_seconds = float(data.get("play_seconds", 0.0))
	GameManager.finished_game = bool(data.get("finished", false))


func autosave() -> void:
	write_save("auto", capture_state({"kind": "autosave"}))


func quick_save() -> void:
	write_save("quick", capture_state({"kind": "quick"}))


func quick_load() -> bool:
	var d := read_save("quick")
	if d.is_empty():
		return false
	restore_state(d)
	loaded.emit(d)
	return true


func _write_preview(id: String) -> void:
	# Скриншот-превью слота; в headless-режиме пропускаем.
	if DisplayServer.get_name() == "headless":
		return
	var vp := get_viewport()
	if vp == null:
		return
	var img := vp.get_texture().get_image()
	if img == null or img.is_empty():
		return
	img.resize(320, 180, Image.INTERPOLATE_BILINEAR)
	img.save_png(SAVES_DIR + "save_%s.png" % id)
