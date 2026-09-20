extends Control
## VNStage — сцена визуальной новеллы. PHASE 2 SCAFFOLD.
##
## Доказывает весь конвейер от начала до конца:
##   JSON главы -> DialogueManager -> реплики / выборы / автоматические шаги
##   -> GameManager, AudioManager, SaveManager, GalleryManager, достижения.
## Фаза 4 заменит презентационный слой (спрайты, expressions, переходы,
## AUTO/SKIP, история, быстрое меню) — формат данных при этом не изменится.
##
## Управление (см. project.godot -> input):
##   клик / Space / Enter — дальше (первый клик дописывает строку)
##   F5 / ⌘S — быстрый сейв, F9 / ⌘L — быстрая загрузка
##   Esc — автосейв и выход в меню

const UITheme := preload("res://scripts/ui/theme_builder.gd")

enum State { BUSY, TYPING, WAITING, CHOOSING }

## Плейсхолдер-цвета фонов; настоящие текстуры — Фаза 4 (assets/backgrounds).
const BG_COLORS := {
	"black": Color("#060409"),
	"bg_planetarium_night": Color("#181226"),
	"bg_dome_stars": Color("#0d1230"),
	"bg_rain_window": Color("#141020"),
	"bg_street_night": Color("#0e0c1a"),
	"bg_rooftop_dawn": Color("#2a1c2e"),
	"bg_bedroom_morning": Color("#2b2230"),
	"memory": Color("#241a2b"),
}

var _state: int = State.BUSY
var _index := 0
var _type_pos := 0.0
var _line_total := 0
var _title_mode := false
var _end_mode := false
var _pulse := 0.0
var _auto_cooldown := 0.0
var _headless := false

var _bg: ColorRect
var _note: Label
var _frag_label: Label
var _title_box: CenterContainer
var _title_label: Label
var _title_sub: Label
var _panel: PanelContainer
var _name_label: Label
var _text: RichTextLabel
var _arrow: Label
var _choices_center: CenterContainer
var _choices_box: VBoxContainer


func _ready() -> void:
	theme = UITheme.build()
	_headless = DisplayServer.get_name() == "headless"
	_build_ui()
	AchievementManager.achievement_unlocked.connect(_on_achievement_toast)
	GameManager.fragment_added.connect(_on_fragment_added)

	var chapter := int(GameManager.pending.get("chapter", 0))
	if chapter <= 0:
		chapter = maxi(GameManager.current_chapter, 0)
	GameManager.current_chapter = chapter  # сцена может быть запущена напрямую
	if not DialogueManager.load_chapter(chapter):
		_note.text = "Нет файла главы %d (data/dialogue). Формат — docs/DATA_FORMAT.md" % chapter
		return

	_index = maxi(GameManager.dialogue_step_index, 0)
	if GameManager.current_label != "":
		var li := DialogueManager.seek_label(GameManager.current_label)
		if li >= 0:
			_index = li

	var title := DialogueManager.chapter_title()
	if title != "":
		_show_center(title, LocalizationManager.t("vn.chapter") % chapter)
		await get_tree().create_timer(0.05 if _headless else 2.2).timeout
		_title_box.visible = false
	_run_steps()


# ---------- UI ----------

