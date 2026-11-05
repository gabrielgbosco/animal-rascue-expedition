extends Area2D
## PuzzleItem
##
## Item colecionável genérico usado no sistema de puzzle. Cada instância
## representa uma unidade de uma grandeza (ex: um tronco de 2m de
## comprimento, um balde de 3L de capacidade, uma pedra de 4kg de massa).
##
## Para reaproveitar entre fases: duplique esta cena, troque o "value",
## o texto do rótulo e o sprite/cor visual.

## Valor numérico que este item representa.
@export var value: float = 1.0

## Texto mostrado acima do item. Se vazio, usa o valor numérico.
@export var value_label_text: String = ""

@onready var label: Label = $Label

var _collected: bool = false


func _ready() -> void:
	if label:
		label.text = value_label_text if value_label_text != "" else str(value)
	PuzzleManager.puzzle_reset.connect(_on_puzzle_reset)


## Chamado pelo jogador (via InteractionArea) ao pressionar a tecla de interação.
func interact() -> void:
	if _collected or not PuzzleManager.is_active:
		return

	_collected = true
	PuzzleManager.add_value(value)
	_apply_collected(true)


## Mostra/esconde o item e liga/desliga a detecção pela área de interação.
func _apply_collected(collected: bool) -> void:
	_collected = collected
	visible = not collected
	set_deferred("monitorable", not collected)
	set_deferred("monitoring", not collected)


## Quando o puzzle reinicia (ex.: após ultrapassar o alvo), o item volta a aparecer.
func _on_puzzle_reset() -> void:
	_apply_collected(false)
