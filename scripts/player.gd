extends CharacterBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractionArea

const SPEED = 450.0
const JUMP_FORCE = -650.0

## Lista de objetos interagíveis (ex: PuzzleItem) atualmente ao alcance do jogador.
var _nearby_interactables: Array[Area2D] = []


func _ready() -> void:
	interaction_area.area_entered.connect(_on_interaction_area_entered)
	interaction_area.area_exited.connect(_on_interaction_area_exited)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_try_interact()


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
