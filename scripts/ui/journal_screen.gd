class_name JournalScreen
extends CanvasLayer
## Diário do explorador: um caderno aberto com duas páginas.
##
## Página esquerda: índice das espécies. Página direita: a espécie selecionada
## (foto, nome, situação e, se ela foi ajudada, a ficha completa).
##
## J abre e fecha. Abrir pausa o jogo, mas só abre se nada mais estiver pausando
## (modal de introdução, ficha). A/D ou setas viram a página; Esc fecha.

## Emitido ao abrir e ao fechar o diário.
signal toggled(is_open: bool)

const BOOK_SIZE: Vector2 = Vector2(1320, 820)
const INK: Color = Color(0.23, 0.15, 0.09)
const INK_SOFT: Color = Color(0.45, 0.33, 0.22)
const COVER: Color = Color(0.36, 0.2, 0.1)
const COVER_DARK: Color = Color(0.22, 0.12, 0.06)
const COLOR_HELPED: Color = Color(0.16, 0.46, 0.22)
const COLOR_OBSERVED: Color = Color(0.72, 0.45, 0.08)
const COLOR_UNKNOWN: Color = Color(0.5, 0.45, 0.4)

## Campos da ficha: [chave em SpeciesDB, título exibido].
const FIELDS: Array = [
	["cientifico", "Nome científico"],
	["habitat", "Habitat"],
	["alimentacao", "Alimentação"],
	["curiosidade", "Curiosidade"],
]

var selected_index: int = 0
var entry_buttons: Array[Button] = []
var detail_name: Label
var detail_stamp: Label
var detail_hint: Label
var detail_values: Array[Label] = []

var _ids: Array[String] = []
var _photo: TextureRect
var _photo_placeholder: Label
var _field_headings: Array[Label] = []
var _page_label: Label


func _ready() -> void:
	layer = 12
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_ids = SpeciesDB.ids()
	_build()
	Journal.changed.connect(_refresh)
	_refresh()


func _exit_tree() -> void:
	# Se a fase for descarregada com o diário aberto, não deixa o jogo pausado.
	if visible and is_inside_tree():
		get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("journal"):
		if visible:
			close()
		elif not get_tree().paused:
			open()
		else:
			return
		get_viewport().set_input_as_handled()
	elif visible:
		if event.is_action_pressed("ui_cancel"):
			close()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("left"):
			select(selected_index - 1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("right"):
			select(selected_index + 1)
			get_viewport().set_input_as_handled()


## Abre o diário e pausa o jogo. Não abre se outro modal já estiver pausando.
func open() -> void:
	if visible or get_tree().paused:
		return
	visible = true
	get_tree().paused = true
	_refresh()
	toggled.emit(true)


func close() -> void:
	if not visible:
		return
	visible = false
	get_tree().paused = false
	toggled.emit(false)


## Vira para a espécie [param index] (limitado ao início e ao fim do diário).
func select(index: int) -> void:
	selected_index = clampi(index, 0, _ids.size() - 1)
	_refresh()


# --- Construção da interface -------------------------------------------------

func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.6)
	root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var holder := Control.new()
	holder.custom_minimum_size = BOOK_SIZE
	center.add_child(holder)

	var cover := Panel.new()
	cover.set_anchors_preset(Control.PRESET_FULL_RECT)
	cover.add_theme_stylebox_override("panel", _cover_style())
	holder.add_child(cover)

	var inner := MarginContainer.new()
	inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side: String in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		inner.add_theme_constant_override(side, 26)
	holder.add_child(inner)

	var spread := HBoxContainer.new()
	spread.add_theme_constant_override("separation", 0)
	inner.add_child(spread)

	var left := PaperPage.new()
	left.is_left = true
	left.draw_rules = false # o índice tem as próprias linhas
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spread.add_child(left)

	var spine := ColorRect.new()
	spine.color = COVER_DARK
	spine.custom_minimum_size = Vector2(10, 0)
	spread.add_child(spine)

	var right := PaperPage.new()
	right.is_left = false
	right.rule_start = 250.0 # pautas só abaixo da foto e do título
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spread.add_child(right)

	_build_index_page(left)
	_build_detail_page(right)


func _build_index_page(page: Control) -> void:
	var box := _page_box(page, 60, 40, 40, 28)
	box.add_child(_make_label("Diário do Explorador", 38, INK))
	box.add_child(_make_label("Animais que encontrei pelo caminho", 18, INK_SOFT))
	box.add_child(_spacer(18))

	for i: int in _ids.size():
		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(0, 64)
		button.add_theme_font_size_override("font_size", 26)
		button.pressed.connect(select.bind(i))
		box.add_child(button)
		entry_buttons.append(button)

	var filler := Control.new()
	filler.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(filler)
	box.add_child(_make_label("A / D ou setas: virar a página", 16, INK_SOFT))


