class_name Needs
extends RefCounted
## Utility AI (GDD §7.3): pontua atividades candidatas por necessidade,
## personalidade e contexto. A rotina é o hábito (peso alto por padrão);
## necessidades urgentes ou eventos a quebram — rotinas estáveis que flexionam.

const HABIT_WEIGHT := 0.6

## Taxas de crescimento por hora de jogo.
const GROWTH := {
	"hunger": 0.04,
	"sleep": 0.035,
	"social": 0.02,
	"duty": 0.03,
	"ambition": 0.005,
}


static func grow(npc: NPCRecord, hours: float) -> void:
	for need: String in GROWTH.keys():
		npc.needs[need] = clampf(npc.needs[need] + GROWTH[need] * hours, 0.0, 1.0)


## Escolhe a atividade da hora. Retorna: "work", "meal", "sleep", "social",
## "flee", "tend_sick", "idle".
static func choose_activity(npc: NPCRecord, hour: int, danger_level: float) -> String:
	var scores := {}
	# Fome pesa mais que o hábito: urgência quebra rotina (mas a rotina
	# ainda vence a fome leve — NPCs almoçam na hora do almoço, como gente).
	scores["meal"] = npc.needs["hunger"] * 1.3
	scores["sleep"] = npc.needs["sleep"] * (1.4 if _is_rest_hour(hour) else 0.6)
	scores["social"] = npc.needs["social"] * npc.personality["openness"]
	scores["work"] = npc.needs["duty"] * (0.6 + npc.personality["loyalty"] * 0.6)
	scores["flee"] = danger_level * (1.5 - npc.personality["courage"])
	if npc.health < 0.6 or npc.sick_with != "":
		scores["tend_sick"] = 0.8 + (1.0 - npc.health)

	# Hábito: a atividade da rotina ganha bônus forte — quebra só com urgência.
	var habitual := npc.scheduled_activity(hour)
	if scores.has(habitual):
		scores[habitual] += HABIT_WEIGHT

	var best := "idle"
	var best_score := 0.25  # abaixo disso, o NPC vagueia/observa
	for activity: String in scores.keys():
		if scores[activity] > best_score:
			best_score = scores[activity]
			best = activity
	return best


static func apply_activity(npc: NPCRecord, activity: String) -> void:
	match activity:
		"meal":
			npc.needs["hunger"] = maxf(0.0, npc.needs["hunger"] - 0.6)
			npc.money = maxf(0.0, npc.money - 0.5)
		"sleep":
			npc.needs["sleep"] = maxf(0.0, npc.needs["sleep"] - 0.5)
		"social":
			npc.needs["social"] = maxf(0.0, npc.needs["social"] - 0.4)
		"work":
			npc.needs["duty"] = maxf(0.0, npc.needs["duty"] - 0.3)
			npc.money += 1.0
		"tend_sick":
			npc.health = minf(1.0, npc.health + 0.05)
		"flee":
			npc.needs["safety"] = maxf(0.0, npc.needs["safety"] - 0.3)


static func _is_rest_hour(hour: int) -> bool:
	return hour >= 21 or hour < 6
