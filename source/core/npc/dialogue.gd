class_name Dialogue
extends RefCounted
## Diálogo por tópicos + conhecimento (GDD §7.5): NPCs só falam do que
## sabem — memórias próprias, fofocas ouvidas e notícias que já chegaram
## até eles. Sem vendedores de exposition, sem falas oniscientes.

const NEWS_MAX_AGE_DAYS := 15
const NEWS_TRAVEL_DELAY_DAYS := 2

const PROFESSION_LINES := {
	"smith": "A forja não para: ferradura, prego, faca... e o carvão pela hora da morte.",
	"innkeeper": "Senta. Cerveja, ensopado, e tudo que se diz por aí — nessa ordem.",
	"fisher": "A maré anda estranha. O mar fala baixo desde antes do meu avô.",
	"priest": "Todo caminho merece abrigo, forasteiro. Até o seu.",
	"raider": "Rosto novo. Rostos novos valem alguma coisa — vivos ou não.",
	"farmer": "A terra dá o que o céu deixa. Este ano o céu anda avarento.",
	"miner": "Lá embaixo a pedra zumbia, dizem. Eu nunca ouvi. Melhor assim.",
	"hunter": "As manadas mudaram de trilha. Alguma coisa as empurrou.",
	"herbalist": "Cheiro de febre no ar. Leve ervas se for para o pântano.",
	"weaver": "Lã boa vem cara desde que fecharam o passo.",
	"carpenter": "Madeira do Bosque eu não corto. Nem por dobro.",
	"villager": "Dia longo. Sempre são, agora.",
}


## Gera a fala de um NPC para o jogador, a partir do que ele SABE.
static func line_for(npc: NPCRecord, day: int, world_record: Array) -> String:
	var greeting := _greeting(npc)
	var topic := _pick_topic(npc, day, world_record)
	if topic == "":
		return greeting
	return "%s %s" % [greeting, topic]


static func _greeting(npc: NPCRecord) -> String:
	if "player" in npc.fears:
		return "N-não quero problemas..."
	if npc.player_opinion < -30.0:
		return "Sai da minha frente, forasteiro."
	if npc.player_opinion > 30.0:
		return "Boas, amigo!"
	return "Dia."


static func _pick_topic(npc: NPCRecord, day: int, world_record: Array) -> String:
	# 1. Memória forte e recente do próprio NPC (o que ele viveu/ouviu).
	var memory := _strongest_memory(npc, day)
	if not memory.is_empty():
		var prefix := "Dizem que" if memory["veracity"] < 0.7 else "Fica sabendo:"
		return "%s %s." % [prefix, _strip_lean(memory["detail"])]
	# 2. Notícia do Registro do Mundo que JÁ chegou até este lugar.
	var news := _known_news(npc, day, world_record)
	if news != "":
		return "Ouvi que %s." % news
	# 3. Fala de ofício — o que essa pessoa faz o dia todo.
	return PROFESSION_LINES.get(npc.profession, "")


static func _strongest_memory(npc: NPCRecord, day: int) -> Dictionary:
	var best: Dictionary = {}
	var best_score := 0.55  # abaixo disso não vale conversa
	for memory: Dictionary in npc.memories:
		if memory["topic"] == "avistamento_recente":
			continue
		var recency: float = clampf(1.0 - float(day - memory["day"]) / 20.0, 0.0, 1.0)
		var score: float = memory["weight"] * 0.6 + recency * 0.4
		if score > best_score:
			best_score = score
			best = memory
	return best


static func _known_news(npc: NPCRecord, day: int, world_record: Array) -> String:
	# Percorre do mais recente para o mais antigo; notícia de fora chega
	# com atraso (GDD §3.3) — nada de fama teleportada.
	for i in range(world_record.size() - 1, -1, -1):
		var event: Dictionary = world_record[i]
		var age: int = day - int(event["day"])
		if age > NEWS_MAX_AGE_DAYS:
			break
		var is_local: bool = event.get("place", "") == npc.location
		if not is_local and age < NEWS_TRAVEL_DELAY_DAYS:
			continue
		if event.get("description", "") != "":
			return event["description"]
	return ""


## Memórias sobre o jogador guardam o sinal no prefixo (+/-); na fala, sai.
static func _strip_lean(detail: String) -> String:
	if detail.begins_with("+") or detail.begins_with("-"):
		return detail.substr(1)
	return detail
