#!/bin/bash
# Автотест-скрипт Фазы 2: прогон валидатора + boot→меню + полный VN-прогон.
# Использование: bash tests/run_headless.sh /path/to/godot_binary
set -u
GODOT="${1:-/tmp/godot-src/bin/godot.linuxbsd.template_debug.x86_64}"
PROJ="$(cd "$(dirname "$0")/.." && pwd)"
fail=0

echo "== 1. validate_data =="
"$GODOT" --headless --path "$PROJ" --script tests/validate_data.gd 2>&1
[ $? -ne 0 ] && fail=1

echo "== 2. boot -> main menu (12 sec) =="
"$GODOT" --headless --path "$PROJ" --quit-after 720 > /tmp/t_menu.log 2>&1
# «Could not load global script cache» — норм для template-бинарника без редактора.
if grep -i "ERROR" /tmp/t_menu.log | grep -iv "global script cache\|get_global_class_list" | grep -q .; then
	echo "--- ошибки:"; grep -i "ERROR" /tmp/t_menu.log | head -10; fail=1
fi
echo "menu log lines: $(wc -l < /tmp/t_menu.log)"

echo "== 3. VN scaffold полный прогон (autotest) =="
timeout 120 "$GODOT" --headless --path "$PROJ" res://scenes/visual_novel/vn_stage.tscn --quit-after 6000 > /tmp/t_vn.log 2>&1
grep -q "AUTOTEST: scaffold run complete" /tmp/t_vn.log && echo "AUTOTEST OK" || { echo "AUTOTEST FAIL"; fail=1; }
grep -i "SCRIPT ERROR" /tmp/t_vn.log | head -10
grep -q "AUTOTEST: chapter 0 -> 1" /tmp/t_vn.log && echo "chapter transition OK" || { echo "chapter transition FAIL"; fail=1; }
echo "--- vn log (хвост):"
tail -6 /tmp/t_vn.log

echo "== 4. шрифты =="
"$GODOT" --headless --path "$PROJ" --script tests/font_check.gd 2>&1 | grep -i "FONT"
"$GODOT" --headless --path "$PROJ" --script tests/font_check.gd > /dev/null 2>&1 || fail=1

echo "== 5. настройки, титры, главы (soak) =="
for sc in scenes/ui/settings_menu.tscn scenes/ui/credits.tscn scenes/ui/chapter_select.tscn; do
	timeout 60 "$GODOT" --headless --path "$PROJ" "res://$sc" --quit-after 300 > /tmp/t_scene.log 2>&1
	if grep -i "SCRIPT ERROR\|Parse Error" /tmp/t_scene.log | grep -q .; then
		echo "--- $sc:"; grep -i "ERROR" /tmp/t_scene.log | head -6; fail=1
	else
		echo "$sc OK"
	fi
done

echo "== ИТОГ: $([ $fail -eq 0 ] && echo PASS || echo FAIL) =="
exit $fail
