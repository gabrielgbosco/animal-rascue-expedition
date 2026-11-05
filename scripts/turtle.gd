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

@onready var sprite: Sprite2D = $Sprite2D

var _bob: Tween = null
var _waddle: Tween = null


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
