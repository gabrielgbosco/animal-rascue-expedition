class_name CuriosityCard
extends CanvasLayer
## CuriosityCard — ficha do animal exibida ao concluir a missão.
##
## Mostra imagem, nome popular, nome científico, habitat, alimentação e uma
## curiosidade (campos previstos no GDD) e oferece o botão "Jogar de novo".
## Pausa a árvore enquanto está aberta. Reutilizável: cada fase chama
## [method show_card] com os dados do seu animal.

## Emitido quando o jogador pede para jogar a fase novamente.
signal replay_requested

@onready var picture: TextureRect = $Control/Panel/Margin/VBox/Content/Picture
@onready var name_label: Label = $Control/Panel/Margin/VBox/Content/Info/NameLabel
@onready var scientific_label: Label = $Control/Panel/Margin/VBox/Content/Info/ScientificLabel
@onready var habitat_label: Label = $Control/Panel/Margin/VBox/Content/Info/HabitatLabel
@onready var diet_label: Label = $Control/Panel/Margin/VBox/Content/Info/DietLabel
@onready var curiosity_label: Label = $Control/Panel/Margin/VBox/Content/Info/CuriosityLabel
@onready var replay_button: Button = $Control/Panel/Margin/VBox/ReplayButton


func _ready() -> void:
	# Continua processando mesmo com a árvore pausada (o jogo fica parado atrás).
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	replay_button.pressed.connect(_on_replay_pressed)


## Abre a ficha com os dados do animal. Pausa o jogo até o jogador escolher.
func show_card(image: Texture2D, common_name: String, scientific_name: String,
		habitat: String, diet: String, curiosity: String) -> void:
	if image:
		picture.texture = image
	name_label.text = common_name
	scientific_label.text = "Nome científico: %s" % scientific_name
	habitat_label.text = "Habitat: %s" % habitat
	diet_label.text = "Alimentação: %s" % diet
	curiosity_label.text = "Curiosidade: %s" % curiosity
	visible = true
	get_tree().paused = true
	replay_button.grab_focus()


func _on_replay_pressed() -> void:
	visible = false
	get_tree().paused = false
	replay_requested.emit()
