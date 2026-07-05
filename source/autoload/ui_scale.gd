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


func _classify(size: Vector2, aspect: float) -> int:
	var is_mobile := OS.get_name() in ["Android", "iOS"]
	if is_mobile:
		var inches := _diagonal_inches(size)
		if inches >= 7.0:
			return Breakpoint.TABLET
		return Breakpoint.PHONE_SMALL if inches < 5.7 else Breakpoint.PHONE_LARGE
	if aspect >= 2.2:
		return Breakpoint.ULTRAWIDE
	return Breakpoint.DESKTOP


func _diagonal_inches(size: Vector2) -> float:
	var dpi := maxf(float(DisplayServer.screen_get_dpi()), 96.0)
	return size.length() / dpi


## Tamanho de fonte seguro: escala com a tela e com a preferência do
## jogador (Config.font_scale), nunca abaixo do legível.
func font_size(base: int) -> int:
	var dpi := maxf(float(DisplayServer.screen_get_dpi()), 96.0)
	var min_px := int(MIN_FONT_PT * dpi / 72.0)
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
	return maxi(int(base * scale_factor), min_px if OS.get_name() == "Android" else base)


## Margem segura (notch/ilha): UI crítica nunca embaixo de recorte de tela.
func safe_margins() -> Rect2i:
	return DisplayServer.get_display_safe_area()
