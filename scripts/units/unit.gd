class_name Unit
extends CharacterBody3D

signal move_order_completed
signal move_order_failed
signal move_order_cancelled

const ARRIVE_DISTANCE := 0.35
const TURN_SPEED := 6.0
const MIN_PROGRESS_RATIO := 0.25
const RING_RADIUS := 1.5
const RING_SEGMENTS := 16
const RING_SEGMENT_SIZE := Vector3(0.28, 0.05, 0.16)
const RING_HEIGHT := 0.08
const SELECTION_COLOR := Color(1.0, 0.82, 0.05)

const AVOID_PROBE_HEIGHT := 0.5
const AVOID_PROBE_ORIGIN := 1.0
const AVOID_PROBE_DISTANCE := 3.4
const AVOID_MIN_CLEARANCE := 0.55
const AVOID_ALIGNMENT_WEIGHT := 1.0
const AVOID_CLEARANCE_WEIGHT := 0.65
const AVOID_SEPARATION_RADIUS := 3.0
const AVOID_SEPARATION_STRENGTH := 0.9
const AVOID_TURN_RATE := 3.4
const AVOID_ANGLES := [0.0, 18.0, -18.0, 36.0, -36.0, 54.0, -54.0, 72.0, -72.0, 95.0, -95.0, 125.0, -125.0]

const AVOID_DETECT_RADIUS := 5.0
const AVOID_CORRIDOR_RADIUS := 3.2
const AVOID_CORRIDOR_AHEAD := 7.0
const AVOID_BEHIND_TOLERANCE := 1.0
const AVOID_TIME_HORIZON := 1.6
const AVOID_ALONG_CLOSING := 0.35
const AVOID_LATERAL_CLOSING := 0.22
const AVOID_ANTICIPATION_FLOOR := 0.5
const AVOID_HEADON_CLOSING := 1.0
const AVOID_HEADON_LATERAL := 1.3
const AVOID_HEADON_MIN_SPEED := 0.5
const AVOID_BRAKE_REACH := 1.5
const AVOID_SIDE_EPSILON := 0.15
const AVOID_SIDE_BONUS := 0.35
const AVOID_LATERAL_GAIN := 1.25
const AVOID_BRAKE_GAIN := 0.85
const AVOID_YIELD_COMMIT := 1.2
const AVOID_ATTACK_RATE := 9.0
const AVOID_RETURN_RATE := 2.8
const AVOID_MAX_OFFSET := 0.9
const AVOID_BLOCKED_MAX_SPEED := 0.35
const AVOID_BLOCK_PASS_LATERAL := 1.9
const AVOID_BLOCK_PASS_MIN_AHEAD := 2.0

const PATH_LOOK_AHEAD := 3.2
const PATH_WAYPOINT_REACHED := 0.7
const PATH_OFF_ROUTE := 2.0
const PATH_BLOCKED_TIME := 0.6
const PATH_REPLAN_COOLDOWN := 0.4
const PATH_MAX_REPLANS := 5

const BLOCKED_REPLAN_TIME := 2.0
const BLOCKED_REPLAN_PROGRESS := 0.5
const BLOCKED_REPLAN_COOLDOWN := 1.2
const BLOCKED_MAX_ATTEMPTS := 3

const UNSTUCK_DISTANCE := 0.7
const UNSTUCK_DURATION := 0.4
const UNSTUCK_SPEED := 1.75
const UNSTUCK_COOLDOWN := 1.5
const UNSTUCK_MAX_ATTEMPTS := 2

const STALL_TIME := 6.0
const STALL_PROGRESS := 0.35

static var _avoid_rank_counter := 0

