class_name Bandit
extends CombatActor
## Saqueador da Máscara Rubra encenado (GDD §8.3). Usa CombatAI para
## decisões táticas: cerca, pressiona postura quebrada, recua, chama
## reforços e FOGE — e a fuga vira memória do mundo (fofoca real).

const SPEED := 3.4
const AGGRO_RANGE := 18.0
const FLEE_ESCAPE_DISTANCE := 30.0
const DECISION_INTERVAL := 0.5

var ai := CombatAI.new()
var target: CombatActor

var _decision: int = CombatAI.Decision.ENGAGE
var _decision_timer := 0.0
var _attack_timer := 0.0
var _stagger_timer := 0.0
var _strafe_direction := 1.0


func _ready() -> void:
	super._ready()
	add_to_group("bandits")
	max_health = 55.0
	health = max_health
	max_posture = 40.0
	posture = max_posture
	ai.courage = randf_range(0.3, 0.8)
	ai.role = CombatAI.Role.HARASSER if randf() < 0.4 else CombatAI.Role.CIRCLER
	ai.has_horn = randf() < 0.25
	_strafe_direction = 1.0 if randf() < 0.5 else -1.0
	weapon = Weapon.new()
	weapon.damage = 9.0
	weapon.posture_damage = 10.0
	weapon.reach = 1.4
	weapon.swing_time = 0.6
	posture_broken.connect(func(_actor: CombatActor) -> void: _stagger_timer = 1.2)
	died.connect(_on_died)
	var capsule := get_node_or_null("Mesh")
	if capsule != null:
		capsule.visible = false
	add_child(HumanoidRig.make(
		Color(0.7, 0.55, 0.42), Color(0.42, 0.16, 0.13),
		Color(0.22, 0.2, 0.18), Color(0.1, 0.08, 0.06), true
	))
	var tag := Label3D.new()
	tag.text = "Máscara Rubra"
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.position = Vector3(0, 2.15, 0)
	tag.font_size = 28
	tag.pixel_size = 0.004
	tag.outline_size = 8
	tag.modulate = Color(0.95, 0.35, 0.3)
	tag.visibility_range_end = 13.0
	add_child(tag)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not is_on_floor():
		velocity += get_gravity() * delta
	_attack_timer = maxf(0.0, _attack_timer - delta)
	_stagger_timer = maxf(0.0, _stagger_timer - delta)
	if _stagger_timer > 0.0:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return
	_acquire_target()
	if target == null:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.z = move_toward(velocity.z, 0.0, SPEED)
		move_and_slide()
		return
	_decision_timer -= delta
	if _decision_timer <= 0.0:
		_decision_timer = DECISION_INTERVAL
		_decide()
	_act(delta)
	move_and_slide()


func _acquire_target() -> void:
	if target != null and is_instance_valid(target) and target.is_alive():
		return
	target = null
	var player := get_tree().get_first_node_in_group("player")
	if player is CombatActor and player.is_alive() \
			and global_position.distance_to(player.global_position) < AGGRO_RANGE:
		target = player


func _decide() -> void:
	var pack := get_tree().get_nodes_in_group("bandits")
	var alive_count := 0
	var engaging := 0
	for member in pack:
		if member is Bandit and member.is_alive():
			alive_count += 1
			if member != self and member._decision == CombatAI.Decision.ENGAGE:
				engaging += 1
	var group_ratio := float(alive_count) / maxf(float(pack.size()), 1.0)
	var target_posture_ratio: float = target.posture / maxf(target.max_posture, 1.0)
	_decision = ai.decide(health / max_health, group_ratio, target_posture_ratio, engaging)
	if _decision == CombatAI.Decision.CALL_REINFORCEMENTS:
		# Chifre diegético: o reforço existe de verdade (ou não vem).
		get_tree().call_group("main", "on_horn_blown", global_position)


func _act(_delta: float) -> void:
	var to_target := target.global_position - global_position
	to_target.y = 0.0
	var distance := to_target.length()
	if distance < 0.2:
		return
	var direction := to_target.normalized()
	var look_point := target.global_position
	look_point.y = global_position.y
	look_at(look_point, Vector3.UP, true)
	match _decision:
		CombatAI.Decision.ENGAGE:
			if distance > weapon.reach:
				_move_toward_direction(direction)
			else:
				velocity.x = 0.0
				velocity.z = 0.0
				_try_attack(distance)
		CombatAI.Decision.CIRCLE:
			var tangent := direction.cross(Vector3.UP) * _strafe_direction
			var keep_distance := direction if distance > 4.5 else -direction
			_move_toward_direction((tangent + keep_distance * 0.4).normalized(), 0.7)
		CombatAI.Decision.RETREAT:
			_move_toward_direction(-direction, 0.8)
		CombatAI.Decision.FLEE, CombatAI.Decision.CALL_REINFORCEMENTS:
			_move_toward_direction(-direction)
			if distance > FLEE_ESCAPE_DISTANCE:
				_escape()


func _move_toward_direction(direction: Vector3, speed_scale := 1.0) -> void:
	velocity.x = direction.x * SPEED * speed_scale
	velocity.z = direction.z * SPEED * speed_scale


func _try_attack(distance: float) -> void:
	if _attack_timer > 0.0 or distance > weapon.reach + 0.3:
		return
	_attack_timer = weapon.swing_time * 2.2  # ritmo legível, telegrafado
	target.take_hit(self, weapon.damage, weapon.posture_damage)


## Escapou vivo: o mundo fica sabendo — sem script, só consequência.
func _escape() -> void:
	ai.register_flee_memory(Sim.world.clock.day(), true)
	Sim.world.director.record(
		Sim.world.clock.day(), "conflict",
		"um saqueador voltou correndo do vau, falando de um forasteiro perigoso",
		"bruma_alta"
	)
	queue_free()


## Morreu: testemunhas próximas formam opinião (reputação por testemunho).
func _on_died(_actor: CombatActor) -> void:
	if last_attacker is Player:
		var day := Sim.world.clock.day()
		for body in get_tree().get_nodes_in_group("npc_bodies"):
			if body is NPCBody and body.record != null \
					and body.global_position.distance_to(global_position) < 20.0:
				Gossip.witness(
					body.record, "combate",
					"+o forasteiro derrubou um saqueador da Máscara", day, "player"
				)
	# Corpo cai e fica um tempo — cicatriz curta do evento.
	set_physics_process(false)
	rotation.z = PI / 2.0
	await get_tree().create_timer(20.0).timeout
	queue_free()
