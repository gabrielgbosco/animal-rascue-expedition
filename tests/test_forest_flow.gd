extends Node
## Testes de integração da Fase 1 (floresta) com a cena real.
##
## Percorre o fluxo do jogador sem teclado: fecha o modal, coleta os troncos,
## valida na margem e confere a travessia e a ficha da tartaruga.

const FOREST_SCENE: PackedScene = preload("res://scenes/forest.tscn")

## Tempo real máximo para esperar a travessia (a tartaruga leva ~5 s).
const CROSSING_TIMEOUT_MS: int = 20000

var failures: Array[String] = []


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


## Instancia a fase na árvore e deixa o _ready rodar (modal de introdução aberto).
func _spawn_forest() -> Node:
	# Não grava o diário em disco durante os testes.
	Journal.persist = false
	Journal.reset()
	var forest: Node = FOREST_SCENE.instantiate()
	get_tree().root.add_child(forest)
	await get_tree().process_frame
	return forest


## Equivale ao jogador clicar em "Começar" no modal de introdução.
func _close_intro(forest: Node) -> void:
	forest.intro_modal.start_button.pressed.emit()
	await get_tree().process_frame


func _collect(forest: Node, item_name: String) -> void:
	forest.get_node(item_name).interact()


func _validate_at_bridge(forest: Node) -> void:
	forest.get_node("BuildSite").interact()


func _cleanup(forest: Node) -> void:
	get_tree().paused = false
	forest.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


func _hud_objective(forest: Node) -> String:
	return forest.hud.objective_label.text


func _hud_feedback(forest: Node) -> String:
	return forest.hud.feedback_label.text


## Fluxo feliz: dois troncos de 3 m (6 m) -> ponte -> travessia -> ficha.
func test_fluxo_completo_com_dois_troncos_de_3m() -> void:
	var forest = await _spawn_forest()
	check(get_tree().paused, "o modal de introdução deve pausar o jogo")
	check(forest.intro_modal.visible, "o modal de introdução deve estar visível")

	await _close_intro(forest)
	check(not get_tree().paused, "fechar o modal deve retomar o jogo")
	check(PuzzleManager.is_active, "o puzzle deve iniciar após fechar o modal")
	check(is_equal_approx(PuzzleManager.target_value, 6.0), "o alvo da fase deve ser 6 m")

	var crossings: Array = [0]
	forest.turtle.crossed.connect(func() -> void: crossings[0] += 1)

	_collect(forest, "Tronco_A")
	_collect(forest, "Tronco_B")
	check(is_equal_approx(PuzzleManager.current_value, 6.0), "dois troncos de 3 m devem somar 6 m")
	check(_hud_objective(forest).begins_with("Muito bem"), "com 6 m a HUD deve mandar construir a ponte")

	_validate_at_bridge(forest)
	check(PuzzleManager.current_value == 6.0 and not PuzzleManager.is_active,
		"validar 6 m deve concluir o puzzle")

	var started: int = Time.get_ticks_msec()
	while not forest.curiosity_card.visible and Time.get_ticks_msec() - started < CROSSING_TIMEOUT_MS:
		await get_tree().process_frame

	check(forest.curiosity_card.visible, "a ficha da tartaruga deve aparecer após a travessia")
	if forest.curiosity_card.visible:
		check(get_tree().paused, "a ficha deve pausar o jogo")
		check(forest.curiosity_card.name_label.text == "Tartaruga", "a ficha deve mostrar a tartaruga")
		check(forest.curiosity_card.scientific_label.text.begins_with("Nome científico: "),
			"a ficha deve trazer o nome científico")
		check(forest.curiosity_card.replay_button.text == "Jogar de novo", "a ficha deve ter o botão de replay")
	check(is_equal_approx(forest.turtle.position.x, forest.turtle_target_x),
		"a tartaruga deve chegar à margem do jogador")
	check(forest.bridge.visible, "a ponte deve estar visível após a conclusão")
	# Regressão: antes, a travessia era disparada de novo em loop.
	check(crossings[0] == 1, "a tartaruga deve atravessar exatamente uma vez (obtido: %d)" % crossings[0])
	check(Journal.get_state("tartaruga") == Journal.HELPED, "ao atravessar, a tartaruga deve ficar 'ajudada' no diário")

	await _cleanup(forest)


