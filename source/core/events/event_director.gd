class_name EventDirector
extends RefCounted
## "O Dramaturgo" (GDD §12): não inventa histórias — expõe as que a simulação
## já criou. Lê pressões (fome, guerra, clima, caravanas perdidas) e
## materializa consequências como eventos situados no mundo, sem popups
## e sem marcadores. Também mantém o Registro do Mundo (história viva).

signal event_fired(event: Dictionary)

var templates: Array[EventTemplate] = []
## Registro do Mundo: história viva narrada por bardos/fofoca com atraso.
var world_record: Array = []

var _rng: RandomNumberGenerator


func _init(rng: RandomNumberGenerator) -> void:
	_rng = rng


func setup(template_data: Array) -> void:
	for data: Dictionary in template_data:
		templates.append(EventTemplate.from_data(data))


## Tick diário. `pressures` agrega leituras de todos os sistemas:
##   food_deficit_total, war_intensity, storm_regions, lost_caravans...
func daily_tick(day: int, pressures: Dictionary, world: Dictionary) -> Array:
	var fired: Array = []
	for template in templates:
		if not template.is_ready(day):
			continue
		var chance := clampf(template.score(pressures) * 0.15, 0.0, 0.5)
		if _rng.randf() >= chance:
			continue
		var event := _materialize(template, day, pressures, world)
		template.mark_fired(day)
		world_record.append(event)
		fired.append(event)
		event_fired.emit(event)
	if world_record.size() > 400:
		world_record = world_record.slice(world_record.size() - 400)
	return fired


## Preenche o template com atores e locais reais da simulação.
func _materialize(
	template: EventTemplate, day: int, pressures: Dictionary, world: Dictionary
) -> Dictionary:
	var settlements: Array = world.get("settlements", [])
	var regions: Array = world.get("regions", [])
	var place := ""
	if template.category == "natural" and not regions.is_empty():
		place = regions[_rng.randi() % regions.size()]
	elif not settlements.is_empty():
		# Eventos de fome/conflito tendem ao lugar mais pressionado.
		var deficits: Dictionary = pressures.get("food_deficit", {})
		if not deficits.is_empty() and template.triggers.has("food_deficit_total"):
			var worst := ""
			var worst_value := 0.0
			for sid: String in deficits.keys():
				if deficits[sid] > worst_value:
					worst_value = deficits[sid]
					worst = sid
			place = worst
		else:
			place = settlements[_rng.randi() % settlements.size()]
	var description := template.description_template.replace("{place}", place)
	return {
		"template_id": template.id,
		"category": template.category,
		"day": day,
		"place": place,
		"description": description,
		"resolved": false,
	}


## Registra um marco histórico vindo de outro sistema (guerra declarada,
## caravana destruída...) para que bardos e arautos possam narrá-lo.
func record(day: int, category: String, description: String, place := "") -> void:
	world_record.append({
		"template_id": "record",
		"category": category,
		"day": day,
		"place": place,
		"description": description,
		"resolved": true,
	})


## Notícias que um NPC de um lugar conheceria hoje: chegam com atraso
## proporcional à distância — notícia de longe chega tarde (e distorcida
## pela fofoca no caminho, ver Gossip).
func news_known_at(day: int, place: String, distance_days: Dictionary) -> Array:
	var known: Array = []
	for event: Dictionary in world_record:
		var delay: float = distance_days.get(event.get("place", ""), 3.0)
		if event["place"] == place:
			delay = 0.0
		if day - event["day"] >= delay:
			known.append(event)
	return known


func to_dict() -> Dictionary:
	return {"world_record": world_record.duplicate(true)}


func from_dict(data: Dictionary) -> void:
	world_record = data.get("world_record", world_record)
