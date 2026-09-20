extends Control
## VNStage — движок визуальной новеллы (Фаза 4).
##
## Интерпретатор потока шагов из data/dialogue/chapter_XX.json:
##   line / choice / bg / music / sfx / show / hide / expr / transition /
##   wait / fragment / achievement / unlock_* / puzzle / minigame / label /
##   jump / if_flag / chapter_end / title_card
##
## Умеет: typing-эффект со звуком, АВТО и SKIP, историю диалогов (H),
## скрытие UI (S), быстрое меню, паузу (Esc), тосты достижений и
## фрагментов, дождь и другие эффекты, переходы фонов, спрайты с
## выражениями, автосейвы. Headless-автотест продолжает работать.
##
## Управление: клик/Space/Enter — дальше · A — авто · Ctrl (удерж.) — skip ·
## H — история · S — скрыть UI · F5/⌘S и F9/⌘L — быстрый сейв/лоад · Esc — пауза

const UITheme := preload("res://scripts/ui/theme_builder.gd")
const BackgroundsLayer := preload("res://scripts/ui/backgrounds_layer.gd")
const CharactersLayer := preload("res://scripts/ui/characters_layer.gd")
const Toast := preload("res://scripts/ui/toast.gd")
const HistoryOverlay := preload("res://scripts/ui/history_overlay.gd")

enum State { BUSY, TYPING, WAITING, CHOOSING }

const TYPE_SFX_EVERY := 3          # символ печати на один «тик» звука
const AUTO_CHAR_TIME := 0.032      # базовая пауза AUTO на символ (до множителя)

var _state: int = State.BUSY
var _index := 0
var _type_pos := 0.0
var _line_total := 0
var _line_text := ""
var _last_typed_tick := 0
var _title_mode := false
var _end_mode := false
var _pulse := 0.0
var _auto_after := 0.0            # таймер автопродвижения в AUTO-режиме
var _auto_mode := false
var _skip_mode := false
var _ui_hidden := false
var _headless := false
var _awaiting_click_gate := 0.0   # защита от двойного клика после choice

# --- слои ---
var _bg_layer: Control
var _chars_layer: Control
var _fx_layer: Control
var _fx_rain: CPUParticles2D

# --- UI ---
var _ui_root: Control
var _note: Label
var _title_box: CenterContainer
var _title_label: Label
var _title_sub: Label
var _panel: PanelContainer
var _name_label: Label
var _text: RichTextLabel
var _arrow: Label
var _choices_center: CenterContainer
var _choices_box: VBoxContainer
var _toast: Control
var _history: Control
var _pause_overlay: Control
var _quick_buttons: Array[Button] = []
var _btn_auto: Button
var _btn_skip: Button


func _ready() -> void:
	theme = UITheme.build()
	_headless = DisplayServer.get_name() == "headless"
	_build_layers()
	_build_ui()
	AchievementManager.achievement_unlocked.connect(_on_achievement_toast)
	GameManager.fragment_added.connect(_on_fragment_added)
	SettingsManager.settings_changed.connect(_apply_text_size)

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


# ============================================================
# ПОСТРОЕНИЕ СЦЕНЫ
# ============================================================

func _build_layers() -> void:
	_bg_layer = BackgroundsLayer.new()
	_bg_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg_layer)

	_chars_layer = CharactersLayer.new()
	_chars_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_chars_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_chars_layer)

	_fx_layer = Control.new()
	_fx_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fx_layer)


