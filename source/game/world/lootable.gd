class_name Lootable
extends Interactable
## Recipiente saqueável. Se tem dono, pegar é FURTO — e furto sem
## testemunha não existe (GDD §5.1/§7.4). Testemunhas decidem por
## personalidade; o clima degrada a percepção (tempestade favorece o crime).

const WITNESS_BASE_RANGE := 12.0

@export var item_id := "iron"
@export var quantity := 2
## NPC dono (vazio = achado legítimo, sem crime).
@export var owner_npc_id := ""

var looted := false


func _ready() -> void:
	super._ready()
	prompt = "Saquear" if owner_npc_id != "" else "Pegar"
	is_crime = owner_npc_id != ""
	interacted.connect(_on_looted)


func _on_looted(by: Node) -> void:
	if looted or not (by is Player):
		return
	looted = true
	var player: Player = by
	player.inventory.add(item_id, quantity)
	var hud := get_tree().get_first_node_in_group("hud")
	if is_crime:
		var witnesses := _find_witnesses(player)
		for witness: NPCBody in witnesses:
			witness.witness_crime("furto no depósito de %s" % owner_npc_id)
		if hud != null:
			if witnesses.is_empty():
				hud.show_dialog("", "Ninguém viu. (Você acha.)")
			else:
				hud.show_dialog("", "Alguém viu você.")
	elif hud != null:
		hud.show_dialog("", "Você pegou %d× %s." % [quantity, item_id])
	# Furto treina furtividade só se houve risco real (anti-grind).
	if is_crime:
		player.skills.practice("stealth", 0.6, 0.4 + 0.4 * float(player.sneaking))
	prompt = "Vazio"


## Percepção real: distância, clima e furtividade do ladrão contam.
func _find_witnesses(player: Player) -> Array:
	var witnesses: Array = []
	var weather_mod := Sim.world.weather.perception_modifier(player.current_region())
	var sneak_mod := 0.55 if player.sneaking else 1.0
	var effective_range := WITNESS_BASE_RANGE * weather_mod * sneak_mod
	for body in get_tree().get_nodes_in_group("npc_bodies"):
		if body is NPCBody and body.record != null and body.record.alive \
				and body.global_position.distance_to(global_position) < effective_range:
			witnesses.append(body)
	return witnesses
