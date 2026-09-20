extends Node
## GameManager (autoload)
## Верхнеуровневый флоу: меню <-> главы, состояние прохождения (флаги
## выборов, фрагменты сообщения, время игры) и параметры перехода
## между сценами (pending). Координирует автосейвы через SaveManager.

signal flag_changed(flag: String, value: Variant)
signal fragment_added(found: int, total: int)

const SCENE_MENU := "res://scenes/main_menu/main_menu.tscn"
const SCENE_VN := "res://scenes/visual_novel/vn_stage.tscn"
const SCENE_SETTINGS := "res://scenes/ui/settings_menu.tscn"
const SCENE_CREDITS := "res://scenes/ui/credits.tscn"
const SCENE_ENDING := "res://scenes/ending/ending.tscn"
const SCENE_GALLERY := "res://scenes/ui/gallery.tscn"
const SCENE_ACHIEVEMENTS := "res://scenes/ui/achievements.tscn"
const FRAGMENTS_TOTAL := 7
## «Мир меню» после финальной главы (GDD §1.10): глава 8 = возврат в меню,
## уже как продолжение истории (рассветный фон, «ЕЩЁ РАЗ ♥»).
const MENU_CHAPTER := 8

var current_chapter := -1
var current_label := ""
var dialogue_step_index := 0
var flags: Dictionary = {}          # выборы и сюжетные переключатели
var fragments: Array = []           # найденные фрагменты сообщения (int 1..7)
var play_seconds := 0.0
var finished_game := false
## Параметры для следующей сцены, например {"chapter": 3}.
var pending: Dictionary = {}

var _about_cache: Dictionary = {}
var _fading := false


func _process(delta: float) -> void:
	# Время игры тикает только внутри VN-сцены.
	var cs := get_tree().current_scene
	if cs != null and cs.scene_file_path == SCENE_VN:
		play_seconds += delta


# ---------- флоу ----------

func start_new_game(faded: bool = false) -> void:
	reset_run_state()
	goto_chapter(0, "", 0, faded)


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


func goto_chapter(chapter: int, label: String = "", step_index: int = 0, faded: bool = false) -> void:
	current_chapter = chapter
	current_label = label
	dialogue_step_index = step_index
	pending = {"chapter": chapter}
	var scene := SCENE_VN if chapter < MENU_CHAPTER else SCENE_MENU
	if faded:
		change_scene_faded(scene)
	else:
		change_scene(scene)


func goto_menu() -> void:
	change_scene(SCENE_MENU)


func change_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)


## Смена сцены с плавным затемнением (GDD §8.2: «при выборе PLAY экран
## плавно затемняется»). Асинхронна — вызывай без await, если не нужно ждать.
func change_scene_faded(path: String, fade_out: float = 0.55, fade_in: float = 0.55) -> void:
	if _fading:
		return
	_fading = true
	var layer := CanvasLayer.new()
	layer.layer = 100
	var rect := ColorRect.new()
	rect.color = Color("#060409")
	rect.modulate.a = 0.0
	rect.mouse_filter = Control.MOUSE_FILTER_STOP
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(rect)
	get_tree().root.add_child(layer)
	var tw := create_tween()
	tw.tween_property(rect, "modulate:a", 1.0, fade_out)
	await tw.finished
	get_tree().change_scene_to_file(path)
	var tw2 := create_tween()
	tw2.tween_property(rect, "modulate:a", 0.0, fade_in)
	await tw2.finished
	layer.queue_free()
	_fading = false


## Личный контент из data/custom/about.json (кэшируется).
func custom_about() -> Dictionary:
	if _about_cache.is_empty() and FileAccess.file_exists("res://data/custom/about.json"):
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/custom/about.json"))
		if raw is Dictionary:
			_about_cache = raw
	return _about_cache


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
