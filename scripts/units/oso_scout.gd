class_name OsoScout
extends Unit

const STATS_PATH := "res://resources/units/oso_scout_stats.tres"

const HULL_COLOR := Color(0.25, 0.3, 0.38)
const HULL_WORN_COLOR := Color(0.16, 0.2, 0.26)
const RUST_COLOR := Color(0.4, 0.24, 0.14)
const TRIM_COLOR := Color(0.09, 0.09, 0.11)
const METAL_COLOR := Color(0.45, 0.47, 0.52)
const RUBBER_COLOR := Color(0.07, 0.07, 0.08)
const HUB_COLOR := Color(0.8, 0.45, 0.15)
const HEADLIGHT_COLOR := Color(1.0, 0.94, 0.75)
const MARK_COLOR := Color(0.9, 0.9, 0.92)

const COLLIDER_SIZE := Vector3(2.1, 1.2, 3.6)
const COLLIDER_HEIGHT := 0.6
const WHEEL_RADIUS := 0.5
const WHEEL_WIDTH := 0.34
const WHEEL_OFFSET_X := 1.05
const WHEEL_OFFSET_Z := 1.5

@export var stats: UnitStats

var _wheels: Array[MeshInstance3D] = []


func get_stats() -> UnitStats:
	if stats != null:
		return stats
	var loaded := load(STATS_PATH)
	if loaded is UnitStats:
		stats = loaded
		return stats
	push_warning("OsoScout: no se pudo cargar %s, usando stats por defecto" % STATS_PATH)
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
	_build_front_guard(model)
	_build_turret(model)
	_build_details(model)


func _build_chassis(model: Node3D) -> void:
	MeshFactory.add_box(model, "Chassis", Vector3(0.0, 0.46, 0.0), Vector3(1.9, 0.3, 3.4), TRIM_COLOR)
	MeshFactory.add_box(model, "HullLower", Vector3(0.0, 0.78, 0.0), Vector3(2.0, 0.5, 3.5), HULL_COLOR)
	MeshFactory.add_box(model, "BellyPan", Vector3(0.0, 0.52, 0.0), Vector3(1.7, 0.12, 3.1), TRIM_COLOR)


func _build_hull(model: Node3D) -> void:
	MeshFactory.add_box(model, "HullUpper", Vector3(0.0, 1.14, 0.05), Vector3(1.8, 0.42, 2.7), HULL_COLOR)
	MeshFactory.add_box(model, "Roof", Vector3(0.0, 1.38, 0.1), Vector3(1.68, 0.1, 2.4), HULL_WORN_COLOR)
	var glacis := MeshFactory.add_box(model, "Glacis", Vector3(0.0, 1.0, -1.5), Vector3(1.9, 0.6, 0.9), HULL_COLOR)
	glacis.rotation_degrees = Vector3(-35.0, 0.0, 0.0)
	var rear_slope := MeshFactory.add_box(model, "RearSlope", Vector3(0.0, 0.95, 1.62), Vector3(2.0, 0.72, 0.6), HULL_COLOR)
	rear_slope.rotation_degrees = Vector3(28.0, 0.0, 0.0)
	var side_west := MeshFactory.add_box(model, "SideSlopeWest", Vector3(-0.9, 1.12, 0.05), Vector3(0.12, 0.48, 2.6), HULL_COLOR)
	side_west.rotation_degrees = Vector3(0.0, 0.0, -12.0)
	var side_east := MeshFactory.add_box(model, "SideSlopeEast", Vector3(0.9, 1.12, 0.05), Vector3(0.12, 0.48, 2.6), HULL_COLOR)
	side_east.rotation_degrees = Vector3(0.0, 0.0, 12.0)
	MeshFactory.add_box(model, "WearWest", Vector3(-0.97, 0.8, 0.5), Vector3(0.04, 0.3, 1.3), HULL_WORN_COLOR)
	MeshFactory.add_box(model, "WearEast", Vector3(0.97, 0.88, -0.5), Vector3(0.04, 0.28, 1.1), HULL_WORN_COLOR)
	MeshFactory.add_box(model, "DeckWear", Vector3(0.25, 1.43, 0.9), Vector3(0.9, 0.03, 0.5), HULL_WORN_COLOR)
	MeshFactory.add_box(model, "RustPatch", Vector3(-0.5, 0.7, 1.72), Vector3(0.32, 0.16, 0.22), RUST_COLOR)


