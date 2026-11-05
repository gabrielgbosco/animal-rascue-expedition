extends Node2D
## Script da Fase 1 (Floresta): configura o puzzle genérico com o tema
## "comprimento" (troncos) e reage à conclusão da fase.

## Comprimento total necessário para formar a ponte (soma dos troncos corretos).
@export var target_value: float = 6.0

@onready var hud: CanvasLayer = $HUD
@onready var intro_modal: IntroModal = $IntroModal
@onready var bridge: Node2D = $Bridge
@onready var turtle: Turtle = $Turtle

## Coordenada X onde a tartaruga termina de atravessar (margem do jogador).
@export var turtle_target_x: float = 1250.0

## Texto do objetivo padrão (restaurado enquanto o jogador ainda não tem o total).
var _base_objective: String = ""

func _ready() -> void:
	PuzzleManager.puzzle_completed.connect(_on_puzzle_completed)
	PuzzleManager.progress_changed.connect(_on_progress_changed)

	var bridge_length: String = Units.format(target_value, Units.QuantityType.LENGTH)
	_base_objective = "Ajude a tartaruga: colete troncos até somar %s e construa a ponte na margem do rio." % bridge_length

	if hud:
		hud.set_objective(_base_objective)
		hud.set_success_text("Você formou a ponte de %s!" % bridge_length)

	turtle.crossed.connect(_on_turtle_crossed)

	# Mostra o modal de objetivo antes de liberar a fase; o puzzle só começa
	# quando o jogador confirmar.
	if intro_modal:
		intro_modal.closed.connect(_on_intro_closed)
		intro_modal.show_intro(
			"Fase 1 — A Ponte da Tartaruga",
			"A tartaruga precisa atravessar o rio, mas não há ponte!\n\nColete os troncos e some os comprimentos. Quando achar que tem o suficiente, vá até a margem do rio e construa a ponte de exatamente %s.\n\nSe passar do valor, os troncos voltam e você tenta de novo." % bridge_length
		)
	else:
		_start_phase()


func _on_intro_closed() -> void:
	_start_phase()


## Inicia o puzzle (chamado depois que o jogador fecha o modal de objetivo).
func _start_phase() -> void:
	PuzzleManager.start_puzzle(target_value)


## Guia o jogador: quando já tem o suficiente, aponta para a margem do rio.
func _on_progress_changed(current: float, target: float) -> void:
	if not hud or not PuzzleManager.is_active:
		return
	if current >= target:
		hud.set_objective("Muito bem! Agora vá até a margem do rio e construa a ponte (tecla E).")
	else:
		hud.set_objective(_base_objective)


## Ao concluir o puzzle: a ponte aparece e a tartaruga atravessa o rio.
func _on_puzzle_completed() -> void:
	if hud:
		hud.set_objective("Ponte pronta! A tartaruga está atravessando o rio.")
	await _reveal_bridge()
	turtle.cross_to(turtle_target_x)


## Revela a ponte com um fade-in suave.
func _reveal_bridge() -> void:
	bridge.visible = true
	var tween: Tween = create_tween()
	tween.tween_property(bridge, "modulate:a", 1.0, 0.5)
	await tween.finished


func _on_turtle_crossed() -> void:
	if hud:
		hud.flash("A tartaruga atravessou o rio! Obrigada por ajudar!")
	# Mostra curiosidade via HUD (método estável, sem crashes de scene instanciation)
	hud.set_objective("Curiosidade: As tartarugas podem viver 100 anos ou mais! " + \
		"Elas têm casca dura para se protegerem de predadores e podem permanecer submersas por uma hora " + \
		"dependendo da espécie, usando o oxigênio da água através de sua pele e cloaca.")


	if hud:
		hud.set_objective("Ponte pronta! A tartaruga está atravessando o rio.")
	await _reveal_bridge()
	turtle.cross_to(turtle_target_x)


	bridge.visible = true
	var tween: Tween = create_tween()
	tween.tween_property(bridge, "modulate:a", 1.0, 0.5)
	await tween.finished