func _build_ui() -> void:
	_bg = ColorRect.new()
	_bg.color = UITheme.COL_SHADOW
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)

	_note = Label.new()
	_note.add_theme_font_size_override("font_size", 12)
	_note.add_theme_color_override("font_color", Color(UITheme.COL_TEXT, 0.28))
	add_child(_note)
	_note.position = Vector2(14.0, 10.0)
	_note.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_frag_label = Label.new()
	_frag_label.add_theme_font_size_override("font_size", 15)
	_frag_label.add_theme_color_override("font_color", UITheme.COL_ACCENT_SOFT)
	_frag_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	add_child(_frag_label)
	_frag_label.position = Vector2(1150.0, 10.0)
	_frag_label.visible = false
	_frag_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Центральный оверлей: титул главы / title_card.
	_title_box = CenterContainer.new()
	_title_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_title_box.visible = false
	_title_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_title_box)
	var title_v := VBoxContainer.new()
	title_v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_box.add_child(title_v)
	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 34)
	_title_label.add_theme_color_override("font_color", UITheme.COL_ACCENT_SOFT)
	title_v.add_child(_title_label)
	_title_sub = Label.new()
	_title_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_sub.add_theme_font_size_override("font_size", 14)
	_title_sub.add_theme_color_override("font_color", Color(UITheme.COL_TEXT, 0.5))
	title_v.add_child(_title_sub)

	# Диалоговое окно (GDD §8.3): имя, текст, ▼.
	_panel = PanelContainer.new()
	_panel.anchor_left = 0.0
	_panel.anchor_right = 1.0
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = 80.0
	_panel.offset_right = -80.0
	_panel.offset_top = -230.0
	_panel.offset_bottom = -40.0
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 6)
	pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(pv)
	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 16)
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pv.add_child(_name_label)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = false
	_text.fit_content = false
	_text.scroll_active = false
	_text.custom_minimum_size = Vector2(0, 96)
	_text.add_theme_font_size_override("normal_font_size", SettingsManager.base_font_size())
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pv.add_child(_text)
	_arrow = Label.new()
	_arrow.text = "▼"
	_arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_arrow.add_theme_color_override("font_color", UITheme.COL_ACCENT)
	_arrow.add_theme_font_size_override("font_size", 16)
	_arrow.visible = false
	_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pv.add_child(_arrow)

	# Выборы: центральная панель с кнопками.
	_choices_center = CenterContainer.new()
	_choices_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_choices_center.visible = false
	add_child(_choices_center)
	var choices_panel := PanelContainer.new()
	_choices_center.add_child(choices_panel)
	_choices_box = VBoxContainer.new()
	_choices_box.add_theme_constant_override("separation", 10)
	choices_panel.add_child(_choices_box)


# ---------- главный цикл шагов ----------

## Интерпретатор потока шагов. Автоматические шаги применяются на месте
## («проваливаются»), реплики/выборы/титры ждут игрока. В headless-режиме
## (автотест) продвигается само.
func _run_steps() -> void:
	_state = State.BUSY
	_arrow.visible = false
	while true:
		var step := DialogueManager.step_at(_index)
		if step.is_empty():
			_on_chapter_ended()
			return
		GameManager.dialogue_step_index = _index
		var t := str(step.get("type", ""))
		match t:
			"line":
				_begin_line(step)
				return
			"choice":
				_begin_choice(step)
				return
			"title_card":
				_begin_title(step)
				return
			"bg":
				_set_bg(str(step.get("id", "")))
			"music":
				AudioManager.play_music(str(step.get("id", "")), float(step.get("fade", 1.2)))
			"sfx":
				AudioManager.play_sfx(str(step.get("id", "")))
			"show":
				_note_step("show %s / %s (спрайты — Фаза 4)" % [step.get("who", ""), step.get("expr", "")])
			"hide":
				_note_step("hide %s (Фаза 4)" % step.get("who", ""))
			"expr":
				_note_step("expr %s -> %s (Фаза 4)" % [step.get("who", ""), step.get("expr", "")])
			"transition":
				_note_step("transition: %s (Фаза 4)" % step.get("kind", "fade"))
			"fragment":
				GameManager.add_fragment(int(step.get("id", 0)))
				AudioManager.play_sfx("puzzle_solved")
			"achievement":
				AchievementManager.unlock(str(step.get("id", "")))
			"unlock_photo":
				GalleryManager.unlock("photos", str(step.get("id", "")))
			"unlock_memory":
				GalleryManager.unlock("memories", str(step.get("id", "")))
			"unlock_letter":
				GalleryManager.unlock("letters", str(step.get("id", "")))
			"unlock_secret":
				GalleryManager.unlock("secrets", str(step.get("id", "")))
			"puzzle", "minigame":
				_note_step("%s «%s» — появится в Фазе 7" % [t, step.get("id", "")])
			"wait":
				await get_tree().create_timer(float(step.get("duration", 1.0))).timeout
			"label":
				DialogueManager.current_label = str(step.get("id", ""))
				GameManager.current_label = str(step.get("id", ""))
			"jump":
				var li := DialogueManager.seek_label(str(step.get("label", "")))
				if li >= 0:
					_index = li
					continue
				push_warning("VNStage: jump на несуществующую метку '%s'" % step.get("label", ""))
			"if_flag":
				var target: Variant = step.get("jump_if_true") if GameManager.has_flag(str(step.get("flag", ""))) else step.get("jump_if_false")
				if target != null:
					var li2 := DialogueManager.seek_label(str(target))
					if li2 >= 0:
						_index = li2
						continue
			"chapter_end":
				_on_chapter_ended(step)
				return
			_:
				_note_step("неизвестный шаг '%s' — пропущен" % t)
		_index += 1


