class_name CommandPanel
extends Control

signal stop_pressed

const PANEL_SIZE := Vector2(152.0, 96.0)
const HEADER_HEIGHT := 18.0
const BUTTON_MARGIN := 10.0
const BUTTON_TOP := 28.0
const BUTTON_SIZE := Vector2(132.0, 58.0)
const BUTTON_FONT_SIZE := 14


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	visible = false


func add_command(button_text: String, callback: Callable) -> Button:
	var button := _create_button(button_text)
	button.anchor_left = 0.0
	button.anchor_top = 0.0
	button.anchor_right = 0.0
	button.anchor_bottom = 0.0
	button.offset_left = BUTTON_MARGIN
	button.offset_top = BUTTON_TOP
	button.offset_right = BUTTON_MARGIN + BUTTON_SIZE.x
	button.offset_bottom = BUTTON_TOP + BUTTON_SIZE.y
	button.pressed.connect(callback)
	add_child(button)
	return button


func _build() -> void:
	var background := HudStyle.make_panel(HudStyle.panel_style())
	background.position = Vector2.ZERO
	background.size = PANEL_SIZE
	add_child(background)

	var header := HudStyle.make_panel(HudStyle.header_style())
	header.position = Vector2.ZERO
	header.size = Vector2(PANEL_SIZE.x, HEADER_HEIGHT)
	add_child(header)

	var header_label := HudStyle.make_label("COMANDOS", 11, HudStyle.ACCENT)
	header_label.position = Vector2(6.0, 1.0)
	add_child(header_label)

	add_command("DETENER", _on_stop_button_pressed)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if touch_event.pressed:
			_trigger_stop()
	elif event is InputEventMouseButton:
		var button_event := event as InputEventMouseButton
		if button_event.button_index == MOUSE_BUTTON_LEFT and button_event.pressed:
			_trigger_stop()


func _trigger_stop() -> void:
	stop_pressed.emit()
	accept_event()


func _create_button(button_text: String) -> Button:
	var button := Button.new()
	button.text = button_text
	button.custom_minimum_size = BUTTON_SIZE
	button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
	button.add_theme_color_override("font_color", HudStyle.TEXT_PRIMARY)
	button.add_theme_color_override("font_hover_color", HudStyle.ACCENT)
	button.add_theme_color_override("font_pressed_color", HudStyle.ACCENT)
	button.add_theme_color_override("font_focus_color", HudStyle.TEXT_PRIMARY)
	button.add_theme_stylebox_override("normal", HudStyle.button_style(HudStyle.BUTTON_BG, HudStyle.ACCENT_DIM))
	button.add_theme_stylebox_override("hover", HudStyle.button_style(HudStyle.BUTTON_BG_HOVER, HudStyle.ACCENT))
	button.add_theme_stylebox_override("pressed", HudStyle.button_style(HudStyle.BUTTON_BG_PRESSED, HudStyle.ACCENT))
	button.add_theme_stylebox_override("focus", HudStyle.button_style(HudStyle.BUTTON_BG, HudStyle.ACCENT_DIM))
	return button


func _on_stop_button_pressed() -> void:
	stop_pressed.emit()