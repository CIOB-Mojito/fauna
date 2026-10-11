class_name SelectionBox
extends Control

const FILL_COLOR := Color(0.93, 0.74, 0.12, 0.10)
const BORDER_COLOR := Color(0.93, 0.74, 0.12, 0.85)
const TICK_COLOR := Color(0.98, 0.86, 0.35, 1.0)
const BORDER_WIDTH := 1.0
const TICK_LENGTH := 10.0
const MIN_BOX_SIZE := 8.0

var _box_rect := Rect2()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func show_box(from_screen: Vector2, to_screen: Vector2) -> void:
	_box_rect = _rect_from_points(from_screen, to_screen)
	visible = true
	queue_redraw()


func hide_box() -> void:
	if not visible:
		return
	visible = false
	_box_rect = Rect2()
	queue_redraw()


func has_meaningful_box() -> bool:
	return _box_rect.size.x >= MIN_BOX_SIZE and _box_rect.size.y >= MIN_BOX_SIZE


func _draw() -> void:
	if not has_meaningful_box():
		return
	draw_rect(_box_rect, FILL_COLOR, true)
	draw_rect(_box_rect, BORDER_COLOR, false, BORDER_WIDTH)
	_draw_ticks(_box_rect)


func _draw_ticks(box: Rect2) -> void:
	var right := box.position.x + box.size.x
	var bottom := box.position.y + box.size.y
	draw_line(box.position, box.position + Vector2(TICK_LENGTH, 0.0), TICK_COLOR, BORDER_WIDTH + 1.0)
	draw_line(box.position, box.position + Vector2(0.0, TICK_LENGTH), TICK_COLOR, BORDER_WIDTH + 1.0)
	draw_line(Vector2(right, box.position.y), Vector2(right - TICK_LENGTH, box.position.y), TICK_COLOR, BORDER_WIDTH + 1.0)
	draw_line(Vector2(right, box.position.y), Vector2(right, box.position.y + TICK_LENGTH), TICK_COLOR, BORDER_WIDTH + 1.0)
	draw_line(Vector2(box.position.x, bottom), Vector2(box.position.x + TICK_LENGTH, bottom), TICK_COLOR, BORDER_WIDTH + 1.0)
	draw_line(Vector2(box.position.x, bottom), Vector2(box.position.x, bottom - TICK_LENGTH), TICK_COLOR, BORDER_WIDTH + 1.0)
	draw_line(Vector2(right, bottom), Vector2(right - TICK_LENGTH, bottom), TICK_COLOR, BORDER_WIDTH + 1.0)
	draw_line(Vector2(right, bottom), Vector2(right, bottom - TICK_LENGTH), TICK_COLOR, BORDER_WIDTH + 1.0)


func _rect_from_points(from_screen: Vector2, to_screen: Vector2) -> Rect2:
	var top_left := Vector2(minf(from_screen.x, to_screen.x), minf(from_screen.y, to_screen.y))
	var bottom_right := Vector2(maxf(from_screen.x, to_screen.x), maxf(from_screen.y, to_screen.y))
	return Rect2(top_left, bottom_right - top_left)