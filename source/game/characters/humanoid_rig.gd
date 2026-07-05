class_name HumanoidRig
extends Node3D
## Personagem humanoide procedural: cabeça, tronco, braços e pernas com
## animação de caminhada (pernas/braços alternados, balanço do corpo).
## Substitui as cápsulas — cada NPC ganha pele, roupa e cabelo próprios.

var _left_leg: Node3D
var _right_leg: Node3D
var _left_arm: Node3D
var _right_arm: Node3D
var _torso: Node3D
var _phase := 0.0


static func make(
	skin: Color, tunic: Color, pants: Color, hair: Color, masked := false
) -> HumanoidRig:
	var rig := HumanoidRig.new()
	rig._torso = Node3D.new()
	rig.add_child(rig._torso)

	# Tronco (túnica).
	rig._torso.add_child(_part(Vector3(0.42, 0.56, 0.26), Vector3(0, 1.12, 0), tunic))
	# Cabeça + cabelo (ou máscara).
	rig._torso.add_child(_part(Vector3(0.26, 0.26, 0.26), Vector3(0, 1.56, 0), skin))
	if masked:
		rig._torso.add_child(
			_part(Vector3(0.28, 0.12, 0.28), Vector3(0, 1.58, 0), Color(0.55, 0.12, 0.1))
		)
	else:
		rig._torso.add_child(
			_part(Vector3(0.28, 0.1, 0.28), Vector3(0, 1.68, 0), hair)
		)

	# Braços pendurados nos ombros (pivô no alto para balançar).
	rig._left_arm = _limb(Vector3(0.11, 0.55, 0.11), Vector3(-0.28, 1.38, 0), skin)
	rig._right_arm = _limb(Vector3(0.11, 0.55, 0.11), Vector3(0.28, 1.38, 0), skin)
	rig._torso.add_child(rig._left_arm)
	rig._torso.add_child(rig._right_arm)

	# Pernas com pivô no quadril.
	rig._left_leg = _limb(Vector3(0.14, 0.8, 0.14), Vector3(-0.11, 0.82, 0), pants)
	rig._right_leg = _limb(Vector3(0.14, 0.8, 0.14), Vector3(0.11, 0.82, 0), pants)
	rig.add_child(rig._left_leg)
	rig.add_child(rig._right_leg)
	return rig


static func _part(part_size: Vector3, at: Vector3, color: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = part_size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	box.material = material
	mesh_instance.mesh = box
	mesh_instance.position = at
	return mesh_instance


## Membro com pivô no topo: o nó fica na junta, a malha desce.
static func _limb(part_size: Vector3, joint: Vector3, color: Color) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = joint
	var mesh := _part(part_size, Vector3(0, -part_size.y * 0.5, 0), color)
	pivot.add_child(mesh)
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
	# Balanço sutil do corpo ao andar; respiração parado.
	if stride > 0.05:
		_torso.position.y = absf(sin(_phase * 2.0)) * 0.05 * stride
	else:
		_torso.position.y = sin(_phase * 0.5) * 0.012
		_left_arm.rotation.x = sin(_phase * 0.5) * 0.05
		_right_arm.rotation.x = -sin(_phase * 0.5) * 0.05
