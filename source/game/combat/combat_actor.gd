class_name CombatActor
extends CharacterBody3D
## Base comum de combate para jogador e NPCs (GDD §8): vida, stamina,
## postura e ferimentos localizados. Lutas curtas e legíveis; as mesmas
## regras valem para todos — quebra de postura abre execução no jogador também.

signal died(actor: CombatActor)
signal posture_broken(actor: CombatActor)
signal damaged(actor: CombatActor, amount: float, limb: String)

const POSTURE_RECOVERY_PER_SEC := 14.0
const PARRY_WINDOW := 0.18

var max_health := 100.0
var health := 100.0
var max_posture := 60.0
var posture := 60.0
var blocking := false
var parry_timer := 0.0
## Ferimentos leves localizados: "leg" (manca), "arm" (ataque lento).
var wounds: Dictionary = {}
var weapon: Weapon = Weapon.new()


func _physics_process(delta: float) -> void:
	posture = minf(posture + POSTURE_RECOVERY_PER_SEC * delta, max_posture)
	parry_timer = maxf(0.0, parry_timer - delta)


func begin_parry() -> void:
	parry_timer = PARRY_WINDOW


func take_hit(attacker: CombatActor, damage: float, posture_damage: float, limb := "torso") -> void:
	if parry_timer > 0.0:
		# Aparo perfeito: atacante perde postura, defensor nada.
		attacker.posture = maxf(0.0, attacker.posture - posture_damage * 2.0)
		if attacker.posture <= 0.0:
			attacker._break_posture()
		return
	if blocking:
		posture = maxf(0.0, posture - posture_damage)
		if posture <= 0.0:
			_break_posture()
		return
	health = maxf(0.0, health - damage)
	posture = maxf(0.0, posture - posture_damage * 0.5)
	if damage > max_health * 0.25 and limb != "torso":
		wounds[limb] = 1.0
	damaged.emit(self, damage, limb)
	if health <= 0.0:
		died.emit(self)


func _break_posture() -> void:
	posture_broken.emit(self)
	blocking = false


## Modificadores de ferimento (GDD §8.2): perna = velocidade; braço = golpe.
func move_speed_modifier() -> float:
	return 0.6 if wounds.has("leg") else 1.0


func attack_speed_modifier() -> float:
	return 0.7 if wounds.has("arm") else 1.0


## Cura de verdade requer descanso/medicina — não regen automática.
func treat_wounds(medicine_skill: float) -> void:
	for limb in wounds.keys().duplicate():
		wounds[limb] -= 0.3 + medicine_skill / 200.0
		if wounds[limb] <= 0.0:
			wounds.erase(limb)


func is_alive() -> bool:
	return health > 0.0
