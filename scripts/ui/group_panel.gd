class_name GroupPanel
extends Control

const PANEL_SIZE := Vector2(268.0, 168.0)
const HEADER_HEIGHT := 18.0
const TITLE_POSITION := Vector2(6.0, 1.0)
const COUNT_FONT_SIZE := 12
const ROW_TOP := 26.0
const ROW_HEIGHT := 20.0
const ROW_MARGIN := 8.0
const CHIP_SIZE := 8.0
const CHIP_TOP := 5.0
const NAME_POSITION := 22.0
const ROW_FONT_SIZE := 12
const STATUS_WIDTH := 86.0
const BAR_WIDTH := 56.0
const BAR_SIZE := Vector2(56.0, 8.0)
const MAX_ROWS := 6
const CHIP_COLORS := [
	Color(0.93, 0.74, 0.12, 1.0),
	Color(0.36, 0.72, 0.95, 1.0),
	Color(0.55, 0.82, 0.42, 1.0),
	Color(0.92, 0.55, 0.32, 1.0),
	Color(0.78, 0.55, 0.9, 1.0),
	Color(0.45, 0.85, 0.82, 1.0),
]

var _units: Array[Unit] = []
var _rows: Array[Dictionary] = []
var _count_label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	visible = false


func _process(_delta: float) -> void:
	if _units.is_empty():
		return
	_refresh()


func show_units(units: Array[Unit]) -> void:
	_units.clear()
	for unit in units:
		_units.append(unit)
	visible = true
	_count_label.text = "%d UNIDADES SELECCIONADAS" % _units.size()
	_sync_rows()
	_refresh()


func hide_panel() -> void:
	_units.clear()
	visible = false


func _build() -> void:
	var background := HudStyle.make_panel(HudStyle.panel_style())
	background.position = Vector2.ZERO
	background.size = PANEL_SIZE
	add_child(background)

	var header := HudStyle.make_panel(HudStyle.header_style())
	header.position = Vector2.ZERO
	header.size = Vector2(PANEL_SIZE.x, HEADER_HEIGHT)
	add_child(header)

	_count_label = HudStyle.make_label("0 UNIDADES SELECCIONADAS", COUNT_FONT_SIZE, HudStyle.ACCENT)
	_count_label.position = TITLE_POSITION
	add_child(_count_label)

	var footer := HudStyle.make_label("Toca una unidad para quitarla · Toca el terreno para marchingar", 10, HudStyle.TEXT_SECONDARY)
	footer.position = Vector2(ROW_MARGIN, PANEL_SIZE.y - 18.0)
	footer.size = Vector2(PANEL_SIZE.x - ROW_MARGIN * 2.0, 14.0)
	footer.clip_text = true
	add_child(footer)


func _sync_rows() -> void:
	var shown := mini(_units.size(), MAX_ROWS)
	while _rows.size() > shown:
		var extra: Dictionary = _rows.pop_back()
		_free_row(extra)
	while _rows.size() < shown:
		_rows.append(_create_row(_rows.size()))


func _free_row(row: Dictionary) -> void:
	for key in row.keys():
		var node := row[key] as Node
		if node != null and is_instance_valid(node):
			node.queue_free()


func _create_row(index: int) -> Dictionary:
	var top := ROW_TOP + float(index) * ROW_HEIGHT
	var chip := HudStyle.make_rect(_chip_color(index))
	chip.position = Vector2(ROW_MARGIN, top + CHIP_TOP)
	chip.size = Vector2(CHIP_SIZE, CHIP_SIZE)
	add_child(chip)

	var name_label := HudStyle.make_label("", ROW_FONT_SIZE, HudStyle.TEXT_PRIMARY)
	name_label.position = Vector2(ROW_MARGIN + NAME_POSITION, top)
	name_label.size = Vector2(112.0, ROW_HEIGHT - 2.0)
	name_label.clip_text = true
	add_child(name_label)

	var bar := ProgressBar.new()
	bar.position = Vector2(134.0, top + 5.0)
	bar.size = BAR_SIZE
	bar.show_percentage = false
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.step = 0.1
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("background", HudStyle.bar_background_style())
	bar.add_theme_stylebox_override("fill", HudStyle.bar_fill_style(HudStyle.HEALTH_FILL))
	add_child(bar)

	var status_label := HudStyle.make_label("", 10, HudStyle.TEXT_SECONDARY)
	status_label.position = Vector2(196.0, top + 1.0)
	status_label.size = Vector2(STATUS_WIDTH, ROW_HEIGHT - 2.0)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(status_label)

	return {"chip": chip, "name": name_label, "bar": bar, "status": status_label}


func _refresh() -> void:
	for index in _rows.size():
		if index >= _units.size():
			return
		var unit := _units[index]
		var row: Dictionary = _rows[index]
		var name_label: Label = row["name"]
		var status_label: Label = row["status"]
		var bar: ProgressBar = row["bar"]
		if name_label.text != unit.get_display_name():
			name_label.text = unit.get_display_name()
		bar.value = unit.get_health_ratio() * bar.max_value
		_set_text(status_label, _status_text(unit))


func _status_text(unit: Unit) -> String:
	if unit.has_move_order():
		return "EN MARCHA"
	return "EN ESPERA"


func _chip_color(index: int) -> Color:
	if CHIP_COLORS.is_empty():
		return HudStyle.ACCENT
	return CHIP_COLORS[index % CHIP_COLORS.size()]


func _set_text(label: Label, text: String) -> void:
	if label.text != text:
		label.text = text