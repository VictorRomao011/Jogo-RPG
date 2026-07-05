class_name HUD
extends CanvasLayer
## HUD quase invisível (GDD §14.1): stamina só aparece sob esforço; o botão
## de interação touch só existe quando há algo interagível; notícias do
## mundo chegam como rumor discreto, nunca como popup de sistema.

const FADE_DELAY := 1.5

var _player: Player
var _fade_timer := 0.0

@onready var stamina_bar: ProgressBar = %StaminaBar
@onready var rumor_label: Label = %RumorLabel
@onready var interact_button: Button = %InteractButton
@onready var action_cluster: Control = %ActionCluster
@onready var clock_label: Label = %ClockLabel


func _ready() -> void:
	stamina_bar.modulate.a = 0.0
	rumor_label.modulate.a = 0.0
	interact_button.visible = false
	action_cluster.visible = Actions.is_touch()
	Actions.device_changed.connect(_on_device_changed)
	Sim.world_event.connect(_on_world_event)
	_apply_breakpoint()
	UIScale.breakpoint_changed.connect(func(_bp: String) -> void: _apply_breakpoint())
	interact_button.pressed.connect(func() -> void: Actions.touch_tap("interact"))
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


func bind_player(player: Player) -> void:
	_player = player
	player.stamina_changed.connect(_on_stamina_changed)


func _process(delta: float) -> void:
	if _fade_timer > 0.0:
		_fade_timer -= delta
		if _fade_timer <= 0.0:
			create_tween().tween_property(stamina_bar, "modulate:a", 0.0, 0.6)
	rumor_label.modulate.a = maxf(0.0, rumor_label.modulate.a - delta * 0.1)
	clock_label.text = Sim.world.clock.timestamp()
	_update_interact_button()


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


## Reposiciona densidade por breakpoint; respeita safe-area (notch).
func _apply_breakpoint() -> void:
	var margins := UIScale.safe_margins()
	var root: Control = $Root
	root.offset_left = float(margins.position.x)
	root.offset_top = float(margins.position.y)
	rumor_label.add_theme_font_size_override("font_size", UIScale.font_size(16))
	clock_label.add_theme_font_size_override("font_size", UIScale.font_size(14))
