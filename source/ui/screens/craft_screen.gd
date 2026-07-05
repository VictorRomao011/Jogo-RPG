class_name CraftScreen
extends CanvasLayer
## Bancada de crafting (GDD §9): mostra APENAS o que o jogador aprendeu
## (vendo, desmontando, sendo ensinado). Consome o inventário de verdade;
## qualidade = material × habilidade × estação.

var _player: Player
var _station_quality := 0.7

@onready var craft_title: Label = %CraftTitle
@onready var rows_container: VBoxContainer = %CraftRows
@onready var close_button: Button = %CloseCraft


func _ready() -> void:
	add_to_group("modal_screen")
	visible = false
	close_button.pressed.connect(close)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_menu"):
		close()
		get_viewport().set_input_as_handled()


func open(player: Player, station_name: String, station_quality: float) -> void:
	_player = player
	_station_quality = station_quality
	craft_title.text = station_name
	visible = true
	if not Actions.is_touch():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_rebuild()


func close() -> void:
	visible = false
	if not Actions.is_touch():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _rebuild() -> void:
	for child in rows_container.get_children():
		child.queue_free()
	if _player.crafting.known_recipes.is_empty():
		var empty := Label.new()
		empty.text = "Você ainda não sabe fazer nada aqui.\n" \
			+ "Observe quem trabalha, desmonte coisas, peça para ensinarem."
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rows_container.add_child(empty)
		return
	var first_button: Button = null
	for recipe_id: String in _player.crafting.known_recipes.keys():
		var recipe: Dictionary = _player.crafting.recipes_catalog.get(recipe_id, {})
		if recipe.is_empty():
			continue
		var row := HBoxContainer.new()
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text = "%s  (precisa: %s)" % [recipe_id, _inputs_text(recipe)]
		row.add_child(label)
		var button := Button.new()
		button.text = "Fabricar"
		button.pressed.connect(_on_craft.bind(recipe_id))
		row.add_child(button)
		if first_button == null:
			first_button = button
		rows_container.add_child(row)
	if first_button != null and Actions.active_device == Actions.Device.GAMEPAD:
		first_button.grab_focus()


func _inputs_text(recipe: Dictionary) -> String:
	var parts: Array = []
	var inputs: Dictionary = recipe.get("inputs", {})
	for item_id: String in inputs.keys():
		parts.append("%d× %s" % [int(inputs[item_id]), item_id])
	return ", ".join(parts)


func _on_craft(recipe_id: String) -> void:
	var recipe: Dictionary = _player.crafting.recipes_catalog.get(recipe_id, {})
	var skill_name: String = recipe.get("skill", "smithing")
	var quality := _player.crafting.craft(
		recipe_id,
		_player.inventory.items,
		_player.skills.get_value(skill_name),
		_station_quality
	)
	var hud := get_tree().get_first_node_in_group("hud")
	if quality <= 0.0:
		if hud != null:
			hud.show_dialog("", "Faltou material.")
	else:
		# Fabricar de verdade treina o ofício da receita.
		_player.skills.practice(skill_name, 0.5, 0.3 + quality * 0.4)
		_player.inventory.changed.emit()
		if hud != null:
			hud.show_dialog("", "Feito: %s (qualidade %d%%)." % [
				recipe.get("output", recipe_id), int(quality * 100.0),
			])
	_rebuild()
