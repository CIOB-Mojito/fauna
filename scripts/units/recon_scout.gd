class_name ReconScout
extends Unit

const STATS_PATH := "res://resources/units/scout_stats.tres"

const HULL_COLOR := Color(0.76, 0.6, 0.16)
const HULL_WORN_COLOR := Color(0.56, 0.44, 0.13)
const TRIM_COLOR := Color(0.11, 0.11, 0.12)
const METAL_COLOR := Color(0.43, 0.45, 0.48)
const ACCENT_COLOR := Color(0.16, 0.38, 0.85)
const RUBBER_COLOR := Color(0.07, 0.07, 0.08)
const HEADLIGHT_COLOR := Color(1.0, 0.94, 0.75)
const LAMP_COLOR := Color(1.0, 0.62, 0.14)

const COLLIDER_SIZE := Vector3(1.9, 1.25, 2.9)
const COLLIDER_HEIGHT := 0.62
const WHEEL_RADIUS := 0.52
const WHEEL_WIDTH := 0.34
const WHEEL_OFFSET_X := 0.94
const WHEEL_OFFSET_Z := 1.05

@export var stats: UnitStats

var _wheels: Array[MeshInstance3D] = []


func get_stats() -> UnitStats:
	if stats != null:
		return stats
	var loaded := load(STATS_PATH)
	if loaded is UnitStats:
		stats = loaded
		return stats
	push_warning("ReconScout: no se pudo cargar %s, usando stats por defecto" % STATS_PATH)
	stats = UnitStats.new()
	return stats


func is_amphibious() -> bool:
	return get_stats().amphibious


func get_move_speed() -> float:
	return get_stats().move_speed


func get_max_health() -> float:
	return get_stats().max_health


func get_vision_radius() -> float:
	return get_stats().vision_radius


func get_display_name() -> String:
	return get_stats().display_name


func get_role_text() -> String:
	return get_stats().role_text


func _build_collider() -> void:
	var collider := CollisionShape3D.new()
	collider.name = "BodyCollider"
	collider.position = Vector3(0.0, COLLIDER_HEIGHT, 0.0)
	var shape := BoxShape3D.new()
	shape.size = COLLIDER_SIZE
	collider.shape = shape
	add_child(collider)


func _build_model() -> void:
	var model := Node3D.new()
	model.name = "Model"
	add_child(model)

	_build_chassis(model)
	_build_hull(model)
	_build_turret(model)
	_build_details(model)


func _build_chassis(model: Node3D) -> void:
	MeshFactory.add_box(model, "Chassis", Vector3(0.0, 0.62, 0.0), Vector3(1.55, 0.42, 2.55), TRIM_COLOR)
	MeshFactory.add_box(model, "SkidFront", Vector3(0.0, 0.58, -1.32), Vector3(1.32, 0.28, 0.28), TRIM_COLOR)
	MeshFactory.add_box(model, "FenderWest", Vector3(-1.0, 0.86, 0.0), Vector3(0.28, 0.12, 2.5), TRIM_COLOR)
	MeshFactory.add_box(model, "FenderEast", Vector3(1.0, 0.86, 0.0), Vector3(0.28, 0.12, 2.5), TRIM_COLOR)


func _build_hull(model: Node3D) -> void:
	MeshFactory.add_box(model, "Hull", Vector3(0.0, 0.94, 0.0), Vector3(1.44, 0.4, 2.34), HULL_COLOR)
	var glacis := MeshFactory.add_box(model, "Glacis", Vector3(0.0, 1.02, -1.0), Vector3(1.3, 0.26, 0.78), HULL_COLOR)
	glacis.rotation_degrees = Vector3(-18.0, 0.0, 0.0)
	MeshFactory.add_box(model, "HullWearWest", Vector3(-0.72, 1.06, 0.35), Vector3(0.03, 0.2, 1.0), HULL_WORN_COLOR)
	MeshFactory.add_box(model, "HullWearEast", Vector3(0.72, 1.06, -0.25), Vector3(0.03, 0.2, 0.9), HULL_WORN_COLOR)
	MeshFactory.add_box(model, "RoofWear", Vector3(0.15, 1.15, 0.7), Vector3(0.9, 0.04, 0.6), HULL_WORN_COLOR)
	MeshFactory.add_box(model, "RearPlate", Vector3(0.0, 1.0, 1.22), Vector3(1.3, 0.3, 0.16), HULL_WORN_COLOR)


