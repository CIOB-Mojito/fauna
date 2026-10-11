extends Node3D

const SELECT_RADIUS := 2.6
const HINT_FADE_DELAY := 12.0
const HINT_FADE_DURATION := 1.5
const GROUP_SPACING := 3.4
const FORMATION_SEARCH_RADIUS := 4.0
const FORMATION_SEARCH_STEP := 0.5
const FORMATION_PROBE_COUNT := 8
const BOX_MIN_SIZE := 8.0
const DOUBLE_TAP_MS := 320
const DOUBLE_TAP_RADIUS := 5.0

@onready var camera: TacticalCamera = $TacticalCamera
@onready var vehicle: CommandVehicle = $CommandVehicle
@onready var marker: MoveOrderMarker = $MoveOrderMarker
@onready var touch_input: TouchInput = $TouchInput
@onready var hint: Label = $HUD/Hint
@onready var minimap: TacticalMinimap = $HUD/Minimap
@onready var unit_panel: UnitPanel = $HUD/UnitPanel
@onready var group_panel: GroupPanel = $HUD/GroupPanel
@onready var selection_box: SelectionBox = $HUD/SelectionBox
@onready var command_panel: CommandPanel = $HUD/CommandPanel

var _selected_unit: Unit
var _selected_units: Array[Unit] = []
var _multi_select := false
var _group_target := Vector3.ZERO
var _extra_markers: Dictionary = {}
var _marker_serial := 0
var _box_preview_area := Rect2()
var _box_preview_active := false
var _box_preview_units: Array[Unit] = []
var _box_preview_rings: Dictionary = {}
var _box_preview_serial := 0
var _health_bars: Dictionary = {}
var _health_bar_serial := 0
var _pending_unit: Unit = null
var _last_unit_tap_unit: Unit = null
var _last_unit_tap_msec := 0


func _ready() -> void:
	touch_input.tap.connect(_on_tap)
	touch_input.long_press.connect(_on_long_press)
	touch_input.box_candidate.connect(_on_box_candidate)
	touch_input.box_updated.connect(_on_box_updated)
	touch_input.box_ended.connect(_on_box_ended)
	touch_input.box_cancelled.connect(_on_box_cancelled)
	touch_input.pan_moved.connect(camera.pan_by_screen)
	touch_input.pinch_zoomed.connect(camera.zoom_by_screen)
	touch_input.twist_rotated.connect(camera.rotate_horizontal)
	for node in get_tree().get_nodes_in_group("units"):
		_connect_unit(node as Unit)
	command_panel.stop_pressed.connect(_on_command_stop)
	minimap.setup(vehicle, camera)
	camera.set_focus(vehicle.global_position)
	_fade_hint()


func _process(_delta: float) -> void:
	_update_pending_unit_tap()
	if _box_preview_active:
		_set_box_preview(_box_preview_candidates())
	_refresh_health_bars()


func _update_pending_unit_tap() -> void:
	if _pending_unit == null:
		return
	if not is_instance_valid(_pending_unit):
		_pending_unit = null
		return
	if Time.get_ticks_msec() - _last_unit_tap_msec > DOUBLE_TAP_MS:
		_commit_pending_unit_tap()


func _refresh_health_bars() -> void:
	var hosts := _selected_visual_units()
	for unit in hosts:
		if not is_instance_valid(unit) or not unit.is_inside_tree():
			_free_health_bar_key(unit)
			continue
		var health_bar := _health_bar_for(unit)
		health_bar.global_position = unit.global_position + Vector3(0.0, SelectionHealthBar.HEIGHT_OVER_UNIT, 0.0)
		health_bar.face_camera(camera.global_position)
		health_bar.set_ratio(unit.get_health_ratio())
	for key in _health_bars.keys():
		if not hosts.has(key):
			_free_health_bar_key(key)


func _health_bar_for(unit: Unit) -> SelectionHealthBar:
	var found: SelectionHealthBar = _health_bars.get(unit, null)
	if found != null:
		return found
	found = SelectionHealthBar.new()
	found.name = "HealthBar%d" % _health_bar_serial
	_health_bar_serial += 1
	add_child(found)
	_health_bars[unit] = found
	return found


