class_name EconomySim
extends RefCounted
## Simulação econômica de 3 camadas (GDD §6):
##   1. Produção por assentamento (afetada por clima, estação e segurança)
##   2. Mercados locais com preço por oferta/demanda
##   3. Caravanas fazendo arbitragem física entre mercados

signal caravan_departed(caravan: Caravan)
signal caravan_arrived(caravan: Caravan)
signal caravan_lost(caravan: Caravan)

const CARAVAN_MIN_MARGIN := 1.6  # margem mínima de preço para valer a viagem
const MAX_ACTIVE_CARAVANS := 24

## settlement_id -> Market
var markets: Dictionary = {}
## settlement_id -> Array de produtores: {good_id, daily_output, workers}
var producers: Dictionary = {}
## Rotas: "a|b" -> {days, region_ids}
var routes: Dictionary = {}
var caravans: Array[Caravan] = []
var goods_catalog: Dictionary = {}

var _rng: RandomNumberGenerator
var _caravan_counter := 0


func _init(rng: RandomNumberGenerator) -> void:
	_rng = rng


func setup(regions: Array, goods: Array) -> void:
	for good: Dictionary in goods:
		goods_catalog[good["id"]] = good
	for region: Dictionary in regions:
		for settlement: Dictionary in region.get("settlements", []):
			_setup_settlement(settlement, region["id"])
	_build_routes(regions)


func _setup_settlement(settlement: Dictionary, region_id: String) -> void:
	var market := Market.new(settlement["id"], region_id)
	var pop: float = settlement.get("population", 20)
	for good_id: String in goods_catalog.keys():
		var good: Dictionary = goods_catalog[good_id]
		var demand: float = good.get("demand_per_capita", 0.05) * pop
		market.register_good(good, demand * 10.0, demand)
	markets[settlement["id"]] = market
	var local_producers: Array = []
	for prod: Dictionary in settlement.get("producers", []):
		local_producers.append({
			"good_id": prod["good_id"],
			"daily_output": float(prod["daily_output"]),
			"workers": int(prod.get("workers", 2)),
			"active_workers": int(prod.get("workers", 2)),
		})
	producers[settlement["id"]] = local_producers


func _build_routes(regions: Array) -> void:
	for region: Dictionary in regions:
		for route: Dictionary in region.get("routes", []):
			var key := _route_key(route["from"], route["to"])
			routes[key] = {
				"days": float(route.get("days", 2.0)),
				"region_id": region["id"],
				"danger": float(route.get("danger", 0.1)),
			}


func _route_key(a: String, b: String) -> String:
	return "%s|%s" % [a, b] if a < b else "%s|%s" % [b, a]


## Tick diário: produção -> consumo -> preços -> decisões de caravana.
func daily_tick(weather: WeatherSim, war_zones: Dictionary) -> Dictionary:
	var pressures := {"food_deficit": {}, "lost_caravans": []}
	for settlement_id: String in markets.keys():
		var market: Market = markets[settlement_id]
		var weather_mod := weather.production_modifier(market.region_id)
		var war_mod := 0.5 if war_zones.get(market.region_id, false) else 1.0
		for prod: Dictionary in producers.get(settlement_id, []):
			var worker_mod: float = float(prod["active_workers"]) / maxf(float(prod["workers"]), 1.0)
			market.add_stock(prod["good_id"], prod["daily_output"] * weather_mod * war_mod * worker_mod)
		var deficit := market.consume_daily()
		if deficit > 0.5:
			pressures["food_deficit"][settlement_id] = deficit
		market.update_prices()
	_tick_caravans(weather, pressures)
	_spawn_caravans()
	return pressures


