class_name Horse
extends CharacterBody3D
## Cavalo montável: interaja para montar, stick/WASD dirige (galope de
## verdade, com inclinação nas curvas), pular desmonta. Solto, pasta.

const RIDE_SPEED := 9.5
const TURN_SPEED := 1.9
const WANDER_SPEED := 1.1

var rider: Node3D = null

var _rig: QuadrupedRig
var _wander_timer := 0.0
var _wander_direction := Vector3.ZERO

@onready var mount_area: Interactable = $Montar


func _ready() -> void:
	_rig = QuadrupedRig.make(Color(0.36, 0.26, 0.18))
	_rig.scale = Vector3(1.55, 1.5, 1.75)
	add_child(_rig)
	mount_area.prompt = "Montar"
	mount_area.interacted.connect(_on_interact)


func _on_interact(by: Node) -> void:
	if rider == null and by is Player and by.mounted == null:
		_mount(by)
	elif rider == by:
		dismount()


func _mount(player: Node3D) -> void:
	rider = player
	player.set_mounted(self)
	mount_area.prompt = "Desmontar"
	# Montar treina de leve o vínculo (Sobrevivência).
	player.skills.practice("survival", 0.3, 0.3)


func dismount() -> void:
	if rider == null:
		return
	var player := rider
	rider = null
	mount_area.prompt = "Montar"
	player.clear_mounted(global_position + transform.basis.x * 1.4 + Vector3.UP * 0.5)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	if rider != null:
		_ride(delta)
	else:
		_graze(delta)
	move_and_slide()


func _ride(delta: float) -> void:
	var input := Actions.move_vector()
	rotate_y(-input.x * TURN_SPEED * delta)
	var forward_amount := maxf(0.0, -input.y)
	var backward_amount := maxf(0.0, input.y) * 0.25
	var direction := -transform.basis.z * (forward_amount - backward_amount)
	velocity.x = direction.x * RIDE_SPEED
	velocity.z = direction.z * RIDE_SPEED
	# Inclina nas curvas em velocidade.
	_rig.rotation.z = lerpf(_rig.rotation.z, -input.x * 0.12 * forward_amount, 6.0 * delta)
	if rider != null:
		rider.global_position = global_position + Vector3(0, 1.55, 0) \
			- transform.basis.z * 0.1
		rider.velocity = Vector3.ZERO


func _graze(delta: float) -> void:
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_timer = randf_range(3.0, 8.0)
		if randf() < 0.6:
			_wander_direction = Vector3.ZERO
		else:
			var angle := randf() * TAU
			_wander_direction = Vector3(cos(angle), 0, sin(angle))
	velocity.x = _wander_direction.x * WANDER_SPEED
	velocity.z = _wander_direction.z * WANDER_SPEED
	if _wander_direction.length() > 0.1:
		look_at(global_position + _wander_direction, Vector3.UP, true)
