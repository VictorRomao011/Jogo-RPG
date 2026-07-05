extends SceneTree
## Testes de unidade do núcleo de simulação (sem dependência de addon).
## Uso: godot --headless --path . --script tests/unit_tests.gd

var _failures: Array = []
var _passed := 0


func _init() -> void:
	_test_clock()
	_test_skills_anti_grind()
	_test_market_scarcity()
	_test_needs_habit()
	_test_gossip_distortion()
	_test_survival_never_kills()
	_test_combat_actor()
	_test_combat_ai()
	_test_dialogue()
	print("---")
	print("%d testes ok, %d falhas" % [_passed, _failures.size()])
	for failure in _failures:
		print("FALHA: %s" % failure)
	quit(1 if not _failures.is_empty() else 0)


func _check(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
	else:
		_failures.append(label)


func _test_clock() -> void:
	var clock := WorldClock.new()
	_check(clock.hour() == 8, "clock começa às 08:00")
	clock.skip_days(31)
	_check(clock.day() == 31, "skip_days avança dias exatos")
	_check(clock.season_index() == 1, "estação muda após 30 dias")


func _test_skills_anti_grind() -> void:
	var skills := Skills.new()
	var start := skills.get_value("long_blades")
	skills.practice("long_blades", 1.0, 0.0)
	_check(skills.get_value("long_blades") == start, "desafio zero não treina (anti-grind)")
	skills.practice("long_blades", 1.0, 1.0)
	_check(skills.get_value("long_blades") > start, "desafio real treina")
	var low_gain_skills := Skills.new()
	low_gain_skills.values["long_blades"] = 90.0
	low_gain_skills.practice("long_blades", 1.0, 1.0)
	var high_gain := skills.get_value("long_blades") - start
	var low_gain: float = low_gain_skills.get_value("long_blades") - 90.0
	_check(low_gain < high_gain, "curva logarítmica: mestre aprende devagar")


func _test_market_scarcity() -> void:
	var market := Market.new("teste", "regiao")
	market.register_good({"id": "grain", "base_price": 2.0, "elasticity": 0.6}, 100.0, 10.0)
	var fair_price := market.price_of("grain")
	market.take_stock("grain", 95.0)
	for _i in range(30):
		market.update_prices()
	_check(market.price_of("grain") > fair_price * 1.5, "escassez encarece de verdade")
	var before := market.price_of("grain")
	market.add_stock("grain", 500.0)
	market.update_prices()
	var after := market.price_of("grain")
	_check(after < before, "oferta derruba preço")
	_check(absf(after - before) < before * 0.5, "preço tem inércia (não teleporta)")


func _test_needs_habit() -> void:
	var npc := NPCRecord.new()
	npc.routine = NPCRecord.DEFAULT_ROUTINE.duplicate()
	npc.needs["hunger"] = 0.1
	npc.needs["sleep"] = 0.1
	npc.needs["duty"] = 0.5
	_check(Needs.choose_activity(npc, 8, 0.0) == "work", "rotina é o hábito")
	npc.needs["hunger"] = 1.0
	_check(Needs.choose_activity(npc, 8, 0.0) == "meal", "urgência quebra rotina")
	npc.personality["courage"] = 0.1
	_check(Needs.choose_activity(npc, 8, 0.9) == "flee", "covarde foge do perigo")


func _test_gossip_distortion() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var witness_npc := NPCRecord.new()
	witness_npc.id = "a"
	var listener := NPCRecord.new()
	listener.id = "b"
	Gossip.witness(witness_npc, "crime", "-roubou a forja", 1, "player")
	_check(witness_npc.player_opinion < 0.0, "testemunho move opinião")
	for _i in range(60):
		Gossip.exchange(witness_npc, listener, 1, rng)
	_check(listener.knows_about("crime"), "fofoca propaga informação")
	var relayed: Dictionary = listener.memories[0]
	_check(relayed["veracity"] < 1.0, "fofoca distorce (perde veracidade)")


func _test_survival_never_kills() -> void:
	var survival := Survival.new()
	for _i in range(200):
		survival.hourly_tick("snow", false, false)
	_check(survival.stamina_multiplier() >= 0.25, "medidores nunca matam sozinhos (piso)")
	survival.eat(0.8)
	_check(survival.hunger < 0.3, "comer é um gesto e resolve")


func _test_combat_actor() -> void:
	var attacker: CombatActor = CombatActor.new()
	var defender: CombatActor = CombatActor.new()
	# Golpe limpo tira vida e postura.
	defender.take_hit(attacker, 20.0, 10.0)
	_check(defender.health == 80.0, "golpe limpo tira vida")
	_check(defender.posture < defender.max_posture, "golpe limpo desgasta postura")
	# Bloqueio segura a vida mas drena postura.
	var blocked_health := defender.health
	defender.blocking = true
	defender.take_hit(attacker, 20.0, 10.0)
	_check(defender.health == blocked_health, "bloqueio segura a vida")
	# Aparo perfeito: quem paga é o atacante (postura).
	defender.blocking = false
	defender.begin_parry()
	var attacker_posture := attacker.posture
	defender.take_hit(attacker, 20.0, 10.0)
	_check(defender.health == blocked_health, "aparo não sofre dano")
	_check(attacker.posture < attacker_posture, "aparo pune a postura do atacante")
	# Ferimento em membro: perna ferida deixa manco.
	defender.parry_timer = 0.0  # janela de aparo expirada
	defender.take_hit(attacker, 30.0, 5.0, "leg")
	_check(defender.move_speed_modifier() < 1.0, "perna ferida deixa manco")
	attacker.free()
	defender.free()


func _test_combat_ai() -> void:
	var ai := CombatAI.new()
	ai.courage = 0.5
	_check(
		ai.decide(1.0, 1.0, 1.0, 0) == CombatAI.Decision.ENGAGE,
		"saudável e confiante ataca"
	)
	_check(
		ai.decide(0.05, 0.2, 1.0, 0) == CombatAI.Decision.FLEE,
		"moral quebrada foge de verdade"
	)
	ai.role = CombatAI.Role.CIRCLER
	_check(
		ai.decide(1.0, 1.0, 1.0, 2) == CombatAI.Decision.CIRCLE,
		"não empilha: com 2 atacando, cerca"
	)
	_check(
		ai.decide(1.0, 1.0, 0.1, 2) == CombatAI.Decision.ENGAGE,
		"postura quebrada do alvo = todos pressionam"
	)
	var horn_ai := CombatAI.new()
	horn_ai.courage = 0.5
	horn_ai.has_horn = true
	_check(
		horn_ai.decide(0.5, 0.3, 1.0, 0) == CombatAI.Decision.CALL_REINFORCEMENTS,
		"moral baixa com chifre chama reforço"
	)
	_check(
		horn_ai.decide(0.5, 0.3, 1.0, 0) == CombatAI.Decision.RETREAT,
		"chifre só toca uma vez"
	)


func _test_dialogue() -> void:
	var npc := NPCRecord.new()
	npc.display_name = "Teste"
	npc.profession = "fisher"
	npc.location = "bruma_alta"
	var line := Dialogue.line_for(npc, 10, [])
	_check(line != "", "NPC sem memórias ainda tem fala de ofício")
	npc.player_opinion = -50.0
	_check(
		Dialogue.line_for(npc, 10, []).begins_with("Sai"),
		"opinião negativa muda a saudação"
	)
	npc.player_opinion = 0.0
	npc.remember("combate", "+o forasteiro derrubou um saqueador", 9, 1.0, "player")
	var informed := Dialogue.line_for(npc, 10, [])
	_check(informed.contains("derrubou"), "NPC fala do que testemunhou")
	_check(not informed.contains("+"), "sinal de opinião não vaza na fala")
	var stranger := NPCRecord.new()
	stranger.profession = "farmer"
	stranger.location = "vila_moinho"
	var news := [{"day": 5, "place": "bruma_alta", "description": "houve luta no vau"}]
	_check(
		Dialogue.line_for(stranger, 6, news).contains("Este ano"),
		"notícia de fora NÃO chega no dia seguinte (atraso real)"
	)
	_check(
		Dialogue.line_for(stranger, 9, news).contains("houve luta"),
		"notícia de fora chega depois do atraso"
	)
