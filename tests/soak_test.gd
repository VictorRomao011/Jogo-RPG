extends SceneTree
## Soak test (GDD §16.4): roda o mundo por N dias SEM jogador e valida
## sanidade — o jogo deve parecer vivo mesmo sem o jogador, sem quebrar.
##
## Uso: godot --headless --path . --script tests/soak_test.gd [dias]

const DEFAULT_DAYS := 300


func _init() -> void:
	var days := DEFAULT_DAYS
	var args := OS.get_cmdline_user_args()
	if not args.is_empty() and args[0].is_valid_int():
		days = int(args[0])

	print("=== SOAK TEST: simulando %d dias de Vaethir ===" % days)
	var world := WorldState.new()
	world.initialize(173)

	var initial_population := world.npcs.population_alive()
	var event_count := 0
	var war_days := 0
	world.day_simulated.connect(
		func(_day: int, events: Array) -> void: event_count += events.size()
	)

	var failures: Array = []
	for day in range(days):
		world.clock.skip_days(1)
		if not world.factions.active_war_zones().is_empty():
			war_days += 1
		if day % 30 == 0:
			_check_sanity(world, day, failures)

	_check_sanity(world, days, failures)
	_report(world, initial_population, event_count, war_days, days, failures)
	quit(1 if not failures.is_empty() else 0)


func _check_sanity(world: WorldState, day: int, failures: Array) -> void:
	for settlement_id: String in world.economy.markets.keys():
		var market: Market = world.economy.markets[settlement_id]
		for good_id: String in market.goods.keys():
			var price: float = market.goods[good_id]["price"]
			var stock: float = market.goods[good_id]["stock"]
			if price <= 0.0 or is_nan(price) or is_inf(price):
				failures.append("dia %d: preço inválido %s em %s: %f" % [day, good_id, settlement_id, price])
			if stock < 0.0 or is_nan(stock):
				failures.append("dia %d: estoque inválido %s em %s: %f" % [day, good_id, settlement_id, stock])
	for faction: Faction in world.factions.factions.values():
		if faction.troops < 0 or faction.gold < 0.0 or faction.food < 0.0:
			failures.append("dia %d: recursos negativos na facção %s" % [day, faction.id])
	var alive := world.npcs.population_alive()
	if alive <= 0:
		failures.append("dia %d: população extinta" % day)
	for key: String in world.factions.conflicts.keys():
		var conflict: Dictionary = world.factions.conflicts[key]
		if conflict["state"] == FactionSim.WarState.WAR and conflict["days_in_state"] > 90:
			failures.append("dia %d: guerra eterna em %s" % [day, key])


func _report(
	world: WorldState, initial_pop: int, events: int, war_days: int,
	days: int, failures: Array
) -> void:
	print("--- Relatório ---")
	print("Relógio final: %s" % world.clock.timestamp())
	print("População: %d -> %d" % [initial_pop, world.npcs.population_alive()])
	print("Eventos dinâmicos disparados: %d" % events)
	print("Dias com guerra ativa: %d/%d" % [war_days, days])
	print("Registros históricos: %d" % world.director.world_record.size())
	print("Caravanas ativas agora: %d" % world.economy.caravans.size())
	var sample: Market = world.economy.markets.get("bruma_alta")
	if sample != null:
		print("Preço do grão em Bruma Alta: %.2f (base 2.00)" % sample.price_of("grain"))
	if failures.is_empty():
		print("SOAK OK: mundo estável por %d dias." % days)
	else:
		print("SOAK FALHOU (%d problemas):" % failures.size())
		for failure in failures:
			print("  - %s" % failure)
