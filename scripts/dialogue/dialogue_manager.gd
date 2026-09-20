extends Node
## DialogueManager (autoload)
## Загружает сценарии глав из data/dialogue/chapter_XX.json и отдаёт
## поток шагов + справочники (персонажи, выборы). Презентация — во
## VNStage (Фаза 4); формат данных зафиксирован в docs/DATA_FORMAT.md.
##
## Никакой истории в коде: реплики правятся в JSON без движка.

signal chapter_loaded(chapter_number: int)

const CHAPTERS_DIR := "res://data/dialogue/"
const CHARACTERS_PATH := "res://data/characters.json"
const CHOICES_PATH := "res://data/choices/choices.json"

var current_chapter := -1
var current_label := ""
var chapter_data: Dictionary = {}

var _characters: Dictionary = {}
var _choices: Dictionary = {}


func _ready() -> void:
	_characters = _load_json(CHARACTERS_PATH).get("characters", {})
	_choices = _load_json(CHOICES_PATH).get("choices", {})


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("DialogueManager: нет файла %s" % path)
		return {}
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return raw if raw is Dictionary else {}


# ---------- главы ----------

func chapter_exists(num: int) -> bool:
	return FileAccess.file_exists(CHAPTERS_DIR + "chapter_%02d.json" % num)


func load_chapter(num: int, start_label: String = "") -> bool:
	chapter_data = _load_json(CHAPTERS_DIR + "chapter_%02d.json" % num)
	if chapter_data.is_empty():
		return false
	current_chapter = num
	current_label = start_label
	if start_label != "":
		var idx := seek_label(start_label)
		if idx < 0:
			push_warning("DialogueManager: метка '%s' не найдена в главе %d" % [start_label, num])
			current_label = ""
	chapter_loaded.emit(num)
	return true


func chapter_title(num: int = -1) -> String:
	var n := current_chapter if num < 0 else num
	if n == current_chapter and not chapter_data.is_empty():
		return LocalizationManager.field(chapter_data.get("title", {}))
	var d := _load_json(CHAPTERS_DIR + "chapter_%02d.json" % n)
	if d.is_empty():
		return ""
	return LocalizationManager.field(d.get("title", {}))


## Все шаги текущей главы.
func steps() -> Array:
	return chapter_data.get("steps", [])


## Шаг по индексу; вне диапазона — пустой словарь (конец главы).
func step_at(index: int) -> Dictionary:
	var s := steps()
	if index < 0 or index >= s.size():
		return {}
	var st: Variant = s[index]
	return st if st is Dictionary else {}


## Индекс шага {"type":"label","id":label} или -1.
func seek_label(label: String) -> int:
	var s := steps()
	for i in s.size():
		var st: Variant = s[i]
		if st is Dictionary \
				and str(st.get("type", "")) == "label" \
				and str(st.get("id", "")) == label:
			return i
	return -1


# ---------- справочники ----------

func get_character(id: String) -> Dictionary:
	var c: Dictionary = _characters.get(id, {})
	return c


func get_choice(id: String) -> Dictionary:
	var c: Dictionary = _choices.get(id, {})
	return c
