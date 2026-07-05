extends Node
## Autoload "Config": preferências do jogador persistidas em user://.
## Acessibilidade é dia um (GDD §14.4): sensibilidade, escala de fonte,
## alto contraste, assistência de mira e teto de FPS (bateria no Android).

signal settings_changed

const PATH := "user://settings.cfg"

var mouse_sensitivity := 1.0
var font_scale := 1.0
var high_contrast := false
## Soft-lock levemente mais assistivo no touch por padrão (GDD §15.4).
var aim_assist := true
## 0 = desbloqueado (PC); Android nasce com teto para bateria.
var fps_cap := 0
var quality_preset := "auto"


func _ready() -> void:
	if OS.get_name() == "Android":
		fps_cap = 60
	load_settings()
	apply()


func apply() -> void:
	Engine.max_fps = fps_cap
	settings_changed.emit()


func save_settings() -> void:
	var file := ConfigFile.new()
	file.set_value("input", "mouse_sensitivity", mouse_sensitivity)
	file.set_value("input", "aim_assist", aim_assist)
	file.set_value("ui", "font_scale", font_scale)
	file.set_value("ui", "high_contrast", high_contrast)
	file.set_value("video", "fps_cap", fps_cap)
	file.set_value("video", "quality_preset", quality_preset)
	file.save(PATH)


func load_settings() -> void:
	var file := ConfigFile.new()
	if file.load(PATH) != OK:
		return
	mouse_sensitivity = file.get_value("input", "mouse_sensitivity", mouse_sensitivity)
	aim_assist = file.get_value("input", "aim_assist", aim_assist)
	font_scale = file.get_value("ui", "font_scale", font_scale)
	high_contrast = file.get_value("ui", "high_contrast", high_contrast)
	fps_cap = file.get_value("video", "fps_cap", fps_cap)
	quality_preset = file.get_value("video", "quality_preset", quality_preset)
