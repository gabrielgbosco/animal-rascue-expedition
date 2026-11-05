class_name Quantity
extends RefCounted
## Quantity — uma grandeza física medida: um valor + o tipo de grandeza.
##
## O valor é SEMPRE armazenado na unidade-base da grandeza (m, g ou L), o que
## garante que somas e comparações entre unidades diferentes (ex.: 1,20 m + 90 cm)
## funcionem corretamente. A unidade escolhida serve apenas para exibição/entrada.
##
## Exemplos:
## [codeblock]
## var a := Quantity.of(1.20, "m")
## var b := Quantity.of(90.0, "cm")
## print(a.add(b).format())  # "2,1 m"
## [/codeblock]

## Tipo de grandeza (ver Units.QuantityType).
var type: int = Units.QuantityType.LENGTH

## Valor na unidade-base da grandeza (metros, gramas ou litros).
var base_value: float = 0.0


func _init(p_type: int = Units.QuantityType.LENGTH, p_base_value: float = 0.0) -> void:
	type = p_type
	base_value = p_base_value


## Cria uma grandeza a partir de um valor e uma unidade explícita (ex.: 90, "cm").
static func of(value: float, unit: String) -> Quantity:
	var resolved: int = Units.get_type(unit)
	if resolved == -1:
		push_error("Quantity: unidade inválida '%s'." % unit)
		return Quantity.new()
	return Quantity.new(resolved, Units.to_base(value, unit))


static func length(value: float, unit: String) -> Quantity:
	return Quantity.new(Units.QuantityType.LENGTH, Units.to_base(value, unit))


static func mass(value: float, unit: String) -> Quantity:
	return Quantity.new(Units.QuantityType.MASS, Units.to_base(value, unit))


static func capacity(value: float, unit: String) -> Quantity:
	return Quantity.new(Units.QuantityType.CAPACITY, Units.to_base(value, unit))


## Retorna o valor expresso na unidade pedida.
func to_unit(unit: String) -> float:
	return Units.from_base(base_value, unit)


## Soma outra grandeza do mesmo tipo e retorna o resultado (não altera esta).
func add(other: Quantity) -> Quantity:
	if other.type != type:
		push_error("Quantity: soma de grandezas diferentes.")
		return duplicate()
	return Quantity.new(type, base_value + other.base_value)


## Subtrai outra grandeza do mesmo tipo e retorna o resultado.
func sub(other: Quantity) -> Quantity:
	if other.type != type:
		push_error("Quantity: subtração de grandezas diferentes.")
		return duplicate()
	return Quantity.new(type, base_value - other.base_value)


## Compara com outra grandeza: -1 se menor, 0 se igual, 1 se maior.
func compare(other: Quantity) -> int:
	if other.type != type:
		push_error("Quantity: comparação de grandezas diferentes.")
		return 0
	return int(signf(base_value - other.base_value))


## Retorna true se as grandezas forem do mesmo tipo e diferirem menos que a tolerância
## (informada com valor + unidade, ex.: 1, "cm").
func is_equal(other: Quantity, tolerance_value: float, tolerance_unit: String) -> bool:
	if other.type != type:
		return false
	var tolerance: float = Units.to_base(tolerance_value, tolerance_unit)
	return absf(base_value - other.base_value) <= tolerance


func duplicate() -> Quantity:
	return Quantity.new(type, base_value)


## Formata a grandeza. Sem argumento, escolhe uma unidade legível automaticamente.
func format(unit: String = "") -> String:
	return Units.format(base_value, type, unit)


func _to_string() -> String:
	return format()
