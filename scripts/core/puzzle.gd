class_name Puzzle
extends Node
## Classe-base dos puzzles do jogo.
##
## Cada tipo de puzzle (ponte, balança, recipiente graduado, ...) estende esta
## classe e emite os sinais conforme o jogador resolve a atividade. O
## PuzzleManager (autoload) conecta-se a estes sinais e repassa para a HUD.
##
## Isso mantém o sistema reutilizável: criar um novo puzzle é herdar desta
## classe e emitir [signal solved] / [signal progress_changed] / [signal failed].

## Emitido quando o progresso muda. [param current] e [param target] estão
## na unidade-base da grandeza (ex.: metros para comprimento).
signal progress_changed(current: float, target: float)

## Emitido quando o objetivo é atingido.
signal solved

## Emitido quando o jogador ultrapassa o objetivo (feedback de erro).
signal failed(reason: String)

## Torna-se false depois que o puzzle é resolvido.
var is_active: bool = true


## Reinicia o estado do puzzle (permite nova tentativa).
func reset() -> void:
	is_active = true
