class_name Scout
extends Unit

const STATS_PATH := "res://resources/units/castor_lt_stats.tres"

const HULL_COLOR := Color(0.79, 0.63, 0.16)
const HULL_WORN_COLOR := Color(0.6, 0.47, 0.13)
const TRIM_COLOR := Color(0.1, 0.1, 0.11)
const TRACK_COLOR := Color(0.09, 0.09, 0.1)
const HUB_COLOR := Color(0.5, 0.5, 0.52)
const GUN_COLOR := Color(0.3, 0.31, 0.32)
const VISOR_COLOR := Color(0.05, 0.07, 0.09)
const EMBLEM_BLUE := Color(0.13, 0.32, 0.78)
const EMBLEM_WHITE := Color(0.95, 0.95, 0.95)
const LAMP_COLOR := Color(1.0, 0.62, 0.14)
const HEADLIGHT_COLOR := Color(1.0, 0.94, 0.75)

const COLLIDER_SIZE := Vector3(2.0, 1.1, 3.1)
const COLLIDER_HEIGHT := 0.55

const TRACK_OFFSET_X := 1.0
const TRACK_WIDTH := 0.6
const TRACK_HEIGHT := 0.9
const TRACK_LENGTH := 3.6
const TRACK_CENTER_Y := 0.5
const ROAD_WHEEL_RADIUS := 0.3
const ROAD_WHEEL_WIDTH := 0.56
const SPROCKET_RADIUS := 0.38
const SPROCKET_OFFSET_Z := 1.55
const ROAD_WHEEL_OFFSETS := [-1.25, -0.6, 0.0, 0.6, 1.25]

const TURRET_PIVOT := Vector3(0.0, 1.42, 0.12)

@export var stats: UnitStats

var _wheels: Array[MeshInstance3D] = []


func get_stats() -> UnitStats:
	if stats != null:
		return stats
	var loaded := load(STATS_PATH)
	if loaded is UnitStats:
		stats = loaded
		return stats
	push_warning("Scout: no se pudo cargar %s, usando stats por defecto" % STATS_PATH)
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
		for link in 5:
			var link_z := -TRACK_LENGTH * 0.4 + float(link) * (TRACK_LENGTH * 0.8 / 4.0)
			MeshFactory.add_box(
				model,
				"TrackLink%s%d" % [side_name, link + 1],
				Vector3(track_x + (TRACK_WIDTH * 0.5 + 0.02) * side, TRACK_CENTER_Y, link_z),
				Vector3(0.05, TRACK_HEIGHT * 0.7, 0.18),
				TRACK_COLOR
			)


func _build_hull(model: Node3D) -> void:
	MeshFactory.add_box(model, "LowerHull", Vector3(0.0, 0.9, 0.0), Vector3(1.9, 0.6, 3.3), HULL_COLOR)
	MeshFactory.add_box(model, "UpperHull", Vector3(0.0, 1.32, 0.05), Vector3(2.0, 0.44, 3.0), HULL_COLOR)
	var glacis := MeshFactory.add_box(model, "Glacis", Vector3(0.0, 1.3, -1.5), Vector3(1.86, 0.36, 1.15), HULL_COLOR)
	glacis.rotation_degrees = Vector3(-32.0, 0.0, 0.0)
	MeshFactory.add_box(model, "RearPlate", Vector3(0.0, 1.15, 1.6), Vector3(1.84, 0.5, 0.24), HULL_WORN_COLOR)
	MeshFactory.add_box(model, "EngineDeck", Vector3(0.0, 1.58, 0.9), Vector3(1.7, 0.16, 1.2), TRIM_COLOR)
	for index in 3:
		var slot := -0.36 + float(index) * 0.36
		MeshFactory.add_box(model, "Grille%d" % (index + 1), Vector3(slot, 1.67, 0.9), Vector3(0.2, 0.04, 1.0), HULL_COLOR)
	MeshFactory.add_cylinder(
		model, "FrontEdge", Vector3(0.0, 1.52, -1.45), 0.22, 1.9, HULL_COLOR
	).rotation_degrees = Vector3(0.0, 0.0, 90.0)
	MeshFactory.add_cylinder(
		model, "EdgeWest", Vector3(-0.97, 1.5, 0.0), 0.22, 2.9, HULL_COLOR
	).rotation_degrees = Vector3(90.0, 0.0, 0.0)
	MeshFactory.add_cylinder(
		model, "EdgeEast", Vector3(0.97, 1.5, 0.0), 0.22, 2.9, HULL_COLOR
	).rotation_degrees = Vector3(90.0, 0.0, 0.0)
	MeshFactory.add_box(model, "HullWearWest", Vector3(-0.96, 1.35, 0.4), Vector3(0.03, 0.3, 1.2), HULL_WORN_COLOR)
	MeshFactory.add_box(model, "HullWearEast", Vector3(0.96, 1.35, -0.2), Vector3(0.03, 0.3, 1.0), HULL_WORN_COLOR)
	MeshFactory.add_box(model, "DeckWear", Vector3(0.3, 1.56, -0.8), Vector3(1.0, 0.03, 0.7), HULL_WORN_COLOR)
	MeshFactory.add_box(model, "HeadlightWest", Vector3(0.64, 1.06, -1.66), Vector3(0.28, 0.16, 0.06), HEADLIGHT_COLOR, false, 1.0)
	MeshFactory.add_box(model, "HeadlightEast", Vector3(-0.64, 1.06, -1.66), Vector3(0.28, 0.16, 0.06), HEADLIGHT_COLOR, false, 1.0)
	MeshFactory.add_box(model, "MarkerLight", Vector3(0.0, 1.4, 1.72), Vector3(0.16, 0.08, 0.04), LAMP_COLOR, false, 1.2)
	MeshFactory.add_box(model, "Antenna", Vector3(-0.72, 1.75, 1.2), Vector3(0.04, 0.72, 0.04), TRIM_COLOR)
	MeshFactory.add_mesh(model, "AntennaTip", Vector3(-0.72, 2.11, 1.2), MeshFactory.sphere_mesh(0.05, TRIM_COLOR))
	_build_emblem(model, "EmblemWest", Vector3(-1.0, 1.3, 0.35), true)
	_build_emblem(model, "EmblemEast", Vector3(1.0, 1.3, 0.35), true)
	_build_emblem(model, "EmblemFront", Vector3(0.0, 1.0, -1.67), false)


