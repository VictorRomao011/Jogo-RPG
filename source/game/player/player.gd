class_name Player
extends CombatActor
## Controlador do jogador. Consome APENAS ações semânticas do Actions
## (GDD §15.1) — funciona idêntico com teclado, gamepad e touch.
## Stamina é a moeda universal; correr treina Vigor, aparar treina Aparo
## (fazer é aprender). Herda vida/postura/aparo de CombatActor: as mesmas
## regras de combate valem para todos.

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
const DODGE_COST := 12.0
const DODGE_IFRAMES := 0.3
## No touch, segurar o botão de ataque além disso vira ataque forte.
const TOUCH_HEAVY_HOLD := 0.35

var skills := Skills.new()
var survival := Survival.new()
var inventory := Inventory.new()
var crafting := Crafting.new()
## Catálogo de itens (peso/nutrição) carregado de data/items/items.json.
var item_catalog: Dictionary = {}

var base_max_stamina := 100.0
var stamina := 100.0
var sneaking := false
var look_sensitivity_scale := 1.0

var _hour_accumulator := 0.0
var _attack_cooldown := 0.0
var _dodge_iframes := 0.0
var _dodge_cooldown := 0.0
var _touch_attack_hold := -1.0

@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D


func _ready() -> void:
	super._ready()
	# Câmera em 3ª pessoa: o braço colide com o mundo, nunca com o corpo.
	spring_arm.add_excluded_object(get_rid())
	# Corpo humanoide animado no lugar da cápsula.
	var capsule := get_node_or_null("Mesh")
	if capsule != null:
		capsule.visible = false
	add_child(HumanoidRig.make(
		Color(0.85, 0.68, 0.55), Color(0.24, 0.34, 0.48),
		Color(0.26, 0.23, 0.2), Color(0.2, 0.14, 0.1)
	))
	if not Actions.is_touch():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Actions.device_changed.connect(_on_device_changed)
	Actions.action_pressed.connect(_on_touch_action_pressed)
	Actions.action_released.connect(_on_touch_action_released)
	posture_broken.connect(func(_actor: CombatActor) -> void: stamina = 0.0)
	crafting.load_catalog()
	_load_item_catalog()
	Config.settings_changed.connect(_apply_settings)
	_apply_settings()


func _apply_settings() -> void:
	look_sensitivity_scale = Config.mouse_sensitivity


func _load_item_catalog() -> void:
	var data: Variant = DataLoader.load_json("res://data/items/items.json")
	if data is Dictionary:
		for item: Dictionary in data.get("items", []):
			item_catalog[item["id"]] = item


## Comer/usar remédio direto do inventário — 1 gesto, sem menus fundos.
func consume(item_id: String) -> bool:
	var meta: Dictionary = item_catalog.get(item_id, {})
	if meta.get("category", "") == "medicine":
		if inventory.remove(item_id):
			return survival.use_remedy(item_id)
		return false
	var nutrition: float = meta.get("nutrition", 0.0)
	if nutrition > 0.0 and inventory.remove(item_id):
		survival.eat(nutrition)
		return true
	return false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_apply_look(event.relative * MOUSE_SENSITIVITY * look_sensitivity_scale)
	elif event is InputEventMouseButton and event.pressed \
			and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE and not Actions.is_touch():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_process_look(delta)
	_process_movement(delta)
	_process_combat(delta)
	_process_stamina(delta)
	_process_survival_clock(delta)
	if Actions.was_pressed("interact"):
		interact_requested.emit()


func _process_look(_delta: float) -> void:
	# Mouse-look chega por InputEventMouseMotion; touch-look pelo Actions.
	# Eixo direito de gamepad entra como ações look_* dedicadas.
	var touch_delta := Actions.look_delta() * TOUCH_LOOK_SENSITIVITY * look_sensitivity_scale
	if touch_delta != Vector2.ZERO:
		_apply_look(touch_delta)


func _apply_look(delta_look: Vector2) -> void:
	rotate_y(-delta_look.x)
	camera_pivot.rotate_x(-delta_look.y)
	# Limites de 3ª pessoa: bem para baixo, moderado para cima.
	camera_pivot.rotation.x = clampf(camera_pivot.rotation.x, -1.15, 0.5)


