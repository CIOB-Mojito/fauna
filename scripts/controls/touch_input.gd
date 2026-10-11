class_name TouchInput
extends Node

signal tap(screen_position: Vector2)
signal long_press(screen_position: Vector2)
signal box_candidate(screen_position: Vector2)
signal box_updated(from_screen: Vector2, to_screen: Vector2)
signal box_ended(from_screen: Vector2, to_screen: Vector2)
signal box_cancelled
signal pan_moved(from_screen: Vector2, to_screen: Vector2)
signal pinch_zoomed(scale_factor: float, focus_screen: Vector2)
signal twist_rotated(delta_radians: float)

const DRAG_THRESHOLD := 14.0
const TAP_MAX_DURATION_MS := 400
const LONG_PRESS_MIN_MS := 500
const SELECTION_BOX_DELAY_MS := 280
const PINCH_DEADZONE := 4.0
const TWIST_DEADZONE_DEGREES := 3.0
const WHEEL_ZOOM_STEP := 1.1
const MOUSE_POINTER := -100

var _use_touch := false
var _pointers := {}
var _multi_touch := false
var _pinch_active := false
var _pinch_distance := 0.0
var _pinch_angle := 0.0
var _ui_blockers: Array[Control] = []
var _box_allowed := false
var _box_active := false
var _box_denied := false
var _box_ready_at := 0


func arm_selection_box(allowed: bool) -> void:
	if not allowed:
		_box_allowed = false
		return
	if _pointers.size() != 1 or _multi_touch:
		return
	var data: Dictionary = _pointers.values()[0]
	if bool(data["moved"]):
		return
	_box_allowed = true
	_box_denied = false
	_box_ready_at = int(data["start_time"]) + SELECTION_BOX_DELAY_MS


func _ready() -> void:
	_use_touch = DisplayServer.is_touchscreen_available()
	_collect_ui_blockers(get_tree().root)


func _input(event: InputEvent) -> void:
	if _use_touch:
		_handle_touch_event(event)
	else:
		_handle_mouse_event(event)


func _collect_ui_blockers(node: Node) -> void:
	if node is Control and (node as Control).mouse_filter != Control.MOUSE_FILTER_IGNORE:
		_ui_blockers.append(node as Control)
	for child in node.get_children():
		_collect_ui_blockers(child)


func _is_ui_blocked(screen_position: Vector2) -> bool:
	for control in _ui_blockers:
		if control.is_visible_in_tree() and control.get_global_rect().has_point(screen_position):
			return true
	return false


func _handle_touch_event(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if touch_event.pressed:
			if _is_ui_blocked(touch_event.position):
				return
			_begin_pointer(touch_event.index, touch_event.position)
		else:
			_end_pointer(touch_event.index, touch_event.position)
	elif event is InputEventScreenDrag:
		var drag_event := event as InputEventScreenDrag
		_move_pointer(drag_event.index, drag_event.position)
		_update_pinch()


func _handle_mouse_event(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var button_event := event as InputEventMouseButton
		if button_event.button_index == MOUSE_BUTTON_WHEEL_UP and button_event.pressed:
			pinch_zoomed.emit(1.0 / WHEEL_ZOOM_STEP, button_event.position)
			return
		if button_event.button_index == MOUSE_BUTTON_WHEEL_DOWN and button_event.pressed:
			pinch_zoomed.emit(WHEEL_ZOOM_STEP, button_event.position)
			return
		if button_event.button_index != MOUSE_BUTTON_LEFT:
			return
		if button_event.pressed:
			if _is_ui_blocked(button_event.position):
				return
			_begin_pointer(MOUSE_POINTER, button_event.position)
		else:
			_end_pointer(MOUSE_POINTER, button_event.position)
	elif event is InputEventMouseMotion:
		var motion_event := event as InputEventMouseMotion
		_move_pointer(MOUSE_POINTER, motion_event.position)


func _begin_pointer(index: int, screen_position: Vector2) -> void:
	if not _pointers.is_empty():
		_multi_touch = true
		if _box_active:
			_box_active = false
			_box_allowed = false
			box_cancelled.emit()
		_cancel_pending_taps()
	_pointers[index] = {
		"start_time": Time.get_ticks_msec(),
		"position": screen_position,
		"origin": screen_position,
		"moved": false,
	}
	if _pointers.size() >= 2:
		_pinch_active = false
	if _pointers.size() == 1:
		_box_allowed = false
		_box_active = false
		_box_denied = false
		box_candidate.emit(screen_position)


func _move_pointer(index: int, screen_position: Vector2) -> void:
	if not _pointers.has(index):
		return
	var data: Dictionary = _pointers[index]
	var previous: Vector2 = data["position"]
	data["position"] = screen_position
	if not data["moved"] and previous.distance_to(screen_position) > DRAG_THRESHOLD:
		data["moved"] = true
		if _box_allowed and Time.get_ticks_msec() < _box_ready_at:
			_box_denied = true
	_pointers[index] = data
	if data["moved"] and _pointers.size() == 1:
		if _box_allowed and not _box_denied:
			_box_active = true
			box_updated.emit(data["origin"], screen_position)
		else:
			pan_moved.emit(previous, screen_position)


func _end_pointer(index: int, screen_position: Vector2) -> void:
	if not _pointers.has(index):
		return
	var data: Dictionary = _pointers[index]
	_pointers.erase(index)
	var elapsed := Time.get_ticks_msec() - int(data["start_time"])
	var is_steady: bool = not data["moved"] and not _multi_touch
	var is_tap: bool = is_steady and elapsed <= TAP_MAX_DURATION_MS
	var is_long_press: bool = is_steady and elapsed >= LONG_PRESS_MIN_MS
	var box_origin: Vector2 = data["origin"]
	if _pointers.is_empty():
		_multi_touch = false
		_pinch_active = false
		_box_allowed = false
		_box_denied = false
	elif _pointers.size() >= 2:
		_pinch_active = false
	if _box_active:
		_box_active = false
		box_ended.emit(box_origin, screen_position)
	elif is_tap:
		tap.emit(screen_position)
	elif is_long_press:
		long_press.emit(screen_position)


func _update_pinch() -> void:
	if _pointers.size() < 2:
		_pinch_active = false
		return
	var keys := _pointers.keys()
	var first: Vector2 = _pointers[keys[0]]["position"]
	var second: Vector2 = _pointers[keys[1]]["position"]
	var distance := maxf(first.distance_to(second), 1.0)
	var angle := (second - first).angle()
	if not _pinch_active:
		_pinch_active = true
		_pinch_distance = distance
		_pinch_angle = angle
		return
	if absf(distance - _pinch_distance) > PINCH_DEADZONE:
		pinch_zoomed.emit(_pinch_distance / distance, (first + second) * 0.5)
		_pinch_distance = distance
	var delta_angle := wrapf(angle - _pinch_angle, -PI, PI)
	if absf(rad_to_deg(delta_angle)) > TWIST_DEADZONE_DEGREES:
		twist_rotated.emit(delta_angle)
		_pinch_angle = angle


func _cancel_pending_taps() -> void:
	for key in _pointers.keys():
		var data: Dictionary = _pointers[key]
		data["moved"] = true
		_pointers[key] = data