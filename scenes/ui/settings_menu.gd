extends Control
## Настройки (Фаза 3, GDD §8.4): АУДИО / ТЕКСТ / ДИСПЛЕЙ / ЯЗЫК.
## Каждое изменение сразу пишется через SettingsManager (user://settings.cfg)
## и применяется к живым шинам/окну. Esc или НАЗАД — возврат в меню.

const UITheme := preload("res://scripts/ui/theme_builder.gd")

const SPEED_STEPS := [20.0, 40.0, 70.0, 0.0]  # 0 = мгновенно

var _speed_value: Label
var _size_button: Button


func _ready() -> void:
	theme = UITheme.build()
	_build_ui()


func _build_ui() -> void:
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color("#0b0812"), Color("#110d15")])
	grad.offsets = PackedFloat32Array([0.0, 1.0])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0.5, 0.0)
	gt.fill_to = Vector2(0.5, 1.0)
	var bg := TextureRect.new()
	bg.texture = gt
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 240.0
	scroll.offset_right = -240.0
	scroll.offset_top = 40.0
	scroll.offset_bottom = -90.0
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 8)
	scroll.add_child(box)

	var title := Label.new()
	title.text = LocalizationManager.t("settings.title", "НАСТРОЙКИ")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", UITheme.COL_ACCENT_SOFT)
	box.add_child(title)
	box.add_child(_spacer(10))

	# ---------- АУДИО ----------
	box.add_child(_section(LocalizationManager.t("settings.audio", "АУДИО")))
	_volume_row(box, LocalizationManager.t("settings.master", "Общая громкость"),
		SettingsManager.master_volume, func(v: float) -> void: SettingsManager.master_volume = v)
	_volume_row(box, LocalizationManager.t("settings.music", "Музыка"),
		SettingsManager.music_volume, func(v: float) -> void: SettingsManager.music_volume = v)
	_volume_row(box, LocalizationManager.t("settings.sfx", "Звуки"),
		SettingsManager.sfx_volume, func(v: float) -> void: SettingsManager.sfx_volume = v)
	_volume_row(box, LocalizationManager.t("settings.ambience", "Атмосфера"),
		SettingsManager.ambience_volume, func(v: float) -> void: SettingsManager.ambience_volume = v)

	# ---------- ТЕКСТ ----------
	box.add_child(_section(LocalizationManager.t("settings.text", "ТЕКСТ")))
	_text_speed_row(box)
	_auto_speed_row(box)
	_size_button = Button.new()
	_size_button.custom_minimum_size = Vector2(320, 40)
	_size_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_size_button.pressed.connect(_cycle_text_size)
	box.add_child(_size_button)
	_update_size_button()
	var size_hint := Label.new()
	size_hint.text = LocalizationManager.t("settings.text_size_hint", "применяется к репликам в игре")
	size_hint.add_theme_font_size_override("font_size", 11)
	size_hint.add_theme_color_override("font_color", Color(UITheme.COL_TEXT, 0.3))
	size_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(size_hint)

	# ---------- ДИСПЛЕЙ ----------
	box.add_child(_section(LocalizationManager.t("settings.display", "ДИСПЛЕЙ")))
	_toggle_row(box, LocalizationManager.t("settings.fullscreen", "Полный экран"),
		SettingsManager.fullscreen, func(on: bool) -> void: SettingsManager.fullscreen = on)
	_toggle_row(box, LocalizationManager.t("settings.screen_shake", "Тряска экрана"),
		SettingsManager.screen_shake, func(on: bool) -> void: SettingsManager.screen_shake = on)
	_toggle_row(box, LocalizationManager.t("settings.particles", "Частицы"),
		SettingsManager.particles, func(on: bool) -> void: SettingsManager.particles = on)
	_toggle_row(box, LocalizationManager.t("settings.soft_flashes", "Мягкие вспышки"),
		SettingsManager.soft_flashes, func(on: bool) -> void: SettingsManager.soft_flashes = on)

	# ---------- ЯЗЫК ----------
	box.add_child(_section(LocalizationManager.t("settings.language", "ЯЗЫК")))
	var lang_row := HBoxContainer.new()
	lang_row.alignment = BoxContainer.ALIGNMENT_CENTER
	lang_row.add_theme_constant_override("separation", 12)
	box.add_child(lang_row)
	for lang: Array in [["ru", "РУССКИЙ"], ["en", "ENGLISH"]]:
		var b := Button.new()
		b.text = str(lang[1])
		b.custom_minimum_size = Vector2(150, 40)
		b.disabled = str(lang[0]) == SettingsManager.language
		b.pressed.connect(_set_language.bind(str(lang[0])))
		lang_row.add_child(b)

	# ---------- НАЗАД ----------
	var back := Button.new()
	back.text = LocalizationManager.t("settings.back", "НАЗАД")
	back.custom_minimum_size = Vector2(330, 44)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(_back)
	box.add_child(_spacer(8))
	box.add_child(back)
	back.call_deferred("grab_focus")


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_pause"):
		_back()