func _build_front_guard(model: Node3D) -> void:
	var guard := Node3D.new()
	guard.name = "FrontGuard"
	model.add_child(guard)
	MeshFactory.add_box(guard, "Grille", Vector3(0.0, 0.95, -1.92), Vector3(1.3, 0.28, 0.12), TRIM_COLOR)
	MeshFactory.add_cylinder(guard, "BumperBarTop", Vector3(0.0, 1.05, -2.0), 0.06, 2.1, METAL_COLOR).rotation_degrees = Vector3(0.0, 0.0, 90.0)
	MeshFactory.add_cylinder(guard, "BumperBarMid", Vector3(0.0, 0.7, -2.02), 0.06, 2.1, METAL_COLOR).rotation_degrees = Vector3(0.0, 0.0, 90.0)
	for side in [-1.0, 1.0]:
		var side_name := "West" if side < 0.0 else "East"
		MeshFactory.add_cylinder(guard, "BumperPost%s" % side_name, Vector3(1.0 * side, 0.9, -2.0), 0.06, 0.5, METAL_COLOR)
		MeshFactory.add_cylinder(guard, "BumperCorner%s" % side_name, Vector3(1.0 * side, 0.6, -1.92), 0.055, 0.5, METAL_COLOR).rotation_degrees = Vector3(25.0, 0.0, 0.0)


func _build_turret(model: Node3D) -> void:
	var turret := Node3D.new()
	turret.name = "Turret"
	turret.position = Vector3(0.0, 1.4, 0.0)
	model.add_child(turret)
	MeshFactory.add_cylinder(turret, "TurretRing", Vector3(0.0, 0.0, 0.0), 0.5, 0.08, TRIM_COLOR)
	MeshFactory.add_cylinder(turret, "TurretBase", Vector3(0.0, 0.13, 0.0), 0.64, 0.24, HULL_COLOR)
	var dome := MeshFactory.add_mesh(turret, "TurretDome", Vector3(0.0, 0.24, 0.0), MeshFactory.sphere_mesh(0.62, HULL_COLOR))
	dome.scale = Vector3(1.0, 0.42, 1.0)
	MeshFactory.add_box(turret, "TurretBustle", Vector3(0.0, 0.13, 0.5), Vector3(0.5, 0.2, 0.32), HULL_WORN_COLOR)
	var cannon := MeshFactory.add_cylinder(turret, "Cannon", Vector3(0.0, 0.14, -0.62), 0.09, 1.05, METAL_COLOR)
	cannon.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	var muzzle := MeshFactory.add_cylinder(turret, "Muzzle", Vector3(0.0, 0.14, -1.18), 0.12, 0.18, TRIM_COLOR)
	muzzle.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	MeshFactory.add_box(turret, "TurretSideBox", Vector3(0.5, 0.14, 0.02), Vector3(0.24, 0.18, 0.34), METAL_COLOR)
	MeshFactory.add_cylinder(turret, "TurretSensor", Vector3(0.42, 0.28, -0.18), 0.05, 0.16, TRIM_COLOR)
	MeshFactory.add_box(turret, "PeriscopeWest", Vector3(-0.2, 0.3, -0.24), Vector3(0.07, 0.08, 0.07), METAL_COLOR)
	MeshFactory.add_box(turret, "PeriscopeEast", Vector3(0.12, 0.3, -0.24), Vector3(0.07, 0.08, 0.07), METAL_COLOR)
	_build_marking(turret)


func _build_marking(turret: Node3D) -> void:
	var marking := Node3D.new()
	marking.name = "Marking78"
	marking.position = Vector3(-0.63, 0.12, 0.0)
	marking.rotation_degrees = Vector3(0.0, -90.0, 0.0)
	turret.add_child(marking)
	_build_digit(marking, "Digit7", -0.11, [0, 2, 3])
	_build_digit(marking, "Digit8", 0.11, [0, 1, 2, 3, 4, 5, 6])


