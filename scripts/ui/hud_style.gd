class_name HudStyle
extends RefCounted

const PANEL_BG := Color(0.08, 0.09, 0.1, 0.92)
const HEADER_BG := Color(0.13, 0.14, 0.16, 1.0)
const BORDER := Color(0.26, 0.28, 0.3, 1.0)
const ACCENT := Color(0.93, 0.74, 0.12, 1.0)
const ACCENT_DIM := Color(0.93, 0.74, 0.12, 0.5)
const TEXT_PRIMARY := Color(0.88, 0.89, 0.9, 1.0)
const TEXT_SECONDARY := Color(0.6, 0.63, 0.66, 1.0)
const HEALTH_FILL := Color(0.25, 0.78, 0.34, 1.0)
const HEALTH_LOW := Color(0.85, 0.28, 0.12, 1.0)
const HEALTH_BG := Color(0.09, 0.11, 0.1, 1.0)
const BUTTON_BG := Color(0.13, 0.14, 0.16, 1.0)
const BUTTON_BG_HOVER := Color(0.19, 0.21, 0.23, 1.0)
const BUTTON_BG_PRESSED := Color(0.25, 0.27, 0.29, 1.0)
const BUTTON_BG_ARMED := Color(0.36, 0.28, 0.05, 1.0)
const HEALTH_LOW_RATIO := 0.34


static func panel_style(border_color: Color = BORDER) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BG
	style.set_border_width_all(1)
	style.border_color = border_color
	style.set_corner_radius_all(0)
	return style


static func header_style() -> StyleBoxFlat:
	var style := panel_style()
	style.bg_color = HEADER_BG
	style.border_width_left = 0
	style.border_width_top = 0
	style.border_width_right = 0
	style.border_width_bottom = 2
	style.border_color = ACCENT
	return style


static func button_style(bg_color: Color, border_color: Color) -> StyleBoxFlat:
	var style := panel_style(border_color)
	style.bg_color = bg_color
	style.set_border_width_all(2)
	style.set_content_margin_all(6.0)
	return style


static func bar_fill_style(fill_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.set_corner_radius_all(0)
	return style


static func health_fill_color(ratio: float) -> Color:
	return HEALTH_LOW if ratio < HEALTH_LOW_RATIO else HEALTH_FILL


static func bar_background_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = HEALTH_BG
	style.set_border_width_all(1)
	style.border_color = BORDER
	style.set_corner_radius_all(0)
	return style


static func make_panel(style: StyleBoxFlat) -> Panel:
	var panel := Panel.new()
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel


static func make_label(label_text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


static func make_rect(rect_color: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.color = rect_color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect