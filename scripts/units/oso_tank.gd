class_name OsoTank
extends Unit

const STATS_PATH := "res://resources/units/oso_tank_stats.tres"

const HULL_COLOR := Color(0.25, 0.3, 0.38)
const HULL_WORN_COLOR := Color(0.16, 0.2, 0.26)
const SCRATCH_COLOR := Color(0.34, 0.39, 0.47)
const TRIM_COLOR := Color(0.09, 0.09, 0.11)
const TRACK_COLOR := Color(0.6, 0.5, 0.33)
const TRACK_LINK_COLOR := Color(0.4, 0.32, 0.2)
const HUB_COLOR := Color(0.35, 0.37, 0.4)
const GUN_COLOR := Color(0.3, 0.31, 0.33)
const VISOR_COLOR := Color(0.05, 0.07, 0.09)
const MARK_COLOR := Color(0.92, 0.92, 0.94)
const HEADLIGHT_COLOR := Color(1.0, 0.94, 0.75)
const LAMP_COLOR := Color(1.0, 0.62, 0.14)

const COLLIDER_SIZE := Vector3(2.0, 1.05, 3.7)
const COLLIDER_HEIGHT := 0.5

const TRACK_OFFSET_X := 1.0
const TRACK_WIDTH := 0.62
const TRACK_HEIGHT := 0.84
const TRACK_LENGTH := 3.8
const TRACK_CENTER_Y := 0.44
const ROAD_WHEEL_RADIUS := 0.28
const ROAD_WHEEL_WIDTH := 0.58
const SPROCKET_RADIUS := 0.36
const SPROCKET_OFFSET_Z := 1.68
const ROAD_WHEEL_OFFSETS := [-1.3, -0.65, 0.0, 0.65, 1.3]

const TURRET_PIVOT := Vector3(0.0, 1.3, 0.1)

@export var stats: UnitStats

var _wheels: Array[MeshInstance3D] = []


func get_stats() -> UnitStats:
	if stats != null:
		return stats
	var loaded := load(STATS_PATH)
	if loaded is UnitStats:
		stats = loaded
		return stats
	push_warning("OsoTank: no se pudo cargar %s, usando stats por defecto" % STATS_PATH)
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

	_build_tracks(model)
	_build_hull(model)
	_build_turret(model)


func _build_tracks(model: Node3D) -> void:
	for side in [-1.0, 1.0]:
		var side_name := "West" if side < 0.0 else "East"
		var track_x: float = TRACK_OFFSET_X * side
		MeshFactory.add_box(
			model,
			"Track%s" % side_name,
			Vector3(track_x, TRACK_CENTER_Y, 0.0),
			Vector3(TRACK_WIDTH, TRACK_HEIGHT, TRACK_LENGTH),
			TRACK_COLOR
		)
		MeshFactory.add_box(
			model,
			"TrackGuard%s" % side_name,
			Vector3(track_x, TRACK_CENTER_Y + TRACK_HEIGHT * 0.5 + 0.03, 0.0),
			Vector3(TRACK_WIDTH + 0.12, 0.12, TRACK_LENGTH - 0.1),
			TRIM_COLOR
		)
		MeshFactory.add_box(
			model,
			"FenderFront%s" % side_name,
			Vector3(track_x, TRACK_CENTER_Y + TRACK_HEIGHT * 0.5, -TRACK_LENGTH * 0.5 - 0.12),
			Vector3(TRACK_WIDTH + 0.16, 0.16, 0.32),
			TRIM_COLOR
		)
		MeshFactory.add_box(
			model,
			"FenderRear%s" % side_name,
			Vector3(track_x, TRACK_CENTER_Y + TRACK_HEIGHT * 0.5, TRACK_LENGTH * 0.5 + 0.12),
			Vector3(TRACK_WIDTH + 0.16, 0.16, 0.32),
			TRIM_COLOR
		)
		for link in 6:
			var link_z := -TRACK_LENGTH * 0.42 + float(link) * (TRACK_LENGTH * 0.84 / 5.0)
			MeshFactory.add_box(
				model,
				"TrackLink%s%d" % [side_name, link + 1],
				Vector3(track_x + (TRACK_WIDTH * 0.5 + 0.02) * side, TRACK_CENTER_Y, link_z),
				Vector3(0.05, TRACK_HEIGHT * 0.72, 0.2),
				TRACK_LINK_COLOR
			)


