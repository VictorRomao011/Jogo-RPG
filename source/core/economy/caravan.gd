class_name Caravan
extends RefCounted
## Caravana como agente físico da simulação: compra barato, viaja de verdade
## pela rota (pode ser encontrada, escoltada ou emboscada) e vende caro.
## É o mecanismo que equaliza preços entre mercados.

enum State { LOADING, TRAVELING, TRADING, DEAD }

var id: String
var from_settlement: String
var to_settlement: String
var good_id: String
var cargo := 0.0
var capital := 0.0
var guards := 2
var state := State.LOADING
## Progresso 0..1 ao longo da rota — posição real no mundo.
var route_progress := 0.0
var route_days := 2.0


func _init(p_id: String = "") -> void:
	id = p_id


func is_active() -> bool:
	return state != State.DEAD


## Avança um tick diário de viagem, modulado pelo clima da região.
func travel_tick(travel_modifier: float) -> void:
	if state != State.TRAVELING:
		return
	route_progress += (1.0 / maxf(route_days, 0.5)) * travel_modifier
	if route_progress >= 1.0:
		route_progress = 1.0
		state = State.TRADING


## Emboscada resolvida abstratamente quando longe do jogador.
## Retorna true se a caravana foi destruída.
func resolve_ambush(bandit_strength: int, rng: RandomNumberGenerator) -> bool:
	var defense := guards + rng.randi_range(0, 2)
	if bandit_strength > defense:
		state = State.DEAD
		return true
	guards = maxi(0, guards - 1)
	return false


func to_dict() -> Dictionary:
	return {
		"id": id,
		"from": from_settlement,
		"to": to_settlement,
		"good_id": good_id,
		"cargo": cargo,
		"capital": capital,
		"guards": guards,
		"state": state,
		"route_progress": route_progress,
		"route_days": route_days,
	}


static func from_dict(data: Dictionary) -> Caravan:
	var c := Caravan.new(data.get("id", ""))
	c.from_settlement = data.get("from", "")
	c.to_settlement = data.get("to", "")
	c.good_id = data.get("good_id", "")
	c.cargo = data.get("cargo", 0.0)
	c.capital = data.get("capital", 0.0)
	c.guards = data.get("guards", 2)
	c.state = data.get("state", State.LOADING)
	c.route_progress = data.get("route_progress", 0.0)
	c.route_days = data.get("route_days", 2.0)
	return c
