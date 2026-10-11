class_name CommandVehicle
extends Unit

const STATS_PATH := "res://resources/units/castor_cmd_stats.tres"

const HULL_COLOR := Color(0.79, 0.63, 0.16)
const HULL_WORN_COLOR := Color(0.6, 0.47, 0.13)
const RUST_COLOR := Color(0.45, 0.26, 0.12)
const TRIM_COLOR := Color(0.1, 0.1, 0.11)
const METAL_COLOR := Color(0.42, 0.44, 0.47)
const RUBBER_COLOR := Color(0.07, 0.07, 0.08)
const ACCENT_BLUE := Color(0.14, 0.36, 0.8)
const LAMP_COLOR := Color(1.0, 0.6, 0.12)
const HEADLIGHT_COLOR := Color(1.0, 0.94, 0.75)
const TAILLIGHT_COLOR := Color(0.85, 0.1, 0.08)

const COLLIDER_SIZE := Vector3(1.7, 1.46, 2.7)
const COLLIDER_HEIGHT := 0.75
const WHEEL_RADIUS := 0.44
const WHEEL_WIDTH := 0.34
const WHEEL_OFFSET_X := 0.84
const WHEEL_OFFSET_Z := 1.02
const TREAD_BLOCKS := 10

@export var stats: UnitStats

var _wheels: Array[MeshInstance3D] = []


func get_stats() -> UnitStats:
	if stats != null:
		return stats
	var loaded := load(STATS_PATH)
	if loaded is UnitStats:
		stats = loaded
		return stats
	push_warning("CommandVehicle: no se pudo cargar %s, usando stats por defecto" % STATS_PATH)
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
	_build_roll_cage(model)
	_build_front_guard(model)
	_build_body_details(model)
	_build_antenna(model)


func _build_chassis(model: Node3D) -> void:
	MeshFactory.add_box(model, "SkidPlate", Vector3(0.0, 0.44, 0.0), Vector3(1.15, 0.12, 2.25), TRIM_COLOR)
	MeshFactory.add_box(model, "Tub", Vector3(0.0, 0.64, 0.02), Vector3(1.34, 0.34, 2.28), HULL_COLOR)
	MeshFactory.add_box(model, "SidePanelWest", Vector3(-0.68, 0.7, 0.0), Vector3(0.06, 0.42, 2.1), HULL_COLOR)
	MeshFactory.add_box(model, "SidePanelEast", Vector3(0.68, 0.7, 0.0), Vector3(0.06, 0.42, 2.1), HULL_COLOR)
	MeshFactory.add_box(model, "Nose", Vector3(0.0, 0.72, -1.18), Vector3(1.0, 0.3, 0.6), HULL_COLOR)
	MeshFactory.add_box(model, "RearDeck", Vector3(0.0, 0.86, 0.92), Vector3(1.2, 0.16, 0.6), HULL_COLOR)
	MeshFactory.add_box(model, "EngineBlock", Vector3(0.0, 0.98, 0.72), Vector3(0.78, 0.42, 0.72), METAL_COLOR)
	MeshFactory.add_box(model, "ValveCover", Vector3(0.0, 1.22, 0.72), Vector3(0.6, 0.12, 0.5), HULL_WORN_COLOR)
	MeshFactory.add_box(model, "ExhaustHeaderWest", Vector3(-0.44, 0.98, 0.72), Vector3(0.08, 0.1, 0.6), METAL_COLOR)
	MeshFactory.add_box(model, "ExhaustHeaderEast", Vector3(0.44, 0.98, 0.72), Vector3(0.08, 0.1, 0.6), METAL_COLOR)
	MeshFactory.add_box(model, "SeatBaseWest", Vector3(-0.34, 0.86, -0.18), Vector3(0.4, 0.14, 0.42), TRIM_COLOR)
	MeshFactory.add_box(model, "SeatBackWest", Vector3(-0.34, 1.08, 0.02), Vector3(0.4, 0.4, 0.12), TRIM_COLOR)
	MeshFactory.add_box(model, "SeatBaseEast", Vector3(0.34, 0.86, -0.18), Vector3(0.4, 0.14, 0.42), TRIM_COLOR)
	MeshFactory.add_box(model, "SeatBackEast", Vector3(0.34, 1.08, 0.02), Vector3(0.4, 0.4, 0.12), TRIM_COLOR)
	MeshFactory.add_box(model, "Dash", Vector3(0.0, 0.94, -0.62), Vector3(1.16, 0.24, 0.14), TRIM_COLOR)
	MeshFactory.add_box(model, "SteeringColumn", Vector3(0.34, 0.94, -0.5), Vector3(0.06, 0.06, 0.3), METAL_COLOR)
	MeshFactory.add_cylinder(model, "SteeringWheel", Vector3(0.34, 1.02, -0.64), 0.13, 0.04, TRIM_COLOR).rotation_degrees = Vector3(90.0, 0.0, 0.0)
	MeshFactory.add_box(model, "WearHood", Vector3(0.0, 0.88, -1.18), Vector3(0.8, 0.03, 0.5), HULL_WORN_COLOR)
	MeshFactory.add_box(model, "WearWest", Vector3(-0.71, 0.66, 0.4), Vector3(0.03, 0.3, 0.9), HULL_WORN_COLOR)
	MeshFactory.add_box(model, "WearEast", Vector3(0.71, 0.72, -0.3), Vector3(0.03, 0.22, 0.7), HULL_WORN_COLOR)
	MeshFactory.add_box(model, "RustPatch", Vector3(0.52, 0.8, 0.95), Vector3(0.24, 0.14, 0.24), RUST_COLOR)