func _build_hull(model: Node3D) -> void:
	MeshFactory.add_box(model, "LowerHull", Vector3(0.0, 0.82, 0.0), Vector3(1.9, 0.5, 3.5), HULL_COLOR)
	MeshFactory.add_box(model, "UpperHull", Vector3(0.0, 1.16, 0.1), Vector3(2.0, 0.4, 3.2), HULL_COLOR)
	var glacis := MeshFactory.add_box(model, "Glacis", Vector3(0.0, 1.14, -1.62), Vector3(1.86, 0.34, 1.2), HULL_COLOR)
	glacis.rotation_degrees = Vector3(-30.0, 0.0, 0.0)
	MeshFactory.add_box(model, "RearPlate", Vector3(0.0, 1.0, 1.75), Vector3(1.84, 0.44, 0.24), HULL_WORN_COLOR)
	MeshFactory.add_box(model, "EngineDeck", Vector3(0.0, 1.4, 1.0), Vector3(1.7, 0.16, 1.4), TRIM_COLOR)
	for index in 3:
		var slot := -0.36 + float(index) * 0.36
		MeshFactory.add_box(model, "Grille%d" % (index + 1), Vector3(slot, 1.49, 1.0), Vector3(0.2, 0.04, 1.2), HULL_COLOR)
	MeshFactory.add_cylinder(
		model, "FrontEdge", Vector3(0.0, 1.36, -1.52), 0.2, 1.9, HULL_COLOR
	).rotation_degrees = Vector3(0.0, 0.0, 90.0)
	MeshFactory.add_cylinder(
		model, "EdgeWest", Vector3(-0.97, 1.34, 0.0), 0.2, 3.2, HULL_COLOR
	).rotation_degrees = Vector3(90.0, 0.0, 0.0)
	MeshFactory.add_cylinder(
		model, "EdgeEast", Vector3(0.97, 1.34, 0.0), 0.2, 3.2, HULL_COLOR
	).rotation_degrees = Vector3(90.0, 0.0, 0.0)
	MeshFactory.add_box(model, "HullWearWest", Vector3(-0.96, 1.18, 0.5), Vector3(0.03, 0.28, 1.3), HULL_WORN_COLOR)
	MeshFactory.add_box(model, "HullWearEast", Vector3(0.96, 1.18, -0.3), Vector3(0.03, 0.28, 1.1), HULL_WORN_COLOR)
	MeshFactory.add_box(model, "DeckWear", Vector3(0.3, 1.38, -0.7), Vector3(1.0, 0.03, 0.7), HULL_WORN_COLOR)
	MeshFactory.add_box(model, "ScratchWest", Vector3(-0.965, 1.08, -0.9), Vector3(0.02, 0.03, 0.9), SCRATCH_COLOR)
	MeshFactory.add_box(model, "ScratchEast", Vector3(0.965, 1.24, 0.6), Vector3(0.02, 0.025, 0.7), SCRATCH_COLOR)
	MeshFactory.add_box(model, "ScratchFront", Vector3(-0.4, 1.05, -1.9), Vector3(0.5, 0.025, 0.02), SCRATCH_COLOR)
	MeshFactory.add_box(model, "HeadlightWest", Vector3(0.64, 1.06, -1.8), Vector3(0.28, 0.16, 0.06), HEADLIGHT_COLOR, false, 1.0)
	MeshFactory.add_box(model, "HeadlightEast", Vector3(-0.64, 1.06, -1.8), Vector3(0.28, 0.16, 0.06), HEADLIGHT_COLOR, false, 1.0)
	MeshFactory.add_box(model, "MarkerLight", Vector3(0.0, 1.26, 1.86), Vector3(0.16, 0.08, 0.04), LAMP_COLOR, false, 1.2)
	MeshFactory.add_box(model, "TowHookWest", Vector3(-0.78, 0.5, -1.86), Vector3(0.1, 0.1, 0.16), TRIM_COLOR)
	MeshFactory.add_box(model, "TowHookEast", Vector3(0.78, 0.5, -1.86), Vector3(0.1, 0.1, 0.16), TRIM_COLOR)