var _target_position := Vector3.ZERO
var _has_order := false
var _selected := false
var _blocked_time := 0.0
var _closest_distance := 0.0
var _stall_time := 0.0
var _avoid_direction := Vector2.ZERO
var _avoid_side := 1.0
var _path := PackedVector3Array()
var _path_index := 0
var _blocked_path_time := 0.0
var _replan_count := 0
var _replan_cooldown := 0.0
var _blocked_replan_time := 0.0
var _blocked_replan_anchor := 0.0
var _blocked_replan_cooldown := 0.0
var _blocked_replan_attempts := 0
var _unstuck_active := false
var _unstuck_time := 0.0
var _unstuck_origin := Vector3.ZERO
var _unstuck_direction := Vector3.ZERO
var _unstuck_cooldown := 0.0
var _unstuck_attempts := 0
var _avoid_offset := Vector2.ZERO
var _yield_side := 0.0
var _yield_timer := 0.0
var _avoid_rank := 0
var _conflict_other: Unit
var _conflict_offset := Vector2.ZERO
var _conflict_closing := Vector2.ZERO
var _conflict_time := 0.0
var _conflict_lateral := 0.0
var _conflict_along := 0.0
var _conflict_along_rate := 0.0
var _conflict_lateral_rate := 0.0
var _conflict_moving := false
var _current_health := -1.0
var _selection_ring: Node3D
var _vision_ring: VisionRing


func _ready() -> void:
	_avoid_rank = _avoid_rank_counter
	_avoid_rank_counter += 1
	_configure_collision()
	add_to_group("units")
	_current_health = get_max_health()
	_build_collider()
	_build_model()
	_build_running_gear()
	_build_selection_ring()
	_build_vision_ring()


func _configure_collision() -> void:
	collision_layer = MapConfig.LAYER_UNITS
	collision_mask = MapConfig.LAYER_TERRAIN | MapConfig.LAYER_WATER | MapConfig.LAYER_UNITS


func _physics_process(delta: float) -> void:
	_animate_running_gear(delta)
	if not _has_order:
		velocity = Vector3.ZERO
		return

	var to_target := _target_position - global_position
	to_target.y = 0.0
	var distance_to_target := to_target.length()
	if distance_to_target <= ARRIVE_DISTANCE:
		_complete_order()
		return

	var desired_2d := Vector2(to_target.x, to_target.z).normalized()
	var steer_2d := _compute_steer_direction(desired_2d, delta, distance_to_target)
	var direction := Vector3(steer_2d.x, 0.0, steer_2d.y)

	var position_before := global_position
	var speed := get_move_speed()
	var facing := direction
	if _unstuck_active:
		direction = _unstuck_direction
		speed = UNSTUCK_SPEED
	velocity = direction * speed
	move_and_slide()
	global_position.y = MapConfig.GROUND_TOP_Y
	_face_direction(facing, delta)
	_update_unstuck(delta)
	_update_navigation(delta)
	_update_progress(distance_to_target, position_before, speed, delta)
	_update_blocked_replan(delta)


func _compute_steer_direction(desired_2d: Vector2, delta: float, distance_to_target: float) -> Vector2:
	var route_2d := _path_steer_direction(desired_2d)
	var route_2d_avoiding := _compute_avoidance_steer(route_2d, delta)
	var arrival_fade := clampf(distance_to_target / AVOID_SEPARATION_RADIUS, 0.0, 1.0)
	var separation := _separation_vector() * AVOID_SEPARATION_STRENGTH * arrival_fade
	var blended := route_2d_avoiding + separation
	if blended.length_squared() > 0.0001:
		blended = blended.normalized()
	var chosen := blended
	if _blocked_time > 0.0:
		chosen = _choose_clear_direction(blended)
	_avoid_direction = _turn_towards(_avoid_direction, chosen, AVOID_TURN_RATE * delta)
	return _avoid_direction


func _compute_avoidance_steer(route_2d: Vector2, delta: float) -> Vector2:
	var solution := _solve_dynamic_avoidance(route_2d, delta)
	var rate := AVOID_RETURN_RATE if _conflict_other == null else AVOID_ATTACK_RATE
	var weight := clampf(rate * delta, 0.0, 1.0)
	_avoid_offset = _avoid_offset.lerp(solution, weight)
	if _avoid_offset.length() > AVOID_MAX_OFFSET:
		_avoid_offset = _avoid_offset.normalized() * AVOID_MAX_OFFSET
	var blended := route_2d + _avoid_offset
	if blended.length_squared() < 0.0001:
		return route_2d
	return blended.normalized()


