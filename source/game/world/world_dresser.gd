class_name WorldDresser
extends Node3D
## Veste o mundo: espalha pinheiros e rochas de forma determinística
## (mesmo seed do mundo), evitando a vila, os POIs e as clareiras deles.
## Silhuetas no horizonte = curiosidade (GDD §4.1) — mesmo em graybox.

const TREE_COUNT := 130
const ROCK_COUNT := 45
const CRITTER_COUNT := 9
const AREA := 92.0
const CRITTER_SCENE := "res://source/game/world/critter.tscn"

## Zonas livres: {centro, raio} — vila, spawn, POIs.
const CLEAR_ZONES := [
	{"center": Vector3(0, 0, -12), "radius": 28.0},
	{"center": Vector3(0, 0, 8), "radius": 8.0},
	{"center": Vector3(0, 0, 62), "radius": 14.0},
	{"center": Vector3(-52, 0, 12), "radius": 12.0},
	{"center": Vector3(46, 0, -42), "radius": 12.0},
]

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 173
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.16
	trunk_mesh.bottom_radius = 0.26
	trunk_mesh.height = 2.4
	var trunk_mat := StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.32, 0.24, 0.17)
	trunk_mesh.material = trunk_mat

	var leaf_meshes: Array = []
	for tint in [Color(0.22, 0.36, 0.22), Color(0.27, 0.4, 0.24), Color(0.2, 0.33, 0.27)]:
		var leaves := SphereMesh.new()
		leaves.radius = 1.25
		leaves.height = 2.9
		var mat := StandardMaterial3D.new()
		mat.albedo_color = tint
		leaves.material = mat
		leaf_meshes.append(leaves)

	var rock_mesh := SphereMesh.new()
	rock_mesh.radius = 0.9
	rock_mesh.height = 1.1
	var rock_mat := StandardMaterial3D.new()
	rock_mat.albedo_color = Color(0.45, 0.45, 0.47)
	rock_mesh.material = rock_mat

	for _i in range(TREE_COUNT):
		var pos := _free_position()
		if pos != Vector3.INF:
			add_child(_make_tree(pos, trunk_mesh, leaf_meshes[_rng.randi() % leaf_meshes.size()]))
	for _i in range(ROCK_COUNT):
		var pos := _free_position()
		if pos != Vector3.INF:
			add_child(_make_rock(pos, rock_mesh))
	var critter_scene: PackedScene = load(CRITTER_SCENE)
	if critter_scene != null:
		for _i in range(CRITTER_COUNT):
			var pos := _free_position()
			if pos != Vector3.INF:
				var critter: Critter = critter_scene.instantiate()
				add_child(critter)
				critter.position = pos + Vector3(0, 0.5, 0)


func _free_position() -> Vector3:
	for _attempt in range(12):
		var pos := Vector3(
			_rng.randf_range(-AREA, AREA), 0.0, _rng.randf_range(-AREA, AREA)
		)
		var blocked := false
		for zone: Dictionary in CLEAR_ZONES:
			if pos.distance_to(zone["center"]) < zone["radius"]:
				blocked = true
				break
		if not blocked:
			return pos
	return Vector3.INF


func _make_tree(pos: Vector3, trunk_mesh: Mesh, leaf_mesh: Mesh) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	body.rotation.y = _rng.randf() * TAU
	var tree_scale := _rng.randf_range(0.8, 1.5)
	body.scale = Vector3.ONE * tree_scale

	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = 0.3
	cylinder.height = 2.4
	shape.shape = cylinder
	shape.position.y = 1.2
	body.add_child(shape)

	var trunk := MeshInstance3D.new()
	trunk.mesh = trunk_mesh
	trunk.position.y = 1.2
	body.add_child(trunk)

	var leaves := MeshInstance3D.new()
	leaves.mesh = leaf_mesh
	leaves.position.y = 3.2
	body.add_child(leaves)
	return body


func _make_rock(pos: Vector3, rock_mesh: Mesh) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	body.rotation.y = _rng.randf() * TAU
	body.scale = Vector3(
		_rng.randf_range(0.5, 1.8), _rng.randf_range(0.35, 0.9), _rng.randf_range(0.5, 1.8)
	)
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.9
	shape.shape = sphere
	body.add_child(shape)
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = rock_mesh
	body.add_child(mesh_instance)
	return body
