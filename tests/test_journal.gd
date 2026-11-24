extends Node
## Testes do diário (Journal), do catálogo (SpeciesDB), da tela do diário e da
## barra de atalhos (câmera e diário).

const TEST_PATH: String = "user://test_journal_tmp.json"

## Simula o sinal do jogador para testar a barra de atalhos.
signal photo_taken(species_id: String, is_new: bool)

var failures: Array[String] = []


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _fresh() -> void:
	Journal.persist = false
	Journal.reset()
	get_tree().paused = false


## Evento de tecla que casa tanto por keycode quanto por physical_keycode.
func _key(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = true
	return event


func _open_screen() -> JournalScreen:
	var screen: JournalScreen = JournalScreen.new()
	add_child(screen)
	return screen


func test_catalogo_tem_as_especies_previstas_no_gdd() -> void:
	var ids: Array[String] = SpeciesDB.ids()
	for expected: String in ["tartaruga", "golfinho", "cabra-montesa", "elefante"]:
		check(ids.has(expected), "catálogo deve ter %s" % expected)
		check(SpeciesDB.get_data(expected).get("nome", "") != "", "%s precisa de nome popular" % expected)


func test_observar_so_registra_na_primeira_vez() -> void:
	_fresh()
	check(Journal.observe("golfinho"), "a primeira observação deve ser registrada")
	check(not Journal.observe("golfinho"), "observar de novo não deve registrar outra vez")
	check(Journal.get_state("golfinho") == Journal.OBSERVED, "estado deve ser OBSERVED")


func test_ajudar_funciona_sem_foto_previa() -> void:
	_fresh()
	check(Journal.help("elefante"), "ajudar deve funcionar mesmo sem foto")
	check(Journal.get_state("elefante") == Journal.HELPED, "estado deve ser HELPED")
	check(not Journal.help("elefante"), "ajudar duas vezes não deve registrar de novo")


func test_observar_depois_de_ajudar_nao_rebaixa() -> void:
	_fresh()
	Journal.help("tartaruga")
	Journal.observe("tartaruga")
	check(Journal.get_state("tartaruga") == Journal.HELPED, "observar não deve rebaixar uma espécie ajudada")


func test_especie_desconhecida_e_ignorada() -> void:
	_fresh()
	check(not Journal.observe("dinossauro"), "espécie inexistente não deve ser registrada")
	check(not Journal.help("dinossauro"), "espécie inexistente não deve ser marcada como ajudada")


func test_estado_persiste_em_disco() -> void:
	# Instâncias separadas do script, para não mexer no autoload de verdade.
	var journal_script: Script = load("res://scripts/core/journal.gd")

	var first = journal_script.new()
	first.save_path = TEST_PATH
	first.persist = true
	first.reset()
	first.observe("golfinho")
	first.help("cabra-montesa")
	first.free()

	var second = journal_script.new()
	second.save_path = TEST_PATH
	second.persist = true
	second.load_from_disk()
	check(second.get_state("golfinho") == Journal.OBSERVED, "golfinho observada deve persistir")
	check(second.get_state("cabra-montesa") == Journal.HELPED, "cabra-montesa ajudada deve persistir")
	second.free()

	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))


func test_acoes_de_teclado_estao_mapeadas() -> void:
	check(InputMap.has_action("photo"), "ação 'photo' deve existir no InputMap")
	check(InputMap.has_action("journal"), "ação 'journal' deve existir no InputMap")
	check(InputMap.event_is_action(_key(KEY_F), "photo"), "a tecla F deve disparar 'photo'")
	check(InputMap.event_is_action(_key(KEY_J), "journal"), "a tecla J deve disparar 'journal'")


