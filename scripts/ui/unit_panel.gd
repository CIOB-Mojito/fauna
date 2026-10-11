class_name UnitPanel
extends Control

const PANEL_SIZE := Vector2(340.0, 92.0)
const HEADER_HEIGHT := 18.0
const ACCENT_BAR_SIZE := Vector2(3.0, 22.0)
const NAME_FONT_SIZE := 18
const TYPE_FONT_SIZE := 12
const SMALL_FONT_SIZE := 11
const HEALTH_BAR_SIZE := Vector2(150.0, 12.0)
const HEALTH_BAR_POSITION := Vector2(40.0, 68.0)

var _unit: Unit
var _low_health := false
var _name_label: Label
var _type_label: Label
var _status_label: Label
var _health_bar: ProgressBar
var _health_label: Label
var _speed_label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	visible = false


func _process(_delta: float) -> void:
	if _unit == null:
		return
	_refresh()


func show_unit(unit: Unit) -> void:
	_unit = unit
	_name_label.text = unit.get_display_name()
	_type_label.text = unit.get_role_text()
	visible = true
	_refresh()


func hide_panel() -> void:
	_unit = null
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

	var header_label := HudStyle.make_label("UNIDAD", SMALL_FONT_SIZE, HudStyle.ACCENT)
	header_label.position = Vector2(6.0, 1.0)
	add_child(header_label)

	var accent_bar := HudStyle.make_rect(HudStyle.ACCENT)
	accent_bar.position = Vector2(10.0, 24.0)
	accent_bar.size = ACCENT_BAR_SIZE
	add_child(accent_bar)

	_name_label = HudStyle.make_label("Command Vehicle", NAME_FONT_SIZE, HudStyle.TEXT_PRIMARY)
	_name_label.position = Vector2(20.0, 22.0)
	add_child(_name_label)

	_type_label = HudStyle.make_label("Recon / Command", TYPE_FONT_SIZE, HudStyle.TEXT_SECONDARY)
	_type_label.position = Vector2(20.0, 46.0)
	add_child(_type_label)

	_status_label = HudStyle.make_label("EN ESPERA", TYPE_FONT_SIZE, HudStyle.ACCENT)
	_status_label.position = Vector2(196.0, 24.0)
	_status_label.size = Vector2(134.0, 18.0)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_status_label)

	var health_title := HudStyle.make_label("HP", SMALL_FONT_SIZE, HudStyle.TEXT_SECONDARY)
	health_title.position = Vector2(10.0, 66.0)
	add_child(health_title)

	_health_bar = ProgressBar.new()
	_health_bar.position = HEALTH_BAR_POSITION
	_health_bar.size = HEALTH_BAR_SIZE
	_health_bar.show_percentage = false
	_health_bar.min_value = 0.0
	_health_bar.max_value = 100.0
	_health_bar.step = 0.1
	_health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_health_bar.add_theme_stylebox_override("background", HudStyle.bar_background_style())
	_health_bar.add_theme_stylebox_override("fill", HudStyle.bar_fill_style(HudStyle.HEALTH_FILL))
	add_child(_health_bar)

	_health_label = HudStyle.make_label("100 / 100", SMALL_FONT_SIZE, HudStyle.TEXT_PRIMARY)
	_health_label.position = Vector2(196.0, 66.0)
	_health_label.size = Vector2(64.0, 16.0)
	_health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_health_label)

	_speed_label = HudStyle.make_label("VEL 0.0", SMALL_FONT_SIZE, HudStyle.TEXT_SECONDARY)
	_speed_label.position = Vector2(266.0, 66.0)
	_speed_label.size = Vector2(64.0, 16.0)
	_speed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_speed_label)


func _refresh() -> void:
	var health := _unit.get_health()
	var ratio := _unit.get_health_ratio()
	_health_bar.value = ratio * _health_bar.max_value
	var is_low := ratio < HudStyle.HEALTH_LOW_RATIO
	if is_low != _low_health:
		_low_health = is_low
		var fill_color := HudStyle.HEALTH_LOW if is_low else HudStyle.HEALTH_FILL
		_health_bar.add_theme_stylebox_override("fill", HudStyle.bar_fill_style(fill_color))
	_set_text(_health_label, "%d / %d" % [int(health.x), int(health.y)])
	_set_text(_status_label, _status_text())
	_set_text(_speed_label, "VEL %.1f" % _unit.get_move_speed())


func _status_text() -> String:
	if _unit.has_move_order():
		if MapConfig.is_on_bridge(_unit.global_position):
			return "EN PUENTE"
		return "EN MARCHA"
	if MapConfig.is_on_bridge(_unit.global_position):
		return "PUENTE"
	return "EN ESPERA"


func _set_text(label: Label, text: String) -> void:
	if label.text != text:
		label.text = text