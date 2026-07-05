class_name JournalScreen
extends CanvasLayer
## O Caderno (GDD §14.3): mochila, habilidades e rumores ouvidos — o mapa
## do que o JOGADOR sabe, não do que o jogo quer que ele saiba.
## Nada aqui é objetivo, marcador ou checklist.

var _player: Player

@onready var items_rows: VBoxContainer = %ItemsRows
@onready var skills_label: Label = %SkillsLabel
@onready var rumors_label: Label = %RumorsLabel
@onready var weight_label: Label = %WeightLabel
@onready var close_button: Button = %CloseJournal


func _ready() -> void:
	add_to_group("modal_screen")
	visible = false
	close_button.pressed.connect(close)


func _unhandled_input(event: InputEvent) -> void:
	# Fechar por open_journal fica com o toggle do Main (evita duplo toggle).
	if visible and event.is_action_pressed("ui_menu"):
		close()
		get_viewport().set_input_as_handled()


func open(player: Player) -> void:
	_player = player
	visible = true
	if not Actions.is_touch():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_rebuild()


func close() -> void:
	visible = false
	if not Actions.is_touch():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _rebuild() -> void:
	_rebuild_items()
	_rebuild_skills()
	_rebuild_rumors()


func _rebuild_items() -> void:
	for child in items_rows.get_children():
		child.queue_free()
	weight_label.text = "Peso: %.1f / %.1f  |  Marcos: %.1f" % [
		_player.inventory.total_weight(_player.item_catalog),
		_player.inventory.max_weight,
		_player.inventory.money,
	]
	if _player.inventory.items.is_empty():
		var empty := Label.new()
		empty.text = "Mochila vazia."
		items_rows.add_child(empty)
		return
	var first_button: Button = null
	for item_id: String in _player.inventory.items.keys():
		var meta: Dictionary = _player.item_catalog.get(item_id, {})
		var row := HBoxContainer.new()
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text = "%d× %s" % [_player.inventory.count(item_id), meta.get("name", item_id)]
		row.add_child(label)
		var usable: bool = meta.get("nutrition", 0.0) > 0.0 \
			or meta.get("category", "") == "medicine"
		if usable:
			var use := Button.new()
			use.text = "Comer" if meta.get("nutrition", 0.0) > 0.0 else "Usar"
			use.pressed.connect(_on_use.bind(item_id))
			use.custom_minimum_size = Vector2(
				UIScale.units_for_px(84.0), UIScale.units_for_px(44.0)
			)
			use.add_theme_font_size_override("font_size", UIScale.font_size(15))
			row.add_child(use)
			if first_button == null:
				first_button = use
		label.add_theme_font_size_override("font_size", UIScale.font_size(14))
		items_rows.add_child(row)
	close_button.custom_minimum_size.y = UIScale.units_for_px(44.0)
	close_button.add_theme_font_size_override("font_size", UIScale.font_size(15))
	skills_label.add_theme_font_size_override("font_size", UIScale.font_size(13))
	rumors_label.add_theme_font_size_override("font_size", UIScale.font_size(13))
	if first_button != null and Actions.active_device == Actions.Device.GAMEPAD:
		first_button.grab_focus()


func _on_use(item_id: String) -> void:
	var worked := _player.consume(item_id)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud != null and not worked:
		hud.show_dialog("", "Isso não ajudou em nada agora.")
	_rebuild_items()


## Habilidades treinadas de verdade (acima do valor inicial).
func _rebuild_skills() -> void:
	var lines: Array = []
	for skill: String in Skills.SKILLS:
		var value := _player.skills.get_value(skill)
		if value > 5.5:
			lines.append("%s: %d" % [skill, int(value)])
	skills_label.text = "\n".join(lines) if not lines.is_empty() \
		else "Você ainda é o que era quando acordou na praia."


## Rumores que JÁ chegaram até aqui (atraso real de notícia).
func _rebuild_rumors() -> void:
	var day := Sim.world.clock.day()
	var known := Sim.world.director.news_known_at(day, _player.current_settlement(), {})
	var lines: Array = []
	for i in range(maxi(0, known.size() - 6), known.size()):
		var event: Dictionary = known[i]
		lines.append("• (dia %d) %s" % [event["day"], event["description"]])
	rumors_label.text = "\n".join(lines) if not lines.is_empty() \
		else "Nenhum rumor ainda. Sente numa taverna."
