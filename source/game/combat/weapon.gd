class_name Weapon
extends Resource
## Identidade de arma (GDD §8.2): sem "dano por nível". Cada arma muda o
## verbo do combate — alcance, velocidade, dano de postura, ruído.

@export var id := "faca"
@export var display_name := "Faca"
@export var damage := 12.0
@export var posture_damage := 8.0
@export var reach := 1.2
@export var swing_time := 0.35
@export var stamina_cost := 9.0
## Ruído do golpe (interage com furtividade e percepção de NPCs).
@export var noise := 0.4
## Habilidade que este tipo de arma treina.
@export var skill := "short_blades"
## Lâminas de eco "cantam": furtividade impossível, efeitos estranhos.
@export var echo_touched := false


func heavy_damage() -> float:
	return damage * 1.7


func heavy_stamina_cost() -> float:
	return stamina_cost * 1.8


func effective_noise(sneaking: bool) -> float:
	if echo_touched:
		return 1.0  # sempre canta
	return noise * (0.5 if sneaking else 1.0)
