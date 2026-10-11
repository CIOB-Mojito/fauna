class_name SelectionHealthBar
extends Node3D

const BAR_WIDTH := 1.7
const BAR_HEIGHT := 0.2
const FRAME_SIZE := 0.07
const THICKNESS := 0.05
const HEIGHT_OVER_UNIT := 2.3

var _fill: MeshInstance3D
var _fill_material: StandardMaterial3D
var _ratio := 1.0


func _ready() -> void:
	_build()


func set_ratio(value: float) -> void:
	var ratio := clampf(value, 0.0, 1.0)
	if is_equal_approx(ratio, _ratio):
		return
	_ratio = ratio
	_apply_ratio()


func _apply_ratio() -> void:
	if _fill == null:
		return
	var width := BAR_WIDTH * _ratio
	_fill.visible = width > 0.001
	_fill.scale.x = _ratio
	_fill.position.x = -BAR_WIDTH * 0.5 + width * 0.5
	if _fill_material != null:
		_fill_material.albedo_color = HudStyle.health_fill_color(_ratio)


func face_camera(camera_position: Vector3) -> void:
	var flat_target := Vector3(global_position.x, camera_position.y, global_position.z)
	if flat_target.distance_squared_to(global_position) < 0.0001:
		return
	look_at(flat_target, Vector3.UP)


func _build() -> void:
	MeshFactory.add_box(
		self,
		"Frame",
		Vector3(0.0, 0.0, THICKNESS),
		Vector3(BAR_WIDTH + FRAME_SIZE * 2.0, BAR_HEIGHT + FRAME_SIZE * 2.0, THICKNESS),
		HudStyle.BORDER,
		true
	)
	MeshFactory.add_box(
		self,
		"Background",
		Vector3.ZERO,
		Vector3(BAR_WIDTH, BAR_HEIGHT, THICKNESS),
		HudStyle.HEALTH_BG,
		true
	)
	_fill = MeshFactory.add_box(
		self,
		"Fill",
		Vector3(-BAR_WIDTH * 0.5, 0.0, -THICKNESS),
		Vector3(BAR_WIDTH, BAR_HEIGHT, THICKNESS),
		HudStyle.HEALTH_FILL,
		true
	)
	_fill_material = _fill.mesh.surface_get_material(0) as StandardMaterial3D
	_apply_ratio()