func _solve_dynamic_avoidance(route_2d: Vector2, delta: float) -> Vector2:
	if not _detect_path_conflict(route_2d):
		_yield_timer = 0.0
		_yield_side = 0.0
		_conflict_other = null
		return Vector2.ZERO

	_yield_timer += delta
	var head_on := _is_head_on()
	var yielding := _should_yield_to(_conflict_other)
	var side := _choose_avoidance_side(_predicted_dodge_side(route_2d), route_2d)
	if _yield_timer < AVOID_YIELD_COMMIT or is_zero_approx(_yield_side):
		_yield_side = side
	if not is_zero_approx(_yield_side):
		side = _yield_side

	var proximity := clampf(1.0 - _conflict_lateral / AVOID_CORRIDOR_RADIUS, 0.0, 1.0)
	var imminence := 1.0 - clampf(_conflict_time / AVOID_TIME_HORIZON, 0.0, 1.0)
	var urgency := proximity * lerpf(AVOID_ANTICIPATION_FLOOR, 1.0, imminence)
	var holds_line := head_on and not yielding
	var solution := Vector2.ZERO
	if not holds_line:
		solution = route_2d.orthogonal() * side * AVOID_LATERAL_GAIN * urgency
	var bypass := _blocked_unit_bypass(route_2d, side)
	if bypass.length_squared() > 0.0:
		return bypass
	var closing_ratio := _closing_ratio()
	if closing_ratio > 0.0:
		var brake_reach := clampf(_conflict_along / AVOID_BRAKE_REACH, 0.0, 1.0)
		solution -= route_2d * closing_ratio * AVOID_BRAKE_GAIN * brake_reach
	return solution


func _blocked_unit_bypass(route_2d: Vector2, side: float) -> Vector2:
	if _conflict_other == null:
		return Vector2.ZERO
	var blocker_speed := Vector2(_conflict_other.velocity.x, _conflict_other.velocity.z).length()
	if blocker_speed > AVOID_BLOCKED_MAX_SPEED:
		return Vector2.ZERO
	var ahead := _conflict_offset.dot(route_2d)
	if ahead < AVOID_BLOCK_PASS_MIN_AHEAD or ahead > AVOID_CORRIDOR_AHEAD:
		return Vector2.ZERO
	var perpendicular := route_2d.orthogonal()
	if absf(_conflict_offset.dot(perpendicular)) > AVOID_BLOCK_PASS_LATERAL:
		return Vector2.ZERO
	if _probe_clearance(perpendicular * side) <= 0.0:
		return Vector2.ZERO
	return perpendicular * side * AVOID_MAX_OFFSET


func _detect_path_conflict(route_2d: Vector2) -> bool:
	_conflict_other = null
	if route_2d.length_squared() < 0.0001:
		return false
	var best_score := 0.0
	var speed_reference := maxf(0.5, get_move_speed())
	for node in get_tree().get_nodes_in_group("units"):
		var other := node as Unit
		if other == null or other == self:
			continue
		var offset := Vector2(
			other.global_position.x - global_position.x,
			other.global_position.z - global_position.z
		)
		if offset.length() > AVOID_DETECT_RADIUS:
			continue
		var closing_velocity := Vector2(
			other.velocity.x - velocity.x,
			other.velocity.z - velocity.z
		)
		var time_to_closest := 0.0
		var closing_squared := closing_velocity.length_squared()
		if closing_squared > 0.0001:
			time_to_closest = clampf(
				-offset.dot(closing_velocity) / closing_squared,
				0.0,
				AVOID_TIME_HORIZON
			)
		var approach := offset + closing_velocity * time_to_closest
		var along := approach.dot(route_2d)
		if along < -AVOID_BEHIND_TOLERANCE or along > AVOID_CORRIDOR_AHEAD:
			continue
		var lateral_vector := approach - route_2d * along
		var lateral := lateral_vector.length()
		if lateral > AVOID_CORRIDOR_RADIUS:
			continue
		var along_rate := -closing_velocity.dot(route_2d)
		var lateral_rate := along_rate
		if lateral > 0.001:
			lateral_rate = -closing_velocity.dot(lateral_vector / lateral)
		var on_line := 1.0 - clampf(lateral / AVOID_CORRIDOR_RADIUS, 0.0, 1.0)
		var required_rate := lerpf(AVOID_LATERAL_CLOSING, AVOID_ALONG_CLOSING, on_line)
		if maxf(along_rate, lateral_rate) < required_rate:
			continue
		var closing_ratio := clampf(maxf(along_rate, lateral_rate) / speed_reference, 0.0, 1.0)
		var score := (1.0 - lateral / AVOID_CORRIDOR_RADIUS) * (0.35 + 0.65 * closing_ratio)
		if score <= best_score:
			continue
		best_score = score
		_conflict_other = other
		_conflict_offset = offset
		_conflict_closing = closing_velocity
		_conflict_time = time_to_closest
		_conflict_lateral = lateral
		_conflict_along = along
		_conflict_along_rate = along_rate
		_conflict_lateral_rate = lateral_rate
		_conflict_moving = Vector2(other.velocity.x, other.velocity.z).length() > AVOID_HEADON_MIN_SPEED
	return _conflict_other != null