func _build_roll_cage(model: Node3D) -> void:
	var cage := Node3D.new()
	cage.name = "RollCage"
	model.add_child(cage)
	for side in [-1.0, 1.0]:
		var side_name := "West" if side < 0.0 else "East"
		MeshFactory.add_cylinder(cage, "CagePostFront%s" % side_name, Vector3(0.58 * side, 1.2, -0.62), 0.05, 0.95, HULL_COLOR)
		MeshFactory.add_cylinder(cage, "CagePostRear%s" % side_name, Vector3(0.58 * side, 1.2, 0.68), 0.05, 0.95, HULL_COLOR)
		MeshFactory.add_cylinder(cage, "CageRail%s" % side_name, Vector3(0.58 * side, 1.67, 0.03), 0.05, 1.4, HULL_COLOR).rotation_degrees = Vector3(90.0, 0.0, 0.0)
		MeshFactory.add_cylinder(cage, "CageBrace%s" % side_name, Vector3(0.58 * side, 1.25, 0.03), 0.045, 1.2, HULL_COLOR).rotation_degrees = Vector3(55.0, 0.0, 0.0)
	MeshFactory.add_cylinder(cage, "CageTopFront", Vector3(0.0, 1.67, -0.62), 0.05, 1.16, HULL_COLOR).rotation_degrees = Vector3(0.0, 0.0, 90.0)
	MeshFactory.add_cylinder(cage, "CageTopRear", Vector3(0.0, 1.67, 0.68), 0.05, 1.16, HULL_COLOR).rotation_degrees = Vector3(0.0, 0.0, 90.0)
	MeshFactory.add_cylinder(cage, "CageFrontBar", Vector3(0.0, 1.3, -0.62), 0.045, 1.16, HULL_COLOR).rotation_degrees = Vector3(0.0, 0.0, 90.0)
	MeshFactory.add_box(cage, "MarkerLight", Vector3(0.0, 1.74, -0.62), Vector3(0.5, 0.08, 0.1), LAMP_COLOR, false, 1.2)


func _build_front_guard(model: Node3D) -> void:
	var guard := Node3D.new()
	guard.name = "FrontGuard"
	model.add_child(guard)
	MeshFactory.add_cylinder(guard, "BumperBarTop", Vector3(0.0, 1.02, -1.5), 0.05, 1.3, TRIM_COLOR).rotation_degrees = Vector3(0.0, 0.0, 90.0)
	MeshFactory.add_cylinder(guard, "BumperBarMid", Vector3(0.0, 0.72, -1.52), 0.05, 1.3, TRIM_COLOR).rotation_degrees = Vector3(0.0, 0.0, 90.0)
	for side in [-1.0, 1.0]:
		var side_name := "West" if side < 0.0 else "East"
		MeshFactory.add_cylinder(guard, "BumperPost%s" % side_name, Vector3(0.62 * side, 0.87, -1.5), 0.05, 0.4, TRIM_COLOR)
		MeshFactory.add_cylinder(guard, "BumperCorner%s" % side_name, Vector3(0.62 * side, 0.5, -1.45), 0.045, 0.45, TRIM_COLOR).rotation_degrees = Vector3(20.0, 0.0, 0.0)
	for index in 4:
		var grille_x := -0.36 + float(index) * 0.24
		MeshFactory.add_cylinder(guard, "GrilleBar%d" % (index + 1), Vector3(grille_x, 0.8, -1.42), 0.03, 0.4, TRIM_COLOR)


