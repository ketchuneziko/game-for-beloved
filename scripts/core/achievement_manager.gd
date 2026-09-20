extends Node
## AchievementManager (autoload)
## Определения — data/achievements/achievements.json (8–12 штук, часть скрыта).
## Разблокировки хранятся в SaveManager.progress["achievements"].
## UI-тосты подписываются на achievement_unlocked (полные тосты — Фаза 9).

signal achievement_unlocked(id: String)

const DEFINITIONS_PATH := "res://data/achievements/achievements.json"

var definitions: Array = []
var unlocked: Dictionary = {}   # id -> дата разблокировки


func _ready() -> void:
	_load_definitions()
	var stored: Dictionary = SaveManager.progress.get("achievements", {})
	unlocked = stored.duplicate()


func _load_definitions() -> void:
	if not FileAccess.file_exists(DEFINITIONS_PATH):
		push_warning("AchievementManager: нет %s" % DEFINITIONS_PATH)
		return
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(DEFINITIONS_PATH))
	if raw is Dictionary and raw.has("achievements"):
		definitions = raw["achievements"]
	else:
		push_error("AchievementManager: плохой формат %s" % DEFINITIONS_PATH)


func get_def(id: String) -> Dictionary:
	for d: Variant in definitions:
		if d is Dictionary and str(d.get("id", "")) == id:
			return d
	return {}


func is_unlocked(id: String) -> bool:
	return unlocked.has(id)


## Разблокировать (идемпотентно). Неизвестный id — только предупреждение:
## контент глав не должен ломаться из-за опечатки в ачивке.
func unlock(id: String) -> void:
	if unlocked.has(id):
		return
	if get_def(id).is_empty():
		push_warning("AchievementManager: неизвестное достижение '%s'" % id)
		return
	unlocked[id] = Time.get_datetime_string_from_system(false)
	SaveManager.mark_progress("achievements", unlocked)
	achievement_unlocked.emit(id)


func unlock_count() -> int:
	return unlocked.size()


func total_count() -> int:
	return definitions.size()
