class_name ToolIcon
extends Control
## Ícone redondo desenhado por código (câmera ou diário), sem depender de imagens.

enum Kind { CAMERA, JOURNAL }

const BADGE_BG: Color = Color(0.2, 0.13, 0.08, 0.88)
const BADGE_BORDER: Color = Color(0.85, 0.72, 0.5)
const BADGE_ACTIVE: Color = Color(1.0, 0.85, 0.3)
const CREAM: Color = Color(0.97, 0.93, 0.83)
const DARK: Color = Color(0.16, 0.1, 0.06)
const LENS: Color = Color(0.45, 0.7, 0.9)
const COVER_BROWN: Color = Color(0.55, 0.32, 0.16)
const COVER_DARK: Color = Color(0.33, 0.18, 0.09)
const RIBBON: Color = Color(0.75, 0.15, 0.15)

@export var kind: Kind = Kind.CAMERA

## Destaca o ícone (ex.: diário aberto ou foto tirada).
var highlighted: bool = false:
	set(value):
		highlighted = value
		queue_redraw()


func _draw() -> void:
	var s: Vector2 = size
	var center: Vector2 = s * 0.5
	var radius: float = minf(s.x, s.y) * 0.5 - 3.0

	draw_circle(center, radius, BADGE_BG)
	if highlighted:
		draw_circle(center, radius - 4.0, Color(1.0, 0.85, 0.3, 0.2))
	draw_arc(center, radius, 0.0, TAU, 48,
		BADGE_ACTIVE if highlighted else BADGE_BORDER, 4.0 if highlighted else 3.0, true)

	if kind == Kind.CAMERA:
		_draw_camera(s)
	else:
		_draw_journal(s)


func _draw_camera(s: Vector2) -> void:
	var body := Rect2(s.x * 0.2, s.y * 0.36, s.x * 0.6, s.y * 0.38)
	_round_rect(Rect2(s.x * 0.34, s.y * 0.27, s.x * 0.24, s.y * 0.14), CREAM, 3)
	_round_rect(body, CREAM, 7)
	var lens_center: Vector2 = body.get_center() + Vector2(0.0, 1.0)
	draw_circle(lens_center, s.x * 0.14, DARK)
	draw_circle(lens_center, s.x * 0.10, LENS)
	draw_circle(lens_center + Vector2(-3.0, -3.0), s.x * 0.03, Color.WHITE)
	_round_rect(Rect2(s.x * 0.64, s.y * 0.40, s.x * 0.09, s.y * 0.06), Color(0.95, 0.6, 0.2), 2)


func _draw_journal(s: Vector2) -> void:
	var cover := Rect2(s.x * 0.28, s.y * 0.2, s.x * 0.44, s.y * 0.6)
	_round_rect(cover, COVER_BROWN, 5)
	# Bordas das páginas à direita e lombada à esquerda.
	draw_rect(Rect2(cover.position.x + cover.size.x * 0.82, cover.position.y + 4.0,
		cover.size.x * 0.13, cover.size.y - 8.0), CREAM)
	draw_rect(Rect2(cover.position.x, cover.position.y, cover.size.x * 0.16, cover.size.y), COVER_DARK)
	# Etiqueta na capa e fita marcadora.
	draw_rect(Rect2(cover.position.x + cover.size.x * 0.30, cover.position.y + cover.size.y * 0.22,
		cover.size.x * 0.42, cover.size.y * 0.2), CREAM)
	draw_rect(Rect2(cover.position.x + cover.size.x * 0.6, cover.end.y - 2.0, 5.0, s.y * 0.12), RIBBON)


func _round_rect(rect: Rect2, color: Color, radius: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	draw_style_box(style, rect)
