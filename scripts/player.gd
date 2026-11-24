class_name Player
extends CharacterBody2D

## Emitido quando a câmera fotografa um animal. [param is_new] é true na primeira foto da espécie.
signal photo_taken(species_id: String, is_new: bool)

## Emitido quando o jogador aperta o botão da câmera sem nenhum animal na tela.
signal photo_missed

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractionArea

const SPEED = 450.0
const JUMP_FORCE = -650.0

## A câmera olha um pouco à frente do jogador (para a direita), para que a margem
## oposta do rio apareça inteira e longe dos ícones do lado direito da tela.
const CAMERA_LOOK_AHEAD: float = 260.0

## Lista de objetos interagíveis (ex: PuzzleItem) atualmente ao alcance do jogador.
var _nearby_interactables: Array[Area2D] = []


func _ready() -> void:
	var camera: Camera2D = get_node_or_null("Camera2D")
	if camera:
		camera.offset.x = CAMERA_LOOK_AHEAD
		# O Godot aplica o offset depois dos limites; compensamos para a tela
		# nunca passar da borda esquerda do mundo.
		camera.limit_left -= int(CAMERA_LOOK_AHEAD)
	interaction_area.area_entered.connect(_on_interaction_area_entered)
	interaction_area.area_exited.connect(_on_interaction_area_exited)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_try_interact()
	elif event.is_action_pressed("photo"):
		_try_photograph()


## Mostra o aviso "Fotografar (F)" nos animais que estão na tela.
func _process(_delta: float) -> void:
	var view: Rect2 = _view_rect()
	for node: Node in get_tree().get_nodes_in_group("wildlife"):
		if node.has_method("set_photo_hint"):
			node.set_photo_hint(view.has_point(node.global_position))


## Área do mundo que aparece na tela agora. Se o animal está visível, dá para fotografar.
func _view_rect() -> Rect2:
	return get_canvas_transform().affine_inverse() * get_viewport_rect()


## Fotografa o animal visível mais próximo. Sem animal na tela, só avisa.
func _try_photograph() -> void:
	var view: Rect2 = _view_rect()
	var closest = null
	var best: float = INF
	for node: Node in get_tree().get_nodes_in_group("wildlife"):
		if not node.has_method("photograph") or not view.has_point(node.global_position):
			continue
		var distance: float = global_position.distance_to(node.global_position)
		if distance < best:
			best = distance
			closest = node

	if closest == null:
		photo_missed.emit()
		return
	var species_id: String = str(closest.get("species_id"))
	var is_new: bool = closest.photograph()
	photo_taken.emit(species_id, is_new)


func _on_interaction_area_entered(area: Area2D) -> void:
	if area.has_method("interact"):
		_nearby_interactables.append(area)


func _on_interaction_area_exited(area: Area2D) -> void:
	_nearby_interactables.erase(area)


## Interage com o objeto interagível mais próximo do jogador, se houver algum.
func _try_interact() -> void:
	if _nearby_interactables.is_empty():
		return

	var closest: Area2D = _nearby_interactables[0]
	for candidate in _nearby_interactables:
		if global_position.distance_to(candidate.global_position) < global_position.distance_to(closest.global_position):
			closest = candidate

	closest.interact()


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_FORCE

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	if is_on_floor():
		if direction > 0:
			anim.flip_h = true
			anim.play("run")
		elif direction < 0:
			anim.flip_h = false
			anim.play("run")
		else:
			anim.play("idle")
	else:
		anim.play("jump"	)

	move_and_slide()