func _build_ui() -> void:
	_ui_root = Control.new()
	_ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ui_root)

	_note = Label.new()
	_note.add_theme_font_size_override("font_size", 12)
	_note.add_theme_color_override("font_color", Color(UITheme.COL_TEXT, 0.28))
	_note.position = Vector2(14.0, 10.0)
	_note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_root.add_child(_note)

	# --- центральный оверлей: титул главы / title_card ---
	_title_box = CenterContainer.new()
	_title_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_title_box.visible = false
	_title_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_root.add_child(_title_box)
	var title_v := VBoxContainer.new()
	title_v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_box.add_child(title_v)
	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var display := UITheme.display_font()
	if display != null:
		_title_label.add_theme_font_override("font", display)
	_title_label.add_theme_font_size_override("font_size", 30)
	_title_label.add_theme_color_override("font_color", UITheme.COL_ACCENT_SOFT)
	title_v.add_child(_title_label)
	_title_sub = Label.new()
	_title_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_sub.add_theme_font_size_override("font_size", 14)
	_title_sub.add_theme_color_override("font_color", Color(UITheme.COL_TEXT, 0.5))
	title_v.add_child(_title_sub)

	# --- диалоговое окно (GDD §8.3) ---
	_panel = PanelContainer.new()
	_panel.anchor_left = 0.0
	_panel.anchor_right = 1.0
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = 80.0
	_panel.offset_right = -80.0
	_panel.offset_top = -230.0
	_panel.offset_bottom = -78.0
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_root.add_child(_panel)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 4)
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
	_apply_text_size()

	# --- выборы ---
	_choices_center = CenterContainer.new()
	_choices_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_choices_center.visible = false
	_ui_root.add_child(_choices_center)
	var choices_panel := PanelContainer.new()
	_choices_center.add_child(choices_panel)
	_choices_box = VBoxContainer.new()
	_choices_box.add_theme_constant_override("separation", 10)
	choices_panel.add_child(_choices_box)

	# --- быстрое меню (GDD §8.3) ---
	if not _headless:
		_build_quick_menu()

	# --- тосты, история, пауза ---
	_toast = Toast.new()
	_ui_root.add_child(_toast)

	_history = HistoryOverlay.new()
	_ui_root.add_child(_history)

	_build_pause_overlay()


func _build_quick_menu() -> void:
	var bar := HBoxContainer.new()
	bar.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	bar.offset_left = -620.0
	bar.offset_right = -16.0
	bar.offset_top = -66.0
	bar.offset_bottom = -22.0
	bar.alignment = BoxContainer.ALIGNMENT_END
	bar.add_theme_constant_override("separation", 6)
	bar.mouse_filter = Control.MOUSE_FILTER_PASS
	_ui_root.add_child(bar)

	var defs := [
		["AUTO", func() -> void: _toggle_auto()],
		["SKIP", func() -> void: _toggle_skip()],
		["LOG", func() -> void: _open_history()],
		["SAVE", func() -> void: _quick_save()],
		["LOAD", func() -> void: _quick_load()],
		["UI", func() -> void: _toggle_ui()],
		["☰", func() -> void: _open_pause()],
	]
	for d: Array in defs:
		var b := Button.new()
		b.text = str(d[0])
		b.custom_minimum_size = Vector2(72, 34)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(d[1])
		bar.add_child(b)
		_quick_buttons.append(b)
	_btn_auto = _quick_buttons[0]
	_btn_skip = _quick_buttons[1]


func _build_pause_overlay() -> void:
	_pause_overlay = Control.new()
	_pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_overlay.visible = false
	_pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui_root.add_child(_pause_overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.015, 0.035, 0.8)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_pause_overlay.add_child(dim)

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	_pause_overlay.add_child(box)

	var t := Label.new()
	t.text = LocalizationManager.t("pause.title", "ПАУЗА")
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 24)
	t.add_theme_color_override("font_color", UITheme.COL_ACCENT_SOFT)
	box.add_child(t)
	box.add_child(_vspacer(12))

	for d: Array in [
		["pause.continue", func() -> void: _close_pause()],
		["menu.settings", func() -> void:
			SettingsManager.save_settings()
			GameManager.change_scene_faded(GameManager.SCENE_SETTINGS)],
		["pause.menu", func() -> void:
			SaveManager.autosave()
			SaveManager.flush()
			GameManager.goto_menu()],
	]:
		var b := Button.new()
		b.text = LocalizationManager.t(str(d[0]))
		b.custom_minimum_size = Vector2(330, 44)
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		b.pressed.connect(d[1])
		box.add_child(b)


func _vspacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


