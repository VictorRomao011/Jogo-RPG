extends Node
## Autoload "UIScale": responsividade (GDD §14.2). Classifica a tela em
## breakpoints e garante fonte mínima legível em qualquer dispositivo.
## Telas escutam `breakpoint_changed` e reorganizam densidade/layout —
## nunca removem função.

signal breakpoint_changed(breakpoint_name: String)

enum Breakpoint { PHONE_SMALL, PHONE_LARGE, TABLET, DESKTOP, ULTRAWIDE }

const BREAKPOINT_NAMES := {
	Breakpoint.PHONE_SMALL: "phone_small",
	Breakpoint.PHONE_LARGE: "phone_large",
	Breakpoint.TABLET: "tablet",
	Breakpoint.DESKTOP: "desktop",
	Breakpoint.ULTRAWIDE: "ultrawide",
}

## Mínimo físico legível (~12sp) convertido por DPI.
const MIN_FONT_PT := 12.0

var current: int = Breakpoint.DESKTOP


func _ready() -> void:
	get_viewport().size_changed.connect(_reevaluate)
	_reevaluate()


func _reevaluate() -> void:
	var size := get_viewport().get_visible_rect().size
	var aspect := size.x / maxf(size.y, 1.0)
	var new_breakpoint := _classify(size, aspect)
	if new_breakpoint != current:
		current = new_breakpoint
		breakpoint_changed.emit(BREAKPOINT_NAMES[current])


func _classify(_size: Vector2, aspect: float) -> int:
	# Web em celular também é mobile: o que decide é ter touchscreen.
	var is_mobile := OS.get_name() in ["Android", "iOS"] \
		or DisplayServer.is_touchscreen_available()
	if is_mobile:
		var win := Vector2(DisplayServer.window_get_size())
		var short_side := minf(win.x, win.y)
		if short_side >= 1100.0:
			return Breakpoint.TABLET
		return Breakpoint.PHONE_SMALL if short_side < 700.0 else Breakpoint.PHONE_LARGE
	if aspect >= 2.2:
		return Breakpoint.ULTRAWIDE
	return Breakpoint.DESKTOP


## Pixels físicos por unidade de canvas no stretch atual. Em retrato num
## celular a UI encolhe ~3×; todo layout touch usa isto para ter tamanho
## FÍSICO garantido (nunca botão de 27px).
func canvas_unit_scale() -> float:
	var win := Vector2(DisplayServer.window_get_size())
	var units := get_viewport().get_visible_rect().size
	return win.x / maxf(units.x, 1.0)


## Converte pixels físicos desejados em unidades de canvas.
func units_for_px(px: float) -> float:
	return px / maxf(canvas_unit_scale(), 0.001)


## Lado curto físico da janela (px) — base para dimensionar botões touch.
func short_side_px() -> float:
	var win := Vector2(DisplayServer.window_get_size())
	return minf(win.x, win.y)


## Tamanho de fonte seguro: escala com a tela e com a preferência do
## jogador (Config.font_scale), nunca abaixo do legível — o mínimo é em
## pixels FÍSICOS convertidos para unidades do canvas (funciona no stretch).
func font_size(base: int) -> int:
	var scale_factor: float = Config.font_scale
	match current:
		Breakpoint.PHONE_SMALL:
			scale_factor *= 1.25
		Breakpoint.PHONE_LARGE:
			scale_factor *= 1.15
		Breakpoint.TABLET:
			scale_factor *= 1.1
		Breakpoint.ULTRAWIDE:
			scale_factor *= 1.05
	var scaled := int(base * scale_factor)
	if DisplayServer.is_touchscreen_available():
		return maxi(scaled, int(units_for_px(15.0)))
	return scaled


## Margem segura (notch/ilha): UI crítica nunca embaixo de recorte de tela.
func safe_margins() -> Rect2i:
	return DisplayServer.get_display_safe_area()
