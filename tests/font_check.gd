extends SceneTree
## Проверка загрузки шрифтов (в т.ч. без импорта редактора):
##   godot --headless --path . --script tests/font_check.gd


func _initialize() -> void:
	var fail := false
	for p in [
		"res://assets/fonts/JetBrainsMono-Regular.ttf",
		"res://assets/fonts/JetBrainsMono-Bold.ttf",
		"res://assets/fonts/PressStart2P-Regular.woff2",
	]:
		if not FileAccess.file_exists(p):
			print("FONT MISSING ", p)
			fail = true
			continue
		var f := FontFile.new()
		var err := f.load_dynamic_font(p)
		if err == OK:
			var has_cyr: bool = f.has_char("Я".unicode_at(0))
			print("FONT OK    %s (кириллица: %s)" % [p, "да" if has_cyr else "нет"])
		else:
			print("FONT FAIL  %s (err=%d)" % [p, err])
			fail = true
	# Press Start 2P — латиница, кириллицы быть не должно (это норма).
	quit(1 if fail else 0)