func _build_turret(model: Node3D) -> void:
	MeshFactory.add_cylinder(model, "TurretRing", Vector3(0.0, 1.16, 0.12), 0.36, 0.08, TRIM_COLOR)
	MeshFactory.add_cylinder(model, "TurretBody", Vector3(0.0, 1.32, 0.12), 0.33, 0.26, HULL_COLOR)
	MeshFactory.add_box(model, "TurretBustle", Vector3(0.0, 1.32, 0.5), Vector3(0.42, 0.22, 0.3), HULL_WORN_COLOR)
	MeshFactory.add_cylinder(model, "Hatch", Vector3(0.0, 1.48, 0.12), 0.16, 0.06, TRIM_COLOR)
	MeshFactory.add_box(model, "Periscope", Vector3(0.16, 1.5, 0.04), Vector3(0.05, 0.12, 0.05), METAL_COLOR)
	var cannon := MeshFactory.add_cylinder(model, "Cannon", Vector3(0.0, 1.32, -0.5), 0.06, 0.86, METAL_COLOR)
	cannon.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	var muzzle := MeshFactory.add_cylinder(model, "Muzzle", Vector3(0.0, 1.32, -0.95), 0.085, 0.14, TRIM_COLOR)
	muzzle.rotation_degrees = Vector3(90.0, 0.0, 0.0)


func _build_details(model: Node3D) -> void:
	MeshFactory.add_box(model, "AccentWest", Vector3(-0.83, 1.02, 0.95), Vector3(0.22, 0.22, 0.22), ACCENT_COLOR)
	MeshFactory.add_box(model, "AccentEast", Vector3(0.83, 1.02, 0.95), Vector3(0.22, 0.22, 0.22), ACCENT_COLOR)
	MeshFactory.add_box(model, "AccentHood", Vector3(0.44, 1.16, -0.62), Vector3(0.18, 0.16, 0.2), ACCENT_COLOR)
	MeshFactory.add_box(model, "AccentRear", Vector3(-0.5, 1.14, 1.18), Vector3(0.2, 0.18, 0.14), ACCENT_COLOR)
	MeshFactory.add_box(model, "HeadlightWest", Vector3(-0.48, 0.98, -1.14), Vector3(0.2, 0.13, 0.05), HEADLIGHT_COLOR, false, 1.0)
	MeshFactory.add_box(model, "HeadlightEast", Vector3(0.48, 0.98, -1.14), Vector3(0.2, 0.13, 0.05), HEADLIGHT_COLOR, false, 1.0)
	MeshFactory.add_box(model, "MarkerLight", Vector3(0.0, 1.09, 1.3), Vector3(0.12, 0.07, 0.04), LAMP_COLOR, false, 1.2)
	MeshFactory.add_box(model, "Antenna", Vector3(-0.58, 1.4, 1.0), Vector3(0.03, 0.7, 0.03), TRIM_COLOR)
	MeshFactory.add_mesh(model, "AntennaTip", Vector3(-0.58, 1.77, 1.0), MeshFactory.sphere_mesh(0.045, METAL_COLOR))


func _build_running_gear() -> void:
	var model := get_node("Model") as Node3D
	var offsets := [
		Vector3(WHEEL_OFFSET_X, WHEEL_RADIUS, -WHEEL_OFFSET_Z),
		Vector3(-WHEEL_OFFSET_X, WHEEL_RADIUS, -WHEEL_OFFSET_Z),
		Vector3(WHEEL_OFFSET_X, WHEEL_RADIUS, WHEEL_OFFSET_Z),
		Vector3(-WHEEL_OFFSET_X, WHEEL_RADIUS, WHEEL_OFFSET_Z),
	]
	for index in offsets.size():
		var wheel_position: Vector3 = offsets[index]
		var wheel := MeshFactory.add_cylinder(
			model,
			"Wheel%d" % (index + 1),
			wheel_position,
			WHEEL_RADIUS,
			WHEEL_WIDTH,
			RUBBER_COLOR
		)
		wheel.rotation_degrees = Vector3(0.0, 0.0, 90.0)
		MeshFactory.add_cylinder(
			model,
			"Hub%d" % (index + 1),
			wheel_position,
			WHEEL_RADIUS * 0.45,
			WHEEL_WIDTH + 0.04,
			METAL_COLOR
		).rotation_degrees = Vector3(0.0, 0.0, 90.0)
		_wheels.append(wheel)


func _animate_running_gear(delta: float) -> void:
	var forward_speed := velocity.dot(-global_transform.basis.z)
	if is_zero_approx(forward_speed):
		return
	var spin := forward_speed / WHEEL_RADIUS * delta
	for wheel in _wheels:
		wheel.rotate_object_local(Vector3.UP, spin)