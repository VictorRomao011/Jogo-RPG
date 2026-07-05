class_name HUD
extends CanvasLayer
## HUD quase invisível (GDD §14.1): stamina só aparece sob esforço; o botão
## de interação touch só existe quando há algo interagível; notícias do
## mundo chegam como rumor discreto, nunca como popup de sistema.

const FADE_DELAY := 1.5
const DIALOG_SECONDS := 6.0

var _player: Player
var _fade_timer := 0.0
var _dialog_timer := 0.0
var _hint_timer := 25.0

@onready var stamina_bar: ProgressBar = %StaminaBar
@onready var health_bar: ProgressBar = %HealthBar
@onready var rumor_label: Label = %RumorLabel
@onready var interact_button: Button = %InteractButton
@onready var action_cluster: Control = %ActionCluster
@onready var clock_label: Label = %ClockLabel
@onready var dialog_panel: PanelContainer = %DialogPanel
@onready var dialog_label: Label = %DialogLabel
@onready var journal_button: Button = %JournalButton
@onready var hint_label: Label = %HintLabel
@onready var pause_button: Button = %PauseButton


func _ready() -> void:
	add_to_group("hud")
	($Root as Control).theme = UIStyle.theme()
	stamina_bar.add_theme_stylebox_override(
		"fill", UIStyle.bar_fill(Color(0.55, 0.75, 0.35))
	)
	health_bar.add_theme_stylebox_override(
		"fill", UIStyle.bar_fill(Color(0.75, 0.28, 0.22))
	)
	if not Sim.world_healthy():
		show_dialog("", "Aviso: os dados do mundo não carregaram nesta build.")
	stamina_bar.modulate.a = 0.0
	health_bar.visible = false
	rumor_label.modulate.a = 0.0
	interact_button.visible = false
	dialog_panel.visible = false
	action_cluster.visible = Actions.is_touch()
	Actions.device_changed.connect(_on_device_changed)
	Sim.world_event.connect(_on_world_event)
	_apply_breakpoint()
	UIScale.breakpoint_changed.connect(func(_bp: String) -> void: _apply_breakpoint())
	Config.settings_changed.connect(_apply_breakpoint)
	get_viewport().size_changed.connect(_apply_breakpoint)
	interact_button.pressed.connect(func() -> void: Actions.touch_tap("interact"))
	journal_button.visible = Actions.is_touch()
	# Chamada DIRETA (sem cadeia de sinais): o toque nunca se perde.
	journal_button.pressed.connect(func() -> void:
		get_tree().call_group("main", "toggle_journal")
	)
	# Dica de controles que se dissolve sozinha — aprender em minutos,
	# sem tutorial (GDD: experiência do usuário).
	hint_label.visible = not Actions.is_touch()
	pause_button.visible = Actions.is_touch()
	pause_button.pressed.connect(func() -> void:
		var pause_menu := get_tree().get_first_node_in_group("pause_menu")
		if pause_menu != null:
			pause_menu.open()
	)
	_wire_action_cluster()


## Botões do cluster emitem as MESMAS ações semânticas do teclado/gamepad —
## o gameplay não sabe (nem precisa saber) de onde veio o toque.
func _wire_action_cluster() -> void:
	for child in action_cluster.get_children():
		if child is Button:
			var action := String(child.name)
			if child.toggle_mode:
				# Agachar é toggle no touch: segurar botão seria desconfortável.
				child.toggled.connect(func(on: bool) -> void:
					if on:
						Actions.touch_press(action)
					else:
						Actions.touch_release(action)
				)
			else:
				child.button_down.connect(func() -> void: Actions.touch_press(action))
				child.button_up.connect(func() -> void: Actions.touch_release(action))
			child.button_down.connect(Audio.click)


func bind_player(player: Player) -> void:
	_player = player
	player.stamina_changed.connect(_on_stamina_changed)
	player.damaged.connect(_on_player_damaged)


