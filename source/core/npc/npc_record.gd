class_name NPCRecord
extends RefCounted
## Ficha completa de um NPC (GDD §7.2). Este registro É o NPC — o corpo 3D
## (npc_body) é apenas a encenação quando o jogador está perto.

const DEFAULT_ROUTINE := {
	6: "work", 12: "meal", 13: "work", 18: "meal", 19: "social", 22: "sleep",
}

var id: String
var display_name: String
var profession: String
var home_settlement: String
var faction_id := ""
## Localização lógica: assentamento atual ou rota (quando viajando).
var location: String
var traveling_to := ""
var travel_progress := 0.0
var alive := true

## Necessidades 0..1 (1 = urgente).
var needs := {
	"hunger": 0.2,
	"sleep": 0.0,
	"safety": 0.0,
	"social": 0.3,
	"duty": 0.5,
	"ambition": 0.4,
}

## Personalidade 0..1 em 5 eixos.
var personality := {
	"courage": 0.5,
	"empathy": 0.5,
	"greed": 0.5,
	"loyalty": 0.5,
	"openness": 0.5,
}

## Rotina: hora -> atividade ("work", "meal", "social", "sleep", "travel").
var routine: Dictionary = {}
## Objetivos {desc, progress}.
var goals: Array = []
## Memórias {topic, detail, day, veracity 0..1, weight 0..1, about}.
var memories: Array = []
## other_npc_id -> -100..+100
var relationships: Dictionary = {}
## Medos: lista de tags ("faction:mascara_rubra", "thunder", ...).
var fears: Array = []
## Inventário real {item_id: qty} + dinheiro.
var inventory: Dictionary = {}
var money := 20.0
## Preferências: {likes: [...], dislikes: [...]}.
var preferences := {"likes": [], "dislikes": []}
## Opinião individual sobre o jogador (-100..+100) — separada da facção.
var player_opinion := 0.0
var health := 1.0
var sick_with := ""


static func from_data(data: Dictionary) -> NPCRecord:
	var npc := NPCRecord.new()
	npc.id = data["id"]
	npc.display_name = data.get("name", data["id"])
	npc.profession = data.get("profession", "villager")
	npc.home_settlement = data.get("home", "")
	npc.location = npc.home_settlement
	npc.faction_id = data.get("faction", "")
	npc.fears = data.get("fears", [])
	npc.money = float(data.get("money", 20.0))
	var pers: Dictionary = data.get("personality", {})
	for axis: String in pers.keys():
		npc.personality[axis] = float(pers[axis])
	var prefs: Dictionary = data.get("preferences", {})
	npc.preferences["likes"] = prefs.get("likes", [])
	npc.preferences["dislikes"] = prefs.get("dislikes", [])
	var routine_data: Dictionary = data.get("routine", {})
	if routine_data.is_empty():
		npc.routine = DEFAULT_ROUTINE.duplicate()
	else:
		for hour_key in routine_data.keys():
			npc.routine[int(hour_key)] = routine_data[hour_key]
	for goal in data.get("goals", []):
		npc.goals.append({"desc": goal, "progress": 0.0})
	return npc


## Atividade prevista pela rotina para uma dada hora (o "hábito").
func scheduled_activity(hour: int) -> String:
	var best_hour := -1
	var activity := "idle"
	for h: int in routine.keys():
		if h <= hour and h > best_hour:
			best_hour = h
			activity = routine[h]
	if best_hour == -1:
		# Antes do primeiro bloco do dia: vale o último bloco (madrugada).
		for h: int in routine.keys():
			if h > best_hour:
				best_hour = h
				activity = routine[h]
	return activity


func remember(topic: String, detail: String, day: int, veracity: float, about := "") -> void:
	memories.append({
		"topic": topic,
		"detail": detail,
		"day": day,
		"veracity": clampf(veracity, 0.0, 1.0),
		"weight": 1.0,
		"about": about,
	})
	if memories.size() > 40:
		memories.sort_custom(
			func(m1: Dictionary, m2: Dictionary) -> bool: return m1["weight"] > m2["weight"]
		)
		memories.resize(40)


func decay_memories() -> void:
	for memory: Dictionary in memories:
		memory["weight"] = maxf(0.0, memory["weight"] - 0.005)
	memories = memories.filter(func(m: Dictionary) -> bool: return m["weight"] > 0.05)


func shift_relationship(other_id: String, delta: float) -> void:
	relationships[other_id] = clampf(relationships.get(other_id, 0.0) + delta, -100.0, 100.0)


func knows_about(topic: String) -> bool:
	for memory: Dictionary in memories:
		if memory["topic"] == topic:
			return true
	return false


func to_dict() -> Dictionary:
	return {
		"id": id,
		"location": location,
		"traveling_to": traveling_to,
		"travel_progress": travel_progress,
		"alive": alive,
		"needs": needs.duplicate(),
		"memories": memories.duplicate(true),
		"relationships": relationships.duplicate(),
		"money": money,
		"inventory": inventory.duplicate(),
		"player_opinion": player_opinion,
		"health": health,
		"sick_with": sick_with,
		"goals": goals.duplicate(true),
	}


func from_dict(data: Dictionary) -> void:
	location = data.get("location", location)
	traveling_to = data.get("traveling_to", "")
	travel_progress = data.get("travel_progress", 0.0)
	alive = data.get("alive", true)
	needs = data.get("needs", needs)
	memories = data.get("memories", memories)
	relationships = data.get("relationships", relationships)
	money = data.get("money", money)
	inventory = data.get("inventory", inventory)
	player_opinion = data.get("player_opinion", 0.0)
	health = data.get("health", 1.0)
	sick_with = data.get("sick_with", "")
	goals = data.get("goals", goals)
