class_name Critter
extends CharacterBody3D
## Fauna ambiente (GDD: animais interagem): corças pastam, vagueiam e
## FOGEM do jogador — presença viva e treino honesto de furtividade
## (chegar perto sem espantar exige agachar e vento a favor... um dia).

const WANDER_SPEED := 1.3
const FLEE_SPEED := 5.5
const FLEE_RANGE := 7.0

var _direction := Vector3.ZERO
var _timer := 0.0
var _fleeing := false


func _ready() -> void:
	_timer = randf_range(1.0, 4.0)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	var player := get_tree().get_first_node_in_group("player")
	if player is Player:
		var to_player: Vector3 = player.global_position - global_position
		to_player.y = 0.0
		var threat_range := FLEE_RANGE * (0.45 if player.sneaking else 1.0)
		if to_player.length() < threat_range:
			_fleeing = true
			_timer = 2.5
			_direction = -to_player.normalized()
	_timer -= delta
	if _timer <= 0.0:
		_fleeing = false
		_timer = randf_range(2.0, 6.0)
		if randf() < 0.5:
			_direction = Vector3.ZERO  # pasta
		else:
			var angle := randf() * TAU
			_direction = Vector3(cos(angle), 0.0, sin(angle))
	var speed := FLEE_SPEED if _fleeing else WANDER_SPEED
	velocity.x = _direction.x * speed
	velocity.z = _direction.z * speed
	if _direction.length() > 0.1:
		look_at(global_position + _direction, Vector3.UP, true)
	move_and_slide()
