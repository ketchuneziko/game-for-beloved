extends Node
## GameManager (autoload)
## Верхнеуровневый флоу: меню <-> главы, состояние прохождения (флаги
## выборов, фрагменты сообщения, время игры) и параметры перехода
## между сценами (pending). Координирует автосейвы через SaveManager.

signal flag_changed(flag: String, value: Variant)
signal fragment_added(found: int, total: int)

const SCENE_MENU := "res://scenes/main_menu/main_menu.tscn"
const SCENE_VN := "res://scenes/visual_novel/vn_stage.tscn"
const FRAGMENTS_TOTAL := 7

var current_chapter := -1
var current_label := ""
var dialogue_step_index := 0
var flags: Dictionary = {}          # выборы и сюжетные переключатели
var fragments: Array = []           # найденные фрагменты сообщения (int 1..7)
var play_seconds := 0.0
var finished_game := false
## Параметры для следующей сцены, например {"chapter": 3}.
var pending: Dictionary = {}


func _process(delta: float) -> void:
	# Время игры тикает только внутри VN-сцены.
	var cs := get_tree().current_scene
	if cs != null and cs.scene_file_path == SCENE_VN:
		play_seconds += delta


# ---------- флоу ----------

func start_new_game() -> void:
	reset_run_state()
	goto_chapter(0)


## Продолжить: autosave, иначе самый свежий ручной слот.
func continue_game() -> bool:
	var data := SaveManager.read_save("auto")
	if data.is_empty():
		var slot := _latest_slot()
		if slot != "":
			data = SaveManager.read_save(slot)
	if data.is_empty():
		return false
	SaveManager.restore_state(data)
	goto_chapter(current_chapter, current_label, dialogue_step_index)
	return true


func _latest_slot() -> String:
	var best := ""
	var best_time := ""
	for i in SaveManager.SLOT_COUNT:
		var id := str(i)
		var d := SaveManager.read_save(id)
		if not d.is_empty() and str(d.get("timestamp", "")) > best_time:
			best_time = str(d.get("timestamp", ""))
			best = id
	return best


func goto_chapter(chapter: int, label: String = "", step_index: int = 0) -> void:
	current_chapter = chapter
	current_label = label
	dialogue_step_index = step_index
	pending = {"chapter": chapter}
	change_scene(SCENE_VN)


func goto_menu() -> void:
	change_scene(SCENE_MENU)


func change_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)


# ---------- состояние прохождения ----------

func set_flag(flag: String, value: Variant = true) -> void:
	flags[flag] = value
	flag_changed.emit(flag, value)


func has_flag(flag: String) -> bool:
	return bool(flags.get(flag, false))


func add_fragment(id: int) -> void:
	if id < 1 or id > FRAGMENTS_TOTAL:
		push_warning("GameManager: fragment id вне 1..%d (%d)" % [FRAGMENTS_TOTAL, id])
	if fragments.has(id):
		return
	fragments.append(id)
	fragments.sort()
	SaveManager.mark_seen("fragment:%d" % id)
	if fragments.size() == FRAGMENTS_TOTAL:
		AchievementManager.unlock("all_fragments")
	fragment_added.emit(fragments.size(), FRAGMENTS_TOTAL)


func has_fragment(id: int) -> bool:
	return fragments.has(id)


func reset_run_state() -> void:
	current_chapter = -1
	current_label = ""
	dialogue_step_index = 0
	flags = {}
	fragments = []
	play_seconds = 0.0
	finished_game = false
