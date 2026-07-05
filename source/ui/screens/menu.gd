class_name MainMenu
extends Control
## Menu principal. Layout calculado em pixels FÍSICOS: título e botões
## têm tamanho de toque real em qualquer celular, retrato ou paisagem.


@onready var vbox: VBoxContainer = %VBox
@onready var title_label: Label = %Title
@onready var subtitle_label: Label = %Subtitle
@onready var flavor_label: Label = %Flavor
@onready var continue_button: Button = %ContinueButton
@onready var new_button: Button = %NewButton
@onready var quit_button: Button = %QuitMenuButton
@onready var version_label: Label = %VersionLabel


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	continue_button.visible = FileAccess.file_exists(Sim.SAVE_PATH)
	continue_button.pressed.connect(_start)
	new_button.pressed.connect(_new_game)
	quit_button.pressed.connect(func() -> void: get_tree().quit())
	# No navegador, "Sair" não faz sentido — a aba é o sair.
	quit_button.visible = OS.get_name() != "Web"
	version_label.text = "Ecos de Vaethir — protótipo %s" % \
		ProjectSettings.get_setting("application/config/version", "0.0.0")
	get_viewport().size_changed.connect(_layout)
	_layout()
	if continue_button.visible:
		continue_button.grab_focus()
	else:
		new_button.grab_focus()


## Tudo em px físicos: botão ≥ 52px de altura, título proporcional à tela.
func _layout() -> void:
	var short_px := UIScale.short_side_px()
	var button_height := UIScale.units_for_px(clampf(short_px * 0.075, 52.0, 96.0))
	var button_width := UIScale.units_for_px(clampf(short_px * 0.72, 280.0, 560.0))
	for button: Button in [continue_button, new_button, quit_button]:
		button.custom_minimum_size = Vector2(button_width, button_height)
		button.add_theme_font_size_override("font_size", UIScale.font_size(20))
	title_label.add_theme_font_size_override(
		"font_size", int(UIScale.units_for_px(clampf(short_px * 0.085, 34.0, 88.0)))
	)
	subtitle_label.add_theme_font_size_override("font_size", UIScale.font_size(16))
	flavor_label.add_theme_font_size_override("font_size", UIScale.font_size(13))
	version_label.add_theme_font_size_override("font_size", UIScale.font_size(12))
	var half_width := button_width * 0.5 + UIScale.units_for_px(16.0)
	vbox.offset_left = -half_width
	vbox.offset_right = half_width
	var half_height := UIScale.units_for_px(260.0)
	vbox.offset_top = -half_height
	vbox.offset_bottom = half_height


func _start() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _new_game() -> void:
	if FileAccess.file_exists(Sim.SAVE_PATH):
		DirAccess.remove_absolute(Sim.SAVE_PATH)
	Sim.reset_world()
	_start()
