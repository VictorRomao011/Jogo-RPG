class_name FactionSim
extends RefCounted
## Simulador estratégico de facções (GDD §5.3). Guerras nascem de pressões
## simuladas (comida, rancor, rotas), nunca de script, e seguem o ciclo:
## tensão -> escaramuças -> guerra aberta -> exaustão -> tratado.

signal war_state_changed(faction_a: String, faction_b: String, state: int)

enum WarState { PEACE, TENSION, SKIRMISH, WAR, EXHAUSTION }

const WAR_THRESHOLD := 0.75
const TENSION_THRESHOLD := 0.35
const DAILY_WAR_UPKEEP_GOLD := 30.0
const DAILY_WAR_UPKEEP_FOOD := 20.0

## faction_id -> Faction
var factions: Dictionary = {}
## "a|b" -> {state, days_in_state, war_score}
var conflicts: Dictionary = {}

var _rng: RandomNumberGenerator


func _init(rng: RandomNumberGenerator) -> void:
	_rng = rng


func setup(faction_data: Array) -> void:
	for data: Dictionary in faction_data:
		factions[data["id"]] = Faction.from_data(data)


func get_faction(faction_id: String) -> Faction:
	return factions.get(faction_id)


func _pair_key(a: String, b: String) -> String:
	return "%s|%s" % [a, b] if a < b else "%s|%s" % [b, a]


func war_state(a: String, b: String) -> int:
	return conflicts.get(_pair_key(a, b), {}).get("state", WarState.PEACE)


## Regiões com guerra ativa (produção cai, rotas ficam perigosas).
func active_war_zones() -> Dictionary:
	var zones := {}
	for key: String in conflicts.keys():
		var conflict: Dictionary = conflicts[key]
		if conflict["state"] < WarState.SKIRMISH:
			continue
		var ids := key.split("|")
		for fid in ids:
			var faction: Faction = factions.get(fid)
			if faction == null:
				continue
			for region_id: String in faction.territories.keys():
				zones[region_id] = true
	return zones


## Tick diário estratégico. `food_pressures`: déficit de comida por
## assentamento — fome no território drena o celeiro da facção (pressão real).
func daily_tick(day: int, food_pressures: Dictionary, economy: EconomySim) -> Array:
	var events: Array = []
	var ids: Array = factions.keys()
	for faction: Faction in factions.values():
		faction.decay_grudges()
		faction.food = maxf(0.0, faction.food - float(faction.troops) * 0.2)
		faction.gold += faction.trade_focus * 15.0
		faction.food += 8.0
		# Prosperidade recruta: facção com celeiro cheio e ouro repõe tropas
		# (sem isso, uma derrota seria extinção militar permanente).
		if faction.food > float(faction.troops) * 2.0 and faction.gold > 100.0:
			faction.gold -= 5.0
			faction.troops += 1
		for settlement_id: String in food_pressures.keys():
			var market: Market = economy.markets.get(settlement_id)
			if market != null and faction.territories.has(market.region_id):
				faction.food = maxf(0.0, faction.food - food_pressures[settlement_id] * 0.5)
	for i in range(ids.size()):
		for j in range(i + 1, ids.size()):
			var event := _tick_pair(ids[i], ids[j], day, economy)
			if not event.is_empty():
				events.append(event)
	return events