func _build_body_details(model: Node3D) -> void:
	MeshFactory.add_cylinder(model, "SpareTire", Vector3(0.0, 1.0, 1.42), 0.38, 0.26, RUBBER_COLOR).rotation_degrees = Vector3(90.0, 0.0, 0.0)
	MeshFactory.add_cylinder(model, "SpareHub", Vector3(0.0, 1.0, 1.57), 0.16, 0.28, ACCENT_BLUE).rotation_degrees = Vector3(90.0, 0.0, 0.0)
	MeshFactory.add_box(model, "TaillightWest", Vector3(-0.5, 0.82, 1.2), Vector3(0.18, 0.1, 0.05), TAILLIGHT_COLOR, false, 1.0)
	MeshFactory.add_box(model, "TaillightEast", Vector3(0.5, 0.82, 1.2), Vector3(0.18, 0.1, 0.05), TAILLIGHT_COLOR, false, 1.0)
	MeshFactory.add_cylinder(model, "HeadlightWest", Vector3(-0.42, 0.82, -1.47), 0.13, 0.1, HEADLIGHT_COLOR).rotation_degrees = Vector3(90.0, 0.0, 0.0)
	MeshFactory.add_cylinder(model, "HeadlightEast", Vector3(0.42, 0.82, -1.47), 0.13, 0.1, HEADLIGHT_COLOR).rotation_degrees = Vector3(90.0, 0.0, 0.0)
	MeshFactory.add_box(model, "RadioBox", Vector3(0.0, 1.02, 0.32), Vector3(0.44, 0.2, 0.28), TRIM_COLOR)
	MeshFactory.add_box(model, "RadioLamp", Vector3(0.12, 1.14, 0.2), Vector3(0.1, 0.06, 0.04), ACCENT_BLUE, false, 1.2)
	MeshFactory.add_box(model, "JerryCan", Vector3(-0.5, 1.05, 0.75), Vector3(0.22, 0.36, 0.3), HULL_WORN_COLOR)
	MeshFactory.add_box(model, "JerryHandle", Vector3(-0.5, 1.25, 0.75), Vector3(0.24, 0.05, 0.08), TRIM_COLOR)
	MeshFactory.add_box(model, "AntennaBase", Vector3(0.6, 0.86, 1.0), Vector3(0.16, 0.08, 0.16), TRIM_COLOR)


func _build_antenna(model: Node3D) -> void:
	var antenna := Node3D.new()
	antenna.name = "Antenna"
	antenna.position = Vector3(0.6, 0.86, 1.0)
	model.add_child(antenna)
	MeshFactory.add_cylinder(antenna, "AntennaMount", Vector3(0.0, 0.06, 0.0), 0.06, 0.12, TRIM_COLOR)
	MeshFactory.add_cylinder(antenna, "AntennaMast", Vector3(0.0, 0.7, 0.0), 0.02, 1.25, TRIM_COLOR)
	MeshFactory.add_box(antenna, "AntennaFlag", Vector3(0.0, 1.05, 0.0), Vector3(0.14, 0.1, 0.01), ACCENT_BLUE)
	MeshFactory.add_mesh(antenna, "AntennaTip", Vector3(0.0, 1.35, 0.0), MeshFactory.sphere_mesh(0.05, ACCENT_BLUE))


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
			WHEEL_RADIUS * 0.42,
			WHEEL_WIDTH + 0.03,
			ACCENT_BLUE
		).rotation_degrees = Vector3(0.0, 0.0, 90.0)
		_build_tread(wheel)
		_wheels.append(wheel)


func _build_tread(wheel: MeshInstance3D) -> void:
	for block in TREAD_BLOCKS:
		var angle := TAU * float(block) / float(TREAD_BLOCKS)
		var tread := MeshFactory.add_box(
			wheel,
			"Tread%d" % (block + 1),
			Vector3(cos(angle) * WHEEL_RADIUS, 0.0, sin(angle) * WHEEL_RADIUS),
			Vector3(0.12, WHEEL_WIDTH * 0.7, 0.1),
			RUBBER_COLOR
		)
		tread.rotation = Vector3(0.0, -angle, 0.0)


func _animate_running_gear(delta: float) -> void:
	var forward_speed := velocity.dot(-global_transform.basis.z)
	if is_zero_approx(forward_speed):
		return
	var spin := forward_speed / WHEEL_RADIUS * delta
	for wheel in _wheels:
		wheel.rotate_object_local(Vector3.UP, spin)