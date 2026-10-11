class_name NavGrid
extends RefCounted

const CELL_SIZE := 0.5
const AGENT_RADIUS := 1.5
const AGENT_MARGIN := 0.1
const CLEARANCE_RADIUS := AGENT_RADIUS + AGENT_MARGIN
const BLOCKED := 0
const WALKABLE := 1
const STRAIGHT_COST := 1.0
const DIAGONAL_COST := 1.4142136
const DISC_SAMPLES := 8
const NEIGHBOR_OFFSETS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]
const DIAGONAL_START := 4
const MAX_EXPANSIONS := 30000
const SMOOTH_WINDOW := 28
const LINE_STEP := CELL_SIZE * 0.5

static var _shared: NavGrid = null

var _columns := 0
var _rows := 0
var _origin_x := 0.0
var _origin_z := 0.0
var _cells := PackedByteArray()
var _walkable_count := 0
var _disc_directions: Array[Vector2] = []
var _heap_nodes := PackedInt32Array()
var _heap_scores := PackedFloat32Array()


static func get_shared() -> NavGrid:
	if _shared == null:
		_shared = NavGrid.new()
	return _shared


func _init() -> void:
	_columns = int(round(MapConfig.HALF_WIDTH * 2.0 / CELL_SIZE))
	_rows = int(round(MapConfig.HALF_DEPTH * 2.0 / CELL_SIZE))
	_origin_x = -MapConfig.HALF_WIDTH
	_origin_z = -MapConfig.HALF_DEPTH
	_disc_directions = _build_disc_directions()
	_build_cells()


func get_columns() -> int:
	return _columns


func get_rows() -> int:
	return _rows


func get_walkable_cell_count() -> int:
	return _walkable_count


func world_to_cell(world_position: Vector3) -> Vector2i:
	return Vector2i(
		int(floor((world_position.x - _origin_x) / CELL_SIZE)),
		int(floor((world_position.z - _origin_z) / CELL_SIZE))
	)


func cell_to_world(cell: Vector2i) -> Vector3:
	return Vector3(
		_origin_x + (float(cell.x) + 0.5) * CELL_SIZE,
		MapConfig.GROUND_TOP_Y,
		_origin_z + (float(cell.y) + 0.5) * CELL_SIZE
	)