func test_diario_mostra_o_estado_de_cada_especie() -> void:
	_fresh()
	Journal.observe("golfinho")
	Journal.help("tartaruga")
	var screen := _open_screen()

	check(screen.entry_buttons.size() == 4, "o índice deve listar as 4 espécies")
	check(screen.entry_buttons[0].text.begins_with("Tartaruga") and screen.entry_buttons[0].text.contains("ajudada"),
		"tartaruga ajudada deve aparecer como ajudada (obtido: %s)" % screen.entry_buttons[0].text)
	check(screen.entry_buttons[1].text.contains("observada"), "golfinho deve aparecer como observado")
	check(screen.entry_buttons[3].text.begins_with("???"), "espécie não vista deve aparecer como '???'")

	# Página aberta na tartaruga (ajudada): ficha completa, sem a dica.
	check(screen.detail_name.text == "Tartaruga", "a primeira página deve ser da tartaruga")
	check(screen.detail_values[0].visible and screen.detail_values[3].text != "",
		"espécie ajudada deve mostrar a ficha completa")
	check(not screen.detail_hint.visible, "espécie ajudada não deve mostrar a dica")

	# Golfinho (só observado): sem ficha, com dica para ajudar o animal.
	screen.select(1)
	check(screen.detail_name.text == "Golfinho", "a segunda página deve ser do golfinho")
	check(not screen.detail_values[0].visible, "espécie só observada não deve mostrar a ficha")
	check(screen.detail_hint.visible and screen.detail_hint.text.contains("Ajude"),
		"espécie observada deve explicar como completar a ficha")

	# Elefante (não visto): nome escondido.
	screen.select(3)
	check(screen.detail_name.text == "???", "espécie não vista deve esconder o nome")
	check(not screen.detail_values[1].visible, "espécie não vista não deve mostrar a ficha")

	screen.queue_free()


func test_diario_pausa_o_jogo_e_fecha_com_j_ou_esc() -> void:
	_fresh()
	var screen := _open_screen()
	check(not screen.visible, "o diário deve começar fechado")

	screen._unhandled_input(_key(KEY_J))
	check(screen.visible and get_tree().paused, "J deve abrir o diário e pausar o jogo")
	screen._unhandled_input(_key(KEY_J))
	check(not screen.visible and not get_tree().paused, "J de novo deve fechar e retomar o jogo")

	screen._unhandled_input(_key(KEY_J))
	screen._unhandled_input(_key(KEY_ESCAPE))
	check(not screen.visible and not get_tree().paused, "Esc deve fechar o diário e retomar o jogo")

	screen.queue_free()


func test_diario_nao_abre_sobre_outro_modal() -> void:
	_fresh()
	var screen := _open_screen()

	get_tree().paused = true # como o modal de introdução ou a ficha do animal
	screen._unhandled_input(_key(KEY_J))
	check(not screen.visible, "J não deve abrir o diário sobre outro modal")
	check(get_tree().paused, "o modal que já pausava o jogo deve continuar valendo")

	get_tree().paused = false
	screen.queue_free()


func test_diario_vira_a_pagina_com_a_e_d() -> void:
	_fresh()
	var screen := _open_screen()
	screen.open()

	screen._unhandled_input(_key(KEY_D))
	check(screen.selected_index == 1, "D deve ir para a próxima página")
	screen._unhandled_input(_key(KEY_A))
	screen._unhandled_input(_key(KEY_A))
	check(screen.selected_index == 0, "A não deve passar da primeira página")
	for i: int in 6:
		screen._unhandled_input(_key(KEY_D))
	check(screen.selected_index == 3, "D não deve passar da última página")

	screen.close()
	screen.queue_free()


func test_barra_de_atalhos_mostra_as_teclas_e_acende_o_diario() -> void:
	_fresh()
	check(ExplorerToolbar.key_text("photo") == "F", "o atalho da câmera deve mostrar F")
	check(ExplorerToolbar.key_text("journal") == "J", "o atalho do diário deve mostrar J")

	var toolbar := ExplorerToolbar.new()
	add_child(toolbar)
	var screen := _open_screen()
	toolbar.watch_journal(screen)

	check(not toolbar.journal_icon.highlighted, "o ícone do diário começa apagado")
	screen.open()
	check(toolbar.journal_icon.highlighted, "o ícone do diário deve acender com o diário aberto")
	screen.close()
	check(not toolbar.journal_icon.highlighted, "o ícone do diário deve apagar ao fechar")

	# Este próprio nó faz o papel do jogador: tem o sinal photo_taken.
	toolbar.watch_camera(self)
	photo_taken.emit("golfinho", true)
	check(toolbar.camera_icon.highlighted, "o ícone da câmera deve acender ao tirar uma foto")
	check(toolbar._flash.color.a > 0.0, "a tela deve dar o flash da câmera")

	screen.queue_free()
	toolbar.queue_free()
