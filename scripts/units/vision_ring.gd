class_name VisionRing
extends Node3D

const DOT_SIZE := Vector3(0.24, 0.06, 0.24)
const DOT_HEIGHT := 0.06
const DOT_COLOR := Color(0.95, 0.13, 0.11)
const DOTS_PER_UNIT := 4.0
const MIN_DOT_COUNT := 16

var radius := 9.5


func setup(new_radius: float) -> void:
	radius = new_radius
	if get_child_count() > 0:
		return
	var dot_count := maxi(MIN_DOT_COUNT, int(round(radius * DOTS_PER_UNIT)))
	for index in dot_count:
		var angle := TAU * float(index) / float(dot_count)
		var dot_position := Vector3(cos(angle) * radius, DOT_HEIGHT, sin(angle) * radius)
		if not _is_inside_map(dot_position):
			continue
		MeshFactory.add_box(self, "Dot%d" % (index + 1), dot_position, DOT_SIZE, DOT_COLOR, true, 0.6)


func _is_inside_map(position: Vector3) -> bool:
	return absf(position.x) <= MapConfig.HALF_WIDTH and absf(position.z) <= MapConfig.HALF_DEPTH