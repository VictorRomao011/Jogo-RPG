class_name Main
extends Node3D
## Cena raiz da fatia vertical (Fase 1): liga jogador, HUD e mundo.
## Aqui a simulação vira encenação: eventos de conflito materializam
## emboscadas reais, chifres chamam reforços que existem de verdade,
## e conversas de taverna vazam o que os NPCs realmente sabem.

const BANDIT_SCENE := "res://source/game/combat/bandit.tscn"
const MAX_ACTIVE_BANDITS := 5
const OVERHEAR_INTERVAL := 15.0
const OVERHEAR_RANGE := 7.0

var _spawn_position := Vector3.ZERO
var _overhear_timer := 8.0

@onready var player: Player = $Player
@onready var hud: HUD = $HUD
@onready var trade_screen: TradeScreen = $TradeScreen
@onready var craft_screen: CraftScreen = $CraftScreen
@onready var journal_screen: JournalScreen = $JournalScreen


func _ready() -> void:
	add_to_group("main")
	hud.bind_player(player)
	player.interact_requested.connect(_on_interact_requested)
	player.died.connect(_on_player_died)
	Sim.world_event.connect(_on_world_event)
	Actions.action_pressed.connect(func(action: String) -> void:
		if action == "open_journal":
			_toggle_journal()
	)
	var saved := Sim.load_game()
	if not saved.is_empty():
		player.load_data(saved)
	_spawn_position = player.global_position


func _process(delta: float) -> void:
	_overhear_timer -= delta
	if _overhear_timer <= 0.0:
		_overhear_timer = OVERHEAR_INTERVAL
		_try_overhear()
	if Actions.was_pressed("open_journal"):
		_toggle_journal()


## Caderno nas 3 entradas: J / LB / botão touch — a MESMA ação semântica.
func _toggle_journal() -> void:
	if journal_screen.visible:
		journal_screen.close()
		return
	for screen in get_tree().get_nodes_in_group("modal_screen"):
		if screen.visible:
			return
	journal_screen.open(player)


func _on_interact_requested() -> void:
	var best: Interactable = null
	var best_distance := 2.5
	for node in get_tree().get_nodes_in_group("interactables"):
		if node is Interactable:
			var d: float = node.global_position.distance_to(player.global_position)
			if d < best_distance:
				best_distance = d
				best = node
	if best != null:
		best.interact(player)
		if best.name == "Fogueira":
			_rest_at_fire()
		elif best.name == "Bancada":
			craft_screen.open(player, "Bancada da Forja", 0.7)


## Chamado pelo NPCBody quando um artesão/taverneiro aceita negociar.
func open_trade(record: NPCRecord) -> void:
	var market: Market = Sim.world.economy.markets.get(record.location)
	if market != null:
		trade_screen.open(market, player, record.display_name)


## Chamado pelo menu de pausa antes de sair.
func save_before_exit() -> void:
	Sim.save_game(player.save_data())


## Descansar na fogueira: o mundo avança de verdade (não é fade fake).
func _rest_at_fire() -> void:
	Sim.skip_hours(6)
	player.survival.sleep(6.0, true)
	player.treat_wounds(player.skills.get_value("medicine"))
	player.health = minf(player.max_health, player.health + 30.0)
	player.stamina = player.max_stamina()
	Sim.save_game(player.save_data())
	hud.show_dialog("", "Você descansa junto ao fogo. O mundo seguiu sem você: %s"
		% Sim.world.clock.timestamp())


## O Dramaturgo fala -> a cena responde: conflito perto = emboscada real.
func _on_world_event(event: Dictionary) -> void:
	if event.get("category", "") != "conflict":
		return
	if event.get("place", "") in ["bruma_alta", "cais_quebrado"]:
		_spawn_bandits(randi_range(2, 3))


## Chifre diegético (GDD §8.3): reforço existe — se ainda houver bando.
func on_horn_blown(_position: Vector3) -> void:
	_spawn_bandits(1)


func _spawn_bandits(count: int) -> void:
	var active := 0
	for node in get_tree().get_nodes_in_group("bandits"):
		if node is Bandit and node.is_alive():
			active += 1
	var scene: PackedScene = load(BANDIT_SCENE)
	if scene == null:
		return
	for _i in range(count):
		if active >= MAX_ACTIVE_BANDITS:
			return
		var bandit: Bandit = scene.instantiate()
		add_child(bandit)
		var angle := randf() * TAU
		bandit.global_position = player.global_position \
			+ Vector3(cos(angle), 0.0, sin(angle)) * randf_range(25.0, 35.0)
		bandit.global_position.y = 1.0
		active += 1


## "Teste da taverna" (roadmap Fase 1): perto de NPCs socializando, o
## jogador OUVE o que eles realmente sabem — informação é gameplay.
func _try_overhear() -> void:
	var socializing: Array = []
	for body in get_tree().get_nodes_in_group("npc_bodies"):
		if body is NPCBody and body.record != null and body.record.alive \
				and body.current_activity == "social" \
				and body.global_position.distance_to(player.global_position) < OVERHEAR_RANGE:
			socializing.append(body)
	if socializing.size() < 2:
		return
	var speaker: NPCBody = socializing[randi() % socializing.size()]
	var line := Dialogue.line_for(
		speaker.record, Sim.world.clock.day(), Sim.world.director.world_record
	)
	hud.show_dialog("%s (à meia-voz)" % speaker.record.display_name, line)


## Morrer não é tela de game over: você acorda na praia, mais pobre de
## tempo e orgulho — e o mundo seguiu (autosave preserva consequências).
func _on_player_died(_actor: CombatActor) -> void:
	Sim.skip_hours(10)
	player.health = player.max_health * 0.5
	player.stamina = player.max_stamina() * 0.5
	player.survival.hunger = 0.9
	player.global_position = _spawn_position
	player.velocity = Vector3.ZERO
	Sim.save_game(player.save_data())
	hud.show_dialog("", "Você acorda na praia, dolorido. Alguém o arrastou da estrada até aqui.")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		# Android pausa o app: salvar é obrigatório (GDD §16.3).
		Sim.save_game(player.save_data())
