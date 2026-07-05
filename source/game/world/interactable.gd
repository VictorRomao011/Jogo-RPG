class_name Interactable
extends Area3D
## Base de tudo que pode ser interagido. No touch, o botão de interação SÓ
## existe quando algo está no alcance (GDD §15.4) — este nó alimenta a HUD.

signal interacted(by: Node)

@export var prompt := "Interagir"
## Interações furtivas (furto) consultam percepção de testemunhas.
@export var is_crime := false


func _ready() -> void:
	add_to_group("interactables")


func interact(by: Node) -> void:
	interacted.emit(by)