func _closing_rate() -> float:
	return maxf(_conflict_along_rate, _conflict_lateral_rate)


func _closing_ratio() -> float:
	return clampf(_closing_rate() / maxf(0.5, get_move_speed()), 0.0, 1.0)


func _is_head_on() -> bool:
	if not _conflict_moving:
		return false
	if _conflict_lateral > AVOID_HEADON_LATERAL:
		return false
	if _conflict_along < 0.0:
		return false
	return _conflict_along_rate > AVOID_HEADON_CLOSING


func _should_yield_to(other: Unit) -> bool:
	if other == null:
		return false
	return _avoid_rank > other.get_avoid_rank()


func _predicted_dodge_side(route_2d: Vector2) -> float:
	var predicted := _conflict_offset + _conflict_closing * _conflict_time
	var lateral := predicted - route_2d * predicted.dot(route_2d)
	if lateral.length() < AVOID_SIDE_EPSILON:
		return 0.0
	return -signf(lateral.dot(route_2d.orthogonal()))


func _choose_avoidance_side(preference: float, route_2d: Vector2) -> float:
	var perpendicular := route_2d.orthogonal()
	var plus_score := _probe_clearance(perpendicular) + AVOID_SIDE_BONUS * maxf(0.0, preference)
	var minus_score := _probe_clearance(-perpendicular) + AVOID_SIDE_BONUS * maxf(0.0, -preference)
	if is_equal_approx(plus_score, minus_score):
		if is_zero_approx(preference):
			return 1.0 if _avoid_rank % 2 == 0 else -1.0
		return preference
	return 1.0 if plus_score > minus_score else -1.0


func get_avoid_rank() -> int:
	return _avoid_rank


func _reset_avoidance() -> void:
	_avoid_offset = Vector2.ZERO
	_yield_side = 0.0
	_yield_timer = 0.0
	_conflict_other = null


func _path_steer_direction(desired_2d: Vector2) -> Vector2:
	if _path.is_empty():
		return desired_2d
	_advance_path_index()
	if _path_index < 0 or _path_index >= _path.size():
		return desired_2d

	var origin := _flat_position(global_position)
	var aim := _flat_position(_path[_path_index])
	var previous := origin
	var accumulated := 0.0
	for offset in range(_path_index, _path.size()):
		var point := _flat_position(_path[offset])
		accumulated += previous.distance_to(point)
		if accumulated > PATH_LOOK_AHEAD:
			break
		if _has_clear_line(point):
			aim = point
		previous = point

	var steer := Vector2(aim.x - origin.x, aim.z - origin.z)
	if steer.length_squared() < 0.0001:
		return desired_2d
	return steer.normalized()


func _advance_path_index() -> void:
	while _path_index < _path.size() - 1:
		if _offset_to(_path[_path_index]).length() > PATH_WAYPOINT_REACHED:
			return
		_path_index += 1


