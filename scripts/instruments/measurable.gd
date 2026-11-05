class_name Measurable
extends Area2D
## Componente: um objeto do mundo cuja medida pode ser lida com a régua.
##
## Guarda o valor e a unidade declarados no editor e os expõe como uma
## [Quantity]. Qualquer nó que herde de Measurable pode ser medido.

## Valor numérico medido (ex.: 90).
@export var measure_value: float = 1.0

## Unidade da medida (ex.: "cm", "m", "km").
@export var measure_unit: String = "m"

## Grandeza calculada a partir de [member measure_value] + [member measure_unit].
var quantity: Quantity = null


func _ready() -> void:
	quantity = Quantity.of(measure_value, measure_unit)


## Retorna a grandeza deste objeto (usada pela régua).
func get_quantity() -> Quantity:
	return quantity
