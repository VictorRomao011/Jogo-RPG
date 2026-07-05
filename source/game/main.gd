class_name Main
extends Node3D
## Cena raiz do protótipo cinza (Fase 0): liga jogador, HUD e mundo.
## O objetivo desta cena é provar os pilares: simulação viva embaixo,
## mesma jogabilidade nas três entradas, HUD que quase não existe.

@onready var player: Player = $Player
@onready var hud: HUD = $HUD


func _ready() -> void:
	hud.bind_player(player)
	player.interact_requested.connect(_on_interact_requested)
	var saved := Sim.load_game()
	if not saved.is_empty():
		player.load_data(saved)


func _on_interact_requested() -> void:
	var best: Interactable = null
	var best_distance := 2.5
	for node in get_tree().get_nodes_in_group("interactables"):
		if node is Interactable:
			var d: float = node.global_position.distance_to(player.global_position)
			if d < best_distance:
				best_distance = d
				best = node
	if best != null:
		best.interact(player)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		# Android pausa o app: salvar é obrigatório (GDD §16.3).
		Sim.save_game(player.save_data())