func _has_clear_line(world_point: Vector3) -> bool:
	var origin := global_position
	origin.y = MapConfig.GROUND_TOP_Y + AVOID_PROBE_HEIGHT
	var target := world_point
	target.y = MapConfig.GROUND_TOP_Y + AVOID_PROBE_HEIGHT
	var exclude: Array[RID] = [get_rid()]
	var query := PhysicsRayQueryParameters3D.create(origin, target, MapConfig.PICK_MASK, exclude)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _route_deviation() -> float:
	if _path.is_empty():
		return INF
	var origin := _flat_position(global_position)
	var first := clampi(_path_index - 1, 0, _path.size() - 1)
	var from_point := _flat_position(_path[first])
	var best := origin.distance_to(from_point)
	for offset in range(first + 1, _path.size()):
		var point := _flat_position(_path[offset])
		best = minf(best, _distance_to_segment(origin, from_point, point))
		from_point = point
	return best


func _distance_to_segment(point: Vector3, from_point: Vector3, to_point: Vector3) -> float:
	var segment := to_point - from_point
	var length_squared := segment.length_squared()
	if length_squared < 0.0001:
		return point.distance_to(from_point)
	var ratio := clampf((point - from_point).dot(segment) / length_squared, 0.0, 1.0)
	return point.distance_to(from_point + segment * ratio)


func _update_navigation(delta: float) -> void:
	if _path.is_empty():
		return
	_replan_cooldown = maxf(0.0, _replan_cooldown - delta)
	if _replan_cooldown > 0.0 or _path_index >= _path.size():
		return
	if _replan_count >= PATH_MAX_REPLANS:
		return
	if _route_deviation() > PATH_OFF_ROUTE:
		_try_replan()
		return
	if _blocked_time > 0.0 or not _has_clear_line(_path[_path_index]):
		_blocked_path_time += delta
		if _blocked_path_time >= PATH_BLOCKED_TIME:
			_try_replan()
	else:
		_blocked_path_time = 0.0


func _try_replan() -> bool:
	if _replan_count >= PATH_MAX_REPLANS:
		return false
	_replan_count += 1
	var replanned := NavGrid.get_shared().find_path(global_position, _target_position)
	if replanned.is_empty():
		return false
	_path = replanned
	_path_index = 0
	_blocked_time = 0.0
	_blocked_path_time = 0.0
	_replan_cooldown = PATH_REPLAN_COOLDOWN
	_reset_avoidance()
	return true


func _update_blocked_replan(delta: float) -> void:
	if _blocked_replan_cooldown > 0.0:
		_blocked_replan_cooldown = maxf(0.0, _blocked_replan_cooldown - delta)
	var to_target := _target_position - global_position
	to_target.y = 0.0
	var remaining := to_target.length()
	if _blocked_replan_time <= 0.0:
		_blocked_replan_anchor = remaining
	if remaining < _blocked_replan_anchor - BLOCKED_REPLAN_PROGRESS:
		_blocked_replan_anchor = remaining
		_blocked_replan_time = 0.0
		_blocked_replan_attempts = 0
		return
	if _blocked_time <= 0.0:
		_blocked_replan_time = 0.0
		_blocked_replan_attempts = 0
		return
	_blocked_replan_time += delta
	if _blocked_replan_time < BLOCKED_REPLAN_TIME:
		return
	if _replan_cooldown > 0.0 or _blocked_replan_cooldown > 0.0:
		return
	if _start_unstuck():
		return
	if _blocked_replan_attempts >= BLOCKED_MAX_ATTEMPTS:
		return
	_blocked_replan_attempts += 1
	_blocked_replan_time = 0.0
	_blocked_replan_cooldown = BLOCKED_REPLAN_COOLDOWN
	if _replan_count >= PATH_MAX_REPLANS:
		return
	if not _try_replan():
		_fail_order()


func _start_unstuck() -> bool:
	if _unstuck_active:
		return false
	if _unstuck_attempts >= UNSTUCK_MAX_ATTEMPTS or _unstuck_cooldown > 0.0:
		return false
	var forward := _avoid_direction
	if forward.length_squared() < 0.0001:
		forward = Vector2(_target_position.x - global_position.x, _target_position.z - global_position.z)
		if forward.length_squared() < 0.0001:
			return false
	forward = forward.normalized()
	_unstuck_direction = Vector3(-forward.x, 0.0, -forward.y)
	_unstuck_origin = global_position
	_unstuck_time = 0.0
	_unstuck_active = true
	_unstuck_attempts += 1
	_unstuck_cooldown = UNSTUCK_COOLDOWN
	_blocked_time = 0.0
	_blocked_replan_time = 0.0
	return true


