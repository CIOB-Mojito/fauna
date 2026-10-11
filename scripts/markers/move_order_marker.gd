class_name MoveOrderMarker
extends Node3D

const ARM_LENGTH := 1.2
const ARM_THICKNESS := 0.26
const ARM_HEIGHT := 0.06
const ARM_ANGLE := 45.0
const MARKER_COLOR := Color(0.98, 0.28, 0.1)
const MARKER_LIFT := 0.1
const BOB_HEIGHT := 0.07
const BOB_SPEED := 3.4
const SHOW_DURATION := 0.18
const HIDE_DURATION := 0.15
const HIDDEN_SCALE := 0.01

var _base_height := MapConfig.GROUND_TOP_Y + MARKER_LIFT
var _bob_time := 0.0
var _tween: Tween
var _target := Vector3.ZERO
var _showing := false


func _ready() -> void:
	_build()


func _process(delta: float) -> void:
	if not visible:
		return
	_bob_time += delta
	position.y = _base_height + sin(_bob_time * BOB_SPEED) * BOB_HEIGHT


func is_showing_at(world_position: Vector3) -> bool:
	return _showing and _target.is_equal_approx(world_position)


func show_at(world_position: Vector3) -> void:
	_target = world_position
	_showing = true
	_stop_tween()
	position = Vector3(world_position.x, _base_height, world_position.z)
	scale = Vector3.ONE * HIDDEN_SCALE
	visible = true
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector3.ONE, SHOW_DURATION) \
			.set_trans(Tween.TRANS_BACK) \
			.set_ease(Tween.EASE_OUT)


func clear() -> void:
	if not visible:
		return
	_showing = false
	_stop_tween()
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector3.ONE * HIDDEN_SCALE, HIDE_DURATION)
	_tween.tween_callback(_hide)


func _build() -> void:
	var arm_size := Vector3(ARM_LENGTH, ARM_HEIGHT, ARM_THICKNESS)
	var arm_a := MeshFactory.add_box(self, "ArmA", Vector3.ZERO, arm_size, MARKER_COLOR, true, 0.7)
	arm_a.rotation_degrees = Vector3(0.0, ARM_ANGLE, 0.0)
	var arm_b := MeshFactory.add_box(self, "ArmB", Vector3.ZERO, arm_size, MARKER_COLOR, true, 0.7)
	arm_b.rotation_degrees = Vector3(0.0, -ARM_ANGLE, 0.0)


func _stop_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()


func _hide() -> void:
	visible = false