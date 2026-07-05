class_name WorldClock
extends RefCounted
## Tempo canônico do mundo: minutos, dias, estações e calendário pós-Silêncio.
## Toda a simulação lê o tempo daqui; nenhum sistema mantém relógio próprio.

signal hour_passed(hour: int)
signal day_passed(day: int)
signal season_changed(season: int)

const MINUTES_PER_HOUR := 60
const HOURS_PER_DAY := 24
const DAYS_PER_SEASON := 30
const SEASONS := ["Degelo", "Sol Alto", "Colheita", "Silêncio Branco"]
const STARTING_YEAR := 173

## 1 segundo real = 1 minuto de jogo por padrão (dia de 24 min).
var time_scale := 1.0
var total_minutes := 8.0 * MINUTES_PER_HOUR  # o mundo começa às 08:00 do dia 0

var _last_hour := 8
var _last_day := 0
var _last_season := 0


func advance(real_delta: float) -> void:
	total_minutes += real_delta * time_scale
	var h := hour()
	if h != _last_hour:
		_last_hour = h
		hour_passed.emit(h)
	var d := day()
	if d != _last_day:
		_last_day = d
		day_passed.emit(d)
	var s := season_index()
	if s != _last_season:
		_last_season = s
		season_changed.emit(s)


## Avança dias inteiros de uma vez (usado por viagens, sono e soak tests).
func skip_days(days: int) -> void:
	for _i in range(days * HOURS_PER_DAY):
		advance(float(MINUTES_PER_HOUR) / maxf(time_scale, 0.001))


func minute_of_day() -> int:
	return int(total_minutes) % (HOURS_PER_DAY * MINUTES_PER_HOUR)


func hour() -> int:
	return minute_of_day() / MINUTES_PER_HOUR


func day() -> int:
	return int(total_minutes) / (HOURS_PER_DAY * MINUTES_PER_HOUR)


func season_index() -> int:
	return (day() / DAYS_PER_SEASON) % SEASONS.size()


func season_name() -> String:
	return SEASONS[season_index()]


func year() -> int:
	return STARTING_YEAR + day() / (DAYS_PER_SEASON * SEASONS.size())


func is_night() -> bool:
	var h := hour()
	return h >= 21 or h < 5


## Fração 0..1 do dia (para céu, rotinas e clima).
func day_fraction() -> float:
	return float(minute_of_day()) / float(HOURS_PER_DAY * MINUTES_PER_HOUR)


func timestamp() -> String:
	return "Ano %d, %s, dia %d, %02d:%02d" % [
		year(), season_name(), (day() % DAYS_PER_SEASON) + 1,
		hour(), minute_of_day() % MINUTES_PER_HOUR,
	]


func to_dict() -> Dictionary:
	return {"total_minutes": total_minutes, "time_scale": time_scale}


func from_dict(data: Dictionary) -> void:
	total_minutes = data.get("total_minutes", total_minutes)
	time_scale = data.get("time_scale", time_scale)
	_last_hour = hour()
	_last_day = day()
	_last_season = season_index()