## 3 m + 4 m = 7 m: a HUD precisa avisar que passou e explicar o reinício.
func test_sete_metros_orienta_a_voltar_os_troncos() -> void:
	var forest = await _spawn_forest()
	await _close_intro(forest)

	_collect(forest, "Tronco_A")
	_collect(forest, "Tronco_C")
	check(is_equal_approx(PuzzleManager.current_value, 7.0), "3 m + 4 m deve somar 7 m")
	check(_hud_objective(forest).begins_with("Passou de 6 m"),
		"com 7 m a HUD deve avisar que passou do alvo (obtido: %s)" % _hud_objective(forest))

	_validate_at_bridge(forest)
	check(_hud_feedback(forest).begins_with("Passou de 6 m"),
		"ao validar 7 m o feedback deve dizer que passou de 6 m")
	check(PuzzleManager.is_active and is_equal_approx(PuzzleManager.current_value, 0.0),
		"após ultrapassar, o puzzle deve reiniciar zerado")
	check(forest.get_node("Tronco_A").visible, "os troncos devem voltar a aparecer após o reinício")
	check(is_equal_approx(forest.turtle.position.x, 2050.0), "a tartaruga não deve se mover ao errar")
	check(not forest.curiosity_card.visible, "a ficha não deve aparecer ao errar")

	await _cleanup(forest)


## Fotografar só funciona perto do animal e registra a observação, não a ficha.
func test_camera_sem_animal_na_tela_avisa() -> void:
	var forest = await _spawn_forest()
	await _close_intro(forest)
	var player = forest.player
	var turtle = forest.turtle

	var misses: Array = [0]
	player.photo_missed.connect(func() -> void: misses[0] += 1)

	# No ponto de partida a tartaruga ainda está fora da tela.
	player.get_node("Camera2D").force_update_scroll()
	player._process(0.0)
	check(not turtle.photo_hint.visible, "o aviso 'Fotografar' não deve aparecer com a tartaruga fora da tela")

	player._try_photograph()
	check(misses[0] == 1, "fotografar sem animal na tela deve emitir photo_missed")
	check(_hud_feedback(forest).begins_with("Nenhum animal à vista"),
		"a HUD deve avisar que não há animal (obtido: %s)" % _hud_feedback(forest))
	check(Journal.get_state("tartaruga") == Journal.UNKNOWN, "nada deve ser registrado no diário")

	await _cleanup(forest)


## Regressão: o rio barra o jogador. Do ponto mais distante que ele alcança, a
## tartaruga precisa estar na tela e dar para fotografá-la. (Antes o alcance era
## de 260 px e era impossível fotografá-la jogando de verdade.)
func test_da_margem_do_rio_da_para_fotografar_a_tartaruga() -> void:
	var forest = await _spawn_forest()
	await _close_intro(forest)
	var player = forest.player
	var turtle = forest.turtle

	# Anda para a direita de verdade, como o jogador faria, até o rio barrar.
	Input.action_press("right")
	var started: int = Time.get_ticks_msec()
	while Time.get_ticks_msec() - started < 4500:
		await get_tree().process_frame
	Input.action_release("right")

	player.get_node("Camera2D").force_update_scroll()
	await get_tree().process_frame # o _process do jogador atualiza os avisos

	check(player.global_position.x > 1000.0,
		"o jogador deve ter chegado à margem (x = %d)" % player.global_position.x)
	check(player.global_position.x < 1200.0,
		"o rio deve barrar o jogador (x = %d)" % player.global_position.x)
	check(turtle.photo_hint.visible, "o aviso 'Fotografar' deve aparecer com a tartaruga na tela")

	player._try_photograph()
	check(Journal.get_state("tartaruga") == Journal.OBSERVED, "a foto da margem deve registrar a observação")
	check(_hud_feedback(forest).begins_with("Você observou: Tartaruga"),
		"a HUD deve confirmar a observação (obtido: %s)" % _hud_feedback(forest))
	check(not forest.curiosity_card.visible, "observar não deve abrir a ficha completa")

	# Segunda foto: não é novidade e o aviso some.
	player._try_photograph()
	check(_hud_feedback(forest).begins_with("Você já fotografou: Tartaruga"),
		"fotografar de novo deve avisar que já está registrado (obtido: %s)" % _hud_feedback(forest))
	player._process(0.0)
	check(not turtle.photo_hint.visible, "o aviso 'Fotografar' deve sumir depois da primeira foto")

	await _cleanup(forest)


## Um tronco de 3 m não basta: validar deve pedir os 3 m que faltam.
func test_validar_com_3m_pede_o_que_falta() -> void:
	var forest = await _spawn_forest()
	await _close_intro(forest)

	_collect(forest, "Tronco_A")
	_validate_at_bridge(forest)
	check(_hud_feedback(forest).begins_with("Ainda faltam 3 m"),
		"com 3 m validados o feedback deve dizer quanto falta (obtido: %s)" % _hud_feedback(forest))
	check(PuzzleManager.is_active, "o puzzle deve continuar ativo para o jogador completar")

	await _cleanup(forest)
