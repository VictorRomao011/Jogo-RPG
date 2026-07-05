class_name TouchControls
extends Control
## Controles touch modernos (GDD §15.4): joystick FIXO sempre visível no
## canto esquerdo (todas as direções, 360°) + câmera por arrasto na metade
## direita. Todos os tamanhos são calculados em pixels FÍSICOS da tela —
## em retrato ou paisagem, o polegar sempre encontra o stick.

const STICK_DEADZONE := 0.1

var _stick_index := -1
var _look_index := -1
var _base_center := Vector2.ZERO
var _radius := 90.0

@onready var stick_base: Control = $StickBase
@onready var stick_knob: Control = $StickBase/StickKnob


func _ready() -> void:
	visible = Actions.is_touch()
	Actions.device_changed.connect(_on_device_changed)
	get_viewport().size_changed.connect(_layout)
	_layout()


func _on_device_changed(_device: int) -> void:
	visible = Actions.is_touch()
	if not visible:
		_release_stick()


## Stick com diâmetro físico ~34% do lado curto da tela (mín. 130px).
func _layout() -> void:
	var diameter := UIScale.units_for_px(
		clampf(UIScale.short_side_px() * 0.34, 130.0, 320.0)
	)
	var margin := UIScale.units_for_px(20.0)
	stick_base.size = Vector2(diameter, diameter)
	stick_base.position = Vector2(margin, size.y - diameter - margin)
	var knob := diameter * 0.42
	stick_knob.size = Vector2(knob, knob)
	_center_knob()
	_base_center = stick_base.position + stick_base.size * 0.5
	_radius = diameter * 0.5


func _center_knob() -> void:
	stick_knob.position = stick_base.size * 0.5 - stick_knob.size * 0.5


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_on_touch_down(event)
		else:
			_on_touch_up(event)
	elif event is InputEventScreenDrag:
		_on_drag(event)


func _on_touch_down(event: InputEventScreenTouch) -> void:
	# Metade esquerda inteira controla o stick fixo — sem exigir precisão.
	if event.position.x < size.x * 0.45 and _stick_index == -1:
		_stick_index = event.index
		_apply_stick(event.position)
	elif event.position.x >= size.x * 0.45 and _look_index == -1:
		_look_index = event.index


func _on_touch_up(event: InputEventScreenTouch) -> void:
	if event.index == _stick_index:
		_release_stick()
	elif event.index == _look_index:
		_look_index = -1


func _on_drag(event: InputEventScreenDrag) -> void:
	if event.index == _stick_index:
		_apply_stick(event.position)
	elif event.index == _look_index:
		Actions.touch_look += event.relative


func _apply_stick(touch_position: Vector2) -> void:
	var vec := (touch_position - _base_center) / _radius
	if vec.length() > 1.0:
		vec = vec.normalized()
	stick_knob.position = stick_base.size * 0.5 - stick_knob.size * 0.5 \
		+ vec * _radius * 0.55
	Actions.touch_move = Vector2.ZERO if vec.length() < STICK_DEADZONE else vec


func _release_stick() -> void:
	_stick_index = -1
	_center_knob()
	Actions.touch_move = Vector2.ZERO
