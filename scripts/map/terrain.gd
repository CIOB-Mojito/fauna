class_name MapTerrain
extends Node3D

const GROUND_COLOR := Color(0.42, 0.43, 0.45)
const WATER_COLOR := Color(0.13, 0.4, 0.72)
const BRIDGE_COLOR := Color(0.45, 0.28, 0.14)
const BRIDGE_RAIL_COLOR := Color(0.3, 0.18, 0.09)
const BORDER_COLOR := Color(0.85, 0.08, 0.06)

const WATER_BLOCKER_TOP := 2.0
const WATER_BLOCKER_BOTTOM := -1.5
const BRIDGE_PASSAGE_MARGIN := 0.5
const BORDER_INSET := 0.35
const BORDER_WIDTH := 0.3
const BORDER_HEIGHT := 0.06
const RAIL_HEIGHT := 0.26
const RAIL_THICKNESS := 0.12


func _ready() -> void:
	_build_ground()
	_build_river()
	_build_bridge()
	_build_border()


func _build_ground() -> void:
	var slab_length := MapConfig.HALF_WIDTH - MapConfig.RIVER_HALF_WIDTH
	var slab_center_x := (MapConfig.HALF_WIDTH + MapConfig.RIVER_HALF_WIDTH) * 0.5
	var slab_size := Vector3(slab_length, MapConfig.GROUND_THICKNESS, MapConfig.HALF_DEPTH * 2.0)
	var slab_center_y := MapConfig.GROUND_TOP_Y - MapConfig.GROUND_THICKNESS * 0.5
	_add_solid_box("GroundWest", Vector3(-slab_center_x, slab_center_y, 0.0), slab_size, GROUND_COLOR)
	_add_solid_box("GroundEast", Vector3(slab_center_x, slab_center_y, 0.0), slab_size, GROUND_COLOR)


func _build_river() -> void:
	var water_size := Vector3(
		MapConfig.RIVER_HALF_WIDTH * 2.0,
		MapConfig.RIVER_DEPTH,
		MapConfig.HALF_DEPTH * 2.0
	)
	var water_center := Vector3(
		MapConfig.RIVER_CENTER_X,
		MapConfig.RIVER_SURFACE_Y - MapConfig.RIVER_DEPTH * 0.5,
		0.0
	)
	MeshFactory.add_box(self, "Water", water_center, water_size, WATER_COLOR, false, 0.2)

	var passage_half_length := MapConfig.BRIDGE_HALF_LENGTH + BRIDGE_PASSAGE_MARGIN
	var blocker_height := WATER_BLOCKER_TOP - WATER_BLOCKER_BOTTOM
	var blocker_length := MapConfig.HALF_DEPTH - passage_half_length
	var blocker_center_y := (WATER_BLOCKER_TOP + WATER_BLOCKER_BOTTOM) * 0.5
	var blocker_center_z := (MapConfig.HALF_DEPTH + passage_half_length) * 0.5
	_add_blocker(
		"WaterBlockerNorth",
		Vector3(MapConfig.RIVER_CENTER_X, blocker_center_y, -blocker_center_z),
		Vector3(MapConfig.RIVER_HALF_WIDTH * 2.0, blocker_height, blocker_length)
	)
	_add_blocker(
		"WaterBlockerSouth",
		Vector3(MapConfig.RIVER_CENTER_X, blocker_center_y, blocker_center_z),
		Vector3(MapConfig.RIVER_HALF_WIDTH * 2.0, blocker_height, blocker_length)
	)


func _build_bridge() -> void:
	var deck_size := Vector3(
		(MapConfig.RIVER_HALF_WIDTH + MapConfig.BRIDGE_OVERLAP) * 2.0,
		MapConfig.GROUND_THICKNESS,
		MapConfig.BRIDGE_HALF_LENGTH * 2.0
	)
	var deck_center := Vector3(
		MapConfig.RIVER_CENTER_X,
		MapConfig.GROUND_TOP_Y - MapConfig.GROUND_THICKNESS * 0.5,
		MapConfig.BRIDGE_CENTER_Z
	)
	var deck := _add_solid_box("Bridge", deck_center, deck_size, BRIDGE_COLOR)
	var rail_size := Vector3(deck_size.x, RAIL_HEIGHT, RAIL_THICKNESS)
	var rail_z := MapConfig.BRIDGE_HALF_LENGTH - RAIL_THICKNESS * 0.5
	MeshFactory.add_box(deck, "BridgeRailNorth", Vector3(0.0, RAIL_HEIGHT * 0.5, -rail_z), rail_size, BRIDGE_RAIL_COLOR)
	MeshFactory.add_box(deck, "BridgeRailSouth", Vector3(0.0, RAIL_HEIGHT * 0.5, rail_z), rail_size, BRIDGE_RAIL_COLOR)


func _build_border() -> void:
	var north_south_size := Vector3(
		MapConfig.HALF_WIDTH * 2.0 - BORDER_INSET * 2.0,
		BORDER_HEIGHT,
		BORDER_WIDTH
	)
	var east_west_size := Vector3(
		BORDER_WIDTH,
		BORDER_HEIGHT,
		MapConfig.HALF_DEPTH * 2.0 - BORDER_INSET * 2.0
	)
	var z_line := MapConfig.HALF_DEPTH - BORDER_INSET
	var x_line := MapConfig.HALF_WIDTH - BORDER_INSET
	MeshFactory.add_box(self, "BorderNorth", Vector3(0.0, BORDER_HEIGHT, -z_line), north_south_size, BORDER_COLOR, true)
	MeshFactory.add_box(self, "BorderSouth", Vector3(0.0, BORDER_HEIGHT, z_line), north_south_size, BORDER_COLOR, true)
	MeshFactory.add_box(self, "BorderWest", Vector3(-x_line, BORDER_HEIGHT, 0.0), east_west_size, BORDER_COLOR, true)
	MeshFactory.add_box(self, "BorderEast", Vector3(x_line, BORDER_HEIGHT, 0.0), east_west_size, BORDER_COLOR, true)


func _add_solid_box(node_name: String, box_position: Vector3, size: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = box_position
	body.collision_layer = MapConfig.LAYER_TERRAIN
	body.collision_mask = 0
	add_child(body)

	var collider := CollisionShape3D.new()
	collider.name = "Collider"
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	body.add_child(collider)

	MeshFactory.add_box(body, "Mesh", Vector3.ZERO, size, color)
	return body


func _add_blocker(node_name: String, box_position: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = box_position
	body.collision_layer = MapConfig.LAYER_WATER
	body.collision_mask = 0
	add_child(body)

	var collider := CollisionShape3D.new()
	collider.name = "Collider"
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	body.add_child(collider)
	return body