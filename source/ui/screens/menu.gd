class_name MainMenu
extends Control
## Menu principal. Sem cinemática, sem barulho: o título, o mar ao fundo
## (um dia), e três escolhas. Continuar só existe se houver um mundo salvo.


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
	version_label.text = "Ecos de Vaethir — protótipo %s" % \
		ProjectSettings.get_setting("application/config/version", "0.0.0")
	if continue_button.visible:
		continue_button.grab_focus()
	else:
		new_button.grab_focus()


func _start() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _new_game() -> void:
	if FileAccess.file_exists(Sim.SAVE_PATH):
		DirAccess.remove_absolute(Sim.SAVE_PATH)
	Sim.reset_world()
	_start()
