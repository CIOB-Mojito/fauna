class_name SelectionPreviewRing
extends Node3D

const RING_RADIUS := 1.9
const RING_SEGMENTS := 16
const RING_SEGMENT_SIZE := Vector3(0.26, 0.05, 0.16)
const RING_HEIGHT := 0.1
const PREVIEW_COLOR := Color(0.25, 0.85, 0.95)


func _ready() -> void:
	for index in RING_SEGMENTS:
		var angle := TAU * float(index) / float(RING_SEGMENTS)
		var segment_position := Vector3(
			cos(angle) * RING_RADIUS,
			RING_HEIGHT,
			sin(angle) * RING_RADIUS
		)
		MeshFactory.add_box(
			self,
			"Segment%d" % (index + 1),
			segment_position,
			RING_SEGMENT_SIZE,
			PREVIEW_COLOR,
			true,
			1.1
		)