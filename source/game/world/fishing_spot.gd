class_name FishingSpot
extends Interactable
## Pesca: lance a linha, espere a água decidir. Peixe alimenta você e o
## Cinza — e treina Sobrevivência. Sem minigame de reflexo no touch.

var _busy := false


func _ready() -> void:
	super._ready()
	prompt = "Pescar"
	interacted.connect(_on_fish)


func _on_fish(by: Node) -> void:
	if _busy or not (by is Player):
		return
	_busy = true
	prompt = "Pescando..."
	var hud := get_tree().get_first_node_in_group("hud")
	if hud != null:
		hud.show_dialog("", "Você lança a linha. A água respira devagar.")
	await get_tree().create_timer(randf_range(3.0, 7.0)).timeout
	_busy = false
	prompt = "Pescar"
	if not is_instance_valid(by) \
			or by.global_position.distance_to(global_position) > 5.0:
		return
	var player: Player = by
	var roll := randf()
	if hud == null:
		return
	if roll < 0.6:
		var amount := 1 + (1 if randf() < 0.3 else 0)
		player.inventory.add("fish", amount)
		player.skills.practice("survival", 0.6, 0.4)
		hud.show_dialog("", "Fisgou! %d× peixe na mochila." % amount)
	elif roll < 0.85:
		hud.show_dialog("", "Beliscou... e fugiu. O mar riu baixinho.")
	else:
		player.inventory.add("cloth", 1)
		hud.show_dialog("", "Você pescou... um trapo encharcado. Serve de tecido.")