# ============================================================
# ГЛАВНЫЙ ЦИКЛ ШАГОВ
# ============================================================

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
				_bg_layer.set_background(str(step.get("id", "")), str(step.get("transition", "fade")), float(step.get("duration", 1.1)))
				_apply_bg_effects(str(step.get("id", "")))
			"music":
				AudioManager.play_music(str(step.get("id", "")), float(step.get("fade", 1.2)))
			"sfx":
				AudioManager.play_sfx(str(step.get("id", "")))
			"show":
				_chars_layer.show_character(str(step.get("who", "")), str(step.get("expr", "neutral")), str(step.get("at", "center")))
			"hide":
				_chars_layer.hide_character(str(step.get("who", "")))
			"expr":
				_chars_layer.set_expression(str(step.get("who", "")), str(step.get("expr", "")))
			"transition":
				match str(step.get("kind", "fade")):
					"white_flash":
						_bg_layer.set_background(_bg_layer.current_id(), "white_flash", float(step.get("duration", 0.9)))
					"to_black":
						_bg_layer.to_black(float(step.get("duration", 0.8)))
					_:
						pass  # остальные виды применяются на bg-шаге
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
				_note.text = "· %s «%s» — появится в Фазе 7" % [t, step.get("id", "")]
			"wait":
				if _headless or _skip_mode:
					pass  # в skip/headless не ждём
				else:
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
				_note.text = "· неизвестный шаг '%s' — пропущен" % t
		_index += 1


# ============================================================
# ШАГИ, ЖДУЩИЕ ИГРОКА
# ============================================================

func _begin_line(step: Dictionary) -> void:
	var text := LocalizationManager.field(step.get("text", ""))
	if text == "":
		_index += 1
		_run_steps()
		return
	var who := str(step.get("who", ""))
	var ch := DialogueManager.get_character(who)
	var display_name: String = LocalizationManager.field(ch.get("name", {})) if not ch.is_empty() else who.capitalize()
	if bool(ch.get("plate_hidden", false)):
		display_name = ""
	_name_label.text = display_name
	_name_label.add_theme_color_override("font_color", Color(str(ch.get("color", "#ff8fbd")) if not ch.is_empty() else "#ffb9d5"))
	_name_label.visible = display_name != ""
	_panel.visible = true
	_title_box.visible = false
	_line_text = text
	_line_total = text.length()
	_type_pos = 0.0
	_last_typed_tick = 0
	_text.text = text
	_text.visible_characters = 0
	SaveManager.mark_seen("%d:%d" % [DialogueManager.current_chapter, _index])
	_history.add_entry(display_name, Color(str(ch.get("color", "#ffb9d5")) if not ch.is_empty() else "#ffb9d5"), text)
	if SettingsManager.text_speed_value() <= 0.0 or _skip_mode:
		_type_pos = float(_line_total)
		_text.visible_characters = _line_total
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
	_set_arrow(false)
	var choice := DialogueManager.get_choice(str(step.get("id", "")))
	if choice.is_empty():
		_note.text = "· выбор '%s' не найден в choices.json" % step.get("id", "")
		_index += 1
		_run_steps()
		return
	_history.add_entry("·", UITheme.COL_ACCENT, LocalizationManager.field(choice.get("prompt", {})))
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
	_awaiting_click_gate = 0.15
	for f: Variant in opt.get("set_flags", []):
		GameManager.set_flag(str(f))
	var secret := str(opt.get("unlock_secret", ""))
	if secret != "":
		GalleryManager.unlock("secrets", secret)
		AchievementManager.unlock("secret")
	var opt_id := str(opt.get("id", ""))
	if opt_id != "":
		SaveManager.mark_seen("choice:%d:%s" % [DialogueManager.current_chapter, opt_id])
	_index += 1
	_run_steps()


# ============================================================
# КОНЕЦ ГЛАВЫ
# ============================================================

