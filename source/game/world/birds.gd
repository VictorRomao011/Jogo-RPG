class_name Birds
extends Node3D
## Bando ambiente: gaivotas circulando alto sobre a costa. Vida no céu.

const COUNT := 7

var _birds: Array = []


func _ready() -> void:
	var body := CapsuleMesh.new()
	body.radius = 0.09
	body.height = 0.5
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.85, 0.85, 0.88)
	body.material = material
	for i in range(COUNT):
		var bird := MeshInstance3D.new()
		bird.mesh = body
		bird.rotation.x = PI / 2.0
		add_child(bird)
		_birds.append({
			"node": bird,
			"radius": randf_range(18.0, 45.0),
			"height": randf_range(16.0, 26.0),
			"speed": randf_range(0.15, 0.3) * (1.0 if i % 2 == 0 else -1.0),
			"angle": randf() * TAU,
		})


func _process(delta: float) -> void:
	for bird: Dictionary in _birds:
		bird["angle"] += bird["speed"] * delta
		var node: MeshInstance3D = bird["node"]
		node.position = Vector3(
			cos(bird["angle"]) * bird["radius"],
			bird["height"] + sin(bird["angle"] * 3.0) * 1.5,
			sin(bird["angle"]) * bird["radius"]
		)
		node.rotation.y = -bird["angle"]
