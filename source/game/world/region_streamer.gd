class_name RegionStreamer
extends Node3D
## Streaming de encenação (GDD §7.1/§16.3): materializa corpos para NPCs
## abstratos próximos do jogador e os dissolve ao afastar. Raio menor e
## imposters no Android — a simulação embaixo é idêntica.

const NPC_BODY_SCENE := "res://source/game/npc_body/npc_body.tscn"

@export var settlement_id := "bruma_alta"
@export var stage_radius := 150.0

## Pontos de atividade da vila (work/meal/social/sleep) por marcadores filhos.
var activity_spots: Dictionary = {}

var _staged: Dictionary = {}
var _check_timer := 0.0


func _ready() -> void:
	if OS.get_name() == "Android":
		stage_radius *= 0.6
	for child in get_children():
		if child is Marker3D:
			activity_spots[child.name] = child.global_position


func _process(delta: float) -> void:
	_check_timer -= delta
	if _check_timer > 0.0:
		return
	_check_timer = 1.0
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var close := global_position.distance_to(player.global_position) < stage_radius
	if close:
		_stage_npcs()
	else:
		_unstage_all()


func _stage_npcs() -> void:
	for npc: NPCRecord in Sim.world.npcs.alive_in(settlement_id):
		if _staged.has(npc.id):
			continue
		var scene: PackedScene = load(NPC_BODY_SCENE)
		if scene == null:
			return
		var body: NPCBody = scene.instantiate()
		add_child(body)
		body.bind_record(npc, activity_spots)
		var spot: Variant = activity_spots.get("work", Vector3.ZERO)
		body.global_position = global_position + Vector3(
			randf_range(-5, 5), 1.0, randf_range(-5, 5)
		) if not (spot is Vector3) else spot
		_staged[npc.id] = body
	# Corpos de NPCs que morreram na simulação abstrata somem da cena.
	for npc_id: String in _staged.keys().duplicate():
		var rec: NPCRecord = Sim.world.npcs.npcs.get(npc_id)
		if rec == null or not rec.alive or rec.location != settlement_id:
			_staged[npc_id].queue_free()
			_staged.erase(npc_id)


func _unstage_all() -> void:
	for npc_id: String in _staged.keys():
		_staged[npc_id].queue_free()
	_staged.clear()