func _update_unstuck(delta: float) -> void:
	if _unstuck_cooldown > 0.0:
		_unstuck_cooldown = maxf(0.0, _unstuck_cooldown - delta)
	if not _unstuck_active:
		return
	_unstuck_time += delta
	var travelled := _unstuck_origin.distance_to(global_position)
	if _unstuck_time >= UNSTUCK_DURATION or travelled >= UNSTUCK_DISTANCE:
		_finish_unstuck()


func _finish_unstuck() -> void:
	_unstuck_active = false
	_unstuck_time = 0.0
	_blocked_time = 0.0
	_blocked_replan_time = 0.0
	_reset_avoidance()


func _reset_navigation_state() -> void:
	_blocked_time = 0.0
	_blocked_path_time = 0.0
	_replan_count = 0
	_replan_cooldown = 0.0
	_closest_distance = 0.0
	_stall_time = 0.0
	_blocked_replan_time = 0.0
	_blocked_replan_anchor = 0.0
	_blocked_replan_cooldown = 0.0
	_blocked_replan_attempts = 0
	_unstuck_active = false
	_unstuck_time = 0.0
	_unstuck_origin = Vector3.ZERO
	_unstuck_direction = Vector3.ZERO
	_unstuck_cooldown = 0.0
	_unstuck_attempts = 0


func _clear_path() -> void:
	_path.clear()
	_path_index = 0


func _flat_position(world_point: Vector3) -> Vector3:
	return Vector3(world_point.x, MapConfig.GROUND_TOP_Y, world_point.z)


func _offset_to(world_point: Vector3) -> Vector3:
	var offset := world_point - global_position
	offset.y = 0.0
	return offset


func _choose_clear_direction(desired_2d: Vector2) -> Vector2:
	var best_direction := desired_2d
	var best_clearance := -1.0
	var best_alignment := -INF
	var best_angle := 0.0
	for entry in AVOID_ANGLES:
		var signed_angle: float = entry * _avoid_side
		var candidate := desired_2d.rotated(deg_to_rad(signed_angle))
		var alignment := candidate.dot(desired_2d) * AVOID_ALIGNMENT_WEIGHT
		var clearance := _probe_clearance(candidate) * AVOID_CLEARANCE_WEIGHT
		var is_better := clearance > best_clearance
		if is_equal_approx(clearance, best_clearance):
			is_better = alignment > best_alignment
		if is_better:
			best_clearance = clearance
			best_alignment = alignment
			best_direction = candidate
			best_angle = signed_angle
	if not is_zero_approx(best_angle):
		_avoid_side = signf(best_angle)
	return best_direction


func _probe_clearance(direction_2d: Vector2) -> float:
	var step := Vector3(direction_2d.x, 0.0, direction_2d.y)
	var origin := global_position + step * AVOID_PROBE_ORIGIN
	origin.y = MapConfig.GROUND_TOP_Y + AVOID_PROBE_HEIGHT
	var exclude: Array[RID] = [get_rid()]
	var query := PhysicsRayQueryParameters3D.create(
		origin,
		origin + step * AVOID_PROBE_DISTANCE,
		MapConfig.PICK_MASK,
		exclude
	)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return 1.0
	var hit_distance := origin.distance_to(hit["position"])
	return clampf((hit_distance - AVOID_MIN_CLEARANCE) / AVOID_PROBE_DISTANCE, 0.0, 1.0)


func _separation_vector() -> Vector2:
	var push := Vector2.ZERO
	var origin := global_position
	for node in get_tree().get_nodes_in_group("units"):
		var other := node as Unit
		if other == null or other == self:
			continue
		var away := Vector2(origin.x - other.global_position.x, origin.z - other.global_position.z)
		var distance := away.length()
		if distance >= AVOID_SEPARATION_RADIUS:
			continue
		if distance < 0.001:
			push += Vector2(1.0, 0.0)
		else:
			push += away / distance * (1.0 - distance / AVOID_SEPARATION_RADIUS)
	return push


func _turn_towards(current: Vector2, target: Vector2, max_radians: float) -> Vector2:
	if current.length_squared() < 0.0001:
		return target
	var difference := wrapf(target.angle() - current.angle(), -PI, PI)
	return current.rotated(clampf(difference, -max_radians, max_radians))