func _on_chapter_ended(step: Dictionary = {}) -> void:
	_state = State.BUSY
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
	_bg_layer.to_black(1.0)
	AudioManager.stop_music(1.5)
	_show_center("КОНЕЦ ДОСТУПНОГО ФРАГМЕНТА", "Полные главы — с Фазы 6.\nПрогресс сохранён (autosave).")
	_state = State.WAITING
	_end_mode = true
	_panel.visible = false


# ============================================================
# ВВОД
# ============================================================

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("vn_advance"):
		if _history.visible:
			_history.close_history()
			return
		_advance()
	elif event.is_action_pressed("vn_auto"):
		_toggle_auto()
	elif event.is_action_pressed("vn_history"):
		_open_history()
	elif event.is_action_pressed("vn_hide_ui"):
		_toggle_ui()
	elif event.is_action_pressed("vn_skip_hold"):
		_skip_mode = true
		_update_mode_buttons()
	elif event.is_action_released("vn_skip_hold"):
		_skip_mode = false
		_update_mode_buttons()
	elif event.is_action_pressed("quick_save"):
		_quick_save()
	elif event.is_action_pressed("quick_load"):
		_quick_load()
	elif event.is_action_pressed("ui_pause"):
		if _history.visible:
			_history.close_history()
		elif _pause_overlay.visible:
			_close_pause()
		else:
			_open_pause()


func _advance() -> void:
	if _awaiting_click_gate > 0.0:
		return
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


# ============================================================
# РЕЖИМЫ И КНОПКИ
# ============================================================

func _toggle_auto() -> void:
	_auto_mode = not _auto_mode
	if _auto_mode:
		_skip_mode = false
	_arm_auto_if_waiting()
	_update_mode_buttons()


func _toggle_skip() -> void:
	_skip_mode = not _skip_mode
	if _skip_mode:
		_auto_mode = false
	_arm_auto_if_waiting()
	_update_mode_buttons()


func _update_mode_buttons() -> void:
	if _btn_auto != null:
		_btn_auto.modulate = Color(1.6, 1.2, 1.5) if _auto_mode else Color.WHITE
		_btn_auto.text = "AUTO ●" if _auto_mode else "AUTO"
	if _btn_skip != null:
		_btn_skip.modulate = Color(1.6, 1.2, 1.5) if _skip_mode else Color.WHITE
		_btn_skip.text = "SKIP ●" if _skip_mode else "SKIP"


func _arm_auto_if_waiting() -> void:
	if _state == State.WAITING and (_auto_mode or _skip_mode) and not _end_mode:
		_auto_after = _auto_delay()


func _auto_delay() -> float:
	if _skip_mode:
		return 0.04
	var base := float(_line_total) * AUTO_CHAR_TIME + 0.9
	return base / maxf(SettingsManager.auto_speed, 0.1)


func _open_history() -> void:
	_history.open()


func _toggle_ui() -> void:
	_ui_hidden = not _ui_hidden
	_panel.visible = (not _ui_hidden) and not _title_mode \
		and _state in [State.TYPING, State.WAITING, State.CHOOSING]
	for b in _quick_buttons:
		b.get_parent().visible = not _ui_hidden
	_choices_center.visible = (not _ui_hidden) and _state == State.CHOOSING
	_set_arrow((not _ui_hidden) and _state == State.WAITING)


func _quick_save() -> void:
	SaveManager.quick_save()
	_toast.show_toast(LocalizationManager.t("vn.quick_saved", "СОХРАНЕНО"), 1.4)
	AudioManager.play_sfx("click")


func _quick_load() -> void:
	if SaveManager.quick_load():
		AudioManager.play_sfx("page")
		GameManager.goto_chapter(GameManager.current_chapter, GameManager.current_label, GameManager.dialogue_step_index)
	else:
		_toast.show_toast(LocalizationManager.t("vn.no_quick_save", "быстрого сохранения нет"), 1.6)


func _open_pause() -> void:
	_pause_overlay.visible = true


func _close_pause() -> void:
	_pause_overlay.visible = false


# ============================================================
# PROCESS: ПЕЧАТЬ, AUTO/SKIP, ПУЛЬС
# ============================================================

