class_name EventTemplate
extends RefCounted
## Template parametrizável de evento dinâmico. O template define a forma;
## atores, local, clima e desfecho vêm da simulação — por isso o "mesmo"
## evento nunca se repete igual (GDD §12).

var id: String
var category: String  # "economic", "conflict", "natural", "echo", "social"
## Pressões que habilitam o evento e seus pesos.
var triggers: Dictionary = {}
var base_weight := 1.0
var cooldown_days := 5
var description_template := ""

var _last_fired_day := -999


static func from_data(data: Dictionary) -> EventTemplate:
	var t := EventTemplate.new()
	t.id = data["id"]
	t.category = data.get("category", "social")
	t.triggers = data.get("triggers", {})
	t.base_weight = float(data.get("weight", 1.0))
	t.cooldown_days = int(data.get("cooldown_days", 5))
	t.description_template = data.get("description", "")
	return t


func is_ready(day: int) -> bool:
	return day - _last_fired_day >= cooldown_days


func mark_fired(day: int) -> void:
	_last_fired_day = day


## Peso final dado o estado das pressões do mundo.
func score(pressures: Dictionary) -> float:
	var total := base_weight * 0.1  # chance basal pequena mesmo sem pressão
	for pressure_key: String in triggers.keys():
		var pressure_value: float = pressures.get(pressure_key, 0.0)
		total += pressure_value * float(triggers[pressure_key])
	return total