func _free_health_bar_key(key: Variant) -> void:
	var stale: SelectionHealthBar = _health_bars.get(key, null)
	_health_bars.erase(key)
	if stale != null and is_instance_valid(stale):
		stale.queue_free()


func _connect_unit(unit: Unit) -> void:
	if unit == null:
		return
	unit.move_order_completed.connect(_on_move_order_completed)
	unit.move_order_failed.connect(_on_move_order_failed)
	unit.move_order_cancelled.connect(_on_move_order_cancelled)


func _on_tap(screen_position: Vector2) -> void:
	var ground_point: Variant = camera.screen_to_ground(screen_position)
	var pick := _pick(screen_position)
	var tapped_unit: Unit = null
	if not pick.is_empty() and pick["collider"] is Unit:
		tapped_unit = pick["collider"]
	elif ground_point != null:
		var ground_position: Vector3 = ground_point
		tapped_unit = _find_unit_at(ground_position)

	if tapped_unit != null:
		_handle_unit_tap(tapped_unit)
		return

	_commit_pending_unit_tap()

	if _selected_unit == null:
		return

	var order_point: Variant = pick["position"] if not pick.is_empty() else ground_point
	if order_point == null:
		return
	var order_position: Vector3 = order_point
	_issue_move_order(order_position)


func _handle_unit_tap(unit: Unit) -> void:
	var now := Time.get_ticks_msec()
	if _pending_unit != null and _pending_unit != unit:
		_commit_pending_unit_tap()
	if unit == _last_unit_tap_unit and now - _last_unit_tap_msec <= DOUBLE_TAP_MS:
		_cancel_pending_unit_tap()
		_double_tap_unit(unit)
		return
	_pending_unit = unit
	_last_unit_tap_unit = unit
	_last_unit_tap_msec = now


func _commit_pending_unit_tap() -> void:
	var unit := _pending_unit
	_pending_unit = null
	if unit != null and is_instance_valid(unit):
		_toggle_selection(unit)


func _cancel_pending_unit_tap() -> void:
	_pending_unit = null
	_last_unit_tap_unit = null
	_last_unit_tap_msec = 0


func _double_tap_unit(unit: Unit) -> void:
	if unit == null or not is_instance_valid(unit):
		return
	var nearby := _units_within_radius(unit.global_position, DOUBLE_TAP_RADIUS)
	if nearby.size() < 2:
		_select(unit)
		return
	_deselect()
	_add_group_member(unit)
	for other in nearby:
		if other != unit:
			_add_group_member(other)
	_multi_select = true
	_selected_unit = unit
	_refresh_hud()
	_refresh_move_marker()


func _units_within_radius(center: Vector3, radius: float) -> Array[Unit]:
	var found: Array[Unit] = []
	for node in get_tree().get_nodes_in_group("units"):
		var unit := node as Unit
		if unit == null:
			continue
		if unit.global_position.distance_to(center) <= radius:
			found.append(unit)
	found.sort_custom(_sort_units_for_selection)
	return found


func _find_unit_at(world_position: Vector3) -> Unit:
	var found: Unit
	var best_distance := SELECT_RADIUS
	for node in get_tree().get_nodes_in_group("units"):
		var unit := node as Unit
		if unit == null:
			continue
		var distance := world_position.distance_to(unit.global_position)
		if distance <= best_distance:
			best_distance = distance
			found = unit
	return found


func _issue_move_order(world_position: Vector3) -> void:
	if _selected_units.size() >= 2:
		_issue_group_move_order(world_position)
		return
	var target := MapConfig.resolve_target(world_position)
	_selected_unit.issue_move_order(target)
	_refresh_move_marker()


func _issue_group_move_order(world_position: Vector3) -> void:
	_group_target = MapConfig.resolve_target(world_position)
	var forward := _formation_forward(_group_target)
	var lateral := Vector3(-forward.z, 0.0, forward.x)
	var ordered := _order_by_lateral(lateral, _group_target)
	var count := ordered.size()
	for index in count:
		var offset := (float(index) - (float(count) - 1.0) * 0.5) * GROUP_SPACING
		var slot := _resolve_formation_slot(_group_target + lateral * offset, _group_target)
		ordered[index].issue_move_order(slot)
	_refresh_move_marker()


