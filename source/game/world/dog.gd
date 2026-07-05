class_name Dog
extends CharacterBody3D
## Cinza, o filhote adotável: segue você, late e MORDE saqueadores que
## ameaçam seu dono, e adora peixe (alimente interagindo com ele).

const FOLLOW_SPEED := 5.4
const STOP_DISTANCE := 2.4
const GUARD_RANGE := 9.0
const BITE_RANGE := 1.4
const BITE_COOLDOWN := 1.3

var owner_player: Node3D = null

var _rig: QuadrupedRig
var _bite_timer := 0.0
var _wander_timer := 0.0
var _wander_direction := Vector3.ZERO

@onready var adopt_area: Interactable = $Adotar


func _ready() -> void:
	_rig = QuadrupedRig.make(Color(0.55, 0.55, 0.58))
	_rig.scale = Vector3.ONE * 0.55
	add_child(_rig)
	adopt_area.prompt = "Adotar filhote"
	adopt_area.interacted.connect(_on_interact)


func _on_interact(by: Node) -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if owner_player == null and by is Player:
		owner_player = by
		adopt_area.prompt = "Cinza"
		if hud != null:
			hud.show_dialog("", "O filhote fareja sua mão e decide: você é dele agora. Cinza.")
	elif owner_player == by and by is Player:
		if by.inventory.remove("fish"):
			if hud != null:
				hud.show_dialog("", "Cinza devora o peixe e gira duas vezes. Rabo a mil.")
		elif hud != null:
			hud.show_dialog("", "Au! (Cinza aceitaria um peixe.)")


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	_bite_timer = maxf(0.0, _bite_timer - delta)
	if owner_player != null:
		_follow_and_guard()
	else:
		_puppy_wander(delta)
	move_and_slide()


func _follow_and_guard() -> void:
	var threat := _nearest_threat()
	var target := owner_player.global_position
	var chase_speed := FOLLOW_SPEED
	if threat != null:
		target = threat.global_position
		chase_speed = FOLLOW_SPEED * 1.25
		var bite_distance := global_position.distance_to(threat.global_position)
		if bite_distance < BITE_RANGE and _bite_timer <= 0.0:
			_bite_timer = BITE_COOLDOWN
			threat.take_hit(owner_player, 4.0, 6.0)
	var to_target := target - global_position
	to_target.y = 0.0
	# Perdeu o dono de vista há muito: reaparece atrás dele.
	if threat == null and to_target.length() > 28.0:
		global_position = owner_player.global_position \
			- owner_player.transform.basis.z * -1.5 + Vector3.UP * 0.5
		return
	if to_target.length() > (STOP_DISTANCE if threat == null else BITE_RANGE * 0.7):
		var direction := to_target.normalized()
		velocity.x = direction.x * chase_speed
		velocity.z = direction.z * chase_speed
		look_at(global_position + direction, Vector3.UP, true)
	else:
		velocity.x = 0.0
		velocity.z = 0.0


func _nearest_threat() -> CombatActor:
	var best: CombatActor = null
	var best_distance := GUARD_RANGE
	for node in get_tree().get_nodes_in_group("bandits"):
		if node is CombatActor and node.is_alive():
			var d: float = node.global_position.distance_to(owner_player.global_position)
			if d < best_distance:
				best_distance = d
				best = node
	return best


func _puppy_wander(delta: float) -> void:
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_timer = randf_range(1.5, 4.0)
		var angle := randf() * TAU
		_wander_direction = Vector3(cos(angle), 0, sin(angle)) \
			if randf() < 0.5 else Vector3.ZERO
	velocity.x = _wander_direction.x * 1.4
	velocity.z = _wander_direction.z * 1.4
	if _wander_direction.length() > 0.1:
		look_at(global_position + _wander_direction, Vector3.UP, true)
