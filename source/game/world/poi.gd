class_name POI
extends Area3D
## Ponto de interesse artesanal (GDD §13.2). Descoberta é diegética:
## nenhum ícone prévio no mapa — o nome só existe depois que você chegou.
## Se for sítio de ressonância, alimenta o fio do Eco (GDD §13.3).

@export var location_name := "Lugar Sem Nome"
## Camada 1 de leitura: a anomalia que pergunta algo.
@export_multiline var lore_hint := ""
@export var is_echo_site := false
@export var echo_id := ""

var _discovered := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if _discovered or not (body is Player):
		return
	_discovered = true
	var hud := get_tree().get_first_node_in_group("hud")
	var day := Sim.world.clock.day()
	if hud != null:
		var text := location_name if lore_hint == "" else "%s — %s" % [location_name, lore_hint]
		hud.show_dialog("", text)
	# Descoberta vira conhecimento do mundo (bardos podem citar depois).
	Sim.world.director.record(
		day, "social", "um forasteiro andou explorando %s" % location_name, "bruma_alta"
	)
	if is_echo_site and echo_id != "":
		if Sim.world.echoes.find(echo_id):
			var whisper := Sim.world.echoes.whisper_for(Sim.world.echoes.count())
			if hud != null:
				hud.show_dialog("", whisper)
