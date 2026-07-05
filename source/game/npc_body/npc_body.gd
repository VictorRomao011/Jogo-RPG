class_name NPCBody
extends CharacterBody3D
## Corpo encenado de um NPC (GDD §7.1). Só existe perto do jogador; a vida
## real está no NPCRecord. Este nó lê a decisão do registro e a encena:
## anda até o trabalho, senta na taverna, dorme — e percebe o jogador.

const WALK_SPEED := 2.2

## O registro é a fonte da verdade; o corpo é descartável.
var record: NPCRecord
var current_activity := "idle"
## Pontos da vila para cada atividade (preenchidos pelo RegionStreamer).
var activity_spots: Dictionary = {}

var _target := Vector3.ZERO
var _has_target := false
var _perception_timer := 0.0


func bind_record(npc_record: NPCRecord, spots: Dictionary) -> void:
	record = npc_record
	activity_spots = spots


func _physics_process(delta: float) -> void:
	if record == null or not record.alive:
		return
	_follow_schedule()
	_move(delta)
	_perception_timer -= delta
	if _perception_timer <= 0.0:
		_perception_timer = 0.5
		_perceive()


func _follow_schedule() -> void:
	var hour := Sim.world.clock.hour()
	var activity := Needs.choose_activity(record, hour, 0.0)
	if activity == current_activity:
		return
	current_activity = activity
	var spot: Variant = activity_spots.get(activity)
	if spot is Vector3:
		_target = spot
		_has_target = true


func _move(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	if _has_target:
		var to_target := _target - global_position
		to_target.y = 0.0
		if to_target.length() < 0.5:
			_has_target = false
			velocity.x = 0.0
			velocity.z = 0.0
		else:
			var dir := to_target.normalized()
			velocity.x = dir.x * WALK_SPEED
			velocity.z = dir.z * WALK_SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, WALK_SPEED)
		velocity.z = move_toward(velocity.z, 0.0, WALK_SPEED)
	move_and_slide()


## Percepção degradada por clima (GDD §7.4) — tempestade favorece furto.
func _perceive() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var weather_mod := Sim.world.weather.perception_modifier(record.location)
	var sight_range := 12.0 * weather_mod
	var distance := global_position.distance_to(player.global_position)
	if distance > sight_range:
		return
	if player is Player and player.sneaking:
		var stealth: float = player.skills.get_value("stealth")
		if distance > sight_range * (0.3 + 0.4 * (1.0 - stealth / 100.0)):
			return
	# Viu o jogador: memória curta de avistamento (base para testemunho).
	if not record.knows_about("avistamento_recente"):
		record.remember(
			"avistamento_recente", "vi o forasteiro por aqui",
			Sim.world.clock.day(), 1.0, "player"
		)


## Testemunhou um crime: decide por personalidade (GDD §7.4).
func witness_crime(detail: String) -> void:
	if record == null:
		return
	var day := Sim.world.clock.day()
	if record.personality["loyalty"] > 0.6:
		Gossip.witness(record, "crime", "-%s" % detail, day, "player")
	elif record.personality["greed"] > 0.7:
		record.remember("chantagem", detail, day, 1.0, "player")
	# Covardes e cúmplices "não viram nada".