func _tick_caravans(weather: WeatherSim, pressures: Dictionary) -> void:
	for caravan in caravans:
		if not caravan.is_active():
			continue
		match caravan.state:
			Caravan.State.LOADING:
				_load_caravan(caravan)
			Caravan.State.TRAVELING:
				var key := _route_key(caravan.from_settlement, caravan.to_settlement)
				var route: Dictionary = routes.get(key, {"region_id": "", "danger": 0.1})
				caravan.travel_tick(weather.travel_modifier(route["region_id"]))
				if _rng.randf() < route["danger"] * 0.5:
					if caravan.resolve_ambush(_rng.randi_range(2, 6), _rng):
						pressures["lost_caravans"].append(caravan.id)
						caravan_lost.emit(caravan)
			Caravan.State.TRADING:
				_unload_caravan(caravan)
	caravans = caravans.filter(func(c: Caravan) -> bool: return c.is_active())


func _load_caravan(caravan: Caravan) -> void:
	var origin: Market = markets.get(caravan.from_settlement)
	if origin == null:
		caravan.state = Caravan.State.DEAD
		return
	var afford: float = caravan.capital / maxf(origin.price_of(caravan.good_id), 0.01)
	var bought := origin.take_stock(caravan.good_id, minf(afford, 40.0))
	caravan.capital -= bought * origin.price_of(caravan.good_id)
	caravan.cargo = bought
	caravan.state = Caravan.State.TRAVELING
	caravan_departed.emit(caravan)


func _unload_caravan(caravan: Caravan) -> void:
	var destination: Market = markets.get(caravan.to_settlement)
	if destination != null and caravan.cargo > 0.0:
		destination.add_stock(caravan.good_id, caravan.cargo)
		caravan.capital += caravan.cargo * destination.price_of(caravan.good_id)
		destination.update_prices()
	caravan.state = Caravan.State.DEAD
	caravan_arrived.emit(caravan)


## Mercadores avaliam diferenciais de preço e despacham caravanas — a
## arbitragem é o que puxa preços de volta ao equilíbrio.
func _spawn_caravans() -> void:
	if caravans.size() >= MAX_ACTIVE_CARAVANS:
		return
	for key: String in routes.keys():
		var ends := key.split("|")
		var market_a: Market = markets.get(ends[0])
		var market_b: Market = markets.get(ends[1])
		if market_a == null or market_b == null:
			continue
		for good_id: String in goods_catalog.keys():
			var price_a := market_a.price_of(good_id)
			var price_b := market_b.price_of(good_id)
			if price_a <= 0.0 or price_b <= 0.0:
				continue
			var ratio := maxf(price_a, price_b) / minf(price_a, price_b)
			if ratio < CARAVAN_MIN_MARGIN or _rng.randf() > 0.3:
				continue
			var cheap := ends[0] if price_a < price_b else ends[1]
			var dear := ends[1] if price_a < price_b else ends[0]
			if markets[cheap].stock_of(good_id) < 10.0:
				continue
			_caravan_counter += 1
			var caravan := Caravan.new("caravan_%d" % _caravan_counter)
			caravan.from_settlement = cheap
			caravan.to_settlement = dear
			caravan.good_id = good_id
			caravan.capital = 120.0
			caravan.route_days = routes[key]["days"]
			caravan.guards = _rng.randi_range(1, 4)
			caravans.append(caravan)
			if caravans.size() >= MAX_ACTIVE_CARAVANS:
				return


## Injeção de moeda por facção em guerra (soldo) — gera inflação local real.
func inject_money(settlement_id: String, amount: float) -> void:
	var market: Market = markets.get(settlement_id)
	if market != null:
		market.money_supply += amount


func to_dict() -> Dictionary:
	var market_data := {}
	for k: String in markets.keys():
		market_data[k] = markets[k].to_dict()
	return {
		"markets": market_data,
		"caravans": caravans.map(func(c: Caravan) -> Dictionary: return c.to_dict()),
		"caravan_counter": _caravan_counter,
	}


func from_dict(data: Dictionary) -> void:
	var market_data: Dictionary = data.get("markets", {})
	for k: String in market_data.keys():
		if markets.has(k):
			markets[k].from_dict(market_data[k])
	caravans.clear()
	for c: Dictionary in data.get("caravans", []):
		caravans.append(Caravan.from_dict(c))
	_caravan_counter = data.get("caravan_counter", 0)
