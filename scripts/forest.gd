extends Node2D
## Script da Fase 1 (Floresta): configura o puzzle genérico com o tema
## "comprimento" (troncos) e reage à conclusão da fase.

## Comprimento total necessário para formar a ponte (soma dos troncos corretos).
@export var target_value: float = 6.0

@onready var hud: CanvasLayer = $HUD
@onready var intro_modal: IntroModal = $IntroModal
@onready var curiosity_card: CuriosityCard = $CuriosityCard
@onready var bridge: Node2D = $Bridge
@onready var turtle: Turtle = $Turtle
@onready var player: Player = $player

## Coordenada X onde a tartaruga termina de atravessar (margem do jogador).
@export var turtle_target_x: float = 1250.0

## Texto do objetivo padrão (restaurado enquanto o jogador ainda não tem o total).
var _base_objective: String = ""


func _ready() -> void:
	PuzzleManager.puzzle_completed.connect(_on_puzzle_completed)
	PuzzleManager.progress_changed.connect(_on_progress_changed)
	player.photo_taken.connect(_on_photo_taken)
	player.photo_missed.connect(_on_photo_missed)
	turtle.crossed.connect(_on_turtle_crossed)
	curiosity_card.replay_requested.connect(_on_replay_requested)

	# Câmera e diário: ícones com as teclas no lado direito e o caderno (J).
	var journal_screen := JournalScreen.new()
	add_child(journal_screen)
	var toolbar := ExplorerToolbar.new()
	add_child(toolbar)
	toolbar.watch_journal(journal_screen)
	toolbar.watch_camera(player)

	var bridge_length: String = Units.format(target_value, Units.QuantityType.LENGTH)
	_base_objective = "Ajude a tartaruga: colete troncos até somar %s e construa a ponte na margem do rio." % bridge_length

	if hud:
		hud.set_objective(_base_objective)
		hud.set_success_text("Você formou a ponte de %s!" % bridge_length)

	# Mostra o modal de objetivo antes de liberar a fase; o puzzle só começa
	# quando o jogador confirmar.
	if intro_modal:
		intro_modal.closed.connect(_on_intro_closed)
		intro_modal.show_intro(
			"Fase 1 — A Ponte da Tartaruga",
			"A tartaruga precisa atravessar o rio, mas não há ponte!\n\nColete os troncos e some os comprimentos. Quando achar que tem o suficiente, vá até a margem do rio e construa a ponte de exatamente %s.\n\nSe passar do valor, os troncos voltam e você tenta de novo.\n\nCâmera: quando um animal aparecer na tela, aperte F para fotografá-lo. Aperte J para abrir o diário." % bridge_length
		)
	else:
		_start_phase()


func _on_intro_closed() -> void:
	_start_phase()


## Inicia o puzzle (chamado depois que o jogador fecha o modal de objetivo).
func _start_phase() -> void:
	PuzzleManager.start_puzzle(target_value)


## Guia o jogador conforme o total coletado: só manda construir quando o valor
## é exatamente o alvo; se passou, avisa que é preciso recomeçar.
func _on_progress_changed(current: float, target: float) -> void:
	if not hud or not PuzzleManager.is_active:
		return
	if is_equal_approx(current, target):
		hud.set_objective("Muito bem! Agora vá até a margem do rio e construa a ponte (tecla E).")
	elif current > target:
		hud.set_objective("Passou de %s (você tem %s). Vá até a margem e aperte E para devolver os troncos e tentar de novo." % [
			Units.format(target, Units.QuantityType.LENGTH),
			Units.format(current, Units.QuantityType.LENGTH),
		])
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


## Foto tirada: confirma na HUD e explica o que mudou no diário.
func _on_photo_taken(species_id: String, is_new: bool) -> void:
	if not hud:
		return
	var species_name: String = SpeciesDB.get_data(species_id)["nome"]
	if is_new:
		hud.flash("Você observou: %s. Veja no diário (J)." % species_name)
	elif Journal.get_state(species_id) == Journal.HELPED:
		hud.flash("%s já está completo no seu diário (J)." % species_name)
	else:
		hud.flash("Você já fotografou: %s. Ajude o animal para completar a ficha." % species_name)


## Câmera sem animal na tela: avisa em vez de não fazer nada.
func _on_photo_missed() -> void:
	if hud:
		hud.flash("Nenhum animal à vista. Procure um animal na tela e aperte F.")


## Quando a tartaruga chega ao outro lado, libera a ficha completa da espécie.
func _on_turtle_crossed() -> void:
	Journal.help(turtle.species_id)
	if hud:
		hud.flash("A tartaruga atravessou o rio! Obrigada por ajudar!")
		hud.set_objective("Missão cumprida!")
	await get_tree().create_timer(1.5).timeout

	var data: Dictionary = SpeciesDB.get_data(turtle.species_id)
	var image: Texture2D = (load(data["imagem"]) as Texture2D) if data["imagem"] != "" else null
	curiosity_card.show_card(
		image,
		data["nome"],
		data["cientifico"],
		data["habitat"],
		data["alimentacao"],
		data["curiosidade"]
	)


## Reinicia a fase (botão "Jogar de novo" da ficha).
func _on_replay_requested() -> void:
	get_tree().reload_current_scene()
