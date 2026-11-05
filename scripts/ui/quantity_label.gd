class_name QuantityLabel
extends Label
## Label que exibe uma [Quantity] formatada no padrão brasileiro (vírgula decimal).
##
## Uso: [code]label.show_quantity(PuzzleManager...) [/code] ou diretamente
## [code]label.show_quantity(Quantity.of(1.2, "m"))  # -> "1,2 m"[/code]

## Exibe a grandeza. Se [param unit] for vazio, a unidade é escolhida automaticamente.
func show_quantity(quantity: Quantity, unit: String = "") -> void:
	if quantity == null:
		text = "—"
		return
	text = quantity.format(unit)