func _tick_pair(a: String, b: String, day: int, economy: EconomySim) -> Dictionary:
	var key := _pair_key(a, b)
	var fa: Faction = factions[a]
	var fb: Faction = factions[b]
	if not conflicts.has(key):
		conflicts[key] = {"state": WarState.PEACE, "days_in_state": 0, "war_score": 0.0}
	var conflict: Dictionary = conflicts[key]
	conflict["days_in_state"] += 1

	var food_stress_a: float = 1.0 if fa.food < float(fa.troops) * 2.0 else 0.0
	var food_stress_b: float = 1.0 if fb.food < float(fb.troops) * 2.0 else 0.0
	var pressure: float = maxf(
		fa.war_pressure_against(b, food_stress_a),
		fb.war_pressure_against(a, food_stress_b)
	)

	var old_state: int = conflict["state"]
	match conflict["state"]:
		WarState.PEACE:
			if pressure > TENSION_THRESHOLD:
				conflict["state"] = WarState.TENSION
		WarState.TENSION:
			if pressure > WAR_THRESHOLD and conflict["days_in_state"] > 5:
				conflict["state"] = WarState.SKIRMISH
			elif pressure < TENSION_THRESHOLD * 0.5:
				conflict["state"] = WarState.PEACE
		WarState.SKIRMISH:
			_resolve_skirmish(fa, fb, conflict, day)
			if conflict["days_in_state"] > 10 and pressure > WAR_THRESHOLD:
				conflict["state"] = WarState.WAR
			elif pressure < TENSION_THRESHOLD:
				conflict["state"] = WarState.TENSION
		WarState.WAR:
			_resolve_war_day(fa, fb, conflict, day, economy)
			if _is_exhausted(fa) or _is_exhausted(fb) or conflict["days_in_state"] > 60:
				conflict["state"] = WarState.EXHAUSTION
		WarState.EXHAUSTION:
			if conflict["days_in_state"] > 7:
				conflict["state"] = WarState.PEACE
				conflict["war_score"] = 0.0
				fa.shift_relation(b, 10.0)
				fb.shift_relation(a, 10.0)

	if conflict["state"] != old_state:
		conflict["days_in_state"] = 0
		war_state_changed.emit(a, b, conflict["state"])
		return {
			"type": "war_state",
			"factions": [a, b],
			"state": conflict["state"],
			"day": day,
		}
	return {}


func _resolve_skirmish(fa: Faction, fb: Faction, conflict: Dictionary, day: int) -> void:
	if _rng.randf() > 0.3:
		return
	var loss_a := _rng.randi_range(0, 3)
	var loss_b := _rng.randi_range(0, 3)
	fa.troops = maxi(0, fa.troops - loss_a)
	fb.troops = maxi(0, fb.troops - loss_b)
	conflict["war_score"] += float(loss_b - loss_a)
	fa.shift_relation(fb.id, -2.0)
	fb.shift_relation(fa.id, -2.0)
	if loss_a > 0:
		fa.add_grudge("escaramuça contra %s" % fb.id, day, 0.4)
	if loss_b > 0:
		fb.add_grudge("escaramuça contra %s" % fa.id, day, 0.4)


func _resolve_war_day(
	fa: Faction, fb: Faction, conflict: Dictionary, day: int, economy: EconomySim
) -> void:
	for faction: Faction in [fa, fb]:
		faction.gold = maxf(0.0, faction.gold - DAILY_WAR_UPKEEP_GOLD)
		faction.food = maxf(0.0, faction.food - DAILY_WAR_UPKEEP_FOOD)
		# Facções cunham moeda para pagar soldo -> inflação na zona de guerra.
		for region_id: String in faction.territories.keys():
			for settlement_id: String in economy.markets.keys():
				if economy.markets[settlement_id].region_id == region_id:
					economy.inject_money(settlement_id, 20.0)
	if _rng.randf() < 0.5:
		var strength_a := fa.troops + _rng.randi_range(-5, 5)
		var strength_b := fb.troops + _rng.randi_range(-5, 5)
		var loser: Faction = fb if strength_a > strength_b else fa
		var winner: Faction = fa if strength_a > strength_b else fb
		loser.troops = maxi(0, loser.troops - _rng.randi_range(2, 8))
		winner.troops = maxi(0, winner.troops - _rng.randi_range(0, 4))
		conflict["war_score"] += 1.0 if winner == fa else -1.0
		loser.add_grudge("batalha perdida para %s" % winner.id, day, 0.8)


func _is_exhausted(faction: Faction) -> bool:
	return faction.troops < 10 or (faction.gold < 20.0 and faction.food < 20.0)


## Testemunho de ação do jogador chega via fofoca e move reputação.
func report_player_action(faction_id: String, delta: float) -> void:
	var faction: Faction = factions.get(faction_id)
	if faction != null:
		faction.player_reputation = clampf(faction.player_reputation + delta, -100.0, 100.0)


func to_dict() -> Dictionary:
	var faction_data := {}
	for k: String in factions.keys():
		faction_data[k] = factions[k].to_dict()
	return {"factions": faction_data, "conflicts": conflicts.duplicate(true)}


func from_dict(data: Dictionary) -> void:
	var faction_data: Dictionary = data.get("factions", {})
	for k: String in faction_data.keys():
		if factions.has(k):
			factions[k].from_dict(faction_data[k])
	conflicts = data.get("conflicts", conflicts)
