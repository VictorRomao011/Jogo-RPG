class_name VillageBuilder
extends Node3D
## Constrói Bruma Alta de verdade: casas com telhado, porta, janelas que
## acendem à noite, chaminé; poço central e cercas. Tudo com colisão.

## [x, z, largura, profundidade, rotação_y, cor_telhado]
const HOUSES := [
	[-12.0, -16.0, 7.0, 6.0, 0.1, Color(0.42, 0.2, 0.16)],
	[6.0, -18.0, 8.5, 7.0, -0.15, Color(0.3, 0.24, 0.18)],
	[14.0, -12.0, 6.0, 5.5, 0.35, Color(0.42, 0.2, 0.16)],
	[-2.0, -24.0, 6.5, 5.5, 0.0, Color(0.34, 0.3, 0.22)],
	[-18.0, -24.0, 6.0, 5.0, -0.3, Color(0.3, 0.24, 0.18)],
	[3.0, -7.0, 5.0, 4.5, 0.2, Color(0.42, 0.2, 0.16)],
]

var _window_material: StandardMaterial3D


func _ready() -> void:
	add_to_group("village")
	var wall_material := StandardMaterial3D.new()
	wall_material.albedo_color = Color(0.72, 0.66, 0.55)
	wall_material.roughness = 1.0
	var wood_material := StandardMaterial3D.new()
	wood_material.albedo_color = Color(0.32, 0.24, 0.16)
	wood_material.roughness = 1.0
	_window_material = StandardMaterial3D.new()
	_window_material.albedo_color = Color(0.9, 0.75, 0.4)
	_window_material.emission_enabled = true
	_window_material.emission = Color(1.0, 0.75, 0.35)
	_window_material.emission_energy_multiplier = 0.0
	for house: Array in HOUSES:
		add_child(_build_house(house, wall_material, wood_material))
	add_child(_build_well(wood_material))
	_build_fences(wood_material)


## Janelas acendem conforme a noite chega (chamado pelo DayNight).
func set_window_glow(energy: float) -> void:
	_window_material.emission_energy_multiplier = energy


func _build_house(
	data: Array, wall_material: StandardMaterial3D, wood_material: StandardMaterial3D
) -> StaticBody3D:
	var width: float = data[2]
	var depth: float = data[3]
	var wall_height := 3.0
	var body := StaticBody3D.new()
	body.position = Vector3(data[0], 0, data[1])
	body.rotation.y = data[4]

	var walls := MeshInstance3D.new()
	var wall_mesh := BoxMesh.new()
	wall_mesh.size = Vector3(width, wall_height, depth)
	wall_mesh.material = wall_material
	walls.mesh = wall_mesh
	walls.position.y = wall_height * 0.5
	body.add_child(walls)

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(width, wall_height, depth)
	shape.shape = box
	shape.position.y = wall_height * 0.5
	body.add_child(shape)

	var roof := MeshInstance3D.new()
	var roof_mesh := PrismMesh.new()
	roof_mesh.size = Vector3(width + 0.8, 1.8, depth + 0.8)
	var roof_material := StandardMaterial3D.new()
	roof_material.albedo_color = data[5]
	roof_material.roughness = 1.0
	roof_mesh.material = roof_material
	roof.mesh = roof_mesh
	roof.position.y = wall_height + 0.9
	body.add_child(roof)

	var door := MeshInstance3D.new()
	var door_mesh := BoxMesh.new()
	door_mesh.size = Vector3(0.9, 1.9, 0.1)
	door_mesh.material = wood_material
	door.mesh = door_mesh
	door.position = Vector3(0, 0.95, depth * 0.5 + 0.04)
	body.add_child(door)

	for side in [-1.0, 1.0]:
		var window := MeshInstance3D.new()
		var window_mesh := BoxMesh.new()
		window_mesh.size = Vector3(0.7, 0.7, 0.08)
		window_mesh.material = _window_material
		window.mesh = window_mesh
		window.position = Vector3(side * width * 0.28, 1.7, depth * 0.5 + 0.04)
		body.add_child(window)

	var chimney := MeshInstance3D.new()
	var chimney_mesh := BoxMesh.new()
	chimney_mesh.size = Vector3(0.5, 1.4, 0.5)
	chimney_mesh.material = wall_material
	chimney.mesh = chimney_mesh
	chimney.position = Vector3(width * 0.3, wall_height + 1.4, 0)
	body.add_child(chimney)
	return body


func _build_well(wood_material: StandardMaterial3D) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = Vector3(-3, 0, -14)
	var ring := MeshInstance3D.new()
	var ring_mesh := CylinderMesh.new()
	ring_mesh.top_radius = 0.9
	ring_mesh.bottom_radius = 1.0
	ring_mesh.height = 0.9
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.45, 0.45, 0.48)
	ring_mesh.material = stone
	ring.mesh = ring_mesh
	ring.position.y = 0.45
	body.add_child(ring)
	var roof := MeshInstance3D.new()
	var roof_mesh := PrismMesh.new()
	roof_mesh.size = Vector3(2.2, 0.9, 2.2)
	roof_mesh.material = wood_material
	roof.mesh = roof_mesh
	roof.position.y = 2.3
	body.add_child(roof)
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = 1.0
	cylinder.height = 1.0
	shape.shape = cylinder
	shape.position.y = 0.5
	body.add_child(shape)
	return body


func _build_fences(wood_material: StandardMaterial3D) -> void:
	var rail_mesh := BoxMesh.new()
	rail_mesh.size = Vector3(2.0, 0.12, 0.08)
	rail_mesh.material = wood_material
	var post_mesh := BoxMesh.new()
	post_mesh.size = Vector3(0.12, 1.0, 0.12)
	post_mesh.material = wood_material
	for i in range(8):
		var segment := Node3D.new()
		segment.position = Vector3(-20.0 + i * 2.0, 0, -4.0)
		var post := MeshInstance3D.new()
		post.mesh = post_mesh
		post.position.y = 0.5
		segment.add_child(post)
		var rail := MeshInstance3D.new()
		rail.mesh = rail_mesh
		rail.position = Vector3(1.0, 0.75, 0)
		segment.add_child(rail)
		add_child(segment)