## Flash vermelho nas bordas ao levar dano — feedback imediato.
func _on_player_damaged(_actor: CombatActor, _amount: float, _limb: String) -> void:
	var vignette := get_node_or_null("Root/HurtVignette")
	if vignette == null:
		vignette = ColorRect.new()
		vignette.name = "HurtVignette"
		vignette.color = Color(0.7, 0.05, 0.05, 0.0)
		vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
		$Root.add_child(vignette)
		$Root.move_child(vignette, 0)
	vignette.color.a = 0.32
	create_tween().tween_property(vignette, "color:a", 0.0, 0.5)


func _process(delta: float) -> void:
	if _fade_timer > 0.0:
		_fade_timer -= delta
		if _fade_timer <= 0.0:
			create_tween().tween_property(stamina_bar, "modulate:a", 0.0, 0.6)
	rumor_label.modulate.a = maxf(0.0, rumor_label.modulate.a - delta * 0.1)
	clock_label.text = Sim.time_text()
	if _hint_timer > 0.0:
		_hint_timer -= delta
		if _hint_timer <= 0.0:
			create_tween().tween_property(hint_label, "modulate:a", 0.0, 1.5)
	_update_interact_button()
	_update_health()
	if _dialog_timer > 0.0:
		_dialog_timer -= delta
		if _dialog_timer <= 0.0:
			dialog_panel.visible = false


## Vida só aparece machucado — HUD quase invisível (GDD §14.1).
func _update_health() -> void:
	if _player == null:
		return
	health_bar.max_value = _player.max_health
	health_bar.value = _player.health
	health_bar.visible = _player.health < _player.max_health


## Fala diegética: conversa direta ou ouvida na taverna.
func show_dialog(speaker: String, text: String) -> void:
	dialog_label.text = "%s — %s" % [speaker, text] if speaker != "" else text
	dialog_panel.visible = true
	_dialog_timer = DIALOG_SECONDS


func _on_stamina_changed(current: float, maximum: float) -> void:
	stamina_bar.max_value = maximum
	stamina_bar.value = current
	# Só aparece quando relevante: gastando ou abaixo de 90%.
	if current < maximum * 0.9:
		stamina_bar.modulate.a = 1.0
		_fade_timer = FADE_DELAY


## Notícia do mundo vira rumor discreto no canto — sem popup, sem pausa.
func _on_world_event(event: Dictionary) -> void:
	if event.get("description", "") == "":
		return
	rumor_label.text = "Ouve-se por aí: %s" % event["description"]
	rumor_label.modulate.a = 1.0


## Botão contextual: só existe quando há algo no alcance (GDD §15.4).
func _update_interact_button() -> void:
	if not Actions.is_touch() or _player == null:
		interact_button.visible = false
		return
	var nearest := _nearest_interactable()
	interact_button.visible = nearest != null
	if nearest != null:
		interact_button.text = nearest.prompt


func _nearest_interactable() -> Interactable:
	var best: Interactable = null
	var best_distance := 2.5
	for node in get_tree().get_nodes_in_group("interactables"):
		if node is Interactable:
			var d: float = node.global_position.distance_to(_player.global_position)
			if d < best_distance:
				best_distance = d
				best = node
	return best


func _on_device_changed(_device: int) -> void:
	action_cluster.visible = Actions.is_touch()
	journal_button.visible = Actions.is_touch()
	pause_button.visible = Actions.is_touch()
	hint_label.visible = not Actions.is_touch() and _hint_timer > 0.0


## Reposiciona densidade por breakpoint; respeita safe-area (notch).
func _apply_breakpoint() -> void:
	var margins := UIScale.safe_margins()
	var root: Control = $Root
	root.offset_left = float(margins.position.x)
	root.offset_top = float(margins.position.y)
	rumor_label.add_theme_font_size_override("font_size", UIScale.font_size(16))
	clock_label.add_theme_font_size_override("font_size", UIScale.font_size(14))
	dialog_label.add_theme_font_size_override("font_size", UIScale.font_size(18))
	if Actions.is_touch():
		_layout_touch_hud()


