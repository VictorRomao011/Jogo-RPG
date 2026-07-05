class_name DataLoader
extends RefCounted
## Carrega o conteúdo declarativo de data/ (JSON versionável e moddável).


static func load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("DataLoader: arquivo não encontrado: %s" % path)
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	var text := file.get_as_text()
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null:
		push_error("DataLoader: JSON inválido em %s" % path)
	return parsed


static func load_factions() -> Array:
	var data: Variant = load_json("res://data/factions/factions.json")
	return data.get("factions", []) if data is Dictionary else []


static func load_regions() -> Array:
	var data: Variant = load_json("res://data/regions/regions.json")
	return data.get("regions", []) if data is Dictionary else []


static func load_goods() -> Array:
	var data: Variant = load_json("res://data/economy/goods.json")
	return data.get("goods", []) if data is Dictionary else []


static func load_npc_seeds() -> Dictionary:
	var data: Variant = load_json("res://data/npcs/npc_seeds.json")
	return data if data is Dictionary else {}


static func load_event_templates() -> Array:
	var data: Variant = load_json("res://data/events/templates.json")
	return data.get("templates", []) if data is Dictionary else []