func _build_turret(model: Node3D) -> void:
	var turret := Node3D.new()
	turret.name = "Turret"
	turret.position = TURRET_PIVOT
	model.add_child(turret)

	MeshFactory.add_cylinder(turret, "TurretRing", Vector3(0.0, 0.02, 0.0), 0.82, 0.12, TRIM_COLOR)
	MeshFactory.add_box(turret, "TurretBase", Vector3(0.0, 0.16, 0.02), Vector3(1.5, 0.28, 1.7), HULL_COLOR)
	var dome := MeshFactory.add_mesh(
		turret, "TurretDome", Vector3(0.0, 0.3, -0.02), MeshFactory.sphere_mesh(1.0, HULL_COLOR)
	)
	dome.scale = Vector3(0.72, 0.26, 0.86)
	MeshFactory.add_box(turret, "Mantlet", Vector3(0.0, 0.18, -0.92), Vector3(0.6, 0.34, 0.3), TRIM_COLOR)
	var visor := MeshFactory.add_box(turret, "Visor", Vector3(0.0, 0.24, -0.86), Vector3(1.0, 0.16, 0.08), VISOR_COLOR)
	visor.rotation_degrees = Vector3(-5.0, 0.0, 0.0)
	var cannon := MeshFactory.add_cylinder(turret, "Cannon", Vector3(0.0, 0.18, -2.0), 0.09, 2.3, GUN_COLOR)
	cannon.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	var muzzle := MeshFactory.add_cylinder(turret, "Muzzle", Vector3(0.0, 0.18, -3.24), 0.14, 0.26, TRIM_COLOR)
	muzzle.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	MeshFactory.add_box(turret, "TurretBustle", Vector3(0.0, 0.18, 0.92), Vector3(1.1, 0.24, 0.36), HULL_WORN_COLOR)
	MeshFactory.add_box(turret, "TurretWear", Vector3(0.74, 0.2, 0.3), Vector3(0.03, 0.22, 1.0), HULL_WORN_COLOR)
	MeshFactory.add_box(turret, "SecondMount", Vector3(0.34, 0.34, 0.2), Vector3(0.2, 0.18, 0.3), TRIM_COLOR)
	var secondary := MeshFactory.add_cylinder(turret, "SecondBarrel", Vector3(0.34, 0.42, -0.12), 0.05, 0.6, GUN_COLOR)
	secondary.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	MeshFactory.add_cylinder(turret, "TurretAntenna", Vector3(-0.42, 0.62, 0.5), 0.03, 0.7, TRIM_COLOR)
	MeshFactory.add_mesh(turret, "TurretAntennaTip", Vector3(-0.42, 0.98, 0.5), MeshFactory.sphere_mesh(0.045, TRIM_COLOR))
	MeshFactory.add_cylinder(turret, "Cupola", Vector3(-0.28, 0.44, 0.24), 0.19, 0.14, HULL_COLOR)
	MeshFactory.add_cylinder(turret, "Hatch", Vector3(-0.28, 0.52, 0.24), 0.15, 0.06, TRIM_COLOR)
	MeshFactory.add_box(turret, "HatchHandle", Vector3(-0.28, 0.56, 0.24), Vector3(0.13, 0.03, 0.03), HUB_COLOR)
	MeshFactory.add_box(turret, "PeriscopeWest", Vector3(-0.1, 0.42, -0.3), Vector3(0.07, 0.12, 0.07), VISOR_COLOR)
	MeshFactory.add_box(turret, "PeriscopeEast", Vector3(0.06, 0.44, -0.5), Vector3(0.07, 0.12, 0.07), VISOR_COLOR)
	_build_marking(turret)


func _build_marking(turret: Node3D) -> void:
	var marking := Node3D.new()
	marking.name = "Marking47"
	marking.position = Vector3(-0.76, 0.16, 0.12)
	marking.rotation_degrees = Vector3(0.0, -90.0, 0.0)
	turret.add_child(marking)
	_build_digit(marking, "Digit4", -0.11, [1, 6, 2, 3])
	_build_digit(marking, "Digit7", 0.11, [0, 2, 3])


func _build_digit(parent: Node3D, digit_name: String, offset_x: float, segments: Array) -> void:
	var digit := Node3D.new()
	digit.name = digit_name
	digit.position = Vector3(offset_x, 0.0, 0.0)
	parent.add_child(digit)
	var half_width := 0.05
	var half_height := 0.09
	var thickness := 0.024
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
	for side in [-1.0, 1.0]:
		var side_name := "West" if side < 0.0 else "East"
		for index in ROAD_WHEEL_OFFSETS.size():
			var wheel := MeshFactory.add_cylinder(
				model,
				"RoadWheel%s%d" % [side_name, index + 1],
				Vector3(TRACK_OFFSET_X * side, ROAD_WHEEL_RADIUS, ROAD_WHEEL_OFFSETS[index]),
				ROAD_WHEEL_RADIUS,
				ROAD_WHEEL_WIDTH,
				HUB_COLOR
			)
			wheel.rotation_degrees = Vector3(0.0, 0.0, 90.0)
			_wheels.append(wheel)
		for end_index in 2:
			var end_name := "Front" if end_index == 0 else "Rear"
			var end_sign := -1.0 if end_index == 0 else 1.0
			var sprocket := MeshFactory.add_cylinder(
				model,
				"Sprocket%s%s" % [side_name, end_name],
				Vector3(TRACK_OFFSET_X * side, SPROCKET_RADIUS, SPROCKET_OFFSET_Z * end_sign),
				SPROCKET_RADIUS,
				ROAD_WHEEL_WIDTH,
				TRIM_COLOR
			)
			sprocket.rotation_degrees = Vector3(0.0, 0.0, 90.0)
			_wheels.append(sprocket)


func _animate_running_gear(delta: float) -> void:
	var forward_speed := velocity.dot(-global_transform.basis.z)
	if is_zero_approx(forward_speed):
		return
	var spin := forward_speed / ROAD_WHEEL_RADIUS * delta
	for wheel in _wheels:
		wheel.rotate_object_local(Vector3.UP, spin)
