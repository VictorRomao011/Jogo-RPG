class_name NPCBody
extends CharacterBody3D
## Corpo encenado de um NPC (GDD §7.1). Só existe perto do jogador; a vida
## real está no NPCRecord. Este nó lê a decisão do registro e a encena:
## anda até o trabalho, senta na taverna, dorme — e percebe o jogador.

const WALK_SPEED := 2.2
const WATCH_LEARN_RANGE := 5.0
const WATCH_LEARN_SECONDS := 12.0

## Profissões que comerciam ao conversar (usam o mercado local real).
const MERCHANT_PROFESSIONS := ["smith", "innkeeper", "herbalist", "weaver"]
## Aprender observando (GDD §9.1): o que cada ofício pode ensinar.
const PROFESSION_RECIPES := {
	"smith": ["faca_simples"],
	"innkeeper": ["ensopado_do_cais"],
	"herbalist": ["cha_de_raiz_morna", "unguento_limpo"],
	"weaver": ["capa_de_la"],
}

## O registro é a fonte da verdade; o corpo é descartável.
var record: NPCRecord
var current_activity := "idle"
## Pontos da vila para cada atividade (preenchidos pelo RegionStreamer).
var activity_spots: Dictionary = {}

var _target := Vector3.ZERO
var _has_target := false
var _perception_timer := 0.0
var _watch_accumulated := 0.0


func _ready() -> void:
	add_to_group("npc_bodies")
	var talk: Interactable = get_node_or_null("Talk")
	if talk != null:
		talk.interacted.connect(_on_talk)


func bind_record(npc_record: NPCRecord, spots: Dictionary) -> void:
	record = npc_record
	activity_spots = spots
	var talk: Interactable = get_node_or_null("Talk")
	if talk != null:
		talk.prompt = "Conversar"
	_attach_name_tag()


## Nome flutuante discreto — só de perto (o mundo não vira HUD).
func _attach_name_tag() -> void:
	var tag := Label3D.new()
	tag.text = record.display_name
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.position = Vector3(0, 2.15, 0)
	tag.font_size = 40
	tag.outline_size = 8
	tag.modulate = Color(1.0, 0.95, 0.8)
	tag.visibility_range_end = 14.0
	add_child(tag)


## Conversa: a fala vem do que o NPC sabe (Dialogue), nunca de script fixo.
func _on_talk(_by: Node) -> void:
	if record == null or not record.alive:
		return
	var line := Dialogue.line_for(
		record, Sim.world.clock.day(), Sim.world.director.world_record
	)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud != null:
		hud.show_dialog(record.display_name, line)
	# Conversar deixa rastro: o NPC lembra do forasteiro (e simpatiza um pouco).
	record.remember(
		"conversa", "troquei palavras com o forasteiro",
		Sim.world.clock.day(), 1.0, "player"
	)
	record.player_opinion = clampf(record.player_opinion + 1.0, -100.0, 100.0)
	# Artesãos e taverneiros comerciam — com o mercado REAL da vila.
	if record.profession in MERCHANT_PROFESSIONS and record.player_opinion > -20.0:
		get_tree().call_group("main", "open_trade", record)


## Ver um artesão trabalhando ensina (GDD §9.1): crafting é conhecimento.
func _teach_by_watching(elapsed: float) -> void:
	if record == null or current_activity != "work" \
			or not PROFESSION_RECIPES.has(record.profession):
		return
	var player := get_tree().get_first_node_in_group("player")
	if player == null or not (player is Player):
		return
	if global_position.distance_to(player.global_position) > WATCH_LEARN_RANGE:
		return
	_watch_accumulated += elapsed
	if _watch_accumulated < WATCH_LEARN_SECONDS:
		return
	_watch_accumulated = 0.0
	var teachable: Array = PROFESSION_RECIPES[record.profession]
	for recipe_id: String in teachable:
		if not player.crafting.known_recipes.has(recipe_id):
			player.crafting.learn(recipe_id, "observando %s" % record.display_name)
			var hud := get_tree().get_first_node_in_group("hud")
			if hud != null:
				hud.show_dialog(
					"", "Observando %s trabalhar, você entende como se faz: %s."
					% [record.display_name, recipe_id]
				)
			return


func _physics_process(delta: float) -> void:
	if record == null or not record.alive:
		return
	_follow_schedule()
	_move(delta)
	_perception_timer -= delta
	if _perception_timer <= 0.0:
		_perception_timer = 0.5
		_perceive()
		_teach_by_watching(0.5)


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
