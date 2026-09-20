extends Node
## GalleryManager (autoload)
## Учёт разблокировок Галереи: PHOTOS / MEMORIES / LETTERS / SECRETS.
## Содержимое секций читается из данных (data/memories, data/custom/letters),
## здесь — только флаги «открыто/не открыто» (в progress.json).

signal item_unlocked(section: String, id: String)

const SECTIONS := ["photos", "memories", "letters", "secrets"]


func unlock(section: String, id: String) -> void:
	if not SECTIONS.has(section):
		push_warning("GalleryManager: неизвестная секция '%s'" % section)
		return
	var store: Dictionary = SaveManager.progress.get("gallery", {})
	var sec: Dictionary = store.get(section, {})
	if sec.has(id):
		return
	sec[id] = true
	store[section] = sec
	SaveManager.mark_progress("gallery", store)
	item_unlocked.emit(section, id)


func is_unlocked(section: String, id: String) -> bool:
	var store: Dictionary = SaveManager.progress.get("gallery", {})
	var sec: Dictionary = store.get(section, {})
	return sec.has(id)


func section_unlocked_count(section: String) -> int:
	var store: Dictionary = SaveManager.progress.get("gallery", {})
	return store.get(section, {}).size()
