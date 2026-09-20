# Формат данных — справочник

Вся история и весь личный контент живут в JSON. Этот документ — контракт между
тобой (правки текста) и движком (который тексты читает). После правки любого файла
прогоняй валидатор:

```bash
godot --headless --path . --script tests/validate_data.gd
```

Общие правила:

- Любое поле с текстом игрока может быть **строкой** (`"Привет"`) или **двуязычным
  объектом** (`{"ru": "Привет", "en": "Hi"}`). Русский — канон; при отсутствии текущего
  языка используется `ru`.
- Ключи вида `"_readme"` движок игнорирует — там можно оставлять себе заметки.
- Незнакомые движку значения не ломают игру: они попадают в лог с пометкой
  (в headless-автотесте — ошибка валидации).

---

## 1. Сценарии глав — `data/dialogue/chapter_XX.json`

Одна глава — один файл: `chapter_00.json` (пролог) … `chapter_07.json`. Файлы с
главами, которых ещё нет, просто не открываются (переход `chapter_end` в них
пока завершает эпизод).

```json
{
  "chapter": 1,
  "title": { "ru": "CHAPTER 1 — THE BEGINNING", "en": "..." },
  "steps": [ { ... }, { ... } ]
}
```

### Типы шагов

| Тип | Поля | Что делает |
|---|---|---|
| `line` | `who`, `text`, `pause_after?` | Реплика. `who` — id из `characters.json`. `pause_after` — пауза после клика (сек, Фаза 4) |
| `choice` | `id` | Показать выбор из `choices.json` |
| `bg` | `id` | Сменить фон (`bg_planetarium_night`, `bg_dome_stars`, `bg_rain_window`, `bg_street_night`, `bg_rooftop_dawn`, `bg_bedroom_morning`, `memory`, `black`) |
| `music` | `id`, `fade?` | Музыка (`assets/music/<id>.ogg`): кроссфейд out → смена → in |
| `sfx` | `id` | Звук (`assets/sounds/<id>.ogg`) |
| `show` / `hide` | `who`, `expr?` | Вход/выход персонажа на сцену (Фаза 4 — спрайты) |
| `expr` | `who`, `expr` | Смена выражения: `neutral, happy, sad, surprised, thinking, embarrassed, smiling` |
| `transition` | `kind` | `fade / dissolve / slide / blur / white_flash` между сценами (Фаза 4) |
| `wait` | `duration` | Пауза, сек |
| `title_card` | `text`, `sub?` | Крупная надпись по центру (титры пролога и т.п.) |
| `fragment` | `id` (1–7) | Найти фрагмент сообщения. 7 штук за игру |
| `achievement` | `id` | Разблокировать достижение (`achievements.json`) |
| `unlock_photo` / `unlock_memory` / `unlock_letter` / `unlock_secret` | `id` | Открыть элемент галереи |
| `puzzle` | `id` | Запустить загадку (Фаза 7) |
| `minigame` | `id` | Запустить мини-игру (Фаза 7) |
| `label` | `id` | Метка для прыжков (игроком не видна) |
| `jump` | `label` | Безусловный прыжок на метку |
| `if_flag` | `flag`, `jump_if_true?`, `jump_if_false?` | Ветвление по флагу выбора |
| `chapter_end` | `next` | Конец главы: `next` — номер следующей или `-1` |

Пример связки «выбор → ветка → слияние»:

```json
{ "type": "choice", "id": "ch1_how_it_started" },
{ "type": "if_flag", "flag": "ch1_asked_story", "jump_if_true": "branch_tell", "jump_if_false": "branch_common" },
{ "type": "label", "id": "branch_tell" },
{ "type": "line", "who": "author", "text": { "ru": "…" } },
{ "type": "jump", "label": "merge" },
{ "type": "label", "id": "branch_common" },
{ "type": "line", "who": "author", "text": { "ru": "…" } },
{ "type": "label", "id": "merge" }
```

> Смена таблички имени (ГОЛОС → ОН → АВТОР → настоящее имя) и тексты финала берутся
> из `data/custom/about.json` — правится там.

---

