class_name ExplorerToolbar
extends CanvasLayer
## Atalhos do explorador no lado direito da tela: câmera e diário, cada um com
## o ícone e a tecla correspondente (lida do InputMap, então acompanha o remapeamento).

const INK: Color = Color(0.23, 0.15, 0.09)
const CREAM: Color = Color(0.97, 0.93, 0.83)

var camera_icon: ToolIcon
var journal_icon: ToolIcon

var _box: VBoxContainer
var _flash: ColorRect


func _ready() -> void:
	layer = 5
	_build()


## Texto da primeira tecla mapeada para a ação (ex.: "F"). "?" se não houver.
static func key_text(action: String) -> String:
	if not InputMap.has_action(action):
		return "?"
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey:
			var key_event: InputEventKey = event
			if key_event.physical_keycode != KEY_NONE:
				return key_event.as_text_physical_keycode()
			return key_event.as_text_keycode()
	return "?"


## Acende o ícone do diário enquanto ele estiver aberto.
func watch_journal(screen: JournalScreen) -> void:
	screen.toggled.connect(_on_journal_toggled)


## Faz o flash da câmera sempre que o jogador fotografa um animal.
## [param source] precisa ter o sinal photo_taken (ex.: o [Player]).
func watch_camera(source: Object) -> void:
	source.photo_taken.connect(_on_photo_taken)


## Flash branco na tela e ícone da câmera aceso por um instante.
func flash_camera() -> void:
	camera_icon.highlighted = true
	_flash.color.a = 0.75
	var tween: Tween = create_tween()
	tween.tween_property(_flash, "color:a", 0.0, 0.35)
	await get_tree().create_timer(0.4).timeout
	camera_icon.highlighted = false


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# Flash da câmera: tela inteira, transparente até a foto.
	_flash = ColorRect.new()
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.color = Color(1, 1, 1, 0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_flash)

	# Lado direito, na parte de cima: no meio da lateral os ícones cobririam
	# o animal quando o jogador está na margem do rio.
	_box = VBoxContainer.new()
	_box.anchor_left = 1.0
	_box.anchor_right = 1.0
	_box.offset_left = -130.0
	_box.offset_right = -24.0
	_box.offset_top = 120.0
	_box.offset_bottom = 440.0
	_box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_theme_constant_override("separation", 28)
	root.add_child(_box)

	camera_icon = _add_item(ToolIcon.Kind.CAMERA, "Câmera", "photo")
	journal_icon = _add_item(ToolIcon.Kind.JOURNAL, "Diário", "journal")


func _add_item(kind: int, title: String, action: String) -> ToolIcon:
	var item := VBoxContainer.new()
	item.alignment = BoxContainer.ALIGNMENT_CENTER
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.add_theme_constant_override("separation", 6)
	_box.add_child(item)

	var icon := ToolIcon.new()
	icon.kind = kind
	icon.custom_minimum_size = Vector2(80, 80)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.add_child(icon)

	item.add_child(_make_keycap(key_text(action)))

	var caption := Label.new()
	caption.text = title
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 17)
	caption.add_theme_color_override("font_color", CREAM)
	caption.add_theme_color_override("font_outline_color", INK)
	caption.add_theme_constant_override("outline_size", 5)
	item.add_child(caption)
	return icon


## Tecla desenhada como um keycap (com a borda inferior mais grossa).
func _make_keycap(text: String) -> Control:
	var style := StyleBoxFlat.new()
	style.bg_color = CREAM
	style.border_color = INK
	style.set_border_width_all(2)
	style.border_width_bottom = 5
	style.set_corner_radius_all(8)
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 3.0
	style.content_margin_bottom = 3.0

	var keycap := PanelContainer.new()
	keycap.add_theme_stylebox_override("panel", style)
	keycap.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	keycap.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", INK)
	keycap.add_child(label)
	return keycap


func _on_journal_toggled(is_open: bool) -> void:
	journal_icon.highlighted = is_open


func _on_photo_taken(_species_id: String, _is_new: bool) -> void:
	flash_camera()
