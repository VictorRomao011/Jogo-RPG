class_name WeatherFX
extends Node3D
## Efeitos de clima encenados: chuva de verdade (partículas seguindo o
## jogador) e relâmpagos em tempestade — o mesmo clima que a simulação
## decide para a região, agora na sua pele.

const CHECK_SECONDS := 3.0

var _rain: CPUParticles3D
var _flash: DirectionalLight3D
var _check_timer := 0.0
var _bolt_timer := 999.0
var _storming := false


func _ready() -> void:
	_rain = CPUParticles3D.new()
	_rain.amount = 550
	_rain.lifetime = 0.8
	_rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_rain.emission_box_extents = Vector3(16, 0.5, 16)
	_rain.gravity = Vector3(0, -34, 0)
	_rain.emitting = false
	var drop := BoxMesh.new()
	drop.size = Vector3(0.025, 0.5, 0.025)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.6, 0.7, 0.85, 0.35)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	drop.material = material
	_rain.mesh = drop
	add_child(_rain)
	_flash = DirectionalLight3D.new()
	_flash.rotation_degrees = Vector3(-70, 20, 0)
	_flash.light_color = Color(0.9, 0.93, 1.0)
	_flash.light_energy = 0.0
	add_child(_flash)


func _process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		_rain.global_position = player.global_position + Vector3(0, 11, 0)
	_check_timer -= delta
	if _check_timer <= 0.0:
		_check_timer = CHECK_SECONDS
		var weather: String = Sim.world.weather.current("pelagem_cinza")
		_rain.emitting = weather in ["rain", "storm"]
		_storming = weather == "storm"
		if _storming and _bolt_timer > 60.0:
			_bolt_timer = randf_range(3.0, 9.0)
	if _storming:
		_bolt_timer -= delta
		if _bolt_timer <= 0.0:
			_bolt_timer = randf_range(4.0, 12.0)
			_strike()
	else:
		_bolt_timer = 999.0


## Relâmpago: clarão duplo, como o de verdade.
func _strike() -> void:
	var tween := create_tween()
	tween.tween_property(_flash, "light_energy", 3.2, 0.05)
	tween.tween_property(_flash, "light_energy", 0.3, 0.08)
	tween.tween_property(_flash, "light_energy", 2.2, 0.05)
	tween.tween_property(_flash, "light_energy", 0.0, 0.25)
