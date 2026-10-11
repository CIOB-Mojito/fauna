class_name MeshFactory
extends RefCounted


static func material(color: Color, unshaded := false, emission_energy := 0.0, roughness := 0.85) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	if unshaded:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if emission_energy > 0.0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = emission_energy
	return mat


static func box_mesh(size: Vector3, color: Color, unshaded := false, emission_energy := 0.0) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material(color, unshaded, emission_energy)
	return mesh


static func cylinder_mesh(radius: float, height: float, color: Color, radial_segments := 18) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = radial_segments
	mesh.material = material(color)
	return mesh


static func sphere_mesh(radius: float, color: Color) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	mesh.material = material(color)
	return mesh


static func add_mesh(parent: Node3D, node_name: String, mesh_position: Vector3, mesh: Mesh) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	mesh_instance.position = mesh_position
	mesh_instance.mesh = mesh
	parent.add_child(mesh_instance)
	return mesh_instance


static func add_box(
	parent: Node3D,
	node_name: String,
	box_position: Vector3,
	size: Vector3,
	color: Color,
	unshaded := false,
	emission_energy := 0.0
) -> MeshInstance3D:
	return add_mesh(parent, node_name, box_position, box_mesh(size, color, unshaded, emission_energy))


static func add_cylinder(
	parent: Node3D,
	node_name: String,
	cylinder_position: Vector3,
	radius: float,
	height: float,
	color: Color
) -> MeshInstance3D:
	return add_mesh(parent, node_name, cylinder_position, cylinder_mesh(radius, height, color))