func _process_movement(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	sneaking = Actions.is_held("sneak")
	var wants_sprint := Actions.is_held("sprint") and stamina > 1.0 and not sneaking
	var speed := WALK_SPEED * move_speed_modifier()
	if sneaking:
		speed = SNEAK_SPEED
	elif wants_sprint:
		speed = SPRINT_SPEED * move_speed_modifier()

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


## --- Combate (GDD §8): as mesmas ações nas três entradas -----------------


func _process_combat(delta: float) -> void:
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	_dodge_iframes = maxf(0.0, _dodge_iframes - delta)
	_dodge_cooldown = maxf(0.0, _dodge_cooldown - delta)
	if _touch_attack_hold >= 0.0:
		_touch_attack_hold += delta
	# Teclado/gamepad (touch chega pelos sinais do Actions).
	if Actions.was_pressed("attack_light"):
		_try_attack(false)
	elif Actions.was_pressed("attack_heavy"):
		_try_attack(true)
	if Actions.was_pressed("parry"):
		begin_parry()
	blocking = Actions.is_held("parry") and parry_timer <= 0.0
	if Actions.was_pressed("dodge"):
		_dodge()


func _try_attack(heavy: bool) -> void:
	if _attack_cooldown > 0.0:
		return
	var cost := weapon.heavy_stamina_cost() if heavy else weapon.stamina_cost
	if stamina < cost:
		return
	stamina -= cost
	_apply_aim_assist()
	var swing := weapon.swing_time * (1.8 if heavy else 1.0)
	_attack_cooldown = swing / attack_speed_modifier()
	var damage := weapon.heavy_damage() if heavy else weapon.damage
	var posture_hit := weapon.posture_damage * (1.6 if heavy else 1.0)
	if _sweep_targets(damage, posture_hit):
		# Só treina batendo em quem revida — anti-grind (GDD §11.1).
		skills.practice(weapon.skill, 0.4, 0.7)


## Soft-target (GDD §15.4): no touch, gira suavemente para o alvo mais
## próximo no arco frontal. Mesma mecânica, tuning honesto por dispositivo.
func _apply_aim_assist() -> void:
	if not Config.aim_assist or not Actions.is_touch():
		return
	var forward := -transform.basis.z
	var best: CombatActor = null
	var best_distance := weapon.reach + 1.6
	for node in get_tree().get_nodes_in_group("combat_actors"):
		if node == self or not (node is CombatActor) or not node.is_alive():
			continue
		var to_target: Vector3 = node.global_position - global_position
		to_target.y = 0.0
		var d := to_target.length()
		if d < best_distance and forward.dot(to_target.normalized()) > 0.1:
			best_distance = d
			best = node
	if best != null:
		var look_point := best.global_position
		look_point.y = global_position.y
		look_at(look_point, Vector3.UP, true)


## Varre alvos no arco frontal dentro do alcance da arma.
func _sweep_targets(damage: float, posture_hit: float) -> bool:
	var hit_any := false
	var forward := -transform.basis.z
	for node in get_tree().get_nodes_in_group("combat_actors"):
		if node == self or not (node is CombatActor) or not node.is_alive():
			continue
		var to_target: Vector3 = node.global_position - global_position
		to_target.y = 0.0
		if to_target.length() > weapon.reach + 0.8:
			continue
		if forward.dot(to_target.normalized()) < 0.4:
			continue
		node.take_hit(self, damage, posture_hit)
		hit_any = true
	return hit_any


func _dodge() -> void:
	if stamina < DODGE_COST or _dodge_cooldown > 0.0 or not is_on_floor():
		return
	stamina -= DODGE_COST
	_dodge_iframes = DODGE_IFRAMES
	_dodge_cooldown = 0.8
	var input_vec := Actions.move_vector()
	var burst := transform.basis * Vector3(input_vec.x, 0, input_vec.y)
	if burst.length() < 0.1:
		burst = transform.basis.z  # sem direção = recuo
	velocity += burst.normalized() * 8.0


## Esquiva com iframes; aparo/bloqueio treinam Aparo de verdade.
func take_hit(attacker: CombatActor, damage: float, posture_damage: float, limb := "torso") -> void:
	if _dodge_iframes > 0.0:
		return
	if parry_timer > 0.0:
		skills.practice("block_parry", 0.6, 0.9)
	elif blocking:
		skills.practice("block_parry", 0.25, 0.6)
	super.take_hit(attacker, damage, posture_damage, limb)


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
	# Fase 1: uma região encenada; o RegionStreamer informará a real.
	return "pelagem_cinza"


func current_settlement() -> String:
	return "bruma_alta"


func _on_device_changed(device: int) -> void:
	if device == Actions.Device.TOUCH:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_touch_action_pressed(action: String) -> void:
	match action:
		"interact":
			interact_requested.emit()
		"jump":
			if is_on_floor() and stamina > 5.0:
				velocity.y = JUMP_VELOCITY
				stamina -= 5.0
		"attack_light":
			_touch_attack_hold = 0.0  # decide leve/forte no soltar
		"parry":
			begin_parry()
			blocking = true
		"dodge":
			_dodge()


func _on_touch_action_released(action: String) -> void:
	match action:
		"attack_light":
			if _touch_attack_hold >= 0.0:
				_try_attack(_touch_attack_hold > TOUCH_HEAVY_HOLD)
				_touch_attack_hold = -1.0
		"parry":
			blocking = false


func save_data() -> Dictionary:
	return {
		"position": [global_position.x, global_position.y, global_position.z],
		"skills": skills.to_dict(),
		"survival": survival.to_dict(),
		"inventory": inventory.to_dict(),
		"crafting": crafting.to_dict(),
		"stamina": stamina,
		"health": health,
	}


func load_data(data: Dictionary) -> void:
	var pos: Array = data.get("position", [])
	if pos.size() == 3:
		global_position = Vector3(pos[0], pos[1], pos[2])
	skills.from_dict(data.get("skills", {}))
	survival.from_dict(data.get("survival", {}))
	inventory.from_dict(data.get("inventory", {}))
	crafting.from_dict(data.get("crafting", {}))
	stamina = data.get("stamina", stamina)
	health = data.get("health", health)
