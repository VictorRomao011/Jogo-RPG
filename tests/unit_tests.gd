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
