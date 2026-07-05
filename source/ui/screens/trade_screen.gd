class_name TradeScreen
extends CanvasLayer
## Comércio com o mercado REAL do assentamento (GDD §6): os preços são os
## da simulação, o estoque é o da vila, e cada compra/venda move ambos.
## Comprar barato aqui e vender caro lá é uma carreira — e treina Comércio.

const SELL_SPREAD := 0.9  # mercador compra por 90% do preço local

var _market: Market
var _player: Player
var _merchant_name := ""

@onready var title_label: Label = %TradeTitle
@onready var money_label: Label = %MoneyLabel
@onready var rows_container: VBoxContainer = %Rows
@onready var close_button: Button = %CloseTrade


func _ready() -> void:
	add_to_group("modal_screen")
	visible = false
	close_button.pressed.connect(close)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_menu"):
		close()
		get_viewport().set_input_as_handled()


func open(market: Market, player: Player, merchant_name: String) -> void:
	_market = market
	_player = player
	_merchant_name = merchant_name
	visible = true
	if not Actions.is_touch():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_rebuild()


func close() -> void:
	visible = false
	if not Actions.is_touch():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _rebuild() -> void:
	title_label.text = "Comércio — %s" % _merchant_name
	money_label.text = "Seus marcos: %.1f" % _player.inventory.money
	for child in rows_container.get_children():
		child.queue_free()
	var first_button: Button = null
	for good_id: String in _market.goods.keys():
		var row := HBoxContainer.new()
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text = "%s  |  preço %.1f  |  vila tem %d  |  você tem %d" % [
			good_id, _market.price_of(good_id),
			int(_market.stock_of(good_id)), _player.inventory.count(good_id),
		]
		row.add_child(label)
		var buy := Button.new()
		buy.text = "Comprar"
		buy.pressed.connect(_on_buy.bind(good_id))
		_touch_size(buy)
		row.add_child(buy)
		if first_button == null:
			first_button = buy
		var sell := Button.new()
		sell.text = "Vender"
		sell.pressed.connect(_on_sell.bind(good_id))
		_touch_size(sell)
		row.add_child(sell)
		label.add_theme_font_size_override("font_size", UIScale.font_size(14))
		rows_container.add_child(row)
	_touch_size(close_button)
	if first_button != null and Actions.active_device == Actions.Device.GAMEPAD:
		first_button.grab_focus()


## Alvo de toque real (≥44px físicos) em qualquer tela.
func _touch_size(button: Button) -> void:
	button.custom_minimum_size = Vector2(
		UIScale.units_for_px(96.0), UIScale.units_for_px(44.0)
	)
	button.add_theme_font_size_override("font_size", UIScale.font_size(15))


func _on_buy(good_id: String) -> void:
	var price := _market.price_of(good_id)
	if _player.inventory.money < price or _market.stock_of(good_id) < 1.0:
		return
	_market.take_stock(good_id, 1.0)
	_player.inventory.money -= price
	_player.inventory.add(good_id)
	_market.update_prices()
	# Negociar de verdade treina Comércio — proporcional ao valor em jogo.
	_player.skills.practice("trade", 0.25, clampf(price / 40.0, 0.1, 1.0))
	_rebuild()


func _on_sell(good_id: String) -> void:
	if not _player.inventory.remove(good_id):
		return
	var price := _market.price_of(good_id) * SELL_SPREAD
	_market.add_stock(good_id, 1.0)
	_player.inventory.money += price
	_market.update_prices()
	_player.skills.practice("trade", 0.25, clampf(price / 40.0, 0.1, 1.0))
	_rebuild()
