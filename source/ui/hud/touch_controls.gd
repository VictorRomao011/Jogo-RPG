class_name TouchControls
extends Control
## Controles touch modernos (GDD §15.4): stick virtual DINÂMICO (nasce onde
## o polegar toca, metade esquerda) + câmera por arrasto (metade direita) +
## cluster de botões contextuais. Nunca exige precisão excessiva dos dedos.

const STICK_RADIUS := 90.0
const STICK_DEADZONE := 0.12

var _stick_touch_index := -1
var _stick_origin := Vector2.ZERO
var _look_touch_index := -1

@onready var stick_base: Control = $StickBase
@onready var stick_knob: Control = $StickBase/StickKnob


func _ready() -> void:
	visible = Actions.is_touch()
	Actions.device_changed.connect(_on_device_changed)
	stick_base.visible = false


func _on_device_changed(_device: int) -> void:
	visible = Actions.is_touch()
	if not visible:
		_reset_stick()
		Actions.touch_move = Vector2.ZERO


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_on_touch_down(event)
		else:
			_on_touch_up(event)
	elif event is InputEventScreenDrag:
		_on_drag(event)


func _on_touch_down(event: InputEventScreenTouch) -> void:
	var half := size.x * 0.5
	if event.position.x < half and _stick_touch_index == -1:
		_stick_touch_index = event.index
		_stick_origin = event.position
		stick_base.visible = true
		stick_base.position = _stick_origin - stick_base.size * 0.5
		stick_knob.position = stick_base.size * 0.5 - stick_knob.size * 0.5
	elif event.position.x >= half and _look_touch_index == -1:
		_look_touch_index = event.index


func _on_touch_up(event: InputEventScreenTouch) -> void:
	if event.index == _stick_touch_index:
		_reset_stick()
	elif event.index == _look_touch_index:
		_look_touch_index = -1


func _on_drag(event: InputEventScreenDrag) -> void:
	if event.index == _stick_touch_index:
		var offset := event.position - _stick_origin
		if offset.length() > STICK_RADIUS:
			offset = offset.normalized() * STICK_RADIUS
		stick_knob.position = stick_base.size * 0.5 - stick_knob.size * 0.5 + offset
		var vec := offset / STICK_RADIUS
		Actions.touch_move = Vector2.ZERO if vec.length() < STICK_DEADZONE else vec
	elif event.index == _look_touch_index:
		Actions.touch_look += event.relative


func _reset_stick() -> void:
	_stick_touch_index = -1
	stick_base.visible = false
	Actions.touch_move = Vector2.ZERO
