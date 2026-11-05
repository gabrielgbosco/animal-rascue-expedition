extends CanvasLayer
## HUD simples: mostra o progresso do puzzle atual ("Progresso: X / Y"),
## o objetivo da fase e uma mensagem temporária de feedback.

@onready var progress_label: Label = $Control/ProgressLabel
@onready var objective_label: Label = $Control/ObjectiveLabel
@onready var feedback_label: Label = $Control/FeedbackLabel
@onready var feedback_timer: Timer = $FeedbackTimer

## Mensagem mostrada ao concluir a fase (pode ser trocada pela fase).
var _success_text: String = ""


func _ready() -> void:
	PuzzleManager.progress_changed.connect(_on_progress_changed)
	PuzzleManager.item_collected.connect(_on_item_collected)
	PuzzleManager.puzzle_completed.connect(_on_puzzle_completed)
	PuzzleManager.puzzle_overshoot.connect(_on_puzzle_overshoot)
	PuzzleManager.puzzle_incomplete.connect(_on_puzzle_incomplete)
	feedback_timer.timeout.connect(_on_feedback_timer_timeout)


## Defina o texto do objetivo da fase (ex: "Ajude a tartaruga a atravessar o rio").
func set_objective(text: String) -> void:
	if objective_label:
		objective_label.text = text


## Defina a mensagem de sucesso da fase (ex: "Você formou a ponte!").
func set_success_text(text: String) -> void:
	_success_text = text


## Mostra uma mensagem temporária de feedback (para uso externo, ex.: pela fase).
func flash(text: String) -> void:
	_show_feedback(text)


## Formata um valor usando a grandeza/unidade do puzzle atual (ex.: "3 m").
func _format(value: float) -> String:
	return Units.format(value, PuzzleManager.quantity_type)


func _on_progress_changed(current: float, target: float) -> void:
	if progress_label:
		progress_label.text = "Progresso: %s / %s" % [_format(current), _format(target)]


## Feedback imediato ao coletar um item, mostrando o total acumulado.
func _on_item_collected(amount: float, current: float, target: float) -> void:
	_show_feedback("Você pegou +%s. Total: %s de %s." % [_format(amount), _format(current), _format(target)])


func _on_puzzle_completed() -> void:
	if progress_label:
		progress_label.text = "Objetivo concluído!"
	if _success_text != "":
		_show_feedback(_success_text)
	else:
		_show_feedback("Muito bem! Você atingiu %s." % _format(PuzzleManager.target_value))


func _on_puzzle_overshoot(_current: float, target: float) -> void:
	_show_feedback("Passou de %s! Os troncos voltaram — tente de novo." % _format(target))


## O jogador finalizou a coleta, mas ainda não atingiu o alvo.
func _on_puzzle_incomplete(current: float, target: float) -> void:
	_show_feedback("Ainda faltam %s! Colete mais troncos." % _format(maxf(target - current, 0.0)))


func _show_feedback(text: String) -> void:
	if feedback_label:
		feedback_label.text = text
	feedback_timer.start()


func _on_feedback_timer_timeout() -> void:
	if feedback_label:
		feedback_label.text = ""
