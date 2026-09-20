# Сборка релиза

Ты собираешь на **macOS**. Всё подготовлено: пресеты — `export_presets.cfg`,
скрипт — `scripts/build/build_mac.sh`. Личные данные кладутся по путям из README
(фото, песня, `data/custom/`) — они автоматически попадают в сборку.

---

## 1. Разовая подготовка (5 минут)

1. Скачай **Godot 4.3 stable (стандартный, не .NET)**: <https://godotengine.org/download>
   и перетащи `Godot.app` в `/Applications`.
2. Скачай **Export templates** для 4.3:
   <https://godotengine.org/download> → колонка «Export templates» →
   `Godot_v4.3-stable_export_templates.tpz`.
3. Открой проект: Godot → Import → выбери папку проекта (`project.godot`) → Edit.
4. Дождись, пока Godot импортирует ассеты (полоса прогресса внизу), затем:
   **Editor → Manage Export Templates… → Install from file** → выбери `.tpz` из п. 2.

## 2. macOS (главная сборка)

### Вариант А — скриптом (одна команда)

```bash
cd путь/к/game-for-beloved
bash scripts/build/build_mac.sh release
```

Скрипт сам проверит Godot и шаблоны, соберёт `.app` в `exports/` и сделает ad-hoc
подпись (identity `-`) — это без аккаунта разработчика Apple.

### Вариант Б — через редактор

**Project → Export… → macOS → Export Project…** → выбери папку `exports/`.

## 3. Отправить Марии

Приложи к `.app` (или заархивируй всё в zip вместе с) файл **`КАК ОТКРЫТЬ.txt`**
(лежит в корне репозитория) — он объясняет ей, что делать с предупреждением macOS.

> **Почему macOS ругается:** приложение подписано ad-hoc (без аккаунта Apple
> Developer за $99/год), поэтому Gatekeeper просит подтверждение. Решение —
> правый клик по `.app` → **«Открыть»** → ещё раз «Открыть».
> Либо в Терминале: `xattr -dr com.apple.quarantine /путь/к/ToEternityAndBeyond.app`
> (работает, если отправлять **zip**-архивом: тогда quarantine-метка может вообще не появиться).

**Проверенная связка:** заархивируй `ToEternityAndBeyond.app` + `КАК ОТКРЫТЬ.txt`
в zip (правый клик → «Сжать»), отправь как есть.

## 4. Windows (собирается с Mac — это нормально)

Godot экспортирует Windows-сборки прямо из macOS, ничего дополнительно не нужно:

- Вариант А: `bash scripts/build/build_mac.sh windows`
- Вариант Б: **Project → Export… → Windows Desktop → Export Project…**

Получится одиночный `ToEternityAndBeyond.exe` (PCK вшит). Подписывать не нужно —
Windows SmartScreen может ворчать, там стандартное «Всё равно выполнить».

## 5. Android (по желанию)

1. Установи Android Studio (для JDK и SDK) → в Godot:
   **Editor → Editor Settings → Export → Android**: укажи Android SDK path.
2. **Project → Install Android Build Template** (нужно для сборки).
3. Для теста на телефоне хватит debug-сборки: **Export… → Android** → `ToEternityAndBeyond.apk`
   → скинуть на телефон → разрешить установку из неизвестных источников.
4. Для «настоящего» релиза нужен keystore: `keytool -genkeypair -v -keystore release.keystore -alias eternity`
   и заполнение Keystore-полей в пресете.

Игра уже тач-совместима (UI проверялся под горизонтальную ориентацию, 1280×720 expand).

---

## Чеклист релиза

- [ ] В `data/custom/about.json` — её имя, вопрос, финальные строки, посвящение
- [ ] В `data/custom/song.json` — ваша песня и таймкоды (или плейсхолдер)
- [ ] `assets/photos/` — настоящие фотографии (или плейсхолдеры)
- [ ] Прогон: `bash scripts/build/build_mac.sh check` (валидация данных)
- [ ] Полное прохождение сборки своими руками (2 раза: раз — сразу PLAY, раз — CONTINUE из автосейва)
- [ ] `.app` + `КАК ОТКРЫТЬ.txt` → zip → отправлено

## Известные ограничения

- Windows-версия собирается с Mac — официальная возможность Godot, кросс-инструменты не нужны.
- Без платного аккаунта Apple Developer .app подписывается ad-hoc → «правый клик → Открыть».
- Экспорт из этой песочницы-репозитория (Linux CI) невозможен: нет Apple SDK/mingw —
  сборка выполняется на Mac, где и живёт игра.
