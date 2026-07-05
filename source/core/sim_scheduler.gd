class_name SimScheduler
extends RefCounted
## Timeslicing (GDD §16.3): espalha trabalho de simulação por vários frames
## para nunca estourar o orçamento de CPU — crítico no Android, onde a
## lógica é idêntica à do PC, só com latência de tick abstrato maior.

## Orçamento por frame, em microssegundos (ajustado por plataforma).
var budget_usec := 2000

var _queue: Array[Callable] = []


func enqueue(task: Callable) -> void:
	_queue.append(task)


func enqueue_batch(tasks: Array[Callable]) -> void:
	_queue.append_array(tasks)


func pending() -> int:
	return _queue.size()


## Executa tarefas até esgotar a fila ou o orçamento do frame.
func run_slice() -> void:
	var start := Time.get_ticks_usec()
	while not _queue.is_empty():
		var task: Callable = _queue.pop_front()
		task.call()
		if Time.get_ticks_usec() - start > budget_usec:
			break


## Descarrega tudo de uma vez (headless/soak tests, sono e viagem rápida).
func drain() -> void:
	while not _queue.is_empty():
		var task: Callable = _queue.pop_front()
		task.call()
