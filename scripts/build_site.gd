class_name BuildSite
extends Area2D
## Local na margem do rio onde o jogador finaliza a coleta e constrói a ponte.
##
## Ao interagir (tecla de interação), valida o total de troncos coletado através
## do PuzzleManager. É o "ponto de construção": a validação do tamanho só
## acontece aqui, e não no momento em que cada tronco é coletado.

func _ready() -> void:
	PuzzleManager.puzzle_completed.connect(_on_completed)


## Chamado pelo jogador (via InteractionArea) ao pressionar a tecla de interação.
func interact() -> void:
	PuzzleManager.validate()


## Depois de construída a ponte, o ponto de construção some.
func _on_completed() -> void:
	visible = false
	set_deferred("monitorable", false)
	set_deferred("monitoring", false)