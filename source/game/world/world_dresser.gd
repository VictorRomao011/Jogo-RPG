class_name WorldDresser
extends Node3D
## Veste o mundo sobre o TERRENO real: pinheiros (copas em camadas),
## carvalhos, rochas, milhares de tufos de capim via MultiMesh (1 draw
## call por tipo) e corças. Tudo determinístico e ancorado em
## Terrain.height_at — silhuetas no horizonte convidam à exploração.

const PINE_COUNT := 90
const OAK_COUNT := 45
const ROCK_COUNT := 45
const GRASS_COUNT := 2600
const CRITTER_COUNT := 9
const AREA := 100.0
const CRITTER_SCENE := "res://source/game/world/critter.tscn"

## Zonas livres: {centro, raio} — vila, spawn, POIs, acampamento.
const CLEAR_ZONES := [
	{"center": Vector3(0, 0, -14), "radius": 30.0},
	{"center": Vector3(0, 0, 8), "radius": 9.0},
	{"center": Vector3(0, 0, 62), "radius": 15.0},
	{"center": Vector3(-52, 0, 12), "radius": 11.0},
	{"center": Vector3(46, 0, -42), "radius": 11.0},
	{"center": Vector3(-48, 0, -58), "radius": 12.0},
]

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 173
	_scatter_pines()
	_scatter_oaks()
	_scatter_rocks()
	_scatter_grass()
	_scatter_critters()


func _free_position(min_height := -0.2) -> Vector3:
	for _attempt in range(14):
		var x := _rng.randf_range(-AREA, AREA)
		var z := _rng.randf_range(-AREA, AREA)
		var h := Terrain.height_at(x, z)
		if h < min_height:
			continue
		var pos := Vector3(x, h, z)
		var blocked := false
		for zone: Dictionary in CLEAR_ZONES:
			var flat := Vector3(pos.x - zone["center"].x, 0, pos.z - zone["center"].z)
			if flat.length() < zone["radius"]:
				blocked = true
				break
		if not blocked:
			return pos
	return Vector3.INF


func _vertex_color_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 1.0
	return material


func _multimesh_node(mesh: Mesh, transforms: Array, colors: Array) -> MultiMeshInstance3D:
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.mesh = mesh
	multi.instance_count = transforms.size()
	for i in range(transforms.size()):
		multi.set_instance_transform(i, transforms[i])
		multi.set_instance_color(i, colors[i])
	var node := MultiMeshInstance3D.new()
	node.multimesh = multi
	return node


func _tree_spot(min_height: float, spots: Array) -> void:
	var pos := _free_position(min_height)
	if pos == Vector3.INF:
		return
	spots.append(pos)
	# Colisão do tronco.
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = 0.35
	cylinder.height = 3.0
	shape.shape = cylinder
	shape.position.y = 1.5
	body.add_child(shape)
	body.position = pos
	add_child(body)


func _scatter_pines() -> void:
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.16
	trunk.bottom_radius = 0.3
	trunk.height = 3.2
	var cone := CylinderMesh.new()
	cone.top_radius = 0.02
	cone.bottom_radius = 1.5
	cone.height = 3.4
	var spots: Array = []
	_collect_spots(PINE_COUNT, 0.1, spots)
	var trunk_transforms: Array = []
	var trunk_colors: Array = []
	var cone_transforms: Array = []
	var cone_colors: Array = []
	for pos: Vector3 in spots:
		var s := _rng.randf_range(0.8, 1.6)
		var basis := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * s)
		trunk_transforms.append(Transform3D(basis, pos + Vector3(0, 1.6 * s, 0)))
		trunk_colors.append(Color(0.3, 0.22, 0.15))
		var green := Color(0.14, 0.3, 0.16).lerp(Color(0.22, 0.42, 0.2), _rng.randf())
		cone_transforms.append(Transform3D(basis, pos + Vector3(0, 3.6 * s, 0)))
		cone_colors.append(green)
	add_child(_multimesh_node_with_material(trunk, trunk_transforms, trunk_colors))
	add_child(_multimesh_node_with_material(cone, cone_transforms, cone_colors))


func _scatter_oaks() -> void:
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.22
	trunk.bottom_radius = 0.35
	trunk.height = 2.4
	var crown := SphereMesh.new()
	crown.radius = 1.7
	crown.height = 2.8
	var spots: Array = []
	_collect_spots(OAK_COUNT, 0.1, spots)
	var trunk_transforms: Array = []
	var trunk_colors: Array = []
	var crown_transforms: Array = []
	var crown_colors: Array = []
	for pos: Vector3 in spots:
		var s := _rng.randf_range(0.85, 1.5)
		var basis := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * s)
		trunk_transforms.append(Transform3D(basis, pos + Vector3(0, 1.2 * s, 0)))
		trunk_colors.append(Color(0.33, 0.25, 0.17))
		crown_transforms.append(Transform3D(basis, pos + Vector3(0, 3.1 * s, 0)))
		crown_colors.append(Color(0.2, 0.34, 0.14).lerp(Color(0.32, 0.44, 0.18), _rng.randf()))
	add_child(_multimesh_node_with_material(trunk, trunk_transforms, trunk_colors))
	add_child(_multimesh_node_with_material(crown, crown_transforms, crown_colors))


func _collect_spots(count: int, min_height: float, spots: Array) -> void:
	for _i in range(count):
		_tree_spot(min_height, spots)


func _scatter_rocks() -> void:
	var rock := SphereMesh.new()
	rock.radius = 0.9
	rock.height = 1.1
	var transforms: Array = []
	var colors: Array = []
	for _i in range(ROCK_COUNT):
		var pos := _free_position(-0.4)
		if pos == Vector3.INF:
			continue
		var basis := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(
			_rng.randf_range(0.5, 1.8), _rng.randf_range(0.3, 0.8), _rng.randf_range(0.5, 1.8)
		))
		transforms.append(Transform3D(basis, pos + Vector3(0, 0.2, 0)))
		colors.append(Color(0.42, 0.42, 0.45).lerp(Color(0.55, 0.53, 0.5), _rng.randf()))
	add_child(_multimesh_node_with_material(rock, transforms, colors))


func _scatter_grass() -> void:
	var blade := BoxMesh.new()
	blade.size = Vector3(0.5, 0.4, 0.06)
	var transforms: Array = []
	var colors: Array = []
	for _i in range(GRASS_COUNT):
		var x := _rng.randf_range(-AREA, AREA)
		var z := _rng.randf_range(-AREA, AREA)
		var h := Terrain.height_at(x, z)
		if h < 0.0:
			continue
		var basis := Basis(Vector3.UP, _rng.randf() * TAU).scaled(
			Vector3.ONE * _rng.randf_range(0.6, 1.4)
		)
		transforms.append(Transform3D(basis, Vector3(x, h + 0.15, z)))
		colors.append(Color(0.25, 0.4, 0.16).lerp(Color(0.42, 0.5, 0.2), _rng.randf()))
	add_child(_multimesh_node_with_material(blade, transforms, colors))


func _multimesh_node_with_material(
	mesh: Mesh, transforms: Array, colors: Array
) -> MultiMeshInstance3D:
	var node := _multimesh_node(mesh, transforms, colors)
	node.material_override = _vertex_color_material()
	return node


func _scatter_critters() -> void:
	var critter_scene: PackedScene = load(CRITTER_SCENE)
	if critter_scene == null:
		return
	for _i in range(CRITTER_COUNT):
		var pos := _free_position(0.0)
		if pos != Vector3.INF:
			var critter: Critter = critter_scene.instantiate()
			add_child(critter)
			critter.position = pos + Vector3(0, 0.6, 0)
