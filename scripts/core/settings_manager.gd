extends Node
## SettingsManager (autoload)
## Пользовательские настройки: звук, текст, дисплей, язык.
## Хранение: user://settings.cfg (ConfigFile).
## Здесь применяются локаль и дисплей; громкости шин применяет
## AudioManager (он подписан на settings_changed и уже создан к моменту
## любых изменений из UI).

signal settings_changed

const SETTINGS_PATH := "user://settings.cfg"

## Скорость текста, символов в секунду (медленно / обычно / быстро). 0 = мгновенно.
const TEXT_SPEED_VALUES := [20.0, 40.0, 70.0]
## Базовые размеры шрифта для доступности (3 ступени).
const TEXT_SIZE_VALUES := [17, 20, 24]

var master_volume := 0.9      # 0..1
var music_volume := 0.8
var sfx_volume := 0.9
var ambience_volume := 0.7
var text_speed := 40.0        # символов/сек; 0 = мгновенно
var instant_text := false     # показывать реплики сразу целиком
var auto_speed := 1.0         # множитель скорости AUTO-режима
var text_size := 1            # индекс в TEXT_SIZE_VALUES
var fullscreen := false
var screen_shake := true      # доступность: тряска экрана on/off
var particles := true         # доступность: частицы on/off
var soft_flashes := false     # доступность: мягкие вспышки вместо белых
var language := "ru"


func _ready() -> void:
	load_settings()
	# Тесты/CI: TB_LANG=en переопределяет язык (без записи в настройки).
	var env_lang := OS.get_environment("TB_LANG")
	if env_lang in LocalizationManager.SUPPORTED:
		language = env_lang
		LocalizationManager.set_locale(env_lang)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		master_volume = float(cfg.get_value("audio", "master", master_volume))
		music_volume = float(cfg.get_value("audio", "music", music_volume))
		sfx_volume = float(cfg.get_value("audio", "sfx", sfx_volume))
		ambience_volume = float(cfg.get_value("audio", "ambience", ambience_volume))
		text_speed = float(cfg.get_value("text", "speed", text_speed))
		instant_text = bool(cfg.get_value("text", "instant", instant_text))
		auto_speed = float(cfg.get_value("text", "auto_speed", auto_speed))
		text_size = int(cfg.get_value("text", "size", text_size))
		fullscreen = bool(cfg.get_value("display", "fullscreen", fullscreen))
		screen_shake = bool(cfg.get_value("display", "screen_shake", screen_shake))
		particles = bool(cfg.get_value("display", "particles", particles))
		soft_flashes = bool(cfg.get_value("display", "soft_flashes", soft_flashes))
		language = str(cfg.get_value("general", "language", language))
	apply_settings()


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("audio", "ambience", ambience_volume)
	cfg.set_value("text", "speed", text_speed)
	cfg.set_value("text", "instant", instant_text)
	cfg.set_value("text", "auto_speed", auto_speed)
	cfg.set_value("text", "size", text_size)
	cfg.set_value("display", "fullscreen", fullscreen)
	cfg.set_value("display", "screen_shake", screen_shake)
	cfg.set_value("display", "particles", particles)
	cfg.set_value("display", "soft_flashes", soft_flashes)
	cfg.set_value("general", "language", language)
	cfg.save(SETTINGS_PATH)


func apply_settings() -> void:
	LocalizationManager.set_locale(language)
	_apply_display()
	settings_changed.emit()


func set_language(lang: String) -> void:
	language = lang
	save_settings()
	apply_settings()


func text_speed_value() -> float:
	return 0.0 if instant_text else text_speed


func base_font_size() -> int:
	var idx := clampi(text_size, 0, TEXT_SIZE_VALUES.size() - 1)
	return int(TEXT_SIZE_VALUES[idx])


func _apply_display() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var target := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != target:
		DisplayServer.window_set_mode(target)
