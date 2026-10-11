class_name TacticalCamera
extends Camera3D

const DEFAULT_DISTANCE := 24.0
const MIN_DISTANCE := 11.0
const MAX_DISTANCE := 36.0
const PITCH_CLOSE := 64.0
const PITCH_FAR := 48.0
const INITIAL_YAW_DEGREES := -18.0
const BOUNDS_MARGIN := 2.5
const PICK_RANGE := 400.0

var focus := Vector3.ZERO
var _distance := DEFAULT_DISTANCE
var _yaw := deg_to_rad(INITIAL_YAW_DEGREES)


func _ready() -> void:
	set_focus(focus)


func set_focus(world_position: Vector3) -> void:
	focus = Vector3(world_position.x, MapConfig.GROUND_TOP_Y, world_position.z)
	_apply_transform()


func pan_by_screen(from_screen: Vector2, to_screen: Vector2) -> void:
	var from_ground: Variant = screen_to_ground(from_screen)
	var to_ground: Variant = screen_to_ground(to_screen)
	if from_ground != null and to_ground != null:
		var from_point: Vector3 = from_ground
		var to_point: Vector3 = to_ground
		focus += from_point - to_point
	else:
		focus += _screen_delta_to_fallback_world(to_screen - from_screen)
	_apply_transform()


func rotate_horizontal(delta_radians: float) -> void:
	if is_zero_approx(delta_radians):
		return
	_yaw = wrapf(_yaw + delta_radians, -PI, PI)
	_apply_transform()


func zoom_by_screen(scale_factor: float, focus_screen: Vector2) -> void:
	var before: Variant = screen_to_ground(focus_screen)
	_distance = clampf(_distance * scale_factor, MIN_DISTANCE, MAX_DISTANCE)
	_apply_transform()
	var after: Variant = screen_to_ground(focus_screen)
	if before != null and after != null:
		var before_point: Vector3 = before
		var after_point: Vector3 = after
		focus += before_point - after_point
		_apply_transform()


func screen_to_ground(screen_position: Vector2) -> Variant:
	var ground_plane := Plane(Vector3.UP, MapConfig.GROUND_TOP_Y)
	return ground_plane.intersects_ray(project_ray_origin(screen_position), project_ray_normal(screen_position))


func pick_ray(screen_position: Vector2) -> PhysicsRayQueryParameters3D:
	var from := project_ray_origin(screen_position)
	var to := from + project_ray_normal(screen_position) * PICK_RANGE
	return PhysicsRayQueryParameters3D.create(from, to, MapConfig.PICK_MASK)


func _apply_transform() -> void:
	var ratio := clampf(inverse_lerp(MIN_DISTANCE, MAX_DISTANCE, _distance), 0.0, 1.0)
	var pitch := deg_to_rad(lerpf(PITCH_CLOSE, PITCH_FAR, ratio))
	var offset := Vector3(sin(_yaw) * cos(pitch), sin(pitch), cos(_yaw) * cos(pitch)) * _distance
	_clamp_focus()
	global_position = focus + offset
	look_at(focus, Vector3.UP)


func _clamp_focus() -> void:
	var half := Vector2(MapConfig.HALF_WIDTH, MapConfig.HALF_DEPTH) - Vector2(BOUNDS_MARGIN, BOUNDS_MARGIN)
	focus.x = clampf(focus.x, -half.x, half.x)
	focus.z = clampf(focus.z, -half.y, half.y)
	focus.y = MapConfig.GROUND_TOP_Y


func _screen_delta_to_fallback_world(screen_delta: Vector2) -> Vector3:
	var viewport_size := get_viewport().get_visible_rect().size
	var world_per_pixel := 2.0 * _distance * tan(deg_to_rad(fov) * 0.5) / maxf(viewport_size.y, 1.0)
	var flat_basis := Basis(Vector3.UP, global_rotation.y)
	var world_delta := Vector3.ZERO
	world_delta -= flat_basis.x * screen_delta.x
	world_delta += flat_basis.z * screen_delta.y
	return world_delta * world_per_pixel