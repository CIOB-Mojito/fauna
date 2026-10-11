class_name Oso413
extends Unit

const STATS_PATH := "res://resources/units/oso_413_stats.tres"

const HULL_COLOR := Color(0.25, 0.3, 0.38)
const HULL_WORN_COLOR := Color(0.16, 0.2, 0.26)
const RUST_COLOR := Color(0.4, 0.24, 0.14)
const TRIM_COLOR := Color(0.09, 0.09, 0.11)
const METAL_COLOR := Color(0.45, 0.47, 0.52)
const RUBBER_COLOR := Color(0.07, 0.07, 0.08)
const ACCENT_RED := Color(0.8, 0.13, 0.11)
const HEADLIGHT_COLOR := Color(1.0, 0.94, 0.75)
const MARK_COLOR := Color(0.86, 0.86, 0.88)

const COLLIDER_SIZE := Vector3(2.0, 1.3, 3.4)
const COLLIDER_HEIGHT := 0.65
const WHEEL_RADIUS := 0.54
const WHEEL_WIDTH := 0.38
const WHEEL_OFFSET_X := 1.0
const WHEEL_OFFSET_Z := 1.32

@export var stats: UnitStats

var _wheels: Array[MeshInstance3D] = []


func get_stats() -> UnitStats:
	if stats != null:
		return stats
	var loaded := load(STATS_PATH)
	if loaded is UnitStats:
		stats = loaded
		return stats
	push_warning("Oso413: no se pudo cargar %s, usando stats por defecto" % STATS_PATH)
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
	_build_marking(model)


func _build_chassis(model: Node3D) -> void:
	MeshFactory.add_box(model, "Chassis", Vector3(0.0, 0.5, 0.0), Vector3(1.7, 0.32, 3.1), TRIM_COLOR)
	MeshFactory.add_box(model, "HullLower", Vector3(0.0, 0.82, 0.0), Vector3(1.9, 0.52, 3.2), HULL_COLOR)
	MeshFactory.add_box(model, "BellyPan", Vector3(0.0, 0.56, 0.0), Vector3(1.5, 0.12, 2.9), TRIM_COLOR)


func _build_hull(model: Node3D) -> void:
	MeshFactory.add_box(model, "HullUpper", Vector3(0.0, 1.18, 0.05), Vector3(1.72, 0.4, 2.5), HULL_COLOR)
	MeshFactory.add_box(model, "Roof", Vector3(0.0, 1.4, 0.1), Vector3(1.6, 0.1, 2.2), HULL_WORN_COLOR)
	var glacis := MeshFactory.add_box(model, "Glacis", Vector3(0.0, 1.05, -1.35), Vector3(1.66, 0.55, 0.85), HULL_COLOR)
	glacis.rotation_degrees = Vector3(-38.0, 0.0, 0.0)
	var rear_slope := MeshFactory.add_box(model, "RearSlope", Vector3(0.0, 0.98, 1.5), Vector3(1.7, 0.7, 0.6), HULL_COLOR)
	rear_slope.rotation_degrees = Vector3(26.0, 0.0, 0.0)
	var side_west := MeshFactory.add_box(model, "SideSlopeWest", Vector3(-0.86, 1.16, 0.05), Vector3(0.12, 0.46, 2.4), HULL_COLOR)
	side_west.rotation_degrees = Vector3(0.0, 0.0, -12.0)
	var side_east := MeshFactory.add_box(model, "SideSlopeEast", Vector3(0.86, 1.16, 0.05), Vector3(0.12, 0.46, 2.4), HULL_COLOR)
	side_east.rotation_degrees = Vector3(0.0, 0.0, 12.0)
	MeshFactory.add_box(model, "WearWest", Vector3(-0.92, 0.82, 0.4), Vector3(0.04, 0.3, 1.2), HULL_WORN_COLOR)
	MeshFactory.add_box(model, "WearEast", Vector3(0.92, 0.9, -0.4), Vector3(0.04, 0.28, 1.0), HULL_WORN_COLOR)
	MeshFactory.add_box(model, "DeckWear", Vector3(0.2, 1.45, 1.0), Vector3(0.9, 0.03, 0.5), HULL_WORN_COLOR)
	MeshFactory.add_box(model, "RustPatch", Vector3(-0.4, 0.75, 1.55), Vector3(0.3, 0.16, 0.22), RUST_COLOR)