## 2. Выборы — `data/choices/choices.json`

```json
"ch1_how_it_started": {
  "prompt": { "ru": "Ты помнишь, как всё началось?" },
  "options": [
    { "id": "of_course", "text": { "ru": "Конечно" }, "set_flags": ["ch1_remembered"] },
    { "id": "not_quite", "text": { "ru": "Не совсем" }, "set_flags": ["ch1_not_quite"] }
  ]
}
```

- `set_flags` — список флагов, которые выставятся в состояние прохождения
  (проверяются `if_flag`, сохраняются в сейвах).
- `unlock_secret` — опционально, открыть секрет в галерее.
- Правило GDD: выборы меняют диалог и мелкие сцены, ветвящегося дерева нет.

---

## 3. Персонажи — `data/characters.json`

```json
"author": { "name": { "ru": "ОН", "en": "HE" }, "color": "#ff8fbd" },
"voice":  { "name": { "ru": "", "en": "" }, "color": "#ffb9d5", "plate_hidden": true }
```

`color` — цвет таблички имени. `plate_hidden: true` — плашку не показывать.

---

## 4. Воспоминания — `data/memories/memories.json`

```json
{
  "id": "mem_01",
  "photo": "res://assets/photos/photo_01.jpg",
  "date": "14.02.2024",
  "caption": { "ru": "подпись с оборота фотографии" },
  "scene": "mem_01"
}
```

`scene` — id сцен-воспоминаний (короткие диалоги, добавляются в Фазе 6).

---

## 5. Достижения — `data/achievements/achievements.json`

```json
{ "id": "first_step", "hidden": false,
  "name": { "ru": "FIRST STEP" }, "desc": { "ru": "Сделать первый шаг." } }
```

`hidden: true` — название показывается как `???` до разблокировки.
Правило GDD: 8–12 достижений, скрытые — за любопытство.

---

## 6. Личное — `data/custom/`

| Файл | Назначение |
|---|---|
| `about.json` | Её имя, титул/подзаголовок, табличка автора, финальный вопрос, кнопки ДА, финальные строки, посвящение, `secret_word` (кодовое слово для секрета в меню) |
| `song.json` | Глава 5: `track` (путь к ogg) и `lines` — `[{"time": 0.0, "text": "оригинал", "translation": "русский перевод"}]`. `time` — секунды от начала трека, строго по возрастанию. Синхронизация — по позиции аудио, без таймеров |
| `letters.json` | Глава 3: `ch3_cipher.phrase` (что должно получиться из шифра). Глава 4: `ch4_letters` — письма. Главы 1–6: `final_message` — 7 фрагментов, собираемых в Главе 6 |

---

## 7. Куда класть ассеты

| Путь | Что |
|---|---|
| `assets/backgrounds/<bg_id>.png` | Фоны (id из списка `bg`-шага) |
| `assets/characters/<who>/<expr>.png` | Спрайты-выражения (Фаза 4) |
| `assets/photos/*.jpg` | Фотографии |
| `assets/music/*.ogg` | Музыка: `menu, prologue, chapter1, chapter2, chapter4_piano, chapter6, memory, puzzle, song, final, credits` |
| `assets/sounds/*.ogg` | Звуки: `button, click, dialogue, typing, puzzle_solved, photo, page, notification, heart, transition` + `ambience_<id>.ogg` |
| `assets/fonts/*.ttf` | `JetBrainsMono-Regular.ttf`, `JetBrainsMono-Bold.ttf`, `PressStart2P-Regular.ttf` — подхватываются автоматически |

Пока файла нет — движок тихо пропускает (одно предупреждение в лог на файл).

## 8. Сейвы и прогресс (куда смотрит движок)

| Путь | Что |
|---|---|
| `user://saves/save_0..4.json` | Ручные слоты |
| `user://saves/save_quick.json` / `save_auto.json` | Quick / Auto |
| `user://saves/save_*.png` | PNG-превью слотов |
| `user://settings.cfg` | Настройки |
| `user://progress.json` | Мета-прогресс: увиденные строки, ачивки, галерея, фрагменты текущего прогона в слотах |
