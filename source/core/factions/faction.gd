class_name Faction
extends RefCounted
## Estado de uma facção: recursos reais, territórios, relações e memória.
## Nenhuma facção é boa ou má — cada uma maximiza a própria tese (GDD §5).

var id: String
var display_name: String
var thesis: String
## Recursos reais que lastreiam decisões estratégicas.
var gold := 500.0
var food := 300.0
var troops := 50
var influence := 10.0
## region_id -> força de presença 0..1
var territories: Dictionary = {}
## other_faction_id -> -100..+100
var relations: Dictionary = {}
## Reputação do jogador com esta facção (-100..+100), movida por testemunhos.
var player_reputation := 0.0
## Memória de facção: eventos que ela não esquece {desc, day, weight}.
var grudges: Array = []
## Perfil estratégico 0..1: quão agressiva/comercial/religiosa é.
var aggression := 0.3
var trade_focus := 0.3
var memory_decay := 0.01


static func from_data(data: Dictionary) -> Faction:
	var f := Faction.new()
	f.id = data["id"]
	f.display_name = data.get("name", data["id"])
	f.thesis = data.get("thesis", "")
	f.gold = float(data.get("gold", 500.0))
	f.food = float(data.get("food", 300.0))
	f.troops = int(data.get("troops", 50))
	f.aggression = float(data.get("aggression", 0.3))
	f.trade_focus = float(data.get("trade_focus", 0.3))
	f.memory_decay = float(data.get("memory_decay", 0.01))
	for region_id: String in data.get("territories", []):
		f.territories[region_id] = 1.0
	var rel: Dictionary = data.get("relations", {})
	for other: String in rel.keys():
		f.relations[other] = float(rel[other])
	return f


func relation_with(other_id: String) -> float:
	return relations.get(other_id, 0.0)


func shift_relation(other_id: String, delta: float) -> void:
	relations[other_id] = clampf(relation_with(other_id) + delta, -100.0, 100.0)


func add_grudge(description: String, day: int, weight: float) -> void:
	grudges.append({"desc": description, "day": day, "weight": weight})


## Rancores decaem (clãs khevri têm decay quase nulo — nunca esquecem).
func decay_grudges() -> void:
	for grudge: Dictionary in grudges:
		grudge["weight"] = maxf(0.0, grudge["weight"] - memory_decay)
	grudges = grudges.filter(func(g: Dictionary) -> bool: return g["weight"] > 0.05)


## Pressão interna por guerra: fome + rancor + agressividade - exaustão.
func war_pressure_against(other_id: String, food_stress: float) -> float:
	var grudge_weight := 0.0
	for grudge: Dictionary in grudges:
		if grudge["desc"].contains(other_id):
			grudge_weight += grudge["weight"]
	var relation_pressure: float = maxf(0.0, -relation_with(other_id)) / 100.0
	var strength_confidence: float = clampf(float(troops) / 40.0, 0.2, 2.0)
	return (relation_pressure + grudge_weight * 0.3 + food_stress * 0.5) \
		* aggression * strength_confidence


func to_dict() -> Dictionary:
	return {
		"id": id,
		"gold": gold,
		"food": food,
		"troops": troops,
		"influence": influence,
		"territories": territories.duplicate(),
		"relations": relations.duplicate(),
		"player_reputation": player_reputation,
		"grudges": grudges.duplicate(true),
	}


func from_dict(data: Dictionary) -> void:
	gold = data.get("gold", gold)
	food = data.get("food", food)
	troops = data.get("troops", troops)
	influence = data.get("influence", influence)
	territories = data.get("territories", territories)
	relations = data.get("relations", relations)
	player_reputation = data.get("player_reputation", player_reputation)
	grudges = data.get("grudges", grudges)
