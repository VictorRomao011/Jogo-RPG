class_name Terrain
extends StaticBody3D
## Terreno real: colinas por ruído FBM, praia descendo ao mar no sul e
## platôs aplainados onde o design precisa (vila, POIs, acampamento).
## O shader mistura grama/terra/rocha/areia por inclinação e altura.
## `height_at()` é a fonte da verdade — tudo que nasce no mundo usa ela.

const SIZE := 220.0
const STEP := 2.2
const HEIGHT_SCALE := 7.0
const WATER_LEVEL := -0.8

## Zonas aplainadas: {x, z, raio} — o relevo funde suavemente para 0.
const FLAT_ZONES := [
	[0.0, -12.0, 30.0],
	[0.0, 8.0, 12.0],
	[-48.0, -58.0, 11.0],
	[0.0, 62.0, 15.0],
	[-52.0, 12.0, 9.0],
	[46.0, -42.0, 9.0],
]

const TERRAIN_SHADER := """
shader_type spatial;
uniform sampler2D noise_tex : filter_linear, repeat_enable;
varying vec3 wpos;
varying vec3 wnorm;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnorm = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz;
}
void fragment() {
	float detail = texture(noise_tex, wpos.xz * 0.09).r;
	float patch = texture(noise_tex, wpos.xz * 0.013).r;
	vec3 grass = mix(vec3(0.20, 0.33, 0.14), vec3(0.33, 0.46, 0.19), detail);
	grass = mix(grass, vec3(0.42, 0.44, 0.22), smoothstep(0.6, 0.85, patch) * 0.6);
	vec3 dirt = mix(vec3(0.33, 0.25, 0.17), vec3(0.42, 0.33, 0.22), detail);
	vec3 rock = mix(vec3(0.36, 0.36, 0.38), vec3(0.5, 0.5, 0.52), detail);
	vec3 sand = mix(vec3(0.66, 0.6, 0.45), vec3(0.74, 0.68, 0.52), detail);
	float slope = 1.0 - clamp(normalize(wnorm).y, 0.0, 1.0);
	vec3 col = mix(grass, dirt, smoothstep(0.10, 0.22, slope + (patch - 0.5) * 0.08));
	col = mix(col, rock, smoothstep(0.30, 0.45, slope));
	col = mix(sand, col, smoothstep(-0.4, 0.12, wpos.y));
	ALBEDO = col;
	ROUGHNESS = 0.95;
	SPECULAR = 0.15;
}
"""

static var _noise: FastNoiseLite


static func _ensure_noise() -> void:
	if _noise != null:
		return
	_noise = FastNoiseLite.new()
	_noise.seed = 173
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.frequency = 0.013
	_noise.fractal_octaves = 4
	_noise.fractal_lacunarity = 2.1


## Altura canônica do mundo em (x, z) — usada por tudo que spawna.
static func height_at(x: float, z: float) -> float:
	_ensure_noise()
	var h := _noise.get_noise_2d(x, z) * HEIGHT_SCALE
	h += _noise.get_noise_2d(x * 3.7 + 100.0, z * 3.7) * 0.9
	for zone: Array in FLAT_ZONES:
		var d := Vector2(x - zone[0], z - zone[1]).length()
		var keep := clampf((d - zone[2]) / 10.0, 0.0, 1.0)
		h *= keep * keep * (3.0 - 2.0 * keep)  # smoothstep
	# Costa sul: o continente mergulha no mar.
	h -= maxf(0.0, (z - 72.0) / 26.0) * 4.5
	return h


func _ready() -> void:
	var mesh := _build_mesh()
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = mesh
	var material := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = TERRAIN_SHADER
	material.shader = shader
	var noise_texture := NoiseTexture2D.new()
	var tex_noise := FastNoiseLite.new()
	tex_noise.seed = 7
	tex_noise.frequency = 0.02
	noise_texture.noise = tex_noise
	noise_texture.width = 256
	noise_texture.height = 256
	material.set_shader_parameter("noise_tex", noise_texture)
	mesh_instance.material_override = material
	add_child(mesh_instance)
	var shape := CollisionShape3D.new()
	shape.shape = mesh.create_trimesh_shape()
	add_child(shape)


func _build_mesh() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := SIZE * 0.5
	var count := int(SIZE / STEP)
	for iz in range(count):
		for ix in range(count):
			var x0 := -half + ix * STEP
			var z0 := -half + iz * STEP
			var x1 := x0 + STEP
			var z1 := z0 + STEP
			var p00 := Vector3(x0, height_at(x0, z0), z0)
			var p10 := Vector3(x1, height_at(x1, z0), z0)
			var p01 := Vector3(x0, height_at(x0, z1), z1)
			var p11 := Vector3(x1, height_at(x1, z1), z1)
			surface.add_vertex(p00)
			surface.add_vertex(p10)
			surface.add_vertex(p11)
			surface.add_vertex(p00)
			surface.add_vertex(p11)
			surface.add_vertex(p01)
	surface.generate_normals()
	return surface.commit()
