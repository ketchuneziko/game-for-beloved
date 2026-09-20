#!/bin/bash
# Сборка релиза на macOS (GDD Phase 12).
# Использование:
#   bash scripts/build/build_mac.sh check     — только валидация данных
#   bash scripts/build/build_mac.sh macos     — сборка .app (release-экспорт)
#   bash scripts/build/build_mac.sh windows   — сборка одиночного .exe
#   bash scripts/build/build_mac.sh release   = check + macos + windows
# Опционально: GODOT=/путь/к/Godot bash scripts/build/build_mac.sh macos
set -euo pipefail

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
PROJ="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJ"
mkdir -p exports

say() { printf "\n\033[1;35m== %s ==\033[0m\n" "$*"; }

if [ ! -x "$GODOT" ]; then
	echo "Godot не найден: $GODOT"
	echo "Скачай с https://godotengine.org/download и положи в /Applications,"
	echo "или укажи путь: GODOT=/путь/к/Godot bash $0 macos"
	exit 1
fi

TEMPLATES_DIR="$HOME/Library/Application Support/Godot/export_templates/4.3.stable"
if [ ! -d "$TEMPLATES_DIR" ]; then
	echo "Export templates 4.3 не найдены в:"
	echo "  $TEMPLATES_DIR"
	echo "Установи: Editor → Manage Export Templates → Install from file"
	echo "(см. docs/BUILD.md, раздел 1)"
	exit 1
fi

case "${1:-}" in
check)
	say "Валидация данных"
	"$GODOT" --headless --path "$PROJ" --script tests/validate_data.gd
	;;
macos)
	say "Сборка macOS (universal, ad-hoc подпись)"
	"$GODOT" --headless --path "$PROJ" --export-release "macOS" "exports/ToEternityAndBeyond.app"
	say "Готово: exports/ToEternityAndBeyond.app"
	echo "Рядом положи КАК ОТКРЫТЬ.txt и заархивируй в zip перед отправкой."
	;;
windows)
	say "Сборка Windows (одиночный exe, PCK вшит)"
	"$GODOT" --headless --path "$PROJ" --export-release "Windows Desktop" "exports/ToEternityAndBeyond.exe"
	say "Готово: exports/ToEternityAndBeyond.exe"
	;;
release)
	say "Валидация"
	"$GODOT" --headless --path "$PROJ" --script tests/validate_data.gd
	say "Сборка macOS"
	"$GODOT" --headless --path "$PROJ" --export-release "macOS" "exports/ToEternityAndBeyond.app"
	say "Сборка Windows"
	"$GODOT" --headless --path "$PROJ" --export-release "Windows Desktop" "exports/ToEternityAndBeyond.exe"
	say "Всё собрано в exports/"
	ls -la exports/
	;;
*)
	echo "Использование: bash $0 {check|macos|windows|release}"
	exit 2
	;;
esac