func _back() -> void:
	SettingsManager.save_settings()
	GameManager.change_scene_faded(GameManager.SCENE_MENU)


func _apply() -> void:
	SettingsManager.save_settings()
	SettingsManager.apply_settings()


# ---------- строки-помощники ----------

func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


func _section(text: String) -> VBoxContainer:
	var wrap := VBoxContainer.new()
	wrap.add_theme_constant_override("separation", 2)
	var l := Label.new()
	l.text = "— " + text + " —"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 15)
	l.add_theme_color_override("font_color", UITheme.COL_ACCENT)
	wrap.add_child(l)
	wrap.add_child(_spacer(6))
	return wrap


func _volume_row(parent: Control, label_text: String, value: float, setter: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	var l := Label.new()
	l.text = label_text
	l.custom_minimum_size = Vector2(200, 0)
	row.add_child(l)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.custom_minimum_size = Vector2(160, 24)
	row.add_child(slider)
	var pct := Label.new()
	pct.text = "%d%%" % int(round(value * 100.0))
	pct.custom_minimum_size = Vector2(56, 0)
	row.add_child(pct)
	slider.value_changed.connect(func(v: float) -> void:
		pct.text = "%d%%" % int(round(v * 100.0))
		setter.call(v)
		_apply()
	)
	parent.add_child(row)


func _text_speed_row(parent: Control) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	var l := Label.new()
	l.text = LocalizationManager.t("settings.text_speed", "Скорость текста")
	l.custom_minimum_size = Vector2(200, 0)
	row.add_child(l)
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 3
	slider.step = 1
	slider.custom_minimum_size = Vector2(160, 24)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	# Текущее значение: мгновенно -> 3, иначе ищем шаг.
	var current := 1
	if SettingsManager.instant_text:
		current = 3
	else:
		for i in 3:
			if absf(SettingsManager.text_speed - float(SPEED_STEPS[i])) < 0.5:
				current = i
				break
	slider.value = current
	_speed_value = Label.new()
	_speed_value.custom_minimum_size = Vector2(120, 0)
	_speed_value.text = _speed_name(int(current))
	row.add_child(_speed_value)
	slider.value_changed.connect(func(v: float) -> void:
		var idx := int(v)
		_speed_value.text = _speed_name(idx)
		var sp := float(SPEED_STEPS[idx])
		if sp <= 0.0:
			SettingsManager.instant_text = true
		else:
			SettingsManager.instant_text = false
			SettingsManager.text_speed = sp
		_apply()
	)
	parent.add_child(row)


func _speed_name(idx: int) -> String:
	match idx:
		0: return LocalizationManager.t("speed.slow", "медленно")
		2: return LocalizationManager.t("speed.fast", "быстро")
		3: return LocalizationManager.t("speed.instant", "мгновенно")
		_: return LocalizationManager.t("speed.normal", "обычно")


func _auto_speed_row(parent: Control) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	var l := Label.new()
	l.text = LocalizationManager.t("settings.auto_speed", "Скорость авто-режима")
	l.custom_minimum_size = Vector2(200, 0)
	row.add_child(l)
	var slider := HSlider.new()
	slider.min_value = 0.5
	slider.max_value = 3.0
	slider.step = 0.1
	slider.value = SettingsManager.auto_speed
	slider.custom_minimum_size = Vector2(160, 24)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var mult := Label.new()
	mult.custom_minimum_size = Vector2(120, 0)
	mult.text = "× %.1f" % SettingsManager.auto_speed
	row.add_child(mult)
	slider.value_changed.connect(func(v: float) -> void:
		mult.text = "× %.1f" % v
		SettingsManager.auto_speed = v
		_apply()
	)
	parent.add_child(row)


func _update_size_button() -> void:
	var names := [
		LocalizationManager.t("textsize.s", "размер: обычный"),
		LocalizationManager.t("textsize.m", "размер: крупный"),
		LocalizationManager.t("textsize.l", "размер: огромный"),
	]
	var idx: int = clampi(SettingsManager.text_size, 0, 2)
	_size_button.text = names[idx]


func _cycle_text_size() -> void:
	SettingsManager.text_size = (SettingsManager.text_size + 1) % 3
	_update_size_button()
	_apply()
	AudioManager.play_sfx("click")


func _toggle_row(parent: Control, label_text: String, checked: bool, setter: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var l := Label.new()
	l.text = label_text
	l.custom_minimum_size = Vector2(280, 0)
	row.add_child(l)
	var check := CheckButton.new()
	check.button_pressed = checked
	check.toggled.connect(func(on: bool) -> void:
		setter.call(on)
		_apply()
		AudioManager.play_sfx("click")
	)
	row.add_child(check)
	parent.add_child(row)


func _set_language(lang: String) -> void:
	if lang == SettingsManager.language:
		return
	SettingsManager.set_language(lang)
	AudioManager.play_sfx("click")
	# Перестраиваем экран под новый язык.
	get_tree().reload_current_scene()