func _build_detail_page(page: Control) -> void:
	var box := _page_box(page, 40, 36, 60, 28)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 26)
	box.add_child(top)

	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(1, 1, 1)
	frame_style.border_color = Color(0.8, 0.74, 0.62)
	frame_style.set_border_width_all(2)
	frame_style.set_content_margin_all(10)
	frame_style.shadow_color = Color(0, 0, 0, 0.25)
	frame_style.shadow_size = 6
	frame_style.shadow_offset = Vector2(2, 3)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", frame_style)
	top.add_child(frame)

	var photo_area := Control.new()
	photo_area.custom_minimum_size = Vector2(230, 170)
	frame.add_child(photo_area)

	var photo_bg := ColorRect.new()
	photo_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	photo_bg.color = Color(0.82, 0.88, 0.8)
	photo_area.add_child(photo_bg)

	_photo = TextureRect.new()
	_photo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	photo_area.add_child(_photo)

	_photo_placeholder = _make_label("?", 72, INK_SOFT)
	_photo_placeholder.set_anchors_preset(Control.PRESET_FULL_RECT)
	_photo_placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_photo_placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	photo_area.add_child(_photo_placeholder)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_child(title_box)

	detail_name = _make_label("", 42, INK)
	title_box.add_child(detail_name)
	detail_stamp = _make_label("", 18, INK_SOFT)
	title_box.add_child(detail_stamp)

	detail_hint = _make_label("", 22, INK_SOFT)
	detail_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(detail_hint)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)

	var fields := VBoxContainer.new()
	fields.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fields.add_theme_constant_override("separation", 4)
	scroll.add_child(fields)

	for field: Array in FIELDS:
		var heading := _make_label(str(field[1]).to_upper(), 14, INK_SOFT)
		fields.add_child(heading)
		_field_headings.append(heading)

		var value := _make_label("", 21, INK)
		value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fields.add_child(value)
		detail_values.append(value)
		fields.add_child(_spacer(6))

	var footer := HBoxContainer.new()
	box.add_child(footer)
	footer.add_child(_make_label("J ou Esc: fechar", 16, INK_SOFT))
	var footer_filler := Control.new()
	footer_filler.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(footer_filler)
	_page_label = _make_label("", 18, INK_SOFT)
	footer.add_child(_page_label)


func _page_box(page: Control, left: int, top: int, right: int, bottom: int) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_bottom", bottom)
	page.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)
	return box


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _spacer(height: float) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	return spacer


func _cover_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = COVER
	style.border_color = COVER_DARK
	style.set_border_width_all(4)
	style.set_corner_radius_all(22)
	style.shadow_color = Color(0, 0, 0, 0.55)
	style.shadow_size = 24
	style.shadow_offset = Vector2(0, 8)
	return style


func _entry_style(selected: bool, hovered: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(6)
	style.content_margin_left = 12.0
	# Linha de pauta embaixo de cada item do índice.
	style.border_width_bottom = 2
	style.border_color = Color(0.52, 0.62, 0.78, 0.6)
	if selected:
		style.bg_color = Color(1.0, 0.9, 0.35, 0.55) # marca-texto
	elif hovered:
		style.bg_color = Color(1.0, 0.9, 0.35, 0.22)
	else:
		style.bg_color = Color(0, 0, 0, 0)
	return style


# --- Atualização do conteúdo -------------------------------------------------

func _refresh() -> void:
	if entry_buttons.is_empty():
		return

	for i: int in _ids.size():
		var state: int = Journal.get_state(_ids[i])
		var data: Dictionary = SpeciesDB.get_data(_ids[i])
		var button: Button = entry_buttons[i]
		var shown_name: String = str(data["nome"]) if state != Journal.UNKNOWN else "???"
		button.text = "%s  —  %s" % [shown_name, _status_word(state)]
		for color_name: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			button.add_theme_color_override(color_name, _state_color(state))
		var selected: bool = i == selected_index
		for style_name: String in ["normal", "pressed", "focus"]:
			button.add_theme_stylebox_override(style_name, _entry_style(selected))
		button.add_theme_stylebox_override("hover", _entry_style(selected, true))

	_refresh_detail()


func _refresh_detail() -> void:
	var species_id: String = _ids[selected_index]
	var state: int = Journal.get_state(species_id)
	var data: Dictionary = SpeciesDB.get_data(species_id)

	detail_name.text = str(data["nome"]) if state != Journal.UNKNOWN else "???"
	detail_stamp.text = _status_word(state).to_upper()
	detail_stamp.add_theme_color_override("font_color", _state_color(state))

	var image: Texture2D = null
	if str(data["imagem"]) != "":
		image = load(str(data["imagem"])) as Texture2D
	_photo.texture = image
	# Espécie ainda não vista aparece como silhueta.
	_photo.modulate = Color.BLACK if state == Journal.UNKNOWN else Color.WHITE
	_photo_placeholder.visible = image == null

	var helped: bool = state == Journal.HELPED
	for i: int in FIELDS.size():
		_field_headings[i].visible = helped
		detail_values[i].visible = helped
		if helped:
			detail_values[i].text = str(data[str(FIELDS[i][0])])

	detail_hint.visible = not helped
	if state == Journal.OBSERVED:
		detail_hint.text = "Você viu este animal de perto. Ajude-o a concluir a missão para completar a ficha."
	else:
		detail_hint.text = "Ainda não encontrado. Explore as fases e use a câmera (%s) quando estiver perto de um animal." % ExplorerToolbar.key_text("photo")

	_page_label.text = "%d / %d" % [selected_index + 1, _ids.size()]


func _status_word(state: int) -> String:
	if state == Journal.HELPED:
		return "ajudada"
	if state == Journal.OBSERVED:
		return "observada"
	return "não vista"


func _state_color(state: int) -> Color:
	if state == Journal.HELPED:
		return COLOR_HELPED
	if state == Journal.OBSERVED:
		return COLOR_OBSERVED
	return COLOR_UNKNOWN
