class_name IntroModal
extends CanvasLayer
## IntroModal — modal mostrado no início de uma fase para apresentar o objetivo
## antes de liberar o jogo.
##
## Pausa a árvore enquanto está aberto e emite [signal closed] quando o jogador
## confirma, para a fase então iniciar o puzzle. Reutilizável: basta instanciar
## a cena e chamar [method show_intro] com um título e um texto.

## Emitido quando o jogador confirma o modal (ex.: para iniciar o puzzle).
signal closed

@onready var title_label: Label = $Control/Panel/Margin/VBox/Title
@onready var body_label: Label = $Control/Panel/Margin/VBox/Body
@onready var start_button: Button = $Control/Panel/Margin/VBox/StartButton


func _ready() -> void:
	# Continua processando mesmo com a árvore pausada (o jogo fica parado atrás).
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	start_button.pressed.connect(_on_start_pressed)


## Abre o modal com um título e um corpo de texto. Pausa o jogo até confirmar.
func show_intro(title: String, body: String) -> void:
	title_label.text = title
	body_label.text = body
	visible = true
	get_tree().paused = true
	start_button.grab_focus()


## Fecha o modal, retoma o jogo e avisa quem estiver interessado.
func _on_start_pressed() -> void:
	visible = false
	get_tree().paused = false
	closed.emit()


## Permite fechar também com a tecla de interação (E), além do botão/Enter.
func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("interact"):
		_on_start_pressed()
		get_viewport().set_input_as_handled()