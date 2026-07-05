class_name Crafting
extends RefCounted
## Crafting por conhecimento (GDD §9): receitas não são "desbloqueadas por
## nível" — o jogador as APRENDE (vendo NPCs, desmontando, experimentando,
## sendo ensinado). Qualidade = matéria-prima × habilidade × estação.

signal recipe_learned(recipe_id: String, how: String)
signal item_crafted(item_id: String, quality: float)

## Receitas conhecidas: recipe_id -> como aprendeu.
var known_recipes: Dictionary = {}
var recipes_catalog: Dictionary = {}


func load_catalog() -> void:
	var data: Variant = DataLoader.load_json("res://data/recipes/recipes.json")
	if data is Dictionary:
		for recipe: Dictionary in data.get("recipes", []):
			recipes_catalog[recipe["id"]] = recipe


func learn(recipe_id: String, how: String) -> void:
	if known_recipes.has(recipe_id) or not recipes_catalog.has(recipe_id):
		return
	known_recipes[recipe_id] = how
	recipe_learned.emit(recipe_id, how)


## Desmontar um item ensina (chance) a receita dele.
func disassemble(item_id: String, rng: RandomNumberGenerator) -> void:
	for recipe_id: String in recipes_catalog.keys():
		if recipes_catalog[recipe_id].get("output", "") == item_id and rng.randf() < 0.35:
			learn(recipe_id, "desmontagem")


## Tenta fabricar. `inventory` {item_id: qty} é consumido de verdade.
## Retorna a qualidade (0 = falhou/não sabe/faltou material).
func craft(
	recipe_id: String,
	inventory: Dictionary,
	skill_value: float,
	station_quality: float,
	material_quality := 1.0
) -> float:
	if not known_recipes.has(recipe_id):
		return 0.0
	var recipe: Dictionary = recipes_catalog[recipe_id]
	var inputs: Dictionary = recipe.get("inputs", {})
	for item_id: String in inputs.keys():
		if inventory.get(item_id, 0) < int(inputs[item_id]):
			return 0.0
	for item_id: String in inputs.keys():
		inventory[item_id] -= int(inputs[item_id])
	var quality: float = clampf(
		material_quality * 0.4 + (skill_value / 100.0) * 0.4 + station_quality * 0.2,
		0.1, 1.0
	)
	var output: String = recipe.get("output", "")
	inventory[output] = inventory.get(output, 0) + 1
	item_crafted.emit(output, quality)
	return quality


func to_dict() -> Dictionary:
	return {"known_recipes": known_recipes.duplicate()}


func from_dict(data: Dictionary) -> void:
	known_recipes = data.get("known_recipes", known_recipes)
