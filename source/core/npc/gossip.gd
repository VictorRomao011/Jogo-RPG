class_name Gossip
extends RefCounted
## O sistema nervoso do mundo (GDD §7.6): informação viaja de boca em boca,
## com distorção e atraso reais. Reputação, notícias de guerra e preços
## usam este canal — a fama do jogador não teleporta.

const SHARE_CHANCE := 0.35
const VERACITY_LOSS_PER_HOP := 0.12


## NPCs no mesmo assentamento em atividade social trocam memórias.
static func exchange(
	npc_a: NPCRecord, npc_b: NPCRecord, day: int, rng: RandomNumberGenerator
) -> void:
	_share_one(npc_a, npc_b, day, rng)
	_share_one(npc_b, npc_a, day, rng)
	# Conversar aproxima (ou irrita, se personalidades colidem).
	var affinity: float = 1.0 if absf(
		npc_a.personality["openness"] - npc_b.personality["openness"]
	) < 0.5 else -0.5
	npc_a.shift_relationship(npc_b.id, affinity)
	npc_b.shift_relationship(npc_a.id, affinity)
	npc_a.needs["social"] = maxf(0.0, npc_a.needs["social"] - 0.2)
	npc_b.needs["social"] = maxf(0.0, npc_b.needs["social"] - 0.2)


static func _share_one(
	speaker: NPCRecord, listener: NPCRecord, day: int, rng: RandomNumberGenerator
) -> void:
	if speaker.memories.is_empty() or rng.randf() > SHARE_CHANCE:
		return
	var memory: Dictionary = speaker.memories[rng.randi() % speaker.memories.size()]
	if listener.knows_about(memory["topic"]):
		return
	# Distorção por fofoca: cada salto perde veracidade; NPCs pouco empáticos
	# exageram mais (fofoca saborosa > fofoca precisa).
	var distortion: float = VERACITY_LOSS_PER_HOP * (1.5 - speaker.personality["empathy"])
	listener.remember(
		memory["topic"],
		memory["detail"],
		day,
		maxf(0.1, memory["veracity"] - distortion),
		memory["about"]
	)
	# Opinião sobre o jogador viaja junto do boato.
	if memory["about"] == "player":
		var lean := 3.0 if memory["detail"].begins_with("+") else -3.0
		listener.player_opinion = clampf(
			listener.player_opinion + lean * memory["veracity"], -100.0, 100.0
		)


## Semeia um testemunho direto (crime visto, ajuda recebida...).
static func witness(
	npc: NPCRecord, topic: String, detail: String, day: int, about := ""
) -> void:
	npc.remember(topic, detail, day, 1.0, about)
	if about == "player":
		var lean := 6.0 if detail.begins_with("+") else -6.0
		npc.player_opinion = clampf(npc.player_opinion + lean, -100.0, 100.0)
