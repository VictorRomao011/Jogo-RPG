class_name WorldState
extends RefCounted
## Estado canônico do mundo. Determinístico por seed, separado de qualquer
## cena — roda headless em testes de CI (soak de centenas de dias).
## O jogador é um agente entre agentes: nada aqui depende dele existir.

signal day_simulated(day: int, events: Array)

var clock := WorldClock.new()
var rng := RandomNumberGenerator.new()
var echoes := EchoTrail.new()
## Lugares que o JOGADOR conheceu: {name, x, z} — o mapa é memória.
var discovered: Array = []
var weather: WeatherSim
var economy: EconomySim
var factions: FactionSim
var npcs: NPCSim
var director: EventDirector

var regions: Array = []
var settlement_ids: Array = []
var region_ids: Array = []

var _hour_accumulator := 0
var _initialized := false


func initialize(world_seed: int = 173) -> void:
	rng.seed = world_seed
	weather = WeatherSim.new(rng)
	economy = EconomySim.new(rng)
	factions = FactionSim.new(rng)
	npcs = NPCSim.new(rng)
	director = EventDirector.new(rng)

	regions = DataLoader.load_regions()
	var goods := DataLoader.load_goods()
	var faction_data := DataLoader.load_factions()
	var npc_seeds := DataLoader.load_npc_seeds()
	var event_templates := DataLoader.load_event_templates()

	for region: Dictionary in regions:
		region_ids.append(region["id"])
		weather.register_region(region["id"], region.get("weathers", WeatherSim.WEATHERS))
		for settlement: Dictionary in region.get("settlements", []):
			settlement_ids.append(settlement["id"])

	economy.setup(regions, goods)
	factions.setup(faction_data)
	npcs.setup(npc_seeds, regions)
	director.setup(event_templates)

	clock.hour_passed.connect(_on_hour_passed)
	clock.day_passed.connect(_on_day_passed)
	economy.caravan_lost.connect(_on_caravan_lost)
	factions.war_state_changed.connect(_on_war_state_changed)
	_initialized = true


func advance(real_delta: float) -> void:
	if _initialized:
		clock.advance(real_delta)


func _on_hour_passed(hour: int) -> void:
	_hour_accumulator += 1
	if _hour_accumulator % 3 == 0:
		weather.tick(clock.season_index())
	npcs.hourly_tick(hour, clock.day(), _danger_by_settlement())


func _on_day_passed(day: int) -> void:
	var war_zones := factions.active_war_zones()
	var economy_pressures := economy.daily_tick(weather, war_zones)
	var faction_events := factions.daily_tick(day, economy_pressures["food_deficit"], economy)
	npcs.daily_tick(day)

	for faction_event: Dictionary in faction_events:
		var pair: Array = faction_event["factions"]
		director.record(
			day, "conflict",
			"Relação entre %s e %s mudou para estado %d" % [
				pair[0], pair[1], faction_event["state"],
			]
		)

	var pressures := _aggregate_pressures(economy_pressures, war_zones)
	var events := director.daily_tick(day, pressures, {
		"settlements": settlement_ids,
		"regions": region_ids,
	})
	_apply_event_consequences(events, day)
	day_simulated.emit(day, events)


func _aggregate_pressures(economy_pressures: Dictionary, war_zones: Dictionary) -> Dictionary:
	var food_total := 0.0
	for deficit: float in economy_pressures["food_deficit"].values():
		food_total += deficit
	var storm_count := 0
	for region_id: String in region_ids:
		if weather.current(region_id) in ["storm", "snow", "dust"]:
			storm_count += 1
	return {
		"food_deficit": economy_pressures["food_deficit"],
		"food_deficit_total": clampf(food_total / 20.0, 0.0, 2.0),
		"war_intensity": float(war_zones.size()),
		"bad_weather": float(storm_count) / maxf(float(region_ids.size()), 1.0),
		"lost_caravans": float(economy_pressures["lost_caravans"].size()),
	}


## Eventos têm consequências físicas na simulação (nunca são só texto).
func _apply_event_consequences(events: Array, day: int) -> void:
	for event: Dictionary in events:
		match event["category"]:
			"conflict":
				var locals := npcs.alive_in(event["place"])
				if not locals.is_empty() and rng.randf() < 0.3:
					npcs.kill_npc(locals[rng.randi() % locals.size()], day, event["template_id"])
			"natural":
				for settlement_id: String in settlement_ids:
					var market: Market = economy.markets.get(settlement_id)
					if market != null and market.region_id == event["place"]:
						market.take_stock("grain", 10.0)
			"social":
				for npc: NPCRecord in npcs.alive_in(event["place"]):
					npc.remember(
						"evento", event["description"], day, 1.0
					)
			"echo":
				pass  # zonas de eco são efetivadas pela camada de encenação


func _danger_by_settlement() -> Dictionary:
	var danger := {}
	var war_zones := factions.active_war_zones()
	for settlement_id: String in settlement_ids:
		var market: Market = economy.markets.get(settlement_id)
		if market != null and war_zones.get(market.region_id, false):
			danger[settlement_id] = 0.6
	return danger


## Snapshot completo para save (GDD §16.2).
func to_dict() -> Dictionary:
	return {
		"version": 1,
		"seed": rng.seed,
		"clock": clock.to_dict(),
		"weather": weather.to_dict(),
		"economy": economy.to_dict(),
		"factions": factions.to_dict(),
		"npcs": npcs.to_dict(),
		"director": director.to_dict(),
		"echoes": echoes.to_dict(),
		"discovered": discovered.duplicate(true),
	}


func from_dict(data: Dictionary) -> void:
	clock.from_dict(data.get("clock", {}))
	weather.from_dict(data.get("weather", {}))
	economy.from_dict(data.get("economy", {}))
	factions.from_dict(data.get("factions", {}))
	npcs.from_dict(data.get("npcs", {}))
	director.from_dict(data.get("director", {}))
	echoes.from_dict(data.get("echoes", {}))
	discovered = data.get("discovered", discovered)
