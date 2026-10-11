class_name MapConfig
extends RefCounted

const HALF_WIDTH := 30.0
const HALF_DEPTH := 21.0
const GROUND_TOP_Y := 0.0
const GROUND_THICKNESS := 1.0

const RIVER_CENTER_X := 0.0
const RIVER_HALF_WIDTH := 1.75
const RIVER_SURFACE_Y := -0.12
const RIVER_DEPTH := 0.9

const BRIDGE_CENTER_Z := 0.0
const BRIDGE_HALF_LENGTH := 2.2
const BRIDGE_OVERLAP := 0.4

const BANK_CLEARANCE := 0.8
const PLAY_MARGIN := 1.2

const LAYER_TERRAIN := 1
const LAYER_WATER := 2
const LAYER_UNITS := 4
const PICK_MASK := LAYER_TERRAIN | LAYER_WATER | LAYER_UNITS


static func playable_half_extents() -> Vector2:
	return Vector2(HALF_WIDTH - PLAY_MARGIN, HALF_DEPTH - PLAY_MARGIN)


static func clamp_to_map(position: Vector3) -> Vector3:
	var half := playable_half_extents()
	return Vector3(
		clampf(position.x, -half.x, half.x),
		GROUND_TOP_Y,
		clampf(position.z, -half.y, half.y)
	)


static func is_inside_playable_area(position: Vector3) -> bool:
	var half := playable_half_extents()
	return absf(position.x) <= half.x and absf(position.z) <= half.y


static func is_in_river(position: Vector3) -> bool:
	return absf(position.x - RIVER_CENTER_X) < RIVER_HALF_WIDTH


static func is_on_bridge(position: Vector3) -> bool:
	var within_deck := absf(position.x - RIVER_CENTER_X) <= RIVER_HALF_WIDTH + BRIDGE_OVERLAP
	var along_bridge := absf(position.z - BRIDGE_CENTER_Z) <= BRIDGE_HALF_LENGTH
	return within_deck and along_bridge


static func is_walkable(position: Vector3) -> bool:
	if not is_inside_playable_area(position):
		return false
	return not is_in_river(position) or is_on_bridge(position)


static func resolve_target(raw_position: Vector3) -> Vector3:
	var target := clamp_to_map(raw_position)
	if is_in_river(target) and not is_on_bridge(target):
		var side := signf(target.x - RIVER_CENTER_X)
		if is_zero_approx(side):
			side = 1.0
		target.x = RIVER_CENTER_X + side * (RIVER_HALF_WIDTH + BANK_CLEARANCE)
	return target