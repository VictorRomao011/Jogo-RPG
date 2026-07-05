class_name Wolf
extends CombatActor
## Lobo: predador de verdade. Ronda a floresta, caça corças, e ataca o
## jogador que chega perto demais. Foge ferido — e lobos com fome voltam.

const SPEED := 6.2
const AGGRO_RANGE := 11.0
const BITE_RANGE := 1.5
const BITE_COOLDOWN := 1.4

var _rig: QuadrupedRig
var _bite_timer := 0.0
var _wander_timer := 0.0
var _wander_direction := Vector3.ZERO
var _fleeing := false


func _ready() -> void:
	super._ready()
	max_health = 32.0
	health = max_health
	max_posture = 25.0
	posture = max_posture
	_rig = QuadrupedRig.make(Color(0.32, 0.32, 0.35))
	_rig.scale = Vector3(1.0, 0.95, 1.15)
	add_child(_rig)
	damaged.connect(func(_a: CombatActor, _amt: float, _l: String) -> void:
		if health < max_health * 0.35:
			_fleeing = true
	)
	died.connect(_on_died)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not is_on_floor():
		velocity += get_gravity() * delta
	_bite_timer = maxf(0.0, _bite_timer - delta)
	var prey := _find_prey()
	if _fleeing:
		_run(-_direction_to(prey) if prey != null else _wander_direction, SPEED * 1.2)
	elif prey != null:
		_hunt(prey)
	else:
		_prowl(delta)
	move_and_slide()


func _find_prey() -> Node3D:
	var player := get_tree().get_first_node_in_group("player")
	if player is CombatActor and player.is_alive() \
			and global_position.distance_to(player.global_position) < AGGRO_RANGE:
		return player
	return null


func _direction_to(target: Node3D) -> Vector3:
	if target == null:
		return Vector3.ZERO
	var direction := target.global_position - global_position
	direction.y = 0.0
	return direction.normalized()


func _hunt(prey: Node3D) -> void:
	var distance := global_position.distance_to(prey.global_position)
	if distance < BITE_RANGE:
		velocity.x = 0.0
		velocity.z = 0.0
		if _bite_timer <= 0.0 and prey is CombatActor:
			_bite_timer = BITE_COOLDOWN
			prey.take_hit(self, 7.0, 6.0)
	else:
		_run(_direction_to(prey), SPEED)


func _run(direction: Vector3, speed: float) -> void:
	if direction.length() < 0.1:
		return
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	look_at(global_position + direction, Vector3.UP, true)


func _prowl(delta: float) -> void:
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_timer = randf_range(2.0, 6.0)
		var angle := randf() * TAU
		_wander_direction = Vector3(cos(angle), 0, sin(angle)) \
			if randf() < 0.7 else Vector3.ZERO
	_run(_wander_direction, SPEED * 0.35)


func _on_died(_actor: CombatActor) -> void:
	set_physics_process(false)
	rotation.z = PI / 2.0
	# Caçar rende couro — o mundo paga o risco.
	if last_attacker is Player:
		last_attacker.inventory.add("leather", 1)
	await get_tree().create_timer(15.0).timeout
	queue_free()
