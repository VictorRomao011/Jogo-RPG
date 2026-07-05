class_name Skills
extends RefCounted
## Progressão "fazer é aprender" (GDD §11): sem classes, sem níveis, sem XP.
## Curva logarítmica, anti-grind real: ganho escala com desafio — repetir
## ação sem risco/contexto rende quase nada.

signal skill_increased(skill: String, new_value: float)
signal technique_unlocked(skill: String, technique: String)

const SKILLS := [
	"vigor", "breath", "swimming", "climbing", "stealth",
	"short_blades", "long_blades", "polearms", "impact", "bows",
	"block_parry", "grappling",
	"trade", "persuasion", "medicine", "alchemy", "smithing", "survival",
]

## Técnicas por marco (mudam o verbo, não o número — GDD §11.4).
const TECHNIQUES := {
	"breath": {40.0: "mergulho_longo"},
	"block_parry": {60.0: "riposta_desarmadora"},
	"trade": {50.0: "ler_tendencia"},
	"climbing": {30.0: "escalada_sob_chuva_leve"},
	"stealth": {45.0: "passo_de_sombra"},
	"medicine": {35.0: "diagnostico_rapido"},
}

const MAX_SKILL := 100.0

var values: Dictionary = {}
var unlocked_techniques: Dictionary = {}


func _init() -> void:
	for skill in SKILLS:
		values[skill] = 5.0
		unlocked_techniques[skill] = []


func get_value(skill: String) -> float:
	return values.get(skill, 0.0)


func has_technique(technique: String) -> bool:
	for skill: String in unlocked_techniques.keys():
		if technique in unlocked_techniques[skill]:
			return true
	return false


## `challenge` 0..1: quão real era o risco/contexto. Bater em rato preso
## (challenge ~0) não treina espada; lutar algo que pode te matar, sim.
func practice(skill: String, base_gain: float, challenge: float) -> void:
	if not values.has(skill):
		return
	var current: float = values[skill]
	# Curva logarítmica: rápido no início, lento no domínio.
	var difficulty_curve: float = 1.0 - (current / MAX_SKILL)
	var gain: float = base_gain * clampf(challenge, 0.0, 1.0) * difficulty_curve * difficulty_curve
	if gain <= 0.0001:
		return
	values[skill] = minf(current + gain, MAX_SKILL)
	if int(values[skill]) > int(current):
		skill_increased.emit(skill, values[skill])
	_check_techniques(skill)


func _check_techniques(skill: String) -> void:
	var milestones: Dictionary = TECHNIQUES.get(skill, {})
	for threshold: float in milestones.keys():
		var technique: String = milestones[threshold]
		if values[skill] >= threshold and not technique in unlocked_techniques[skill]:
			unlocked_techniques[skill].append(technique)
			technique_unlocked.emit(skill, technique)


func to_dict() -> Dictionary:
	return {
		"values": values.duplicate(),
		"techniques": unlocked_techniques.duplicate(true),
	}


func from_dict(data: Dictionary) -> void:
	var saved: Dictionary = data.get("values", {})
	for skill: String in saved.keys():
		values[skill] = saved[skill]
	var techs: Dictionary = data.get("techniques", {})
	for skill: String in techs.keys():
		unlocked_techniques[skill] = techs[skill]
