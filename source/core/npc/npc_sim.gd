class_name NPCSim
extends RefCounted
## Nível abstrato da IA (GDD §7.1): todos os NPCs vivem aqui como registros.
## O corpo encenado só existe perto do jogador — mas a vida é a mesma:
## um NPC abstrato viajando existe na estrada e pode ser encontrado.

signal npc_died(npc: NPCRecord)
signal vacancy_filled(settlement_id: String, profession: String, heir: NPCRecord)

## npc_id -> NPCRecord
var npcs: Dictionary = {}
## Vagas econômicas abertas por morte: {settlement, profession, days_open}.
var vacancies: Array = []

var _rng: RandomNumberGenerator
var _generated_counter := 0


func _init(rng: RandomNumberGenerator) -> void:
	_rng = rng


func setup(seeds: Dictionary, regions: Array) -> void:
	for npc_data: Dictionary in seeds.get("named", []):
		var npc := NPCRecord.from_data(npc_data)
		npcs[npc.id] = npc
	# População de fundo gerada por assentamento (com nome, rotina e ficha —
	# "gerado" não significa raso; significa autoria assistida).
	var pool: Dictionary = seeds.get("generation_pool", {})
	for region: Dictionary in regions:
		for settlement: Dictionary in region.get("settlements", []):
			var background_count: int = settlement.get("population", 20) / 4
			for _i in range(background_count):
				var npc := _generate_npc(settlement["id"], pool)
				npcs[npc.id] = npc


func _generate_npc(settlement_id: String, pool: Dictionary) -> NPCRecord:
	_generated_counter += 1
	var first_names: Array = pool.get("first_names", ["Ansel"])
	var professions: Array = pool.get("professions", ["villager"])
	var npc := NPCRecord.new()
	npc.id = "npc_gen_%d" % _generated_counter
	npc.display_name = "%s %s" % [
		first_names[_rng.randi() % first_names.size()],
		pool.get("surnames", ["de Vaethir"])[_rng.randi() % pool.get("surnames", ["de Vaethir"]).size()],
	]
	npc.profession = professions[_rng.randi() % professions.size()]
	npc.home_settlement = settlement_id
	npc.location = settlement_id
	npc.routine = NPCRecord.DEFAULT_ROUTINE.duplicate()
	for axis: String in npc.personality.keys():
		npc.personality[axis] = clampf(_rng.randfn(0.5, 0.2), 0.05, 0.95)
	npc.money = _rng.randf_range(5.0, 60.0)
	return npc


func alive_in(settlement_id: String) -> Array:
	var result: Array = []
	for npc: NPCRecord in npcs.values():
		if npc.alive and npc.location == settlement_id and npc.traveling_to == "":
			result.append(npc)
	return result


## Tick horário (timesliced pelo scheduler): decide e aplica atividades.
func hourly_tick(hour: int, day: int, danger_by_settlement: Dictionary) -> void:
	for npc: NPCRecord in npcs.values():
		if not npc.alive:
			continue
		Needs.grow(npc, 1.0)
		if npc.traveling_to != "":
			_travel_tick(npc)
			continue
		var danger: float = danger_by_settlement.get(npc.location, 0.0)
		var activity := Needs.choose_activity(npc, hour, danger)
		Needs.apply_activity(npc, activity)
		if activity == "social":
			_socialize(npc, day)
		if npc.sick_with != "" and _rng.randf() < 0.02:
			npc.health -= 0.1
		if npc.health <= 0.0:
			kill_npc(npc, day, "doença")


func _travel_tick(npc: NPCRecord) -> void:
	npc.travel_progress += 0.08
	if npc.travel_progress >= 1.0:
		npc.location = npc.traveling_to
		npc.traveling_to = ""
		npc.travel_progress = 0.0


func _socialize(npc: NPCRecord, day: int) -> void:
	var locals := alive_in(npc.location)
	if locals.size() < 2:
		return
	var other: NPCRecord = locals[_rng.randi() % locals.size()]
	if other != npc:
		Gossip.exchange(npc, other, day, _rng)


## Tick diário: memórias decaem, doenças evoluem, vagas são preenchidas.
func daily_tick(day: int) -> void:
	for npc: NPCRecord in npcs.values():
		if npc.alive:
			npc.decay_memories()
			if npc.sick_with != "" and _rng.randf() < 0.15:
				npc.sick_with = ""  # recuperação natural
	_fill_vacancies(day)


func kill_npc(npc: NPCRecord, day: int, cause: String) -> void:
	if not npc.alive:
		return
	npc.alive = false
	vacancies.append({
		"settlement": npc.home_settlement,
		"profession": npc.profession,
		"days_open": 0,
	})
	# Amigos ficam de luto e lembram — morte tem custo social visível.
	for other_id: String in npc.relationships.keys():
		var friend: NPCRecord = npcs.get(other_id)
		if friend != null and friend.alive and npc.relationships[other_id] > 30.0:
			friend.remember("morte", "%s morreu (%s)" % [npc.display_name, cause], day, 1.0, npc.id)
			friend.needs["social"] = 1.0
	npc_died.emit(npc)


## Papéis vagos reocupados com atraso e degradação (o aprendiz não forja
## como a mestra) — o mundo não quebra, mas a morte custa.
func _fill_vacancies(day: int) -> void:
	var remaining: Array = []
	for vacancy: Dictionary in vacancies:
		vacancy["days_open"] += 1
		if vacancy["days_open"] < 10 or _rng.randf() > 0.3:
			remaining.append(vacancy)
			continue
		var heir: NPCRecord = null
		for npc: NPCRecord in npcs.values():
			if npc.alive and npc.location == vacancy["settlement"] \
					and npc.profession == "villager":
				heir = npc
				break
		if heir == null:
			remaining.append(vacancy)
			continue
		heir.profession = vacancy["profession"]
		heir.remember("ofício", "assumi o ofício de %s" % vacancy["profession"], day, 1.0)
		vacancy_filled.emit(vacancy["settlement"], vacancy["profession"], heir)
	vacancies = remaining


func population_alive() -> int:
	var count := 0
	for npc: NPCRecord in npcs.values():
		if npc.alive:
			count += 1
	return count


func to_dict() -> Dictionary:
	var npc_data := {}
	for k: String in npcs.keys():
		npc_data[k] = npcs[k].to_dict()
	return {"npcs": npc_data, "vacancies": vacancies.duplicate(true)}


func from_dict(data: Dictionary) -> void:
	var npc_data: Dictionary = data.get("npcs", {})
	for k: String in npc_data.keys():
		if npcs.has(k):
			npcs[k].from_dict(npc_data[k])
	vacancies = data.get("vacancies", vacancies)