# ---------- шаги, ждущие игрока ----------

func _begin_line(step: Dictionary) -> void:
	var text := LocalizationManager.field(step.get("text", ""))
	if text == "":
		_index += 1
		_run_steps()
		return
	var who := str(step.get("who", ""))
	var ch := DialogueManager.get_character(who)
	_name_label.text = LocalizationManager.field(ch.get("name", {})) if not ch.is_empty() else who.capitalize()
	if bool(ch.get("plate_hidden", false)):
		_name_label.text = ""
	_name_label.add_theme_color_override("font_color", Color(str(ch.get("color", "#ff8fbd")) if not ch.is_empty() else "#ffb9d5"))
	_name_label.visible = _name_label.text != ""
	_panel.visible = true
	_title_box.visible = false
	_text.text = text
	_line_total = text.length()
	_type_pos = 0.0
	_text.visible_characters = 0
	SaveManager.mark_seen("%d:%d" % [DialogueManager.current_chapter, _index])
	if SettingsManager.text_speed_value() <= 0.0:
		_finish_typing()
	else:
		_state = State.TYPING


func _begin_title(step: Dictionary) -> void:
	_show_center(
		LocalizationManager.field(step.get("text", {})),
		LocalizationManager.field(step.get("sub", {}))
	)
	_state = State.WAITING
	_title_mode = true


func _begin_choice(step: Dictionary) -> void:
	_state = State.CHOOSING
	_panel.visible = true
	var choice := DialogueManager.get_choice(str(step.get("id", "")))
	if choice.is_empty():
		_note_step("выбор '%s' не найден в data/choices/choices.json" % step.get("id", ""))
		_index += 1
		_run_steps()
		return
	for child in _choices_box.get_children():
		child.queue_free()
	for opt: Dictionary in choice.get("options", []):
		var btn := Button.new()
		btn.text = LocalizationManager.field(opt.get("text", {}))
		btn.custom_minimum_size = Vector2(440, 44)
		btn.pressed.connect(_on_choice_selected.bind(opt))
		_choices_box.add_child(btn)
	_choices_center.visible = true


func _on_choice_selected(opt: Dictionary) -> void:
	AudioManager.play_sfx("click")
	_choices_center.visible = false
	for f: Variant in opt.get("set_flags", []):
		GameManager.set_flag(str(f))
	var secret := str(opt.get("unlock_secret", ""))
	if secret != "":
		GalleryManager.unlock("secrets", secret)
	var opt_id := str(opt.get("id", ""))
	if opt_id != "":
		SaveManager.mark_seen("choice:%d:%s" % [DialogueManager.current_chapter, opt_id])
	_index += 1
	_run_steps()


# ---------- конец главы ----------

