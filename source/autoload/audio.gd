extends Node
## Autoload "Audio": efeitos e ambiências sintetizados embarcados.
## Ambiência é SISTÊMICA: ondas crescem perto do mar, grilos só à noite
## seca, chuva quando a simulação decide chover, fogueira ao chegar perto.

const SFX_DIR := "res://assets/audio/"
const POOL_SIZE := 8
const LOOPS := ["rain_loop", "waves_loop", "wind_loop", "crickets_loop", "fire_loop"]
const FIRE_SPOTS := [Vector3(3, 0, 2), Vector3(-48, 0, -60)]

var _pool: Array = []
var _pool_index := 0
var _loop_players: Dictionary = {}
var _loop_targets: Dictionary = {}
var _context_timer := 0.0


func _ready() -> void:
	for _i in range(POOL_SIZE):
		var player := AudioStreamPlayer.new()
		add_child(player)
		_pool.append(player)
	for loop_name in LOOPS:
		var stream: AudioStreamWAV = load(SFX_DIR + loop_name + ".wav")
		if stream == null:
			continue
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = stream.data.size() / 2
		var player := AudioStreamPlayer.new()
		player.stream = stream
		player.volume_db = -60.0
		player.autoplay = true
		add_child(player)
		player.play()
		_loop_players[loop_name] = player
		_loop_targets[loop_name] = 0.0


func sfx(name: String, volume_db := -8.0, pitch_jitter := 0.08) -> void:
	var stream: AudioStream = load(SFX_DIR + name + ".wav")
	if stream == null:
		return
	var player: AudioStreamPlayer = _pool[_pool_index]
	_pool_index = (_pool_index + 1) % POOL_SIZE
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	player.play()


func click() -> void:
	sfx("click", -12.0, 0.02)


func _process(delta: float) -> void:
	_context_timer -= delta
	if _context_timer <= 0.0:
		_context_timer = 0.6
		_read_context()
	for loop_name: String in _loop_players.keys():
		var player: AudioStreamPlayer = _loop_players[loop_name]
		var target_db := linear_to_db(maxf(_loop_targets[loop_name], 0.0001))
		player.volume_db = lerpf(player.volume_db, target_db, 2.5 * delta)


## Lê o mundo e decide o que se ouve — sem triggers manuais.
func _read_context() -> void:
	var player := get_tree().get_first_node_in_group("player")
	var weather: String = Sim.world.weather.current("pelagem_cinza")
	var night: bool = Sim.world.clock.is_night()
	var raining := weather in ["rain", "storm"]
	_loop_targets["rain_loop"] = 0.45 if raining else 0.0
	_loop_targets["wind_loop"] = 0.3 if weather == "storm" else 0.12
	_loop_targets["crickets_loop"] = 0.18 if night and not raining else 0.0
	if player == null:
		return
	var pos: Vector3 = player.global_position
	var shore := clampf((pos.z - 20.0) / 60.0, 0.0, 1.0)
	_loop_targets["waves_loop"] = 0.4 * shore
	var fire_distance := 999.0
	for spot: Vector3 in FIRE_SPOTS:
		fire_distance = minf(fire_distance, pos.distance_to(spot))
	_loop_targets["fire_loop"] = clampf(1.0 - fire_distance / 9.0, 0.0, 1.0) * 0.5