func _formation_forward(group_target: Vector3) -> Vector3:
	var forward := group_target - _formation_center()
	forward.y = 0.0
	if forward.length_squared() < 0.0001:
		return Vector3(0.0, 0.0, 1.0)
	return forward.normalized()


func _formation_center() -> Vector3:
	var center := Vector3.ZERO
	var count := 0
	for unit in _selected_units:
		if unit == null:
			continue
		center += unit.global_position
		count += 1
	if count == 0:
		return _group_target
	return center / float(count)


func _order_by_lateral(lateral: Vector3, group_target: Vector3) -> Array[Unit]:
	var ordered: Array[Unit] = []
	for unit in _selected_units:
		if unit == null:
			continue
		var projection := lateral.dot(unit.global_position - group_target)
		var slot := ordered.size()
		for index in ordered.size():
			if projection < lateral.dot(ordered[index].global_position - group_target):
				slot = index
				break
		ordered.insert(slot, unit)
	return ordered


func _resolve_formation_slot(desired: Vector3, group_target: Vector3) -> Vector3:
	var nav := NavGrid.get_shared()
	if nav.has_clearance(desired):
		return desired
	var radius := FORMATION_SEARCH_STEP
	while radius <= FORMATION_SEARCH_RADIUS:
		for probe_index in FORMATION_PROBE_COUNT:
			var angle := TAU * float(probe_index) / float(FORMATION_PROBE_COUNT)
			var probe := desired + Vector3(cos(angle), 0.0, sin(angle)) * radius
			if nav.has_clearance(probe):
				return probe
		radius += FORMATION_SEARCH_STEP
	return group_target


func _select(unit: Unit) -> void:
	if _selected_unit != unit:
		_deselect()
		_selected_unit = unit
		_selected_unit.set_selected(true)
	_refresh_hud()
	_refresh_move_marker()


func _deselect() -> void:
	if _selected_unit != null:
		_selected_unit.set_selected(false)
	_selected_unit = null
	_clear_group()
	_refresh_hud()
	_refresh_move_marker()


func _on_long_press(screen_position: Vector2) -> void:
	_cancel_pending_unit_tap()
	if not _is_empty_ground(screen_position):
		return
	if _selected_unit == null and _selected_units.is_empty():
		return
	_deselect()


func _on_box_candidate(screen_position: Vector2) -> void:
	touch_input.arm_selection_box(_is_empty_ground(screen_position))


func _on_box_updated(from_screen: Vector2, to_screen: Vector2) -> void:
	selection_box.show_box(from_screen, to_screen)
	_start_box_preview(from_screen, to_screen)


func _on_box_ended(from_screen: Vector2, to_screen: Vector2) -> void:
	var box_size := (to_screen - from_screen).abs()
	if box_size.x < BOX_MIN_SIZE or box_size.y < BOX_MIN_SIZE:
		_on_box_cancelled()
		return
	var area := _box_ground_area(from_screen, to_screen)
	selection_box.hide_box()
	_clear_box_preview()
	if area.size.length_squared() < 0.0001:
		return
	_apply_box_selection(_units_in_area(area))


func _on_box_cancelled() -> void:
	selection_box.hide_box()
	_clear_box_preview()


func _start_box_preview(from_screen: Vector2, to_screen: Vector2) -> void:
	_box_preview_active = true
	_box_preview_area = _box_ground_area(from_screen, to_screen)
	_set_box_preview(_box_preview_candidates())


func _box_preview_candidates() -> Array[Unit]:
	if _box_preview_area.size.length_squared() < 0.0001:
		return []
	return _units_in_area(_box_preview_area)


func _set_box_preview(units: Array[Unit]) -> void:
	for unit in _box_preview_units.duplicate():
		if not units.has(unit):
			_release_box_preview(unit)
	for unit in units:
		if not _box_preview_units.has(unit):
			_box_preview_units.append(unit)
		var preview_ring := _box_preview_ring(unit)
		preview_ring.global_position = unit.global_position
		preview_ring.visible = true


