class_name Inventory
extends RefCounted
## Inventário real do jogador: itens com peso e dinheiro contado.
## É o MESMO dicionário que o Crafting consome — nada de inventários mágicos.

signal changed

var items: Dictionary = {}
var money := 15.0
var max_weight := 35.0


func add(item_id: String, qty := 1) -> void:
	items[item_id] = items.get(item_id, 0) + qty
	changed.emit()


func remove(item_id: String, qty := 1) -> bool:
	if items.get(item_id, 0) < qty:
		return false
	items[item_id] -= qty
	if items[item_id] <= 0:
		items.erase(item_id)
	changed.emit()
	return true


func count(item_id: String) -> int:
	return items.get(item_id, 0)


## Peso total usando o catálogo de itens (data/items/items.json).
func total_weight(catalog: Dictionary) -> float:
	var weight := 0.0
	for item_id: String in items.keys():
		weight += catalog.get(item_id, {}).get("weight", 0.5) * items[item_id]
	return weight


func is_overloaded(catalog: Dictionary) -> bool:
	return total_weight(catalog) > max_weight


func to_dict() -> Dictionary:
	return {"items": items.duplicate(), "money": money}


func from_dict(data: Dictionary) -> void:
	items = data.get("items", items)
	money = data.get("money", money)
	changed.emit()
