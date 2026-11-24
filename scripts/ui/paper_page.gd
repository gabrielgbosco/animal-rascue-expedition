class_name PaperPage
extends Control
## Folha de caderno desenhada por código: papel creme, pautas e sombra da lombada.

const PAPER: Color = Color(0.97, 0.93, 0.83)
const EDGE: Color = Color(0.72, 0.62, 0.45)
const RULE: Color = Color(0.52, 0.62, 0.78, 0.24)
const CORNER: int = 14
const SHADOW_STEPS: int = 18

## Página esquerda tem a lombada à direita; a direita tem a lombada à esquerda.
@export var is_left: bool = true

## Desenha as pautas do caderno (a partir de [member rule_start]).
@export var draw_rules: bool = true

## Altura onde começam as pautas, para não riscar o cabeçalho da página.
@export var rule_start: float = 118.0


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER
	style.border_color = EDGE
	style.set_border_width_all(2)
	if is_left:
		style.corner_radius_top_left = CORNER
		style.corner_radius_bottom_left = CORNER
	else:
		style.corner_radius_top_right = CORNER
		style.corner_radius_bottom_right = CORNER
	draw_style_box(style, Rect2(Vector2.ZERO, size))

	# Pautas do caderno.
	var y: float = rule_start
	while draw_rules and y < size.y - 44.0:
		draw_line(Vector2(30.0, y), Vector2(size.x - 30.0, y), RULE, 1.5)
		y += 38.0

	# Sombra suave junto à lombada, como o miolo curvando para dentro.
	for i: int in SHADOW_STEPS:
		var alpha: float = 0.06 * (1.0 - float(i) / SHADOW_STEPS)
		var x: float = i * 3.0
		if is_left:
			x = size.x - (i + 1) * 3.0
		draw_rect(Rect2(x, 2.0, 3.0, size.y - 4.0), Color(0.2, 0.1, 0.0, alpha))