func _build_digit(parent: Node3D, digit_name: String, offset_x: float, segments: Array) -> void:
	var digit := Node3D.new()
	digit.name = digit_name
	digit.position = Vector3(offset_x, 0.0, 0.0)
	parent.add_child(digit)
	var half_width := 0.05
	var half_height := 0.085
	var thickness := 0.022
	var depth := 0.02
	var layout := {
		0: [Vector3(0.0, half_height, 0.0), Vector3(half_width * 2.0, thickness, depth)],
		1: [Vector3(-half_width, half_height * 0.5, 0.0), Vector3(thickness, half_height, depth)],
		2: [Vector3(half_width, half_height * 0.5, 0.0), Vector3(thickness, half_height, depth)],
		3: [Vector3(half_width, -half_height * 0.5, 0.0), Vector3(thickness, half_height, depth)],
		4: [Vector3(0.0, -half_height, 0.0), Vector3(half_width * 2.0, thickness, depth)],
		5: [Vector3(-half_width, -half_height * 0.5, 0.0), Vector3(thickness, half_height, depth)],
		6: [Vector3(0.0, 0.0, 0.0), Vector3(half_width * 2.0, thickness, depth)],
	}
	for segment in segments:
		var entry: Array = layout[segment]
		var segment_position: Vector3 = entry[0]
		var segment_size: Vector3 = entry[1]
		MeshFactory.add_box(digit, "Segment%d" % segment, segment_position, segment_size, MARK_COLOR)


func _build_details(model: Node3D) -> void:
	MeshFactory.add_box(model, "FenderWest", Vector3(-1.12, 1.05, 0.0), Vector3(0.5, 0.12, 3.5), TRIM_COLOR)
	MeshFactory.add_box(model, "FenderEast", Vector3(1.12, 1.05, 0.0), Vector3(0.5, 0.12, 3.5), TRIM_COLOR)
	MeshFactory.add_box(model, "HeadlightWest", Vector3(-0.66, 0.95, -1.92), Vector3(0.26, 0.16, 0.06), HEADLIGHT_COLOR, false, 1.0)
	MeshFactory.add_box(model, "HeadlightEast", Vector3(0.66, 0.95, -1.92), Vector3(0.26, 0.16, 0.06), HEADLIGHT_COLOR, false, 1.0)
	MeshFactory.add_box(model, "TaillightWest", Vector3(-0.64, 1.0, 1.86), Vector3(0.2, 0.1, 0.05), HUB_COLOR)
	MeshFactory.add_box(model, "TaillightEast", Vector3(0.64, 1.0, 1.86), Vector3(0.2, 0.1, 0.05), HUB_COLOR)
	MeshFactory.add_cylinder(model, "Exhaust", Vector3(-1.05, 1.0, 0.7), 0.05, 0.8, METAL_COLOR).rotation_degrees = Vector3(90.0, 0.0, 0.0)
	MeshFactory.add_box(model, "TowHookWest", Vector3(-0.78, 0.6, -1.98), Vector3(0.1, 0.1, 0.16), METAL_COLOR)
	MeshFactory.add_box(model, "TowHookEast", Vector3(0.78, 0.6, -1.98), Vector3(0.1, 0.1, 0.16), METAL_COLOR)


func _build_running_gear() -> void:
	var model := get_node("Model") as Node3D
	var offsets := [
		Vector3(WHEEL_OFFSET_X, WHEEL_RADIUS, -WHEEL_OFFSET_Z),
		Vector3(-WHEEL_OFFSET_X, WHEEL_RADIUS, -WHEEL_OFFSET_Z),
		Vector3(WHEEL_OFFSET_X, WHEEL_RADIUS, 0.0),
		Vector3(-WHEEL_OFFSET_X, WHEEL_RADIUS, 0.0),
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
			WHEEL_RADIUS * 0.44,
			WHEEL_WIDTH + 0.04,
			HUB_COLOR
		).rotation_degrees = Vector3(0.0, 0.0, 90.0)
		_wheels.append(wheel)


func _animate_running_gear(delta: float) -> void:
	var forward_speed := velocity.dot(-global_transform.basis.z)
	if is_zero_approx(forward_speed):
		return
	var spin := forward_speed / WHEEL_RADIUS * delta
	for wheel in _wheels:
		wheel.rotate_object_local(Vector3.UP, spin)
