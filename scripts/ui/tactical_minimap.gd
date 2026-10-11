class_name TacticalMinimap
extends Control

const PANEL_SIZE := Vector2(196.0, 152.0)
const PADDING := 8.0
const HEADER_HEIGHT := 16.0
const MAP_BG := Color(0.05, 0.06, 0.07, 1.0)
const GROUND_TINT := Color(0.31, 0.32, 0.34, 1.0)
const WATER_TINT := Color(0.16, 0.42, 0.68, 1.0)
const BRIDGE_TINT := Color(0.5, 0.33, 0.16, 1.0)
const BORDER_TINT := Color(0.78, 0.15, 0.11, 1.0)
const GRID_TINT := Color(1.0, 1.0, 1.0, 0.06)
const UNIT_COLOR := Color(0.98, 0.85, 0.2, 1.0)
const UNIT_OUTLINE := Color(0.05, 0.05, 0.05, 1.0)
const CAMERA_MARKER_SIZE := Vector2(20.0, 13.0)
const UNIT_DOT_RADIUS := 3.2
const UNIT_HEADING_LENGTH := 9.0

var _unit: CommandVehicle
var _camera: TacticalCamera


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup(unit: CommandVehicle, camera: TacticalCamera) -> void:
	_unit = unit
	_camera = camera
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	_draw_panel_frame()
	_draw_map()
	_draw_camera_marker()
	_draw_unit_marker()


func _draw_panel_frame() -> void:
	var panel_rect := Rect2(Vector2.ZERO, size)
	draw_rect(panel_rect, HudStyle.PANEL_BG, true)
	draw_rect(panel_rect, HudStyle.BORDER, false, 1.0)
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, HEADER_HEIGHT)), HudStyle.HEADER_BG, true)
	draw_line(Vector2(0.0, HEADER_HEIGHT), Vector2(size.x, HEADER_HEIGHT), HudStyle.ACCENT, 2.0)
	var font := get_theme_default_font()
	if font != null:
		draw_string(
			font,
			Vector2(6.0, HEADER_HEIGHT - 4.0),
			"TAC-MAP",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			11,
			HudStyle.ACCENT
		)


func _draw_map() -> void:
	var origin := _map_origin()
	var map_size := Vector2(MapConfig.HALF_WIDTH, MapConfig.HALF_DEPTH) * 2.0 * _map_scale()
	var map_rect := Rect2(origin, map_size)
	var bridge_half_width := MapConfig.RIVER_HALF_WIDTH + MapConfig.BRIDGE_OVERLAP
	draw_rect(map_rect, MAP_BG, true)

	draw_rect(
		_world_rect(Vector2(-MapConfig.HALF_WIDTH, -MapConfig.HALF_DEPTH), Vector2(-MapConfig.RIVER_HALF_WIDTH, MapConfig.HALF_DEPTH)),
		GROUND_TINT,
		true
	)
	draw_rect(
		_world_rect(Vector2(MapConfig.RIVER_HALF_WIDTH, -MapConfig.HALF_DEPTH), Vector2(MapConfig.HALF_WIDTH, MapConfig.HALF_DEPTH)),
		GROUND_TINT,
		true
	)
	draw_rect(
		_world_rect(Vector2(-MapConfig.RIVER_HALF_WIDTH, -MapConfig.HALF_DEPTH), Vector2(MapConfig.RIVER_HALF_WIDTH, MapConfig.HALF_DEPTH)),
		WATER_TINT,
		true
	)
	draw_rect(
		_world_rect(
			Vector2(-bridge_half_width, -MapConfig.BRIDGE_HALF_LENGTH),
			Vector2(bridge_half_width, MapConfig.BRIDGE_HALF_LENGTH)
		),
		BRIDGE_TINT,
		true
	)

	var grid_lines := 4
	for index in range(1, grid_lines):
		var ratio := float(index) / float(grid_lines)
		var x := origin.x + map_size.x * ratio
		var y := origin.y + map_size.y * ratio
		draw_line(Vector2(x, origin.y), Vector2(x, origin.y + map_size.y), GRID_TINT, 1.0)
		draw_line(Vector2(origin.x, y), Vector2(origin.x + map_size.x, y), GRID_TINT, 1.0)

	draw_rect(map_rect, BORDER_TINT, false, 1.0)


func _draw_camera_marker() -> void:
	if _camera == null:
		return
	var focus := _camera.focus
	var center := _world_to_map(Vector2(focus.x, focus.z))
	var marker_rect := Rect2(center - CAMERA_MARKER_SIZE * 0.5, CAMERA_MARKER_SIZE)
	draw_rect(marker_rect, HudStyle.ACCENT, false, 1.0)
	draw_line(center - Vector2(3.0, 0.0), center + Vector2(3.0, 0.0), HudStyle.ACCENT, 1.0)
	draw_line(center - Vector2(0.0, 3.0), center + Vector2(0.0, 3.0), HudStyle.ACCENT, 1.0)


func _draw_unit_marker() -> void:
	if _unit == null:
		return
	var position := _unit.global_position
	var center := _world_to_map(Vector2(position.x, position.z))
	var forward := -_unit.global_transform.basis.z
	var heading := center + Vector2(forward.x, forward.z) * UNIT_HEADING_LENGTH
	draw_line(center, heading, UNIT_COLOR, 1.5)
	draw_circle(center, UNIT_DOT_RADIUS, UNIT_COLOR)
	draw_circle(center, UNIT_DOT_RADIUS, UNIT_OUTLINE, false, 1.0)


func _map_area_size() -> Vector2:
	var panel_size := Vector2(maxf(size.x, PANEL_SIZE.x), maxf(size.y, PANEL_SIZE.y))
	return panel_size - Vector2(PADDING, PADDING + HEADER_HEIGHT) * 2.0


func _map_scale() -> float:
	var available := _map_area_size()
	return minf(
		available.x / (MapConfig.HALF_WIDTH * 2.0),
		available.y / (MapConfig.HALF_DEPTH * 2.0)
	)


func _map_origin() -> Vector2:
	var available := _map_area_size()
	var map_size := Vector2(MapConfig.HALF_WIDTH, MapConfig.HALF_DEPTH) * 2.0 * _map_scale()
	return Vector2(PADDING, PADDING + HEADER_HEIGHT) + (available - map_size) * 0.5


func _world_to_map(world_xz: Vector2) -> Vector2:
	return _map_origin() + Vector2(world_xz.x + MapConfig.HALF_WIDTH, world_xz.y + MapConfig.HALF_DEPTH) * _map_scale()


func _world_rect(world_min: Vector2, world_max: Vector2) -> Rect2:
	var top_left := _world_to_map(world_min)
	var bottom_right := _world_to_map(world_max)
	return Rect2(top_left, bottom_right - top_left)