func _build_emblem(parent: Node3D, emblem_name: String, position: Vector3, on_side: bool) -> void:
	var disc := MeshFactory.add_cylinder(parent, emblem_name, position, 0.24, 0.04, EMBLEM_BLUE)
	var core := MeshFactory.add_cylinder(parent, "%sCore" % emblem_name, position, 0.1, 0.06, EMBLEM_WHITE)
	var disc_rotation := Vector3(0.0, 0.0, 90.0) if on_side else Vector3(90.0, 0.0, 0.0)
	disc.rotation_degrees = disc_rotation
	core.rotation_degrees = disc_rotation


func _build_turret(model: Node3D) -> void:
	var turret := Node3D.new()
	turret.name = "Turret"
	turret.position = TURRET_PIVOT
	model.add_child(turret)

	MeshFactory.add_cylinder(turret, "TurretRing", Vector3(0.0, 0.03, 0.0), 0.82, 0.16, TRIM_COLOR)
	MeshFactory.add_cylinder(turret, "TurretBase", Vector3(0.0, 0.2, -0.04), 0.72, 0.26, HULL_COLOR)
	MeshFactory.add_box(turret, "TurretBustle", Vector3(0.0, 0.24, 0.62), Vector3(1.0, 0.28, 0.4), HULL_COLOR)
	var dome := MeshFactory.add_mesh(
		turret, "TurretDome", Vector3(0.0, 0.4, -0.04), MeshFactory.sphere_mesh(1.0, HULL_COLOR)
	)
	dome.scale = Vector3(0.66, 0.34, 0.66)
	var visor := MeshFactory.add_box(turret, "Visor", Vector3(0.0, 0.24, -0.7), Vector3(1.02, 0.2, 0.08), VISOR_COLOR)
	visor.rotation_degrees = Vector3(-6.0, 0.0, 0.0)
	MeshFactory.add_box(turret, "Mantlet", Vector3(0.0, 0.22, -0.68), Vector3(0.56, 0.4, 0.34), TRIM_COLOR)
	var cannon := MeshFactory.add_cylinder(turret, "Cannon", Vector3(0.0, 0.22, -1.62), 0.1, 2.0, GUN_COLOR)
	cannon.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	var muzzle := MeshFactory.add_cylinder(turret, "Muzzle", Vector3(0.0, 0.22, -2.6), 0.15, 0.26, TRIM_COLOR)
	muzzle.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	MeshFactory.add_box(turret, "SecondaryMount", Vector3(0.36, 0.3, -0.36), Vector3(0.22, 0.2, 0.34), TRIM_COLOR)
	var secondary := MeshFactory.add_cylinder(turret, "SecondaryCannon", Vector3(0.36, 0.36, -0.72), 0.06, 0.7, GUN_COLOR)
	secondary.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	MeshFactory.add_cylinder(turret, "Cupola", Vector3(-0.26, 0.6, 0.18), 0.2, 0.14, HULL_COLOR)
	MeshFactory.add_cylinder(turret, "Hatch", Vector3(-0.26, 0.68, 0.18), 0.16, 0.06, TRIM_COLOR)
	MeshFactory.add_box(turret, "HatchHandle", Vector3(-0.26, 0.72, 0.18), Vector3(0.14, 0.03, 0.03), HUB_COLOR)
	MeshFactory.add_box(turret, "PeriscopeWest", Vector3(0.3, 0.52, -0.1), Vector3(0.07, 0.12, 0.07), VISOR_COLOR)
	MeshFactory.add_box(turret, "PeriscopeEast", Vector3(0.14, 0.54, -0.34), Vector3(0.07, 0.12, 0.07), VISOR_COLOR)


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