func _on_chapter_ended(step: Dictionary = {}) -> void:
	SaveManager.flush()
	SaveManager.autosave()
	DialogueManager.current_label = ""
	GameManager.current_label = ""
	GameManager.dialogue_step_index = 0
	var next := int(step.get("next", -1)) if not step.is_empty() else -1
	if next >= 0 and DialogueManager.chapter_exists(next):
		if _headless:
			print("AUTOTEST: chapter %d -> %d" % [GameManager.current_chapter, next])
		GameManager.goto_chapter(next)
		return
	if _headless:
		print("AUTOTEST: scaffold run complete")
		get_tree().quit(0)
		return
	_set_bg("black")
	AudioManager.stop_music(1.0)
	_show_center("КОНЕЦ ДОСТУПНОГО ФРАГМЕНТА", "Полные главы — с Фазы 6.\nПрогресс сохранён (autosave). Нажми, чтобы вернуться в меню.")
	_state = State.WAITING
	_end_mode = true
	_panel.visible = false


# ---------- ввод ----------

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("vn_advance"):
		_advance()
	elif event.is_action_pressed("quick_save"):
		SaveManager.quick_save()
		_flash_note("★ QUICK SAVE")
	elif event.is_action_pressed("quick_load"):
		if SaveManager.quick_load():
			_flash_note("QUICK LOAD")
			GameManager.goto_chapter(GameManager.current_chapter, GameManager.current_label, GameManager.dialogue_step_index)
		else:
			_flash_note("быстрого сохранения нет")
	elif event.is_action_pressed("ui_pause"):
		SaveManager.autosave()
		GameManager.goto_menu()


func _advance() -> void:
	match _state:
		State.TYPING:
			_type_pos = float(_line_total)
			_text.visible_characters = _line_total
			_finish_typing()
		State.WAITING:
			if _end_mode:
				GameManager.goto_menu()
				return
			if _title_mode:
				_title_mode = false
				_title_box.visible = false
				_panel.visible = true
			_index += 1
			_run_steps()
		_:
			pass


func _process(delta: float) -> void:
	if _state == State.TYPING:
		_type_pos += delta * SettingsManager.text_speed_value()
		if SettingsManager.text_speed_value() <= 0.0:
			_type_pos = float(_line_total)
		_text.visible_characters = int(_type_pos)
		if _text.visible_characters >= _line_total:
			_finish_typing()
	elif _state == State.WAITING:
		if _headless:
			# Автотест: продвигаемся сами.
			_auto_cooldown -= delta
			if _auto_cooldown <= 0.0:
				_auto_cooldown = 0.05
				_advance()
		else:
			_pulse += delta
			_arrow.modulate.a = 0.55 + 0.45 * sin(_pulse * 4.0)
	elif _state == State.CHOOSING and _headless:
		_auto_cooldown -= delta
		if _auto_cooldown <= 0.0:
			_auto_cooldown = 0.05
			# Автотест: всегда первый вариант.
			if not _choices_box.get_children().is_empty():
				var btn := _choices_box.get_child(0) as Button
				if btn != null:
					btn.pressed.emit()


func _finish_typing() -> void:
	_state = State.WAITING
	_arrow.visible = true


# ---------- помощники ----------

func _show_center(main: String, sub: String) -> void:
	_title_label.text = main
	_title_sub.text = sub
	_title_box.visible = true
	_panel.visible = false


func _set_bg(id: String) -> void:
	_bg.color = BG_COLORS.get(id, UITheme.COL_SHADOW)
	if id != "black":
		_note_step("bg: %s (плейсхолдер — Фаза 4)" % id)


func _note_step(msg: String) -> void:
	_note.text = "· " + msg


func _flash_note(msg: String) -> void:
	_note.text = "★ " + msg


func _on_fragment_added(found: int, total: int) -> void:
	_frag_label.text = "✦ %d/%d" % [found, total]
	_frag_label.visible = true


func _on_achievement_toast(id: String) -> void:
	_flash_note("★ ДОСТИЖЕНИЕ: %s" % id.to_upper())
