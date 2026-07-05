class_name PauseMenu
extends CanvasLayer
## Pausa + configurações (GDD §14.4). Pausar congela a ENCENAÇÃO; o estado
## do mundo fica salvo e íntegro. Acessibilidade é dia um: sensibilidade,
## escala de fonte, alto contraste, assistência de mira e teto de FPS.

@onready var resume_button: Button = %ResumeButton
@onready var menu_button: Button = %MenuButton
@onready var quit_button: Button = %QuitButton
@onready var sensitivity_slider: HSlider = %SensitivitySlider
@onready var font_slider: HSlider = %FontSlider
@onready var contrast_check: CheckButton = %ContrastCheck
@onready var assist_check: CheckButton = %AssistCheck
@onready var fps_option: OptionButton = %FpsOption


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	resume_button.pressed.connect(close)
	menu_button.pressed.connect(_to_main_menu)
	quit_button.pressed.connect(_quit)
	sensitivity_slider.min_value = 0.3
	sensitivity_slider.max_value = 2.5
	sensitivity_slider.step = 0.1
	font_slider.min_value = 0.8
	font_slider.max_value = 1.6
	font_slider.step = 0.1
	for cap in [0, 30, 60, 120]:
		fps_option.add_item("Sem teto" if cap == 0 else "%d fps" % cap, cap)
	sensitivity_slider.value_changed.connect(_on_settings_edited)
	font_slider.value_changed.connect(_on_settings_edited)
	contrast_check.toggled.connect(_on_settings_edited)
	assist_check.toggled.connect(_on_settings_edited)
	fps_option.item_selected.connect(_on_settings_edited)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_menu"):
		# Telas modais (comércio/bancada) têm prioridade para fechar.
		for screen in get_tree().get_nodes_in_group("modal_screen"):
			if screen.visible:
				return
		if visible:
			close()
		else:
			open()
		get_viewport().set_input_as_handled()


func open() -> void:
	_load_current_values()
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	resume_button.grab_focus()


func close() -> void:
	visible = false
	get_tree().paused = false
	if not Actions.is_touch():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _load_current_values() -> void:
	sensitivity_slider.set_value_no_signal(Config.mouse_sensitivity)
	font_slider.set_value_no_signal(Config.font_scale)
	contrast_check.set_pressed_no_signal(Config.high_contrast)
	assist_check.set_pressed_no_signal(Config.aim_assist)
	for i in range(fps_option.item_count):
		if fps_option.get_item_id(i) == Config.fps_cap:
			fps_option.select(i)
			break


func _on_settings_edited(_value: Variant) -> void:
	Config.mouse_sensitivity = sensitivity_slider.value
	Config.font_scale = font_slider.value
	Config.high_contrast = contrast_check.button_pressed
	Config.aim_assist = assist_check.button_pressed
	Config.fps_cap = fps_option.get_item_id(fps_option.selected)
	Config.apply()
	Config.save_settings()


func _to_main_menu() -> void:
	get_tree().paused = false
	get_tree().call_group("main", "save_before_exit")
	get_tree().change_scene_to_file("res://scenes/menu.tscn")


func _quit() -> void:
	get_tree().call_group("main", "save_before_exit")
	get_tree().quit()
