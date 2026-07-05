extends Node
## Autoload "Sim": dono do WorldState. Faz a simulação avançar em tempo real,
## expõe sinais para a encenação/UI e cuida de save/load.
## O mundo roda com ou sem o jogador — pausar o jogo pausa a encenação,
## nunca corrompe o estado.

signal world_ready
signal world_event(event: Dictionary)

const SAVE_PATH := "user://save_slot_0.save"

var world := WorldState.new()
var scheduler := SimScheduler.new()
var paused := false


func _ready() -> void:
	# Android: orçamento de timeslice menor por frame (mesma lógica, GDD §16.3).
	if OS.get_name() == "Android":
		scheduler.budget_usec = 1200
	world.initialize()
	world.day_simulated.connect(_on_day_simulated)
	world_ready.emit()


func _process(delta: float) -> void:
	if paused:
		return
	world.advance(delta)
	scheduler.run_slice()


func _on_day_simulated(_day: int, events: Array) -> void:
	for event: Dictionary in events:
		world_event.emit(event)


## Dormir/viajar aceleram o mundo de verdade (não é fade-out fake).
func skip_hours(hours: int) -> void:
	for _i in range(hours):
		world.advance(float(WorldClock.MINUTES_PER_HOUR) / maxf(world.clock.time_scale, 0.001))
	scheduler.drain()


func save_game(player_data: Dictionary) -> bool:
	var snapshot := {
		"world": world.to_dict(),
		"player": player_data,
		"saved_at": Time.get_datetime_string_from_system(),
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Sim: não foi possível salvar em %s" % SAVE_PATH)
		return false
	file.store_var(snapshot, false)
	return true


func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var snapshot: Variant = file.get_var(false)
	if snapshot is Dictionary:
		world.from_dict(snapshot.get("world", {}))
		return snapshot.get("player", {})
	return {}
