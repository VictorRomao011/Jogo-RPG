class_name Water
extends MeshInstance3D
## Mar com ondas animadas no shader: vértices oscilam, a cor afunda com
## o ângulo (fresnel simples) e o brilho do sol reflete na superfície.

const WATER_SHADER := """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;
void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.y += sin(wp.x * 0.35 + TIME * 1.1) * 0.12
		+ cos(wp.z * 0.28 + TIME * 0.8) * 0.10;
}
void fragment() {
	vec3 deep = vec3(0.05, 0.17, 0.28);
	vec3 shallow = vec3(0.12, 0.34, 0.42);
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.5);
	ALBEDO = mix(deep, shallow, fresnel);
	ROUGHNESS = 0.08;
	METALLIC = 0.1;
	SPECULAR = 0.6;
	ALPHA = 0.92;
}
"""


func _ready() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(560.0, 560.0)
	plane.subdivide_width = 48
	plane.subdivide_depth = 48
	mesh = plane
	var material := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = WATER_SHADER
	material.shader = shader
	material_override = material
	position = Vector3(0.0, Terrain.WATER_LEVEL, 120.0)
