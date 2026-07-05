class_name Market
extends RefCounted
## Mercado local de um assentamento: estoque, demanda e preços por
## oferta/procura com inércia (média móvel) — preços nunca teleportam.

const PRICE_SMOOTHING := 0.15
const MIN_PRICE_FACTOR := 0.25
const MAX_PRICE_FACTOR := 6.0

var settlement_id: String
var region_id: String
## good_id -> {stock, daily_demand, price, base_price, elasticity}
var goods: Dictionary = {}
## Moeda em circulação local — guerras injetam moeda (inflação).
var money_supply := 1000.0
var base_money_supply := 1000.0


func _init(p_settlement_id: String = "", p_region_id: String = "") -> void:
	settlement_id = p_settlement_id
	region_id = p_region_id


func register_good(good: Dictionary, initial_stock: float, daily_demand: float) -> void:
	goods[good["id"]] = {
		"stock": initial_stock,
		"daily_demand": daily_demand,
		"price": float(good["base_price"]),
		"base_price": float(good["base_price"]),
		"elasticity": float(good.get("elasticity", 1.0)),
	}


func stock_of(good_id: String) -> float:
	return goods.get(good_id, {}).get("stock", 0.0)


func price_of(good_id: String) -> float:
	return goods.get(good_id, {}).get("price", 0.0)


func add_stock(good_id: String, amount: float) -> void:
	if goods.has(good_id):
		goods[good_id]["stock"] = maxf(0.0, goods[good_id]["stock"] + amount)


## Retira até `amount` do estoque; devolve o que conseguiu retirar.
func take_stock(good_id: String, amount: float) -> float:
	if not goods.has(good_id):
		return 0.0
	var taken: float = minf(amount, goods[good_id]["stock"])
	goods[good_id]["stock"] -= taken
	return taken


## Recalcula preços: alvo = base * (demanda/oferta)^elasticidade * inflação,
## suavizado. Escassez real encarece; guerra (moeda extra) inflaciona.
func update_prices() -> void:
	var inflation: float = money_supply / maxf(base_money_supply, 1.0)
	for good_id: String in goods.keys():
		var g: Dictionary = goods[good_id]
		var days_of_supply: float = g["stock"] / maxf(g["daily_demand"], 0.01)
		var scarcity: float = clampf(7.0 / maxf(days_of_supply, 0.25), MIN_PRICE_FACTOR, MAX_PRICE_FACTOR)
		var target: float = g["base_price"] * pow(scarcity, g["elasticity"]) * inflation
		g["price"] = lerpf(g["price"], target, PRICE_SMOOTHING)


## Consumo diário da população local; retorna o déficit total de comida
## (usado pelo EventDirector como pressão de fome).
func consume_daily(population_scale: float = 1.0) -> float:
	var food_deficit := 0.0
	for good_id: String in goods.keys():
		var g: Dictionary = goods[good_id]
		var wanted: float = g["daily_demand"] * population_scale
		var got: float = minf(wanted, g["stock"])
		g["stock"] -= got
		if good_id == "grain" or good_id == "fish":
			food_deficit += wanted - got
	return food_deficit


func to_dict() -> Dictionary:
	return {
		"settlement_id": settlement_id,
		"region_id": region_id,
		"goods": goods.duplicate(true),
		"money_supply": money_supply,
	}


func from_dict(data: Dictionary) -> void:
	settlement_id = data.get("settlement_id", settlement_id)
	region_id = data.get("region_id", region_id)
	goods = data.get("goods", goods)
	money_supply = data.get("money_supply", money_supply)
