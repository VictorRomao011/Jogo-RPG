class_name QuadrupedRig
extends Node3D
## Corça procedural: corpo, cabeça, orelhas e 4 pernas com trote animado.

var _legs: Array = []
var _phase := 0.0


static func make(body_color: Color) -> QuadrupedRig:
	var rig := QuadrupedRig.new()
	var belly := Color(body_color.r * 1.2, body_color.g * 1.15, body_color.b * 1.1)
	rig.add_child(_part(Vector3(0.36, 0.34, 0.8), Vector3(0, 0.62, 0), body_color))
	rig.add_child(_part(Vector3(0.2, 0.2, 0.26), Vector3(0, 0.88, -0.5), body_color))
	rig.add_child(_part(Vector3(0.05, 0.14, 0.04), Vector3(-0.07, 1.04, -0.52), belly))
	rig.add_child(_part(Vector3(0.05, 0.14, 0.04), Vector3(0.07, 1.04, -0.52), belly))
	for offset in [
		Vector3(-0.13, 0.45, -0.3), Vector3(0.13, 0.45, -0.3),
		Vector3(-0.13, 0.45, 0.3), Vector3(0.13, 0.45, 0.3),
	]:
		var leg := _limb(Vector3(0.09, 0.48, 0.09), offset, body_color)
		rig._legs.append(leg)
		rig.add_child(leg)
	return rig


static func _part(part_size: Vector3, at: Vector3, color: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = part_size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	box.material = material
	mesh_instance.mesh = box
	mesh_instance.position = at
	return mesh_instance


static func _limb(part_size: Vector3, joint: Vector3, color: Color) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = joint
	var mesh := _part(part_size, Vector3(0, -part_size.y * 0.5, 0), color)
	pivot.add_child(mesh)
	return pivot


func _process(delta: float) -> void:
	var parent := get_parent()
	var speed := 0.0
	if parent is CharacterBody3D:
		var v: Vector3 = parent.velocity
		speed = Vector2(v.x, v.z).length()
	var stride := clampf(speed / 3.0, 0.0, 1.5)
	_phase += delta * (3.0 + speed * 2.5)
	for i in range(_legs.size()):
		var side := 1.0 if i % 2 == 0 else -1.0
		var pair := 1.0 if i < 2 else -1.0
		_legs[i].rotation.x = sin(_phase) * 0.6 * stride * side * pair
