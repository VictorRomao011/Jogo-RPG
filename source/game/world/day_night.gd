class_name DayNightCycle
extends Node
## Dia e noite REAIS: o sol segue o WorldClock da simulação (mesmo relógio
## das rotinas dos NPCs), e o clima da região vira névoa e luz na cena.
## Nada de skybox estático — o tempo que passa é o tempo do mundo.

const WEATHER_CHECK_SECONDS := 4.0

var _sun: DirectionalLight3D
var _moon: DirectionalLight3D
var _env: Environment
var _weather_timer := 0.0
var _fog_target := 0.002
var _weather_dim := 1.0


func _ready() -> void:
	_sun = get_node_or_null("../Sun")
	_moon = get_node_or_null("../Moon")
	var world_env: WorldEnvironment = get_node_or_null("../WorldEnvironment")
	if world_env != null and world_env.environment != null:
		_env = world_env.environment
		_env.fog_enabled = true
		_env.fog_density = 0.002
		_env.fog_light_color = Color(0.75, 0.78, 0.82)


func _process(delta: float) -> void:
	var f: float = Sim.world.clock.day_fraction()
	_update_sun(f)
	_weather_timer -= delta
	if _weather_timer <= 0.0:
		_weather_timer = WEATHER_CHECK_SECONDS
		_read_weather()
	if _env != null:
		_env.fog_density = lerpf(_env.fog_density, _fog_target, delta * 0.5)


func _update_sun(f: float) -> void:
	if _sun == null:
		return
	# f=0.25 (6h) nasce no horizonte; f=0.5 (12h) a pino; f=0.75 (18h) se põe.
	var elevation := sinf((f - 0.25) * TAU)
	_sun.rotation = Vector3(
		-deg_to_rad(maxf(elevation, -0.15) * 80.0 + 5.0), deg_to_rad(35.0), 0.0
	)
	var day_strength := clampf(elevation, 0.0, 1.0)
	_sun.light_energy = (0.08 + 1.15 * day_strength) * _weather_dim
	# Amanhecer/entardecer alaranjados; noite azulada.
	if day_strength > 0.25:
		_sun.light_color = Color(1.0, 0.97, 0.9)
	elif day_strength > 0.0:
		_sun.light_color = Color(1.0, 0.75, 0.55)
	else:
		_sun.light_color = Color(0.55, 0.62, 0.85)
	if _env != null:
		_env.background_energy_multiplier = (0.16 + 0.9 * day_strength) * _weather_dim
	# Lua assume à noite; janelas da vila acendem com o escuro.
	if _moon != null:
		_moon.light_energy = 0.28 * (1.0 - day_strength) * _weather_dim
	var glow := clampf(1.0 - day_strength * 1.8, 0.0, 1.0) * 1.8
	get_tree().call_group("village", "set_window_glow", glow)


func _read_weather() -> void:
	match Sim.world.weather.current("pelagem_cinza"):
		"fog":
			_fog_target = 0.035
			_weather_dim = 0.75
		"rain":
			_fog_target = 0.012
			_weather_dim = 0.65
		"storm":
			_fog_target = 0.02
			_weather_dim = 0.45
		"cloudy":
			_fog_target = 0.005
			_weather_dim = 0.85
		_:
			_fog_target = 0.002
			_weather_dim = 1.0
