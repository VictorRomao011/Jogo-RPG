extends Node
## Autoload "Actions": camada de abstração de entrada (GDD §15.1).
## Todo o gameplay consome ações semânticas daqui — nunca inputs crus.
## Detecta o dispositivo ativo e troca a quente (plugou gamepad no celular?
## esquema e UI mudam instantaneamente).

signal device_changed(device: int)
## Ações vindas da UI touch (botões contextuais emitem pelas mesmas ações).
signal action_pressed(action: String)
signal action_released(action: String)

enum Device { KEYBOARD_MOUSE, GAMEPAD, TOUCH }

var active_device: int = Device.KEYBOARD_MOUSE

## Vetores analógicos alimentados pela UI touch (stick virtual/câmera).
var touch_move := Vector2.ZERO
var touch_look := Vector2.ZERO

var _touch_actions_held: Dictionary = {}


func _ready() -> void:
	if DisplayServer.is_touchscreen_available():
		active_device = Device.TOUCH


func _input(event: InputEvent) -> void:
	var detected := active_device
	if event is InputEventKey or event is InputEventMouseButton:
		detected = Device.KEYBOARD_MOUSE
	elif event is InputEventJoypadButton:
		detected = Device.GAMEPAD
	elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.3:
		detected = Device.GAMEPAD
	elif event is InputEventScreenTouch or event is InputEventScreenDrag:
		detected = Device.TOUCH
	if detected != active_device:
		active_device = detected
		device_changed.emit(active_device)


func is_touch() -> bool:
	return active_device == Device.TOUCH


## --- API semântica consumida pelo gameplay -------------------------------


func move_vector() -> Vector2:
	if active_device == Device.TOUCH:
		return touch_move
	return Input.get_vector("move_left", "move_right", "move_forward", "move_back")


func look_delta() -> Vector2:
	if active_device == Device.TOUCH:
		var delta := touch_look
		touch_look = Vector2.ZERO
		return delta
	return Vector2.ZERO  # mouse-look chega por InputEventMouseMotion no player


func is_held(action: String) -> bool:
	if _touch_actions_held.get(action, false):
		return true
	return InputMap.has_action(action) and Input.is_action_pressed(action)


func was_pressed(action: String) -> bool:
	return InputMap.has_action(action) and Input.is_action_just_pressed(action)


## --- Alimentação pela UI touch --------------------------------------------


func touch_press(action: String) -> void:
	_touch_actions_held[action] = true
	action_pressed.emit(action)


func touch_release(action: String) -> void:
	_touch_actions_held[action] = false
	action_released.emit(action)


func touch_tap(action: String) -> void:
	action_pressed.emit(action)
	action_released.emit(action)
