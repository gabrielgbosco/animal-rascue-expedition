class_name Turtle
extends Node2D
## Tartaruga da Fase 1.
##
## Fica parada na margem oposta do rio e, quando o puzzle é resolvido, caminha
## pela ponte até a margem do jogador, com um balancinho suave. Emite
## [signal crossed] ao chegar.

## Emitido quando a tartaruga termina de atravessar a ponte.
signal crossed

## Velocidade da caminhada, em pixels por segundo.
@export var walk_speed: float = 150.0

## Espécie no catálogo (chave em [SpeciesDB]).
@export var species_id: String = "tartaruga"

@onready var sprite: Sprite2D = $Sprite2D

var _bob: Tween = null
var _waddle: Tween = null


## Aviso "Fotografar (F)" mostrado enquanto a tartaruga está na tela e ainda não foi fotografada.
var photo_hint: Label


func _ready() -> void:
	# Entra no grupo para o jogador conseguir fotografar a tartaruga.
	add_to_group("wildlife")
	_build_photo_hint()


## Registra a observação no diário. Retorna true só na primeira foto.
func photograph() -> bool:
	return Journal.observe(species_id)


## O jogador chama isso a cada quadro: [param in_view] é true se a tartaruga está na tela.
func set_photo_hint(in_view: bool) -> void:
	photo_hint.visible = in_view and Journal.get_state(species_id) == Journal.UNKNOWN


func _build_photo_hint() -> void:
	photo_hint = Label.new()
	photo_hint.text = "Fotografar (%s)" % ExplorerToolbar.key_text("photo")
	photo_hint.visible = false
	photo_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	photo_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	photo_hint.offset_left = -170.0
	photo_hint.offset_right = 170.0
	photo_hint.offset_top = -210.0
	photo_hint.offset_bottom = -160.0
	photo_hint.add_theme_font_size_override("font_size", 30)
	photo_hint.add_theme_color_override("font_color", Color.WHITE)
	photo_hint.add_theme_color_override("font_outline_color", Color(0.1, 0.1, 0.1))
	photo_hint.add_theme_constant_override("outline_size", 8)
	# Acima do cenário (a tartaruga fica atrás das margens, com z_index -1).
	photo_hint.z_index = 30
	add_child(photo_hint)


## Faz a tartaruga caminhar até [param target_x] (coordenada local).
func cross_to(target_x: float) -> void:
	var distance: float = absf(target_x - position.x)
	if distance <= 0.0:
		_on_arrived()
		return

	_start_walk_animation()
	var tween: Tween = create_tween()
	tween.tween_property(self, "position:x", target_x, distance / walk_speed)
	tween.finished.connect(_on_arrived)


## Balancinho suave (sobe/desce) + leve gingado, para dar vida ao andar.
func _start_walk_animation() -> void:
	_bob = create_tween().set_loops()
	_bob.tween_property(sprite, "position:y", -7.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_bob.tween_property(sprite, "position:y", 2.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	_waddle = create_tween().set_loops()
	_waddle.tween_property(sprite, "rotation_degrees", 3.5, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_waddle.tween_property(sprite, "rotation_degrees", -2.5, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _stop_walk_animation() -> void:
	if _bob:
		_bob.kill()
	if _waddle:
		_waddle.kill()
	sprite.position = Vector2.ZERO
	sprite.rotation_degrees = 0.0


func _on_arrived() -> void:
	_stop_walk_animation()
	crossed.emit()