func _update_progress(distance_to_target: float, position_before: Vector3, speed: float, delta: float) -> void:
	var travelled := position_before.distance_to(global_position)
	if travelled < speed * delta * MIN_PROGRESS_RATIO:
		_blocked_time += delta
	else:
		_blocked_time = 0.0

	if distance_to_target < _closest_distance - STALL_PROGRESS:
		_closest_distance = distance_to_target
		_stall_time = 0.0
		return
	_stall_time += delta
	if _stall_time >= STALL_TIME:
		_fail_order()


func is_selected() -> bool:
	return _selected


func set_selected(value: bool) -> void:
	_selected = value
	if _selection_ring != null:
		_selection_ring.visible = value
	if _vision_ring != null:
		_vision_ring.visible = value


func get_move_speed() -> float:
	return 4.5


func get_max_health() -> float:
	return 100.0


func get_vision_radius() -> float:
	return 9.5


func get_display_name() -> String:
	return "Unit"


func get_role_text() -> String:
	return ""


func get_health() -> Vector2:
	return Vector2(_current_health, get_max_health())


func get_health_ratio() -> float:
	var maximum := get_max_health()
	if maximum <= 0.0:
		return 0.0
	return clampf(_current_health / maximum, 0.0, 1.0)


func has_move_order() -> bool:
	return _has_order


func get_move_target() -> Vector3:
	return _target_position


func issue_move_order(world_position: Vector3) -> void:
	var target := MapConfig.resolve_target(world_position)
	if not MapConfig.is_walkable(target):
		move_order_failed.emit()
		return
	var path := NavGrid.get_shared().find_path(global_position, target)
	if path.is_empty():
		move_order_failed.emit()
		return
	_target_position = target
	_path = path
	_path_index = 0
	_reset_navigation_state()
	_closest_distance = target.distance_to(global_position)
	_avoid_direction = Vector2.ZERO
	_reset_avoidance()
	_has_order = true


func cancel_move_order() -> void:
	if not _has_order:
		return
	_has_order = false
	_clear_path()
	_reset_navigation_state()
	_reset_avoidance()
	velocity = Vector3.ZERO
	move_order_cancelled.emit()


func _build_collider() -> void:
	pass


func _build_model() -> void:
	pass


func _build_running_gear() -> void:
	pass


func _animate_running_gear(_delta: float) -> void:
	pass


func _build_selection_ring() -> void:
	_selection_ring = Node3D.new()
	_selection_ring.name = "SelectionRing"
	_selection_ring.position = Vector3(0.0, RING_HEIGHT, 0.0)
	_selection_ring.visible = false
	add_child(_selection_ring)

	for index in RING_SEGMENTS:
		var angle := TAU * float(index) / float(RING_SEGMENTS)
		var segment_position := Vector3(cos(angle) * RING_RADIUS, 0.0, sin(angle) * RING_RADIUS)
		MeshFactory.add_box(
			_selection_ring,
			"Segment%d" % (index + 1),
			segment_position,
			RING_SEGMENT_SIZE,
			SELECTION_COLOR,
			true,
			0.9
		)


func _build_vision_ring() -> void:
	_vision_ring = VisionRing.new()
	_vision_ring.name = "VisionRing"
	_vision_ring.setup(get_vision_radius())
	_vision_ring.visible = false
	add_child(_vision_ring)


func _face_direction(direction: Vector3, delta: float) -> void:
	var desired_yaw := atan2(-direction.x, -direction.z)
	rotation.y = lerp_angle(rotation.y, desired_yaw, minf(1.0, TURN_SPEED * delta))


func _complete_order() -> void:
	_has_order = false
	_clear_path()
	_reset_navigation_state()
	_reset_avoidance()
	velocity = Vector3.ZERO
	_avoid_direction = Vector2.ZERO
	move_order_completed.emit()


func _fail_order() -> void:
	_has_order = false
	_clear_path()
	_reset_navigation_state()
	_reset_avoidance()
	velocity = Vector3.ZERO
	_avoid_direction = Vector2.ZERO
	move_order_failed.emit()