func is_cell_walkable(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= _columns or cell.y >= _rows:
		return false
	return _cells[cell.y * _columns + cell.x] == WALKABLE


func has_clearance(world_position: Vector3) -> bool:
	if not MapConfig.is_walkable(world_position):
		return false
	for index in _disc_directions.size():
		var sample := world_position + Vector3(_disc_directions[index].x, 0.0, _disc_directions[index].y) * CLEARANCE_RADIUS
		if not MapConfig.is_walkable(sample):
			return false
	return true


func find_path(from_world: Vector3, to_world: Vector3) -> PackedVector3Array:
	if not MapConfig.is_walkable(to_world):
		return PackedVector3Array()
	var start_cell := _nearest_walkable_cell(world_to_cell(from_world))
	var goal_cell := _nearest_walkable_cell(world_to_cell(to_world))
	if start_cell.x < 0 or goal_cell.x < 0:
		return PackedVector3Array()
	if start_cell == goal_cell:
		var single := PackedVector3Array()
		single.append(cell_to_world(goal_cell))
		return single
	var cells := _search(start_cell, goal_cell)
	if cells.is_empty():
		return PackedVector3Array()
	var points := _string_pull(cells)
	if points.is_empty():
		return PackedVector3Array()
	var final_point := Vector3(to_world.x, MapConfig.GROUND_TOP_Y, to_world.z)
	if _line_has_clearance(points[points.size() - 1], final_point):
		points.append(final_point)
	return points


func _build_disc_directions() -> Array[Vector2]:
	var directions: Array[Vector2] = []
	for index in DISC_SAMPLES:
		var angle := TAU * float(index) / float(DISC_SAMPLES)
		directions.append(Vector2(cos(angle), sin(angle)))
	return directions


func _build_cells() -> void:
	_cells.resize(_columns * _rows)
	_cells.fill(BLOCKED)
	_walkable_count = 0
	for row in _rows:
		for column in _columns:
			var cell := Vector2i(column, row)
			if has_clearance(cell_to_world(cell)):
				_cells[row * _columns + column] = WALKABLE
				_walkable_count += 1


func _nearest_walkable_cell(cell: Vector2i) -> Vector2i:
	if is_cell_walkable(cell):
		return cell
	var clamped := Vector2i(
		clampi(cell.x, 0, _columns - 1),
		clampi(cell.y, 0, _rows - 1)
	)
	if is_cell_walkable(clamped):
		return clamped
	var visited := {}
	var queue: Array[Vector2i] = [clamped]
	visited[clamped] = true
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		for index in NEIGHBOR_OFFSETS.size():
			var neighbor: Vector2i = current + Vector2i(NEIGHBOR_OFFSETS[index])
			if visited.has(neighbor):
				continue
			visited[neighbor] = true
			if is_cell_walkable(neighbor):
				return neighbor
			queue.append(neighbor)
	return Vector2i(-1, -1)


func _search(start_cell: Vector2i, goal_cell: Vector2i) -> PackedInt32Array:
	var total := _columns * _rows
	var g_score := PackedFloat32Array()
	var came_from := PackedInt32Array()
	var closed := PackedByteArray()
	g_score.resize(total)
	came_from.resize(total)
	closed.resize(total)
	g_score.fill(INF)
	came_from.fill(-1)
	closed.fill(0)
	_heap_reset()
	var start_index := _cell_to_index(start_cell)
	var goal_index := _cell_to_index(goal_cell)
	g_score[start_index] = 0.0
	_heap_push(start_index, _heuristic(start_cell, goal_cell))
	var expansions := 0
	var reached := false
	while not _heap_nodes.is_empty():
		var current_index := _heap_pop()
		if current_index < 0:
			break
		if closed[current_index] == 1:
			continue
		closed[current_index] = 1
		if current_index == goal_index:
			reached = true
			break
		expansions += 1
		if expansions > MAX_EXPANSIONS:
			break
		var current_cell := _index_to_cell(current_index)
		for index in NEIGHBOR_OFFSETS.size():
			var offset: Vector2i = Vector2i(NEIGHBOR_OFFSETS[index])
			var neighbor_cell: Vector2i = current_cell + offset
			if not is_cell_walkable(neighbor_cell):
				continue
			if index >= DIAGONAL_START:
				if not is_cell_walkable(Vector2i(current_cell.x + offset.x, current_cell.y)):
					continue
				if not is_cell_walkable(Vector2i(current_cell.x, current_cell.y + offset.y)):
					continue
			var neighbor_index := _cell_to_index(neighbor_cell)
			if closed[neighbor_index] == 1:
				continue
			var step_cost := STRAIGHT_COST
			if index >= DIAGONAL_START:
				step_cost = DIAGONAL_COST
			var tentative := g_score[current_index] + step_cost
			if tentative < g_score[neighbor_index]:
				g_score[neighbor_index] = tentative
				came_from[neighbor_index] = current_index
				_heap_push(neighbor_index, tentative + _heuristic(neighbor_cell, goal_cell))
	if not reached:
		return PackedInt32Array()
	var reversed := PackedInt32Array()
	var cursor := goal_index
	reversed.append(cursor)
	while cursor != start_index:
		cursor = came_from[cursor]
		if cursor < 0:
			return PackedInt32Array()
		reversed.append(cursor)
	reversed.reverse()
	return reversed


func _string_pull(cells: PackedInt32Array) -> PackedVector3Array:
	var raw := PackedVector3Array()
	for index in cells.size():
		raw.append(cell_to_world(_index_to_cell(cells[index])))
	if raw.size() <= 2:
		return raw
	var smoothed := PackedVector3Array()
	var anchor := 0
	smoothed.append(raw[0])
	while anchor < raw.size() - 1:
		var limit: int = mini(raw.size() - 1, anchor + SMOOTH_WINDOW)
		var furthest := anchor + 1
		var probe := limit
		while probe > anchor + 1:
			if _line_has_clearance(raw[anchor], raw[probe]):
				furthest = probe
				break
			probe -= 1
		smoothed.append(raw[furthest])
		anchor = furthest
	return smoothed


func _line_has_clearance(from_world: Vector3, to_world: Vector3) -> bool:
	var steps: int = maxi(1, int(ceil(from_world.distance_to(to_world) / LINE_STEP)))
	for step in range(steps + 1):
		var point := from_world.lerp(to_world, float(step) / float(steps))
		if not is_cell_walkable(world_to_cell(point)):
			return false
	return true


func _heuristic(from_cell: Vector2i, to_cell: Vector2i) -> float:
	var delta_x := absi(to_cell.x - from_cell.x)
	var delta_z := absi(to_cell.y - from_cell.y)
	var diagonal := mini(delta_x, delta_z)
	var straight := maxi(delta_x, delta_z) - diagonal
	return float(diagonal) * DIAGONAL_COST + float(straight) * STRAIGHT_COST


func _cell_to_index(cell: Vector2i) -> int:
	return cell.y * _columns + cell.x


func _index_to_cell(index: int) -> Vector2i:
	return Vector2i(index % _columns, index / _columns)


func _heap_reset() -> void:
	_heap_nodes = PackedInt32Array()
	_heap_scores = PackedFloat32Array()


func _heap_push(node: int, score: float) -> void:
	_heap_nodes.append(node)
	_heap_scores.append(score)
	var child := _heap_nodes.size() - 1
	while child > 0:
		var parent := (child - 1) / 2
		if _heap_scores[parent] <= _heap_scores[child]:
			break
		_heap_swap(parent, child)
		child = parent


func _heap_pop() -> int:
	if _heap_nodes.is_empty():
		return -1
	var top := _heap_nodes[0]
	var last := _heap_nodes.size() - 1
	_heap_swap(0, last)
	_heap_nodes.resize(last)
	_heap_scores.resize(last)
	var parent := 0
	while true:
		var left := parent * 2 + 1
		var right := left + 1
		var smallest := parent
		if left < _heap_nodes.size() and _heap_scores[left] < _heap_scores[smallest]:
			smallest = left
		if right < _heap_nodes.size() and _heap_scores[right] < _heap_scores[smallest]:
			smallest = right
		if smallest == parent:
			break
		_heap_swap(parent, smallest)
		parent = smallest
	return top


func _heap_swap(first: int, second: int) -> void:
	var node_value := _heap_nodes[first]
	var score_value := _heap_scores[first]
	_heap_nodes[first] = _heap_nodes[second]
	_heap_scores[first] = _heap_scores[second]
	_heap_nodes[second] = node_value
	_heap_scores[second] = score_value