func _box_preview_ring(unit: Unit) -> SelectionPreviewRing:
	var found: SelectionPreviewRing = _box_preview_rings.get(unit, null)
	if found != null:
		return found
	found = SelectionPreviewRing.new()
	found.name = "BoxPreview%d" % _box_preview_serial
	_box_preview_serial += 1
	found.visible = false
	add_child(found)
	_box_preview_rings[unit] = found
	return found


func _release_box_preview(unit: Unit) -> void:
	_box_preview_units.erase(unit)
	var preview_ring: SelectionPreviewRing = _box_preview_rings.get(unit, null)
	_box_preview_rings.erase(unit)
	if preview_ring != null and is_instance_valid(preview_ring):
		preview_ring.queue_free()


func _clear_box_preview() -> void:
	for unit in _box_preview_units.duplicate():
		_release_box_preview(unit)
	_box_preview_active = false
	_box_preview_area = Rect2()


func _is_empty_ground(screen_position: Vector2) -> bool:
	var pick := _pick(screen_position)
	if not pick.is_empty() and pick["collider"] is Unit:
		return false
	var ground_point: Variant = camera.screen_to_ground(screen_position)
	if ground_point == null:
		return false
	var ground_position: Vector3 = ground_point
	return _find_unit_at(ground_position) == null


func _box_ground_area(from_screen: Vector2, to_screen: Vector2) -> Rect2:
	var corners: Array[Vector3] = []
	for corner in [
		Vector2(from_screen.x, from_screen.y),
		Vector2(to_screen.x, from_screen.y),
		Vector2(to_screen.x, to_screen.y),
		Vector2(from_screen.x, to_screen.y),
	]:
		var projected: Variant = camera.screen_to_ground(corner)
		if projected != null:
			var ground_corner: Vector3 = projected
			corners.append(ground_corner)
	if corners.size() < 2:
		return Rect2()
	var minimum := corners[0]
	var maximum := corners[0]
	for corner in corners:
		minimum.x = minf(minimum.x, corner.x)
		minimum.z = minf(minimum.z, corner.z)
		maximum.x = maxf(maximum.x, corner.x)
		maximum.z = maxf(maximum.z, corner.z)
	return Rect2(Vector2(minimum.x, minimum.z), Vector2(maximum.x - minimum.x, maximum.z - minimum.z))


func _units_in_area(area: Rect2) -> Array[Unit]:
	var found: Array[Unit] = []
	for node in get_tree().get_nodes_in_group("units"):
		var unit := node as Unit
		if unit == null:
			continue
		var at := unit.global_position
		if area.has_point(Vector2(at.x, at.z)):
			found.append(unit)
	found.sort_custom(_sort_units_for_selection)
	return found


func _sort_units_for_selection(a: Unit, b: Unit) -> bool:
	if not is_equal_approx(a.global_position.x, b.global_position.x):
		return a.global_position.x < b.global_position.x
	return a.global_position.z < b.global_position.z


func _apply_box_selection(units: Array[Unit]) -> void:
	_cancel_pending_unit_tap()
	_deselect()
	for unit in units:
		_add_group_member(unit)
	if units.size() >= 2:
		_multi_select = true
		_selected_unit = units[0]
		_refresh_hud()
		_refresh_move_marker()
		return
	if units.size() == 1:
		_select(units[0])
		return
	_refresh_hud()
	_refresh_move_marker()


func _toggle_group_member(unit: Unit) -> void:
	if unit == null:
		return
	if _selected_units.has(unit):
		_selected_units.erase(unit)
		unit.set_selected(false)
	else:
		_add_group_member(unit)
		if _selected_unit == null:
			_selected_unit = unit
	if _selected_units.size() < 2:
		var keep: Unit = null
		if not _selected_units.is_empty():
			keep = _selected_units[0]
		_exit_multi_select(keep)
		return
	_refresh_hud()
	_refresh_move_marker()


