class_name EchoTrail
extends RefCounted
## O fio do Eco (GDD §13.3): a "história principal" que quase desaparece.
## 7 ressonâncias espalhadas pelo mundo reagem ao fragmento do jogador.
## Sem marcador, sem lista de missão — só o mundo sussurrando. Quem
## conecta as 7 entende (a sua versão de) o Silêncio.

signal resonance_found(echo_id: String, found_count: int)
signal trail_completed

const TOTAL := 7

var found: Array = []
var completed := false


func find(echo_id: String) -> bool:
	if echo_id in found or completed:
		return false
	found.append(echo_id)
	resonance_found.emit(echo_id, found.size())
	if found.size() >= TOTAL:
		completed = true
		trail_completed.emit()
	return true


func count() -> int:
	return found.size()


## Sussurro proporcional ao progresso — o feedback é diegético, nunca
## um contador na tela.
func whisper_for(found_count: int) -> String:
	match found_count:
		1:
			return "O fragmento no seu peito vibra, uma vez, como um sino distante."
		2, 3:
			return "A vibração dura mais. Há um padrão — quase uma frase."
		4, 5:
			return "Você começa a ouvi-lo mesmo acordado. Ele procura algo."
		6:
			return "Falta uma. Você não sabe como sabe. Mas falta uma."
		TOTAL:
			return "Silêncio. Pela primeira vez em 173 anos, um silêncio que ESCOLHE calar."
		_:
			return ""


func to_dict() -> Dictionary:
	return {"found": found.duplicate(), "completed": completed}


func from_dict(data: Dictionary) -> void:
	found = data.get("found", found)
	completed = data.get("completed", completed)
