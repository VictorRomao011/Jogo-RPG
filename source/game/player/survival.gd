class_name Survival
extends RefCounted
## Sobrevivência leve (GDD §10): fricção que gera história, nunca contador
## de tarefas. Estar mal nunca mata sozinho — torna o mundo mais perigoso.

signal condition_changed(condition: String, severity: float)
signal disease_contracted(disease: String)
signal disease_cured(disease: String)

const HUNGER_PER_HOUR := 0.055
const FATIGUE_PER_HOUR := 0.045

const DISEASES := {
	"febre_do_pantano": {"stamina_penalty": 0.3, "cure": "cataplasma_de_sanguessuga"},
	"tosse_gelada": {"stamina_penalty": 0.15, "cure": "cha_de_raiz_morna"},
	"ferida_infectada": {"stamina_penalty": 0.25, "cure": "unguento_limpo"},
}

## 0..1 (1 = urgente). Ritmos lentos: 2 refeições/dia bastam.
var hunger := 0.2
var fatigue := 0.0
## Temperatura percebida -1 (congelando) .. 0 (ok) .. +1 (calor severo).
var temperature := 0.0
var clothing_warmth := 0.3
var diseases: Array = []


func hourly_tick(weather_id: String, sheltered: bool, near_fire: bool) -> void:
	hunger = clampf(hunger + HUNGER_PER_HOUR, 0.0, 1.0)
	fatigue = clampf(fatigue + FATIGUE_PER_HOUR, 0.0, 1.0)
	_update_temperature(weather_id, sheltered, near_fire)
	if hunger > 0.85:
		condition_changed.emit("hunger", hunger)
	if fatigue > 0.85:
		condition_changed.emit("fatigue", fatigue)


func _update_temperature(weather_id: String, sheltered: bool, near_fire: bool) -> void:
	var ambient := 0.0
	match weather_id:
		"snow":
			ambient = -0.8
		"storm", "rain":
			ambient = -0.4
		"dust":
			ambient = 0.6
		"clear":
			ambient = 0.1
	if sheltered:
		ambient *= 0.3
	if near_fire:
		ambient += 0.5
	var target := clampf(ambient + (0.0 if ambient > 0.0 else clothing_warmth), -1.0, 1.0)
	temperature = lerpf(temperature, target, 0.2)
	if temperature < -0.7:
		condition_changed.emit("cold", -temperature)


## Multiplicador sobre a stamina máxima — o único "castigo" dos medidores.
## Fome/frio nunca drenam vida (GDD §10): encolhem sua margem de manobra.
func stamina_multiplier() -> float:
	var mult := 1.0
	if hunger > 0.6:
		mult -= (hunger - 0.6) * 0.75
	if fatigue > 0.7:
		mult -= (fatigue - 0.7) * 0.5
	if temperature < -0.5:
		mult -= (-temperature - 0.5) * 0.6
	for disease: String in diseases:
		mult -= DISEASES.get(disease, {}).get("stamina_penalty", 0.1)
	return clampf(mult, 0.25, 1.0)


func eat(nutrition: float, spoiled := false) -> void:
	hunger = clampf(hunger - nutrition, 0.0, 1.0)
	if spoiled and randf() < 0.5:
		contract("febre_do_pantano")


func sleep(hours: float, safe: bool) -> void:
	fatigue = clampf(fatigue - hours * 0.12, 0.0, 1.0)
	if safe:
		for disease in diseases.duplicate():
			if randf() < 0.1 * hours / 8.0:
				cure(disease)


func contract(disease: String) -> void:
	if disease in diseases or not DISEASES.has(disease):
		return
	diseases.append(disease)
	disease_contracted.emit(disease)


func cure(disease: String) -> void:
	if disease in diseases:
		diseases.erase(disease)
		disease_cured.emit(disease)


func use_remedy(item_id: String) -> bool:
	for disease: String in diseases:
		if DISEASES[disease]["cure"] == item_id:
			cure(disease)
			return true
	return false


func to_dict() -> Dictionary:
	return {
		"hunger": hunger,
		"fatigue": fatigue,
		"temperature": temperature,
		"clothing_warmth": clothing_warmth,
		"diseases": diseases.duplicate(),
	}


func from_dict(data: Dictionary) -> void:
	hunger = data.get("hunger", hunger)
	fatigue = data.get("fatigue", fatigue)
	temperature = data.get("temperature", temperature)
	clothing_warmth = data.get("clothing_warmth", clothing_warmth)
	diseases = data.get("diseases", diseases)
