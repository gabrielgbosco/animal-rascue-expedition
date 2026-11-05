class_name Units
## Units — tabelas de conversão métricas e utilitários de grandezas e medidas.
##
## Concentra todo o conhecimento de unidades do jogo: fatores de conversão
## (múltiplos e submúltiplos), detecção do tipo de uma unidade e
## formatação/leitura de medidas no padrão brasileiro (vírgula decimal).
##
## Reaproveitável: novas grandezas só precisam de uma nova entrada em
## [member FACTORS], [member DISPLAY_UNITS] e [member BASE_UNIT].

## Tipos de grandeza suportados. (Massa e Capacidade já preparados para uso futuro.)
enum QuantityType { LENGTH, MASS, CAPACITY }

## Fatores de conversão em relação à unidade-base de cada grandeza (m / g / L).
const FACTORS: Dictionary = {
	QuantityType.LENGTH: {
		"mm": 0.001, "cm": 0.01, "dm": 0.1, "m": 1.0,
		"dam": 10.0, "hm": 100.0, "km": 1000.0,
	},
	QuantityType.MASS: {
		"mg": 0.001, "g": 1.0, "kg": 1000.0, "t": 1000000.0,
	},
	QuantityType.CAPACITY: {
		"mL": 0.001, "cL": 0.01, "dL": 0.1, "L": 1.0,
	},
}

## Unidade-base de cada grandeza (usada internamente para armazenar valores).
const BASE_UNIT: Dictionary = {
	QuantityType.LENGTH: "m",
	QuantityType.MASS: "g",
	QuantityType.CAPACITY: "L",
}

## Unidades preferidas para exibição automática (evita dm/dam/hm por serem raras na escola).
const DISPLAY_UNITS: Dictionary = {
	QuantityType.LENGTH: ["mm", "cm", "m", "km"],
	QuantityType.MASS: ["mg", "g", "kg", "t"],
	QuantityType.CAPACITY: ["mL", "cL", "L"],
}


## Retorna a tabela de fatores de conversão de um tipo de grandeza.
static func factors_for(type: int) -> Dictionary:
	return FACTORS.get(type, {})


## Descobre o tipo de grandeza de uma unidade (ex.: "cm" -> LENGTH).
## Retorna -1 se a unidade for desconhecida.
static func get_type(unit: String) -> int:
	for type: int in FACTORS:
		if (FACTORS[type] as Dictionary).has(unit):
			return type
	return -1


## Retorna true se a unidade for conhecida.
static func is_valid_unit(unit: String) -> bool:
	return get_type(unit) != -1


## Fator de conversão de uma unidade para a unidade-base da sua grandeza.
static func factor(unit: String) -> float:
	var type: int = get_type(unit)
	if type == -1:
		push_error("Units: unidade desconhecida '%s'." % unit)
		return 1.0
	return (FACTORS[type] as Dictionary)[unit]


## Converte um valor de uma unidade qualquer para a unidade-base (m / g / L).
static func to_base(value: float, unit: String) -> float:
	return value * factor(unit)


## Converte um valor expresso na unidade-base para outra unidade.
static func from_base(base_value: float, unit: String) -> float:
	return base_value / factor(unit)


## Converte um valor entre duas unidades da mesma grandeza (ex.: 150 cm -> m).
static func convert(value: float, from_unit: String, to_unit: String) -> float:
	if get_type(from_unit) != get_type(to_unit):
		push_error("Units: conversão inválida entre '%s' e '%s'." % [from_unit, to_unit])
		return value
	return from_base(to_base(value, from_unit), to_unit)


## Formata um número no padrão brasileiro: vírgula decimal, sem zeros à direita.
static func format_value(value: float) -> String:
	var text: String = String.num(value, 3)
	if text.contains("."):
		text = text.rstrip("0")
		text = text.rstrip(".")
	return text.replace(".", ",")


## Escolhe a unidade mais legível para exibir um valor em unidade-base.
static func auto_unit(base_value: float, type: int) -> String:
	var units: Array = DISPLAY_UNITS.get(type, [])
	var best: String = ""
	for unit: String in units:
		if absf(from_base(base_value, unit)) >= 1.0:
			best = unit
	if best == "":
		# Nenhuma unidade chegou a 1 (caso comum no valor 0): usa a unidade-base
		# da grandeza (m / g / L) em vez da menor, que seria confuso ("0 mm").
		best = str(BASE_UNIT.get(type, units[0] if units.size() > 0 else ""))
	return best


## Formata um valor (em unidade-base) para exibição.
## Se [param unit] for vazio, escolhe uma unidade legível automaticamente.
static func format(base_value: float, type: int, unit: String = "") -> String:
	var chosen: String = unit
	if chosen == "":
		chosen = auto_unit(base_value, type)
	return "%s %s" % [format_value(from_base(base_value, chosen)), chosen]
