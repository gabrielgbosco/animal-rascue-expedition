extends Node
## PuzzleManager (Autoload / Singleton)
##
## Sistema genérico de puzzle: o jogador coleta itens com um valor numérico
## (comprimento, capacidade, massa...) até atingir exatamente um valor-alvo
## definido pela fase atual.
##
## Reaproveitável entre fases: só muda o valor-alvo e o tema visual dos itens.

## Emitido sempre que o progresso muda (para atualizar a HUD).
signal progress_changed(current: float, target: float)

## Emitido quando o jogador coleta um item, com o valor somado e o progresso
## resultante, para a HUD dar feedback ("Você pegou +3 m. Faltam 3 m.").
signal item_collected(amount: float, current: float, target: float)

## Emitido quando o jogador finaliza a coleta mas ainda não atingiu o alvo.
signal puzzle_incomplete(current: float, target: float)

## Emitido quando o jogador atinge exatamente o valor-alvo.
signal puzzle_completed

## Emitido se o jogador ultrapassar o valor-alvo (opcional: pode ser usado
## para dar feedback de erro, tocar um som, etc.)
signal puzzle_overshoot(current: float, target: float)

## Emitido quando o puzzle reinicia (ex.: após ultrapassar o alvo), para que os
## itens já coletados voltem a aparecer e o jogador possa tentar de novo.
signal puzzle_reset

var target_value: float = 0.0
var current_value: float = 0.0
var is_active: bool = false

## Grandeza do puzzle atual (comprimento, massa, capacidade), usada pela HUD
## para exibir os valores com a unidade correta.
var quantity_type: int = Units.QuantityType.LENGTH


## Chame isso no início de uma fase para configurar o puzzle.
## Exemplo: PuzzleManager.start_puzzle(6.0)
## Passe [param type] para puzzles de outra grandeza (massa, capacidade).
func start_puzzle(target: float, type: int = Units.QuantityType.LENGTH) -> void:
	target_value = target
	current_value = 0.0
	quantity_type = type
	is_active = true
	progress_changed.emit(current_value, target_value)


## Chamado pelos PuzzleItem quando o jogador coleta um item. Apenas soma ao
## total e avisa o progresso — NÃO valida ainda. A validação acontece em
## [method validate], quando o jogador decide finalizar a coleta.
func add_value(amount: float) -> void:
	if not is_active:
		return

	current_value += amount
	item_collected.emit(amount, current_value, target_value)
	progress_changed.emit(current_value, target_value)


## Finaliza a coleta e valida o total obtido. Chame quando o jogador decidir
## concluir (ex.: construir a ponte). Pode resultar em conclusão, ultrapassagem
## (reinício) ou aviso de que ainda falta.
func validate() -> void:
	if not is_active:
		return

	if is_equal_approx(current_value, target_value):
		is_active = false
		puzzle_completed.emit()
	elif current_value > target_value:
		puzzle_overshoot.emit(current_value, target_value)
		_restart()
	else:
		puzzle_incomplete.emit(current_value, target_value)


## Reinicia o puzzle (útil para permitir o jogador tentar de novo).
func reset() -> void:
	_restart()


## Zera o progresso, reativa o puzzle e avisa os itens para reaparecerem.
func _restart() -> void:
	current_value = 0.0
	is_active = true
	puzzle_reset.emit()
	progress_changed.emit(current_value, target_value)
