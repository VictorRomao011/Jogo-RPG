class_name WeatherSim
extends RefCounted
## Clima regional. Não é cosmético: expõe modificadores consumidos pela
## economia (produção), pelas viagens (velocidade de caravanas), pela
## percepção de NPCs e pela sobrevivência do jogador.

signal weather_changed(region_id: String, weather: String)

const WEATHERS := ["clear", "cloudy", "rain", "storm", "fog", "snow", "dust"]

## Pesos de transição por estação (índice = estação do WorldClock).
## Cada região pode restringir os climas possíveis (ex.: deserto não neva).
const SEASON_WEIGHTS := [
	{"clear": 3, "cloudy": 3, "rain": 3, "storm": 1, "fog": 2, "snow": 1, "dust": 1},
	{"clear": 6, "cloudy": 2, "rain": 1, "storm": 2, "fog": 1, "snow": 0, "dust": 2},
	{"clear": 4, "cloudy": 3, "rain": 2, "storm": 1, "fog": 2, "snow": 0, "dust": 1},
	{"clear": 2, "cloudy": 3, "rain": 1, "storm": 1, "fog": 2, "snow": 5, "dust": 0},
]

var _region_weather: Dictionary = {}
var _region_allowed: Dictionary = {}
var _rng: RandomNumberGenerator


func _init(rng: RandomNumberGenerator) -> void:
	_rng = rng


func register_region(region_id: String, allowed_weathers: Array) -> void:
	_region_allowed[region_id] = allowed_weathers
	_region_weather[region_id] = "clear"


func current(region_id: String) -> String:
	return _region_weather.get(region_id, "clear")


## Sorteia clima novo por região; chamado a cada poucas horas de jogo.
func tick(season: int) -> void:
	var weights: Dictionary = SEASON_WEIGHTS[season % SEASON_WEIGHTS.size()]
	for region_id: String in _region_weather.keys():
		var allowed: Array = _region_allowed.get(region_id, WEATHERS)
		var total := 0.0
		for w: String in allowed:
			total += weights.get(w, 0)
		if total <= 0.0:
			continue
		var roll := _rng.randf() * total
		for w: String in allowed:
			roll -= weights.get(w, 0)
			if roll <= 0.0:
				if _region_weather[region_id] != w:
					_region_weather[region_id] = w
					weather_changed.emit(region_id, w)
				break


## Multiplicador de produção agrícola/externa (1.0 = normal).
func production_modifier(region_id: String) -> float:
	match current(region_id):
		"rain":
			return 0.85
		"storm", "snow":
			return 0.5
		"dust":
			return 0.7
		_:
			return 1.0


## Multiplicador de velocidade de viagem em estradas da região.
func travel_modifier(region_id: String) -> float:
	match current(region_id):
		"rain", "fog":
			return 0.8
		"storm", "dust":
			return 0.55
		"snow":
			return 0.45
		_:
			return 1.0


## Multiplicador de percepção (visão/audição) de NPCs — sistemas conversam:
## tempestade favorece furtividade e emboscadas.
func perception_modifier(region_id: String) -> float:
	match current(region_id):
		"fog":
			return 0.5
		"storm", "dust", "snow":
			return 0.6
		"rain":
			return 0.75
		_:
			return 1.0


func to_dict() -> Dictionary:
	return {"weather": _region_weather.duplicate()}


func from_dict(data: Dictionary) -> void:
	var saved: Dictionary = data.get("weather", {})
	for k: String in saved.keys():
		_region_weather[k] = saved[k]