func _build_front_guard(model: Node3D) -> void:
	var guard := Node3D.new()
	guard.name = "FrontGuard"
	model.add_child(guard)
	MeshFactory.add_cylinder(guard, "BumperBarTop", Vector3(0.0, 1.05, -1.82), 0.06, 1.9, METAL_COLOR).rotation_degrees = Vector3(0.0, 0.0, 90.0)
	MeshFactory.add_cylinder(guard, "BumperBarMid", Vector3(0.0, 0.72, -1.84), 0.06, 1.9, METAL_COLOR).rotation_degrees = Vector3(0.0, 0.0, 90.0)
	for side in [-1.0, 1.0]:
		var side_name := "West" if side < 0.0 else "East"
		MeshFactory.add_cylinder(guard, "BumperPost%s" % side_name, Vector3(0.9 * side, 0.9, -1.82), 0.06, 0.5, METAL_COLOR)
		MeshFactory.add_cylinder(guard, "BumperCorner%s" % side_name, Vector3(0.9 * side, 0.6, -1.74), 0.055, 0.5, METAL_COLOR).rotation_degrees = Vector3(25.0, 0.0, 0.0)


func _build_turret(model: Node3D) -> void:
	var turret := Node3D.new()
	turret.name = "Turret"
	turret.position = Vector3(0.0, 1.44, 0.1)
	model.add_child(turret)
	MeshFactory.add_cylinder(turret, "TurretRing", Vector3(0.0, 0.0, 0.0), 0.42, 0.08, TRIM_COLOR)
	MeshFactory.add_cylinder(turret, "TurretBase", Vector3(0.0, 0.12, 0.0), 0.36, 0.2, HULL_COLOR)
	MeshFactory.add_cylinder(turret, "Cupola", Vector3(0.0, 0.28, 0.0), 0.22, 0.14, HULL_WORN_COLOR)
	MeshFactory.add_cylinder(turret, "Hatch", Vector3(0.0, 0.37, 0.0), 0.16, 0.05, TRIM_COLOR)
	MeshFactory.add_box(turret, "PeriscopeWest", Vector3(-0.16, 0.3, -0.1), Vector3(0.06, 0.08, 0.06), METAL_COLOR)
	MeshFactory.add_box(turret, "PeriscopeEast", Vector3(0.16, 0.3, -0.1), Vector3(0.06, 0.08, 0.06), METAL_COLOR)
	MeshFactory.add_box(turret, "TurretBustle", Vector3(0.0, 0.12, 0.34), Vector3(0.4, 0.18, 0.24), HULL_COLOR)


func _build_details(model: Node3D) -> void:
	MeshFactory.add_box(model, "FenderWest", Vector3(-1.02, 1.14, 0.0), Vector3(0.44, 0.12, 3.0), TRIM_COLOR)
	MeshFactory.add_box(model, "FenderEast", Vector3(1.02, 1.14, 0.0), Vector3(0.44, 0.12, 3.0), TRIM_COLOR)
	MeshFactory.add_box(model, "HeadlightWest", Vector3(-0.62, 0.95, -1.72), Vector3(0.26, 0.16, 0.06), HEADLIGHT_COLOR, false, 1.0)
	MeshFactory.add_box(model, "HeadlightEast", Vector3(0.62, 0.95, -1.72), Vector3(0.26, 0.16, 0.06), HEADLIGHT_COLOR, false, 1.0)
	MeshFactory.add_box(model, "TaillightWest", Vector3(-0.6, 0.98, 1.68), Vector3(0.2, 0.1, 0.05), ACCENT_RED)
	MeshFactory.add_box(model, "TaillightEast", Vector3(0.6, 0.98, 1.68), Vector3(0.2, 0.1, 0.05), ACCENT_RED)
	MeshFactory.add_cylinder(model, "RedBeacon", Vector3(0.0, 1.47, 0.95), 0.2, 0.06, ACCENT_RED)
	MeshFactory.add_cylinder(model, "Exhaust", Vector3(-0.98, 1.0, 0.6), 0.05, 0.8, METAL_COLOR).rotation_degrees = Vector3(90.0, 0.0, 0.0)
	MeshFactory.add_box(model, "TowHookWest", Vector3(-0.72, 0.62, -1.78), Vector3(0.1, 0.1, 0.16), METAL_COLOR)
	MeshFactory.add_box(model, "TowHookEast", Vector3(0.72, 0.62, -1.78), Vector3(0.1, 0.1, 0.16), METAL_COLOR)


func _build_marking(model: Node3D) -> void:
	var marking := Node3D.new()
	marking.name = "Marking413"
	marking.position = Vector3(-0.97, 1.02, 0.78)
	marking.rotation_degrees = Vector3(0.0, -90.0, 0.0)
	model.add_child(marking)
	_build_digit(marking, "Digit4", -0.19, [1, 6, 2, 3])
	_build_digit(marking, "Digit1", 0.0, [2, 3])
	_build_digit(marking, "Digit3", 0.19, [0, 2, 3, 4, 6])


func _build_digit(parent: Node3D, digit_name: String, offset_x: float, segments: Array) -> void:
	var digit := Node3D.new()
	digit.name = digit_name
	digit.position = Vector3(offset_x, 0.0, 0.0)
	parent.add_child(digit)
	var half_width := 0.075
	var half_height := 0.12
	var thickness := 0.028
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
			WHEEL_RADIUS * 0.44,
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
