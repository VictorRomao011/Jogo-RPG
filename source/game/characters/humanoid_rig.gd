class_name HumanoidRig
extends Node3D
## Personagem humanoide v2: formas arredondadas (nada de cubos) — cabeça
## esférica com olhos, tronco e membros em cápsulas, mãos e pés, cabelo.
## Anima caminhada, ataque e reação a dano proceduralmente.

var _left_leg: Node3D
var _right_leg: Node3D
var _left_arm: Node3D
var _right_arm: Node3D
var _torso: Node3D
var _phase := 0.0
var _attack_time := 0.0
var _hit_time := 0.0


static func make(
	skin: Color, tunic: Color, pants: Color, hair: Color, masked := false
) -> HumanoidRig:
	var rig := HumanoidRig.new()
	rig._torso = Node3D.new()
	rig.add_child(rig._torso)

	# Tronco em cápsula (ombros arredondados) + quadril.
	rig._torso.add_child(_capsule(0.21, 0.62, Vector3(0, 1.14, 0), tunic))
	rig._torso.add_child(_capsule(0.17, 0.3, Vector3(0, 0.86, 0), pants))
	# Cabeça esférica com olhos e cabelo (ou máscara).
	var head := _sphere(0.15, Vector3(0, 1.58, 0), skin)
	rig._torso.add_child(head)
	head.add_child(_sphere(0.025, Vector3(-0.055, 0.03, -0.13), Color(0.08, 0.08, 0.1)))
	head.add_child(_sphere(0.025, Vector3(0.055, 0.03, -0.13), Color(0.08, 0.08, 0.1)))
	if masked:
		head.add_child(_capsule(0.155, 0.1, Vector3(0, 0.02, -0.02), Color(0.5, 0.1, 0.08)))
	else:
		head.add_child(_sphere(0.155, Vector3(0, 0.06, 0.02), hair))

	# Braços em cápsulas com mãos; pivô no ombro.
	rig._left_arm = _limb(0.065, 0.52, Vector3(-0.29, 1.4, 0), skin, tunic)
	rig._right_arm = _limb(0.065, 0.52, Vector3(0.29, 1.4, 0), skin, tunic)
	rig._torso.add_child(rig._left_arm)
	rig._torso.add_child(rig._right_arm)

	# Pernas em cápsulas com pés; pivô no quadril.
	rig._left_leg = _limb(0.085, 0.78, Vector3(-0.11, 0.8, 0), pants, pants, true)
	rig._right_leg = _limb(0.085, 0.78, Vector3(0.11, 0.8, 0), pants, pants, true)
	rig.add_child(rig._left_leg)
	rig.add_child(rig._right_leg)
	return rig


static func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	return material


static func _sphere(radius: float, at: Vector3, color: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.material = _material(color)
	mesh_instance.mesh = sphere
	mesh_instance.position = at
	return mesh_instance


static func _capsule(radius: float, height: float, at: Vector3, color: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = radius
	capsule.height = height + radius * 2.0
	capsule.material = _material(color)
	mesh_instance.mesh = capsule
	mesh_instance.position = at
	return mesh_instance


## Membro arredondado com extremidade (mão/pé); pivô na junta.
static func _limb(
	radius: float, length: float, joint: Vector3, tip_color: Color,
	sleeve_color: Color, is_leg := false
) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = joint
	pivot.add_child(_capsule(radius, length - radius, Vector3(0, -length * 0.5, 0), sleeve_color))
	if is_leg:
		var foot := _capsule(radius * 0.9, 0.12, Vector3(0, -length, -0.06), Color(0.2, 0.16, 0.12))
		foot.rotation.x = PI / 2.0
		pivot.add_child(foot)
	else:
		pivot.add_child(_sphere(radius * 1.15, Vector3(0, -length, 0), tip_color))
	return pivot


## Paleta determinística por identidade (cada aldeão tem a sua cara).
static func palette_for(id: String) -> Array:
	var skins := [Color(0.85, 0.68, 0.55), Color(0.72, 0.53, 0.4), Color(0.55, 0.4, 0.3)]
	var tunics := [
		Color(0.45, 0.38, 0.28), Color(0.35, 0.42, 0.35), Color(0.5, 0.32, 0.28),
		Color(0.32, 0.36, 0.45), Color(0.48, 0.44, 0.3),
	]
	var pants := [Color(0.28, 0.24, 0.2), Color(0.32, 0.3, 0.28), Color(0.24, 0.26, 0.3)]
	var hairs := [Color(0.15, 0.1, 0.08), Color(0.35, 0.25, 0.12), Color(0.55, 0.5, 0.45)]
	var h := abs(hash(id))
	return [
		skins[h % skins.size()],
		tunics[(h / 7) % tunics.size()],
		pants[(h / 31) % pants.size()],
		hairs[(h / 131) % hairs.size()],
	]


## Golpe: o braço direito desce num arco rápido.
func play_attack() -> void:
	_attack_time = 0.35


## Reação a dano: o tronco recua.
func play_hit() -> void:
	_hit_time = 0.25


func _process(delta: float) -> void:
	var parent := get_parent()
	var speed := 0.0
	if parent is CharacterBody3D:
		var v: Vector3 = parent.velocity
		speed = Vector2(v.x, v.z).length()
	var stride := clampf(speed / 4.0, 0.0, 1.4)
	_phase += delta * (2.0 + speed * 2.2)
	var swing := sin(_phase) * 0.75 * stride
	_left_leg.rotation.x = swing
	_right_leg.rotation.x = -swing
	_left_arm.rotation.x = -swing * 0.8
	_right_arm.rotation.x = swing * 0.8

	# Ataque sobrepõe o braço direito; reação a dano inclina o tronco.
	if _attack_time > 0.0:
		_attack_time -= delta
		var t := 1.0 - _attack_time / 0.35
		_right_arm.rotation.x = lerpf(-2.2, 0.7, t)
	if _hit_time > 0.0:
		_hit_time -= delta
		_torso.rotation.x = -_hit_time * 0.9
	else:
		_torso.rotation.x = 0.0

	if stride > 0.05:
		_torso.position.y = absf(sin(_phase * 2.0)) * 0.05 * stride
	else:
		_torso.position.y = sin(_phase * 0.5) * 0.012
		if _attack_time <= 0.0:
			_left_arm.rotation.x = sin(_phase * 0.5) * 0.05
			_right_arm.rotation.x = -sin(_phase * 0.5) * 0.05