func _add_group_member(unit: Unit) -> void:
	if _selected_units.has(unit):
		return
	_selected_units.append(unit)
	unit.set_selected(true)


func _exit_multi_select(keep: Unit) -> void:
	_multi_select = false
	_selected_units.clear()
	_group_target = Vector3.ZERO
	if keep == null:
		_deselect()
		return
	_select(keep)


func _clear_group() -> void:
	_multi_select = false
	_selected_units.clear()
	_group_target = Vector3.ZERO


func _refresh_hud() -> void:
	_refresh_vision_rings()
	if _selected_units.size() >= 2:
		unit_panel.hide_panel()
		group_panel.show_units(_selected_units)
		command_panel.visible = true
		return
	group_panel.hide_panel()
	if _selected_unit != null:
		unit_panel.show_unit(_selected_unit)
		command_panel.visible = true
		return
	unit_panel.hide_panel()
	command_panel.visible = false


func _refresh_move_marker() -> void:
	var hosts := _selected_visual_units()
	for unit in hosts:
		_update_unit_marker(unit)
	if marker != null and not (_selected_unit != null and hosts.has(_selected_unit)):
		marker.clear()
	_release_unused_markers(hosts)


func _selected_visual_units() -> Array[Unit]:
	var hosts: Array[Unit] = []
	for unit in _selected_units:
		if unit != null:
			hosts.append(unit)
	if hosts.is_empty() and _selected_unit != null:
		hosts.append(_selected_unit)
	return hosts


func _update_unit_marker(unit: Unit) -> void:
	var unit_marker := _marker_for(unit)
	if unit_marker == null:
		return
	if not unit.has_move_order():
		unit_marker.clear()
		return
	var target := unit.get_move_target()
	if not unit_marker.is_showing_at(target):
		unit_marker.show_at(target)


func _marker_for(unit: Unit) -> MoveOrderMarker:
	if unit == _selected_unit:
		return marker
	var found: MoveOrderMarker = _extra_markers.get(unit, null)
	if found != null:
		return found
	found = MoveOrderMarker.new()
	found.name = "GroupMarker%d" % _marker_serial
	_marker_serial += 1
	found.visible = false
	add_child(found)
	_extra_markers[unit] = found
	return found


func _release_unused_markers(hosts: Array[Unit]) -> void:
	if _extra_markers.is_empty():
		return
	for key in _extra_markers.keys():
		if hosts.has(key):
			continue
		var stale: MoveOrderMarker = _extra_markers[key]
		_extra_markers.erase(key)
		if stale != null and is_instance_valid(stale):
			stale.queue_free()


func _refresh_vision_rings() -> void:
	var single: Unit = null
	if _selected_units.size() == 1:
		single = _selected_units[0]
	elif _selected_units.is_empty():
		single = _selected_unit
	for unit in _selected_units:
		if unit != null:
			_set_vision_ring(unit, unit == single)
	if _selected_units.is_empty() and _selected_unit != null:
		_set_vision_ring(_selected_unit, true)


func _set_vision_ring(unit: Unit, value: bool) -> void:
	var ring: VisionRing = unit.get_node_or_null("VisionRing")
	if ring != null:
		ring.visible = value


func _toggle_selection(unit: Unit) -> void:
	if _multi_select:
		_toggle_group_member(unit)
		return
	if _selected_unit == unit:
		_deselect()
		return
	_select(unit)


func _on_command_stop() -> void:
	if _selected_unit == null:
		return
	_selected_unit.cancel_move_order()
	_refresh_move_marker()


func _pick(screen_position: Vector2) -> Dictionary:
	return get_world_3d().direct_space_state.intersect_ray(camera.pick_ray(screen_position))


func _on_move_order_completed() -> void:
	_refresh_move_marker()


func _on_move_order_failed() -> void:
	_refresh_move_marker()


func _on_move_order_cancelled() -> void:
	_refresh_move_marker()


func _fade_hint() -> void:
	var tween := create_tween()
	tween.tween_interval(HINT_FADE_DELAY)
	tween.tween_property(hint, "modulate:a", 0.0, HINT_FADE_DURATION)