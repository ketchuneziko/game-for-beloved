extends Node
## LocalizationManager (autoload)
## Загружает UI-строки из data/locales/<lang>.json и разрешает
## двуязычные поля вида {"ru": "...", "en": "..."} во всех данных игры.
## Русский — канон и язык по умолчанию (см. GDD §9.8).

signal locale_changed(new_locale: String)

const LOCALES_DIR := "res://data/locales"
const DEFAULT_LOCALE := "ru"
const SUPPORTED := ["ru", "en"]

var locale: String = DEFAULT_LOCALE
var _strings: Dictionary = {}


func _ready() -> void:
	_load_locale(locale)


func set_locale(new_locale: String) -> void:
	if new_locale == locale:
		return
	if not SUPPORTED.has(new_locale):
		push_warning("LocalizationManager: unsupported locale '%s'" % new_locale)
		return
	locale = new_locale
	_load_locale(locale)
	locale_changed.emit(locale)


func _load_locale(lang: String) -> void:
	_strings = {}
	var path := "%s/%s.json" % [LOCALES_DIR, lang]
	if not FileAccess.file_exists(path):
		push_warning("LocalizationManager: locale file missing (%s) — keys will be used" % path)
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		_strings = parsed
	else:
		push_error("LocalizationManager: bad locale file %s" % path)


## Перевод UI-ключа: t("menu.play") -> "ИГРАТЬ".
## Если ключа нет — возвращает fallback, иначе сам ключ.
func t(key: String, fallback: String = "") -> String:
	if _strings.has(key):
		return str(_strings[key])
	return fallback if fallback != "" else key


## Разрешает инлайновое двуязычное значение:
##   "просто строка"          -> как есть
##   {"ru": "...", "en": "..."} -> текущий язык, fallback на ru
func field(value: Variant) -> String:
	if value is Dictionary:
		if value.has(locale):
			return str(value[locale])
		if value.has(DEFAULT_LOCALE):
			return str(value[DEFAULT_LOCALE])
		if value.is_empty():
			return ""
		return str(value.values()[0])
	if value == null:
		return ""
	return str(value)