func _process(delta: float) -> void:
	if _awaiting_click_gate > 0.0:
		_awaiting_click_gate -= delta
	match _state:
		State.TYPING:
			var speed := SettingsManager.text_speed_value()
			if _skip_mode:
				speed = 400.0
			_type_pos += delta * maxf(speed, 1.0)
			var shown := mini(int(_type_pos), _line_total)
			if shown > _text.visible_characters:
				_text.visible_characters = shown
				_maybe_typing_sfx(shown)
			if _text.visible_characters >= _line_total:
				_finish_typing()
		State.WAITING:
			if not _headless:
				_pulse += delta
				_set_arrow(true)
				_arrow.modulate.a = 0.55 + 0.45 * sin(_pulse * 4.0)
			if (_auto_mode or _skip_mode) and not _end_mode:
				_auto_after -= delta
				if _auto_after <= 0.0:
					_advance()
		State.CHOOSING:
			if _headless:
				_auto_after -= delta
				if _auto_after <= 0.0:
					_auto_after = 0.05
					if not _choices_box.get_children().is_empty():
						var btn := _choices_box.get_child(0) as Button
						if btn != null:
							btn.pressed.emit()
		_:
			pass
	if _headless and _state == State.WAITING:
		_auto_after -= delta
		if _auto_after <= 0.0:
			_auto_after = 0.05
			_advance()


func _maybe_typing_sfx(shown: int) -> void:
	var tick := shown / TYPE_SFX_EVERY
	if tick != _last_typed_tick:
		_last_typed_tick = tick
		if not _skip_mode:
			AudioManager.play_sfx("typing", randf_range(0.95, 1.05))


func _finish_typing() -> void:
	_state = State.WAITING
	_set_arrow(not _skip_mode)
	_arm_auto_if_waiting()


func _set_arrow(on: bool) -> void:
	_arrow.visible = on and not _ui_hidden


# ============================================================
# ЭФФЕКТЫ И ТОСТЫ
# ============================================================

func _apply_bg_effects(bg_id: String) -> void:
	var want_rain := bg_id == "bg_rain_window" and SettingsManager.particles
	if want_rain and _fx_rain == null:
		_fx_rain = CPUParticles2D.new()
		_fx_rain.amount = 140
		_fx_rain.lifetime = 0.9
		_fx_rain.preprocess = 0.9
		_fx_rain.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		_fx_rain.emission_rect_extents = Vector2(760, 20)
		_fx_rain.position = Vector2(640, -30)
		_fx_rain.direction = Vector2(-0.12, 1.0)
		_fx_rain.spread = 2.0
		_fx_rain.gravity = Vector2(0, 900)
		_fx_rain.initial_velocity_min = 620.0
		_fx_rain.initial_velocity_max = 780.0
		_fx_rain.scale_amount_min = 0.6
		_fx_rain.scale_amount_max = 1.2
		_fx_rain.color = Color(0.75, 0.78, 0.95, 0.30)
		var grad := Gradient.new()
		grad.colors = PackedColorArray([Color(1, 1, 1, 0.9), Color(1, 1, 1, 0.0)])
		_fx_rain.color_ramp = grad
		_fx_layer.add_child(_fx_rain)
	elif not want_rain and _fx_rain != null:
		_fx_rain.queue_free()
		_fx_rain = null


func _on_fragment_added(found: int, total: int) -> void:
	_toast.show_toast("✦ %d/%d" % [found, total], 2.0)


func _on_achievement_toast(id: String) -> void:
	var d: Dictionary = AchievementManager.get_def(id)
	var name_text := LocalizationManager.field(d.get("name", id))
	_toast.show_toast("★ %s" % name_text, 2.4)
	AudioManager.play_sfx("notification")


func _apply_text_size() -> void:
	if _text != null:
		_text.add_theme_font_size_override("normal_font_size", SettingsManager.base_font_size())


# ============================================================
# ПОМОЩНИКИ
# ============================================================

func _show_center(main: String, sub: String) -> void:
	_title_label.text = main
	_title_sub.text = sub
	_title_box.visible = true
	_panel.visible = false
