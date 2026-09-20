extends Control
## Звёздное поле главного меню (GDD §8.2): медленный дрейф, мерцание,
## редкие падающие звёзды. Вся отрисовка — в одном узле через _draw(),
## без сотен дочерних нод. warm = рассветный вариант после финала.

const UITheme := preload("res://scripts/ui/theme_builder.gd")

@export var star_count := 130
@export var warm := false

var _stars: Array = []   # {pos: Vector2, r, phase, twinkle, alpha, depth}
var _shoots: Array = []  # {pos: Vector2, vel: Vector2, life}
var _time := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rng.randomize()
	for i in star_count:
		_stars.append({
			"pos": Vector2(_rng.randf_range(0.0, 1280.0), _rng.randf_range(0.0, 720.0)),
			"r": _rng.randf_range(0.8, 2.1),
			"phase": _rng.randf() * TAU,
			"twinkle": _rng.randf_range(0.5, 1.7),
			"alpha": _rng.randf_range(0.22, 0.8),
			"depth": _rng.randf_range(0.35, 1.0),
		})
	_schedule_shooting()


func _schedule_shooting() -> void:
	var t := get_tree().create_timer(_rng.randf_range(5.0, 12.0))
	# Bound-метод (не лямбда): при освобождении сцены вызов безопасно отпадёт.
	t.timeout.connect(_spawn_shooting)


func _spawn_shooting() -> void:
	if not is_inside_tree():
		return
	if SettingsManager.particles:
		_shoots.append({
			"pos": Vector2(_rng.randf_range(0.35, 1.0) * size.x, _rng.randf_range(0.0, 0.35) * size.y),
			"vel": Vector2(_rng.randf_range(-540.0, -400.0), _rng.randf_range(150.0, 240.0)),
			"life": 1.15,
		})
	_schedule_shooting()


func _process(delta: float) -> void:
	_time += delta
	var w := maxf(size.x, 1.0)
	var h := maxf(size.y, 1.0)
	for s: Dictionary in _stars:
		var p: Vector2 = s["pos"]
		p.x = fposmod(p.x - 5.0 * delta * s["depth"], w)
		p.y = fposmod(p.y + 1.6 * delta * s["depth"], h)
		s["pos"] = p
	for i in range(_shoots.size() - 1, -1, -1):
		var sh: Dictionary = _shoots[i]
		sh["pos"] = sh["pos"] + sh["vel"] * delta
		sh["life"] = float(sh["life"]) - delta
		if float(sh["life"]) <= 0.0:
			_shoots.remove_at(i)
	queue_redraw()


func _draw() -> void:
	var base := Color("#ffd9c4") if warm else UITheme.COL_TEXT
	for s: Dictionary in _stars:
		var tw: float = 0.62 + 0.38 * sin(_time * float(s["twinkle"]) + float(s["phase"]))
		var a: float = float(s["alpha"]) * tw
		var r: float = float(s["r"])
		# Мягкое гало у самых ярких.
		if r > 1.7:
			draw_circle(s["pos"], r * 2.8, Color(base, a * 0.14))
		draw_circle(s["pos"], r, Color(base, a))
	for sh: Dictionary in _shoots:
		var k: float = clampf(float(sh["life"]) / 1.15, 0.0, 1.0)
		var tail: Vector2 = (sh["vel"] as Vector2).normalized() * 70.0
		draw_line(sh["pos"], sh["pos"] + tail, Color(base, 0.65 * k), 1.4)
		draw_circle(sh["pos"], 1.8, Color(base, 0.9 * k))
