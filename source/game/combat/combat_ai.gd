class_name CombatAI
extends RefCounted
## IA de combate (GDD §8.3): papéis de grupo emergentes, moral real e
## reforços diegéticos. Inimigos avaliam a luta — e fogem, e LEMBRAM:
## quem escapa espalha seu nome pela fofoca ou volta com amigos.

enum Role { CIRCLER, HARASSER, ARCHER, LEADER }
enum Decision { ENGAGE, CIRCLE, RETREAT, FLEE, CALL_REINFORCEMENTS }

var role: int = Role.CIRCLER
var courage := 0.5
## Registro da simulação por trás deste corpo (memória sobrevive à cena).
var npc_record: NPCRecord
var group_id := ""
var has_horn := false
var _called_help := false


## Decisão tática por tick de IA. `group_alive_ratio`: quanto do bando resta.
func decide(
	self_health_ratio: float,
	group_alive_ratio: float,
	target_posture_ratio: float,
	allies_engaging: int
) -> int:
	var morale := _morale(self_health_ratio, group_alive_ratio)
	var decision := Decision.ENGAGE
	if morale < 0.2:
		decision = Decision.FLEE
	elif morale < 0.45:
		if has_horn and not _called_help:
			_called_help = true
			decision = Decision.CALL_REINFORCEMENTS
		else:
			decision = Decision.RETREAT
	elif target_posture_ratio < 0.25:
		# Postura do alvo quebrada = todos pressionam.
		decision = Decision.ENGAGE
	elif (allies_engaging >= 2 and role == Role.CIRCLER) or role == Role.ARCHER:
		# Não empilhar: no máximo 2 atacando, o resto cerca (legibilidade).
		decision = Decision.CIRCLE
	return decision


func _morale(self_health_ratio: float, group_alive_ratio: float) -> float:
	var base := self_health_ratio * 0.5 + group_alive_ratio * 0.5
	return clampf(base * (0.5 + courage), 0.0, 1.0)


## Fugiu e sobreviveu: a simulação registra — o sobrevivente pode voltar
## com reforços amanhã, ou espalhar seu pesadelo pela taverna.
func register_flee_memory(day: int, player_was_enemy: bool) -> void:
	if npc_record == null:
		return
	if player_was_enemy:
		npc_record.remember(
			"combate", "-fugi de um forasteiro perigoso", day, 1.0, "player"
		)
		npc_record.fears.append("player")
	npc_record.needs["safety"] = 1.0
