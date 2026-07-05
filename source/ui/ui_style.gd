class_name UIStyle
extends RefCounted
## Tema único da UI: painéis escuros translúcidos arredondados, botões
## com estados (normal/hover/pressionado/foco) e barras estilizadas.
## Todas as telas usam o mesmo tema — identidade visual coerente.

const ACCENT := Color(0.83, 0.69, 0.42)
const PANEL_BG := Color(0.08, 0.09, 0.12, 0.92)
const BUTTON_BG := Color(0.14, 0.16, 0.2, 0.95)

static var _theme: Theme


static func theme() -> Theme:
	if _theme != null:
		return _theme
	_theme = Theme.new()

	var panel := _box(PANEL_BG, 14.0, Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.25), 1)
	_theme.set_stylebox("panel", "PanelContainer", panel)
	_theme.set_stylebox("panel", "Panel", panel)

	_theme.set_stylebox("normal", "Button", _box(BUTTON_BG, 10.0,
		Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.35), 1))
	_theme.set_stylebox("hover", "Button", _box(Color(0.2, 0.22, 0.27, 0.95), 10.0,
		Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.7), 1))
	_theme.set_stylebox("pressed", "Button", _box(Color(0.24, 0.2, 0.12, 0.95), 10.0,
		ACCENT, 2))
	_theme.set_stylebox("focus", "Button", _box(Color(0, 0, 0, 0), 10.0, ACCENT, 2))
	_theme.set_color("font_color", "Button", Color(0.92, 0.9, 0.85))
	_theme.set_color("font_hover_color", "Button", Color(1, 0.98, 0.9))
	_theme.set_color("font_pressed_color", "Button", ACCENT)

	_theme.set_stylebox("background", "ProgressBar", _box(Color(0, 0, 0, 0.5), 6.0))
	_theme.set_stylebox("fill", "ProgressBar", _box(ACCENT, 6.0))

	_theme.set_color("font_color", "Label", Color(0.92, 0.9, 0.85))
	return _theme


static func bar_fill(color: Color) -> StyleBoxFlat:
	return _box(color, 6.0)


static func _box(
	bg: Color, radius: float, border := Color(0, 0, 0, 0), border_width := 0
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.corner_radius_top_left = int(radius)
	style.corner_radius_top_right = int(radius)
	style.corner_radius_bottom_left = int(radius)
	style.corner_radius_bottom_right = int(radius)
	style.border_color = border
	style.set_border_width_all(border_width)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style