## Layout touch em pixels FÍSICOS: botões ~13% do lado curto da tela
## (mín. 64px), posicionados nas zonas dos polegares — funciona em
## retrato e paisagem, sem obstruir o centro da tela.
func _layout_touch_hud() -> void:
	var btn := UIScale.units_for_px(clampf(UIScale.short_side_px() * 0.14, 64.0, 170.0))
	var margin := UIScale.units_for_px(14.0)
	var root: Control = $Root
	var vp := root.size
	var font := UIScale.font_size(15)

	# Cluster de combate: arco no canto inferior direito. O cluster está
	# ancorado no canto (tamanho 0); filhos crescem para cima/esquerda.
	action_cluster.offset_left = 0.0
	action_cluster.offset_top = 0.0
	var cluster_nodes := {
		"attack_light": [Vector2(-btn * 1.18, -btn * 1.18), 1.15],
		"dodge": [Vector2(-btn * 2.35, -btn * 1.05), 0.95],
		"jump": [Vector2(-btn * 1.12, -btn * 2.42), 0.95],
		"parry": [Vector2(-btn * 2.25, -btn * 2.2), 0.95],
		"sneak": [Vector2(-btn * 3.4, -btn * 1.0), 0.85],
	}
	for button_name: String in cluster_nodes.keys():
		var button: Button = action_cluster.get_node_or_null(NodePath(button_name))
		if button == null:
			continue
		var side: float = btn * cluster_nodes[button_name][1]
		button.size = Vector2(side, side)
		button.position = cluster_nodes[button_name][0] - Vector2(margin, margin)
		button.add_theme_font_size_override("font_size", font)

	# Interagir: acima do cluster, largo (alvo fácil).
	interact_button.size = Vector2(btn * 2.1, btn * 0.72)
	interact_button.position = Vector2(
		vp.x - btn * 2.1 - margin, vp.y - btn * 3.65
	)
	interact_button.add_theme_font_size_override("font_size", font)

	# Caderno e pausa: topo, longe dos polegares, tamanho de toque real.
	journal_button.size = Vector2(btn * 1.5, btn * 0.62)
	journal_button.position = Vector2(margin, margin)
	journal_button.add_theme_font_size_override("font_size", font)
	pause_button.size = Vector2(btn * 0.62, btn * 0.62)
	pause_button.position = Vector2(margin + btn * 1.5 + margin * 0.5, margin)
	pause_button.add_theme_font_size_override("font_size", UIScale.font_size(20))

	# Barras centrais proporcionais à tela.
	var bar_width := minf(vp.x * 0.42, UIScale.units_for_px(360.0))
	var bar_height := UIScale.units_for_px(9.0)
	stamina_bar.offset_left = -bar_width * 0.5
	stamina_bar.offset_right = bar_width * 0.5
	stamina_bar.offset_top = -bar_height * 4.4
	stamina_bar.offset_bottom = -bar_height * 3.4
	health_bar.offset_left = -bar_width * 0.5
	health_bar.offset_right = bar_width * 0.5
	health_bar.offset_top = -bar_height * 6.0
	health_bar.offset_bottom = -bar_height * 5.0

	# Diálogo: largura de leitura confortável, acima das barras.
	var dialog_width := minf(vp.x * 0.92, UIScale.units_for_px(700.0))
	dialog_panel.offset_left = -dialog_width * 0.5
	dialog_panel.offset_right = dialog_width * 0.5
	dialog_panel.offset_top = -UIScale.units_for_px(150.0)
	dialog_panel.offset_bottom = -UIScale.units_for_px(78.0)
	# Alto contraste (GDD §14.4): contorno forte em todo texto da HUD.
	var outline := 8 if Config.high_contrast else 0
	for label: Label in [rumor_label, clock_label, dialog_label]:
		label.add_theme_constant_override("outline_size", outline)
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		if Config.high_contrast:
			label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.85))
		else:
			label.remove_theme_color_override("font_color")
