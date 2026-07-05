class_name Player
extends CharacterBody3D
## Controlador do jogador. Consome APENAS ações semânticas do Actions
## (GDD §15.1) — funciona idêntico com teclado, gamepad e touch.
## Stamina é a moeda universal; correr treina Vigor (fazer é aprender).

signal stamina_changed(current: float, maximum: float)
signal interact_requested

const WALK_SPEED := 4.0
const SPRINT_SPEED := 7.0
const SNEAK_SPEED := 2.0
const JUMP_VELOCITY := 4.2
const MOUSE_SENSITIVITY := 0.0025
const TOUCH_LOOK_SENSITIVITY := 0.005
const SPRINT_COST_PER_SEC := 8.0
const STAMINA_REGEN_PER_SEC := 12.0

var skills := Skills.new()
var survival := Survival.new()

var base_max_stamina := 100.0
var stamina := 100.0
var sneaking := false
var look_sensitivity_scale := 1.0

var _hour_accumulator := 0.0

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D


func _ready() -> void:
	if not Actions.is_touch():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Actions.device_changed.connect(_on_device_changed)
	Actions.action_pressed.connect(_on_touch_action)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_apply_look(event.relative * MOUSE_SENSITIVITY * look_sensitivity_scale)
	elif event.is_action_pressed("ui_menu"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed \
			and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE and not Actions.is_touch():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	_process_look(delta)
	_process_movement(delta)
	_process_stamina(delta)
	_process_survival_clock(delta)
	if Actions.was_pressed("interact"):
		interact_requested.emit()


func _process_look(_delta: float) -> void:
	# Mouse-look chega por InputEventMouseMotion; touch-look pelo Actions.
	# Eixo direito de gamepad entra na Fase 1 como ações look_* dedicadas.
	var touch_delta := Actions.look_delta() * TOUCH_LOOK_SENSITIVITY * look_sensitivity_scale
	if touch_delta != Vector2.ZERO:
		_apply_look(touch_delta)


func _apply_look(delta_look: Vector2) -> void:
	rotate_y(-delta_look.x)
	camera_pivot.rotate_x(-delta_look.y)
	camera_pivot.rotation.x = clampf(camera_pivot.rotation.x, -1.2, 1.2)


func _process_movement(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	sneaking = Actions.is_held("sneak")
	var wants_sprint := Actions.is_held("sprint") and stamina > 1.0 and not sneaking
	var speed := WALK_SPEED
	if sneaking:
		speed = SNEAK_SPEED
	elif wants_sprint:
		speed = SPRINT_SPEED

	var input_vec := Actions.move_vector()
	var direction := (transform.basis * Vector3(input_vec.x, 0, input_vec.y)).normalized()
	if direction != Vector3.ZERO:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		if wants_sprint:
			stamina = maxf(0.0, stamina - SPRINT_COST_PER_SEC * delta)
			# Correr de verdade treina Vigor — desafio = quão cansado está.
			skills.practice("vigor", 0.02 * delta * 60.0, 0.3 + survival.fatigue * 0.5)
		if sneaking:
			skills.practice("stealth", 0.01 * delta * 60.0, 0.2)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	if Actions.was_pressed("jump") and is_on_floor() and stamina > 5.0:
		velocity.y = JUMP_VELOCITY
		stamina -= 5.0

	move_and_slide()


func max_stamina() -> float:
	var vigor_bonus := 1.0 + skills.get_value("vigor") / 200.0
	return base_max_stamina * vigor_bonus * survival.stamina_multiplier()


func _process_stamina(delta: float) -> void:
	var maximum := max_stamina()
	if not Actions.is_held("sprint") or Actions.move_vector() == Vector2.ZERO:
		stamina = minf(stamina + STAMINA_REGEN_PER_SEC * delta, maximum)
	stamina = minf(stamina, maximum)
	stamina_changed.emit(stamina, maximum)


## Converte tempo real em horas de jogo para os ticks de sobrevivência.
func _process_survival_clock(delta: float) -> void:
	_hour_accumulator += delta * Sim.world.clock.time_scale / 60.0
	if _hour_accumulator >= 1.0:
		_hour_accumulator -= 1.0
		var region := current_region()
		survival.hourly_tick(Sim.world.weather.current(region), false, false)


func current_region() -> String:
	# Fase 0: uma região de protótipo; o RegionStreamer informará a real.
	return "pelagem_cinza"


func _on_device_changed(device: int) -> void:
	if device == Actions.Device.TOUCH:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_touch_action(action: String) -> void:
	match action:
		"interact":
			interact_requested.emit()
		"jump":
			if is_on_floor() and stamina > 5.0:
				velocity.y = JUMP_VELOCITY
				stamina -= 5.0


func save_data() -> Dictionary:
	return {
		"position": [global_position.x, global_position.y, global_position.z],
		"skills": skills.to_dict(),
		"survival": survival.to_dict(),
		"stamina": stamina,
	}


func load_data(data: Dictionary) -> void:
	var pos: Array = data.get("position", [])
	if pos.size() == 3:
		global_position = Vector3(pos[0], pos[1], pos[2])
	skills.from_dict(data.get("skills", {}))
	survival.from_dict(data.get("survival", {}))
	stamina = data.get("stamina", stamina)
